#!/usr/bin/env python3
"""PIPI 앱 백엔드 API 서버 (Python 표준 라이브러리 + SQLite3).

프론트엔드(Flutter Web / Android / iOS)의 모든 기능과 1:1 매칭되는
RESTful API 및 SQLite 영구 저장소를 제공합니다.

실행 방법:
    python3 backend/server.py
기본 포트: 3000 (환경변수 PORT로 변경 가능)
"""

from __future__ import annotations

import hashlib
import json
import os
import secrets
import sqlite3
import threading
from datetime import datetime, timezone
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any, Optional
from urllib.parse import urlparse

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_DB_PATH = os.path.join(BASE_DIR, "pipi.db")


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha256_hex(raw: str) -> str:
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def stage_for_level(level: int) -> str:
    if level >= 7:
        return "adult"
    if level >= 3:
        return "teen"
    return "baby"


class PipiDatabase:
    """SQLite 기반 사용자/세션/캐릭터/일정 데이터 저장소."""

    def __init__(self, db_path: str = DEFAULT_DB_PATH) -> None:
        self.db_path = db_path
        self._lock = threading.Lock()
        self._init_schema()

    def _connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.db_path, check_same_thread=False)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA foreign_keys = ON;")
        return conn

    def _init_schema(self) -> None:
        with self._lock, self._connect() as conn:
            conn.executescript(
                """
                CREATE TABLE IF NOT EXISTS users (
                    id TEXT PRIMARY KEY,
                    password_hash TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    intro_seen INTEGER NOT NULL DEFAULT 0
                );

                CREATE TABLE IF NOT EXISTS sessions (
                    token TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                );

                CREATE TABLE IF NOT EXISTS characters (
                    user_id TEXT PRIMARY KEY,
                    type TEXT NOT NULL,
                    color TEXT NOT NULL,
                    name TEXT NOT NULL,
                    level INTEGER NOT NULL DEFAULT 1,
                    exp INTEGER NOT NULL DEFAULT 0,
                    stage TEXT NOT NULL DEFAULT 'baby',
                    intimacy INTEGER NOT NULL DEFAULT 50,
                    coins INTEGER NOT NULL DEFAULT 100,
                    snacks INTEGER NOT NULL DEFAULT 5,
                    owned_items TEXT NOT NULL DEFAULT '[]',
                    equipped_items TEXT NOT NULL DEFAULT '[]',
                    last_visit TEXT NOT NULL,
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                );

                CREATE TABLE IF NOT EXISTS tasks (
                    id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    title TEXT NOT NULL,
                    duration_min INTEGER NOT NULL DEFAULT 60,
                    goal TEXT NOT NULL DEFAULT '',
                    start_date TEXT NOT NULL,
                    end_date TEXT NOT NULL,
                    alert_before INTEGER NOT NULL DEFAULT 0,
                    priority TEXT NOT NULL DEFAULT 'medium',
                    category TEXT NOT NULL DEFAULT 'personal',
                    placed_date TEXT,
                    start_time TEXT,
                    status TEXT NOT NULL DEFAULT 'placed',
                    proof_image_path TEXT,
                    completed_at TEXT,
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                );
                """
            )

    def _create_session(self, conn: sqlite3.Connection, user_id: str) -> str:
        token = secrets.token_urlsafe(32)
        conn.execute(
            "INSERT INTO sessions (token, user_id, created_at) VALUES (?, ?, ?)",
            (token, user_id, utc_now_iso()),
        )
        return token

    def get_user_by_token(self, token: Optional[str]) -> Optional[dict[str, Any]]:
        if not token:
            return None
        with self._lock, self._connect() as conn:
            row = conn.execute(
                """
                SELECT u.id, u.password_hash, u.created_at, u.intro_seen
                FROM sessions s
                JOIN users u ON u.id = s.user_id
                WHERE s.token = ?
                """,
                (token,),
            ).fetchone()
            return dict(row) if row else None

    def signup(self, user_id: str, password: str) -> tuple[dict[str, Any], str]:
        trimmed = user_id.strip()
        if len(trimmed) < 3:
            raise ValueError("아이디는 최소 3자 이상이어야 합니다.")
        if len(password) < 4:
            raise ValueError("비밀번호는 최소 4자 이상이어야 합니다.")

        pw_hash = sha256_hex(password)
        now = utc_now_iso()
        with self._lock, self._connect() as conn:
            exists = conn.execute(
                "SELECT 1 FROM users WHERE id = ?", (trimmed,)
            ).fetchone()
            if exists:
                raise LookupError("이미 사용 중인 아이디입니다.")

            conn.execute(
                "INSERT INTO users (id, password_hash, created_at, intro_seen) VALUES (?, ?, ?, 0)",
                (trimmed, pw_hash, now),
            )
            token = self._create_session(conn, trimmed)
            return {
                "id": trimmed,
                "passwordHash": pw_hash,
                "createdAt": now,
                "introSeen": False,
            }, token

    def login(self, user_id: str, password: str) -> tuple[dict[str, Any], str]:
        trimmed = user_id.strip()
        if not trimmed or not password:
            raise ValueError("아이디와 비밀번호를 입력해주세요.")

        pw_hash = sha256_hex(password)
        with self._lock, self._connect() as conn:
            row = conn.execute(
                "SELECT id, password_hash, created_at, intro_seen FROM users WHERE id = ?",
                (trimmed,),
            ).fetchone()
            if row is None:
                raise LookupError("가입되지 않은 아이디입니다.")
            if row["password_hash"] != pw_hash:
                raise PermissionError("비밀번호가 올바르지 않습니다.")
            token = self._create_session(conn, trimmed)
            return {
                "id": row["id"],
                "passwordHash": row["password_hash"],
                "createdAt": row["created_at"],
                "introSeen": bool(row["intro_seen"]),
            }, token

    def social_login(self, provider: str) -> tuple[dict[str, Any], str]:
        social_id = "kakao_user" if provider == "kakao" else "google_user"
        with self._lock, self._connect() as conn:
            row = conn.execute(
                "SELECT id, password_hash, created_at, intro_seen FROM users WHERE id = ?",
                (social_id,),
            ).fetchone()
            if row is None:
                pw_hash = sha256_hex(f"{social_id}_social_oauth_salt")
                now = utc_now_iso()
                conn.execute(
                    "INSERT INTO users (id, password_hash, created_at, intro_seen) VALUES (?, ?, ?, 0)",
                    (social_id, pw_hash, now),
                )
                user_dict = {
                    "id": social_id,
                    "passwordHash": pw_hash,
                    "createdAt": now,
                    "introSeen": False,
                }
            else:
                user_dict = {
                    "id": row["id"],
                    "passwordHash": row["password_hash"],
                    "createdAt": row["created_at"],
                    "introSeen": bool(row["intro_seen"]),
                }
            token = self._create_session(conn, social_id)
            return user_dict, token

    def logout(self, token: str) -> None:
        with self._lock, self._connect() as conn:
            conn.execute("DELETE FROM sessions WHERE token = ?", (token,))

    def delete_account(self, user_id: str) -> None:
        with self._lock, self._connect() as conn:
            conn.execute("DELETE FROM users WHERE id = ?", (user_id,))

    def get_intro_seen(self, user_id: str) -> bool:
        with self._lock, self._connect() as conn:
            row = conn.execute(
                "SELECT intro_seen FROM users WHERE id = ?", (user_id,)
            ).fetchone()
            return bool(row["intro_seen"]) if row else False

    def mark_intro_seen(self, user_id: str) -> None:
        with self._lock, self._connect() as conn:
            conn.execute(
                "UPDATE users SET intro_seen = 1 WHERE id = ?", (user_id,)
            )

    def _row_to_character(self, row: sqlite3.Row) -> dict[str, Any]:
        return {
            "type": row["type"],
            "color": row["color"],
            "name": row["name"],
            "level": row["level"],
            "exp": row["exp"],
            "stage": row["stage"],
            "intimacy": row["intimacy"],
            "coins": row["coins"],
            "snacks": row["snacks"],
            "ownedItems": json.loads(row["owned_items"]),
            "equippedItems": json.loads(row["equipped_items"]),
            "lastVisit": row["last_visit"],
        }

    def get_character(self, user_id: str) -> Optional[dict[str, Any]]:
        with self._lock, self._connect() as conn:
            row = conn.execute(
                "SELECT * FROM characters WHERE user_id = ?", (user_id,)
            ).fetchone()
            return self._row_to_character(row) if row else None

    def save_character(self, user_id: str, data: dict[str, Any]) -> dict[str, Any]:
        now = data.get("lastVisit") or utc_now_iso()
        owned = json.dumps(data.get("ownedItems", []))
        equipped = json.dumps(data.get("equippedItems", []))
        with self._lock, self._connect() as conn:
            conn.execute(
                """
                INSERT INTO characters (
                    user_id, type, color, name, level, exp, stage,
                    intimacy, coins, snacks, owned_items, equipped_items, last_visit
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(user_id) DO UPDATE SET
                    type=excluded.type,
                    color=excluded.color,
                    name=excluded.name,
                    level=excluded.level,
                    exp=excluded.exp,
                    stage=excluded.stage,
                    intimacy=excluded.intimacy,
                    coins=excluded.coins,
                    snacks=excluded.snacks,
                    owned_items=excluded.owned_items,
                    equipped_items=excluded.equipped_items,
                    last_visit=excluded.last_visit
                """,
                (
                    user_id,
                    data.get("type", "cat"),
                    data.get("color", "#FFFFFF"),
                    data.get("name", "피피"),
                    int(data.get("level", 1)),
                    int(data.get("exp", 0)),
                    data.get("stage", "baby"),
                    int(data.get("intimacy", 50)),
                    int(data.get("coins", 100)),
                    int(data.get("snacks", 5)),
                    owned,
                    equipped,
                    now,
                ),
            )
            row = conn.execute(
                "SELECT * FROM characters WHERE user_id = ?", (user_id,)
            ).fetchone()
            return self._row_to_character(row)

    def feed_character(self, user_id: str) -> dict[str, Any]:
        with self._lock, self._connect() as conn:
            row = conn.execute(
                "SELECT * FROM characters WHERE user_id = ?", (user_id,)
            ).fetchone()
            if row is None:
                raise LookupError("캐릭터를 찾을 수 없습니다.")
            if row["snacks"] <= 0:
                raise ValueError("간식이 부족합니다.")

            snacks = row["snacks"] - 1
            exp = row["exp"] + 20
            level = row["level"]
            while exp >= 100:
                exp -= 100
                level += 1
            stage = stage_for_level(level)
            intimacy = min(100, row["intimacy"] + 5)

            conn.execute(
                """
                UPDATE characters
                SET snacks = ?, exp = ?, level = ?, stage = ?, intimacy = ?, last_visit = ?
                WHERE user_id = ?
                """,
                (snacks, exp, level, stage, intimacy, utc_now_iso(), user_id),
            )
            updated = conn.execute(
                "SELECT * FROM characters WHERE user_id = ?", (user_id,)
            ).fetchone()
            return self._row_to_character(updated)

    def play_character(self, user_id: str) -> dict[str, Any]:
        with self._lock, self._connect() as conn:
            row = conn.execute(
                "SELECT * FROM characters WHERE user_id = ?", (user_id,)
            ).fetchone()
            if row is None:
                raise LookupError("캐릭터를 찾을 수 없습니다.")

            exp = row["exp"] + 15
            level = row["level"]
            while exp >= 100:
                exp -= 100
                level += 1
            stage = stage_for_level(level)
            coins = row["coins"] + 10
            intimacy = min(100, row["intimacy"] + 4)

            conn.execute(
                """
                UPDATE characters
                SET exp = ?, level = ?, stage = ?, coins = ?, intimacy = ?, last_visit = ?
                WHERE user_id = ?
                """,
                (exp, level, stage, coins, intimacy, utc_now_iso(), user_id),
            )
            updated = conn.execute(
                "SELECT * FROM characters WHERE user_id = ?", (user_id,)
            ).fetchone()
            return self._row_to_character(updated)

    def delete_character(self, user_id: str) -> None:
        with self._lock, self._connect() as conn:
            conn.execute("DELETE FROM characters WHERE user_id = ?", (user_id,))

    def _row_to_task(self, row: sqlite3.Row) -> dict[str, Any]:
        return {
            "id": row["id"],
            "title": row["title"],
            "durationMin": row["duration_min"],
            "goal": row["goal"],
            "startDate": row["start_date"],
            "endDate": row["end_date"],
            "alertBefore": row["alert_before"],
            "priority": row["priority"],
            "category": row["category"],
            "placedDate": row["placed_date"],
            "startTime": row["start_time"],
            "status": row["status"],
            "proofImagePath": row["proof_image_path"],
            "completedAt": row["completed_at"],
        }

    def list_tasks(self, user_id: str) -> list[dict[str, Any]]:
        with self._lock, self._connect() as conn:
            rows = conn.execute(
                "SELECT * FROM tasks WHERE user_id = ? ORDER BY start_date ASC",
                (user_id,),
            ).fetchall()
            return [self._row_to_task(r) for r in rows]

    def upsert_task(self, user_id: str, data: dict[str, Any]) -> dict[str, Any]:
        task_id = data["id"]
        with self._lock, self._connect() as conn:
            conn.execute(
                """
                INSERT INTO tasks (
                    id, user_id, title, duration_min, goal, start_date, end_date,
                    alert_before, priority, category, placed_date, start_time,
                    status, proof_image_path, completed_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    title=excluded.title,
                    duration_min=excluded.duration_min,
                    goal=excluded.goal,
                    start_date=excluded.start_date,
                    end_date=excluded.end_date,
                    alert_before=excluded.alert_before,
                    priority=excluded.priority,
                    category=excluded.category,
                    placed_date=excluded.placed_date,
                    start_time=excluded.start_time,
                    status=excluded.status,
                    proof_image_path=excluded.proof_image_path,
                    completed_at=excluded.completed_at
                WHERE tasks.user_id = excluded.user_id
                """,
                (
                    task_id,
                    user_id,
                    data["title"],
                    int(data.get("durationMin", 60)),
                    data.get("goal", ""),
                    data["startDate"],
                    data["endDate"],
                    int(data.get("alertBefore", 0)),
                    data.get("priority", "medium"),
                    data.get("category", "personal"),
                    data.get("placedDate"),
                    data.get("startTime"),
                    data.get("status", "placed"),
                    data.get("proofImagePath"),
                    data.get("completedAt"),
                ),
            )
            row = conn.execute(
                "SELECT * FROM tasks WHERE id = ? AND user_id = ?",
                (task_id, user_id),
            ).fetchone()
            return self._row_to_task(row)

    def delete_task(self, user_id: str, task_id: str) -> None:
        with self._lock, self._connect() as conn:
            conn.execute(
                "DELETE FROM tasks WHERE id = ? AND user_id = ?",
                (task_id, user_id),
            )

    def complete_task(
        self, user_id: str, task_id: str, proof_image_path: str
    ) -> dict[str, Any]:
        now = utc_now_iso()
        with self._lock, self._connect() as conn:
            row = conn.execute(
                "SELECT * FROM tasks WHERE id = ? AND user_id = ?",
                (task_id, user_id),
            ).fetchone()
            if row is None:
                raise LookupError("일정을 찾을 수 없습니다.")

            conn.execute(
                """
                UPDATE tasks
                SET status = 'completed', proof_image_path = ?, completed_at = ?
                WHERE id = ? AND user_id = ?
                """,
                (proof_image_path, now, task_id, user_id),
            )
            updated_task = conn.execute(
                "SELECT * FROM tasks WHERE id = ? AND user_id = ?",
                (task_id, user_id),
            ).fetchone()

            # 보상 지급 (경험치 +30, 코인 +20, 간식 +1, 애정도 +5)
            char_row = conn.execute(
                "SELECT * FROM characters WHERE user_id = ?", (user_id,)
            ).fetchone()
            if char_row is not None:
                exp = char_row["exp"] + 30
                level = char_row["level"]
                while exp >= 100:
                    exp -= 100
                    level += 1
                stage = stage_for_level(level)
                conn.execute(
                    """
                    UPDATE characters
                    SET exp = ?, level = ?, stage = ?,
                        coins = coins + 20, snacks = snacks + 1,
                        intimacy = MIN(100, intimacy + 5)
                    WHERE user_id = ?
                    """,
                    (exp, level, stage, user_id),
                )

            return self._row_to_task(updated_task)


class PipiRequestHandler(BaseHTTPRequestHandler):
    """CORS 및 JSON API 라우팅 핸들러."""

    db: PipiDatabase  # 주입됨

    def log_message(self, format: str, *args: Any) -> None:
        return  # 테스트/콘솔 출력 깔끔하게 유지

    def _send_cors_headers(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header(
            "Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS"
        )
        self.send_header(
            "Access-Control-Allow-Headers", "Content-Type, Authorization"
        )

    def _send_json(self, status: int, payload: Any) -> None:
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self._send_cors_headers()
        self.end_headers()
        self.wfile.write(body)

    def _read_json(self) -> dict[str, Any]:
        length = int(self.headers.get("Content-Length", "0"))
        if length == 0:
            return {}
        raw = self.rfile.read(length).decode("utf-8")
        return json.loads(raw) if raw else {}

    def _bearer_token(self) -> Optional[str]:
        auth = self.headers.get("Authorization", "")
        if auth.startswith("Bearer "):
            return auth[7:].strip()
        return None

    def _require_user(self) -> Optional[dict[str, Any]]:
        token = self._bearer_token()
        user = self.db.get_user_by_token(token)
        if user is None:
            self._send_json(HTTPStatus.UNAUTHORIZED, {"error": "인증이 필요합니다."})
            return None
        return user

    def do_OPTIONS(self) -> None:
        self.send_response(HTTPStatus.NO_CONTENT)
        self._send_cors_headers()
        self.end_headers()

    def do_GET(self) -> None:
        path = urlparse(self.path).path

        if path == "/api/health":
            self._send_json(HTTPStatus.OK, {"status": "ok", "service": "pipi-backend"})
            return

        user = self._require_user()
        if user is None:
            return
        user_id = user["id"]

        if path == "/api/auth/me":
            self._send_json(
                HTTPStatus.OK,
                {
                    "id": user["id"],
                    "createdAt": user["created_at"],
                    "introSeen": bool(user["intro_seen"]),
                },
            )
        elif path == "/api/intro/status":
            self._send_json(
                HTTPStatus.OK, {"introSeen": self.db.get_intro_seen(user_id)}
            )
        elif path == "/api/character":
            char = self.db.get_character(user_id)
            if char is None:
                self._send_json(HTTPStatus.NOT_FOUND, {"error": "캐릭터가 없습니다."})
            else:
                self._send_json(HTTPStatus.OK, char)
        elif path == "/api/tasks":
            self._send_json(HTTPStatus.OK, {"tasks": self.db.list_tasks(user_id)})
        else:
            self._send_json(HTTPStatus.NOT_FOUND, {"error": "Not found"})

    def do_POST(self) -> None:
        path = urlparse(self.path).path
        data = self._read_json()

        try:
            if path == "/api/auth/signup":
                user, token = self.db.signup(
                    data.get("id", ""), data.get("password", "")
                )
                self._send_json(HTTPStatus.CREATED, {"user": user, "token": token})
                return
            if path == "/api/auth/login":
                user, token = self.db.login(
                    data.get("id", ""), data.get("password", "")
                )
                self._send_json(HTTPStatus.OK, {"user": user, "token": token})
                return
            if path == "/api/auth/social":
                user, token = self.db.social_login(data.get("provider", "kakao"))
                self._send_json(HTTPStatus.OK, {"user": user, "token": token})
                return
            if path == "/api/auth/logout":
                token = self._bearer_token()
                if token:
                    self.db.logout(token)
                self._send_json(HTTPStatus.OK, {"ok": True})
                return
        except ValueError as e:
            self._send_json(HTTPStatus.BAD_REQUEST, {"error": str(e)})
            return
        except LookupError as e:
            self._send_json(HTTPStatus.CONFLICT if "이미" in str(e) else HTTPStatus.NOT_FOUND, {"error": str(e)})
            return
        except PermissionError as e:
            self._send_json(HTTPStatus.UNAUTHORIZED, {"error": str(e)})
            return

        user = self._require_user()
        if user is None:
            return
        user_id = user["id"]

        try:
            if path == "/api/intro/seen":
                self.db.mark_intro_seen(user_id)
                self._send_json(HTTPStatus.OK, {"introSeen": True})
            elif path == "/api/character":
                saved = self.db.save_character(user_id, data)
                self._send_json(HTTPStatus.OK, saved)
            elif path == "/api/character/feed":
                updated = self.db.feed_character(user_id)
                self._send_json(HTTPStatus.OK, updated)
            elif path == "/api/character/play":
                updated = self.db.play_character(user_id)
                self._send_json(HTTPStatus.OK, updated)
            elif path == "/api/tasks":
                saved = self.db.upsert_task(user_id, data)
                self._send_json(HTTPStatus.CREATED, saved)
            elif path.startswith("/api/tasks/") and path.endswith("/complete"):
                task_id = path[len("/api/tasks/") : -len("/complete")]
                updated = self.db.complete_task(
                    user_id, task_id, data.get("proofImagePath", "camera_proof")
                )
                self._send_json(HTTPStatus.OK, updated)
            else:
                self._send_json(HTTPStatus.NOT_FOUND, {"error": "Not found"})
        except ValueError as e:
            self._send_json(HTTPStatus.BAD_REQUEST, {"error": str(e)})
        except LookupError as e:
            self._send_json(HTTPStatus.NOT_FOUND, {"error": str(e)})

    def do_PUT(self) -> None:
        path = urlparse(self.path).path
        user = self._require_user()
        if user is None:
            return
        user_id = user["id"]
        data = self._read_json()

        if path == "/api/character":
            saved = self.db.save_character(user_id, data)
            self._send_json(HTTPStatus.OK, saved)
        elif path.startswith("/api/tasks/"):
            task_id = path[len("/api/tasks/") :]
            data["id"] = task_id
            saved = self.db.upsert_task(user_id, data)
            self._send_json(HTTPStatus.OK, saved)
        else:
            self._send_json(HTTPStatus.NOT_FOUND, {"error": "Not found"})

    def do_DELETE(self) -> None:
        path = urlparse(self.path).path
        user = self._require_user()
        if user is None:
            return
        user_id = user["id"]

        if path == "/api/auth/account":
            self.db.delete_account(user_id)
            self._send_json(HTTPStatus.OK, {"ok": True})
        elif path == "/api/character":
            self.db.delete_character(user_id)
            self._send_json(HTTPStatus.OK, {"ok": True})
        elif path.startswith("/api/tasks/"):
            task_id = path[len("/api/tasks/") :]
            self.db.delete_task(user_id, task_id)
            self._send_json(HTTPStatus.OK, {"ok": True})
        else:
            self._send_json(HTTPStatus.NOT_FOUND, {"error": "Not found"})


def create_server(
    host: str = "0.0.0.0", port: int = 3000, db_path: str = DEFAULT_DB_PATH
) -> ThreadingHTTPServer:
    db = PipiDatabase(db_path=db_path)

    class BoundHandler(PipiRequestHandler):
        pass

    BoundHandler.db = db
    return ThreadingHTTPServer((host, port), BoundHandler)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "3000"))
    server = create_server(port=port)
    print(f"PIPI Backend Server running on http://localhost:{port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down PIPI Backend Server...")
        server.shutdown()

