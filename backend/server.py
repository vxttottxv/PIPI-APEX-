#!/usr/bin/env python3
"""PIPI 앱 백엔드 API 서버 (FastAPI + SQLite3).

프론트엔드(Flutter Web / Android / iOS)의 모든 기능과 1:1 매칭되는
RESTful API 및 SQLite 영구 저장소를 제공합니다.

실행 방법:
    python3 server.py
    또는: uvicorn server:app --host 0.0.0.0 --port 3000
기본 포트: 3000 (환경변수 PORT로 변경 가능)
"""

from __future__ import annotations

from contextlib import contextmanager
import hashlib
import json
import os
import re
import secrets
import sqlite3
import threading
from datetime import datetime, timezone, timedelta
from typing import Any, Optional
import urllib.error
import urllib.parse
import urllib.request
import bcrypt

from fastapi import FastAPI, Depends, Header, HTTPException, Request, APIRouter
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
import uvicorn

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 설정 (모바일 앱 전용 API 백엔드)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_DB_PATH = os.environ.get("DB_PATH") or os.path.join(BASE_DIR, "pipi.db")


# 세션 만료 시간 (7일)
SESSION_TTL = timedelta(days=7)


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 유틸리티
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def sha256_hex(raw: str) -> str:
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def hash_password(raw: str) -> str:
    """bcrypt 솔트 및 단방향 해싱 (새 회원가입 및 비밀번호 갱신 시 적용)."""
    return bcrypt.hashpw(raw.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(raw: str, stored_hash: str) -> tuple[bool, bool]:
    """비밀번호 검증 및 기존 레거시 SHA-256 마이그레이션 필요 여부 판별.

    반환값: (is_valid: bool, needs_rehash: bool)
    - 최신 bcrypt 해시($2a$, $2b$): bcrypt 검증 진행, needs_rehash=False
    - 레거시 SHA-256 해시: sha256_hex 검증 진행, 일치 시 needs_rehash=True (bcrypt 자동 업그레이드)
    """
    if stored_hash.startswith(("$2a$", "$2b$")):
        try:
            valid = bcrypt.checkpw(raw.encode("utf-8"), stored_hash.encode("utf-8"))
            return valid, False
        except Exception:
            return False, False

    # 기존 레거시 SHA-256 회원 호환성 보존
    legacy_hash = sha256_hex(raw)
    if stored_hash == legacy_hash:
        return True, True

    return False, False


def stage_for_level(level: int) -> str:
    if level >= 7:
        return "adult"
    if level >= 3:
        return "teen"
    return "baby"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 데이터베이스
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class PipiDatabase:
    """SQLite 기반 사용자/세션/캐릭터/일정 데이터 저장소."""

    def __init__(self, db_path: str = DEFAULT_DB_PATH) -> None:
        self.db_path = db_path
        self._lock = threading.Lock()
        self._init_schema()
        self._init_demo_account()

    @contextmanager
    def _connect(self):
        conn = sqlite3.connect(self.db_path, check_same_thread=False)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA foreign_keys = ON;")
        try:
            with conn:
                yield conn
        finally:
            conn.close()

    def _init_demo_account(self) -> None:
        """발표 당일 참석자용 공통 시연 계정, 기본 펫, 기본 일정을 자동 준비합니다.

        - 환경변수(DEMO_USER_ID, DEMO_EMAIL, DEMO_PASSWORD, DEMO_USER_PASSWORD)로 설정 시에만 활성화
        - 기본 하드코딩 계정/비밀번호는 일체 노출하지 않음
        - 계정이 이미 존재하면 중복 생성 및 데이터 덮어쓰기 방지
        - 비밀번호는 bcrypt 솔트 및 해시로 안전 저장
        """
        demo_id = (
            os.environ.get("DEMO_USER_ID")
            or os.environ.get("DEMO_EMAIL")
            or os.environ.get("DEMO_ID")
            or ""
        ).strip()
        demo_pw = (
            os.environ.get("DEMO_USER_PASSWORD")
            or os.environ.get("DEMO_PASSWORD")
            or ""
        ).strip()

        # 환경변수로 시연 계정이 지정되지 않은 경우 계정을 자동 생성하지 않음 (공개 저장소 보안)
        if not demo_id or not demo_pw:
            return

        now = utc_now_iso()
        today_date = datetime.now(timezone.utc).date().isoformat()
        pw_hash = hash_password(demo_pw)

        with self._lock, self._connect() as conn:
            # 1. 공통 시연 계정 존재 여부 확인 (기존 일반 계정 및 중복 생성 방지)
            user_row = conn.execute(
                "SELECT id FROM users WHERE id = ?", (demo_id,)
            ).fetchone()

            if user_row is None:
                # 시연 계정 자동 생성 (introSeen=1로 설정하여 스플래시 후 홈으로 바로 진입 가능)
                conn.execute(
                    """
                    INSERT INTO users (id, password_hash, created_at, intro_seen)
                    VALUES (?, ?, ?, 1)
                    """,
                    (demo_id, pw_hash, now),
                )

            # 2. 시연용 기본 펫 확인 및 최초 1회 생성
            char_row = conn.execute(
                "SELECT user_id FROM characters WHERE user_id = ?", (demo_id,)
            ).fetchone()
            if char_row is None:
                conn.execute(
                    """
                    INSERT INTO characters (
                        user_id, type, color, name, level, exp, stage,
                        intimacy, coins, snacks, owned_items, equipped_items, last_visit
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        demo_id,
                        "cat",
                        "default",
                        "피피",
                        1,
                        30,
                        "baby",
                        60,
                        150,
                        5,
                        "[]",
                        "[]",
                        now,
                    ),
                )

            # 3. 시연용 기본 일정 확인 및 최초 1회 생성
            task_rows = conn.execute(
                "SELECT id FROM tasks WHERE user_id = ?", (demo_id,)
            ).fetchall()
            if not task_rows:
                task_1_id = f"demo_task_1_{hashlib.md5(demo_id.encode()).hexdigest()[:8]}"
                task_2_id = f"demo_task_2_{hashlib.md5(demo_id.encode()).hexdigest()[:8]}"
                conn.execute(
                    """
                    INSERT INTO tasks (
                        id, user_id, title, duration_min, goal, start_date, end_date,
                        alert_before, priority, category, placed_date, start_time,
                        status, proof_image_path, completed_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        task_1_id,
                        demo_id,
                        "PIPI 프로젝트 발표 경청하기",
                        60,
                        "프로젝트 소개 및 기능 시연 참관",
                        today_date,
                        today_date,
                        10,
                        "high",
                        "activity",
                        today_date,
                        "14:00",
                        "placed",
                        None,
                        None,
                    ),
                )
                conn.execute(
                    """
                    INSERT INTO tasks (
                        id, user_id, title, duration_min, goal, start_date, end_date,
                        alert_before, priority, category, placed_date, start_time,
                        status, proof_image_path, completed_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        task_2_id,
                        demo_id,
                        "펫 밥주기 및 일정 인증 완료해보기",
                        30,
                        "간식 주기와 사진 인증으로 캐릭터 성장시키기",
                        today_date,
                        today_date,
                        10,
                        "medium",
                        "personal",
                        today_date,
                        "15:30",
                        "placed",
                        None,
                        None,
                    ),
                )

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

    # ── 세션 ────────────────────────────────────────────────────────
    def cleanup_expired_sessions(self) -> int:
        """7일 이상 경과한 모든 만료 세션을 DB에서 일괄 정리합니다."""
        now = datetime.now(timezone.utc)
        threshold = (now - SESSION_TTL).isoformat()
        with self._lock, self._connect() as conn:
            cursor = conn.execute(
                "DELETE FROM sessions WHERE created_at < ?", (threshold,)
            )
            return cursor.rowcount

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
                SELECT u.id, u.password_hash, u.created_at, u.intro_seen, s.created_at AS session_created_at
                FROM sessions s
                JOIN users u ON u.id = s.user_id
                WHERE s.token = ?
                """,
                (token,),
            ).fetchone()
            if not row:
                return None

            # 1. session_created_at 존재 및 형식 검증
            raw_created_at = row["session_created_at"]
            if not raw_created_at:
                conn.execute("DELETE FROM sessions WHERE token = ?", (token,))
                return None

            try:
                session_dt = datetime.fromisoformat(raw_created_at)
                if session_dt.tzinfo is None:
                    session_dt = session_dt.replace(tzinfo=timezone.utc)
            except Exception:
                # created_at이 비정상/손상된 형식이면 즉시 폐기하고 인증 거부
                conn.execute("DELETE FROM sessions WHERE token = ?", (token,))
                return None

            # 2. 7일 만료 시간 검증 (순수 UTC 기준)
            now_utc = datetime.now(timezone.utc)
            if now_utc - session_dt > SESSION_TTL:
                # 7일 초과 시 만료 세션을 DB에서 자동 삭제하고 인증 거부
                conn.execute("DELETE FROM sessions WHERE token = ?", (token,))
                return None

            return {
                "id": row["id"],
                "password_hash": row["password_hash"],
                "created_at": row["created_at"],
                "intro_seen": row["intro_seen"],
            }

    # ── 인증 ────────────────────────────────────────────────────────
    def signup(self, user_id: str, password: str) -> tuple[dict[str, Any], str]:
        trimmed = user_id.strip()
        if len(trimmed) < 3:
            raise ValueError("아이디는 최소 3자 이상이어야 합니다.")
        if len(password) < 4:
            raise ValueError("비밀번호는 최소 4자 이상이어야 합니다.")

        pw_hash = hash_password(password)
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

        with self._lock, self._connect() as conn:
            row = conn.execute(
                "SELECT id, password_hash, created_at, intro_seen FROM users WHERE id = ?",
                (trimmed,),
            ).fetchone()
            if row is None:
                raise LookupError("가입되지 않은 아이디입니다.")

            is_valid, needs_rehash = verify_password(password, row["password_hash"])
            if not is_valid:
                raise PermissionError("비밀번호가 올바르지 않습니다.")

            # 기존 레거시 SHA-256 사용자인 경우 최신 bcrypt로 무중단 투명 마이그레이션
            current_hash = row["password_hash"]
            if needs_rehash:
                current_hash = hash_password(password)
                conn.execute(
                    "UPDATE users SET password_hash = ? WHERE id = ?",
                    (current_hash, trimmed),
                )

            token = self._create_session(conn, trimmed)
            return {
                "id": row["id"],
                "passwordHash": current_hash,
                "createdAt": row["created_at"],
                "introSeen": bool(row["intro_seen"]),
            }, token

    def social_login(
        self, provider: str, account_id: Optional[str] = None
    ) -> tuple[dict[str, Any], str]:
        normalized_provider = "kakao" if provider == "kakao" else "google"
        raw_acc = (account_id or "").strip().lower()
        if raw_acc:
            safe_acc = re.sub(r"[^a-z0-9._@-]", "_", raw_acc)[:60]
            prefix = f"{normalized_provider}_"
            social_id = safe_acc if safe_acc.startswith(prefix) else f"{prefix}{safe_acc}"
        else:
            social_id = f"{normalized_provider}_user"
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

    def kakao_login(
        self,
        kakao_id: str,
        email: Optional[str] = None,
        nickname: Optional[str] = None,
    ) -> tuple[dict[str, Any], str]:
        """검증된 카카오 고유 회원번호로 회원을 조회하거나 신규 등록하고 세션 토큰을 발급합니다."""
        user_id = f"kakao_{kakao_id}"
        with self._lock, self._connect() as conn:
            row = conn.execute(
                "SELECT id, password_hash, created_at, intro_seen FROM users WHERE id = ?",
                (user_id,),
            ).fetchone()
            if row is None:
                pw_hash = sha256_hex(f"{user_id}_kakao_verified_salt")
                now = utc_now_iso()
                conn.execute(
                    "INSERT INTO users (id, password_hash, created_at, intro_seen) VALUES (?, ?, ?, 0)",
                    (user_id, pw_hash, now),
                )
                user_dict = {
                    "id": user_id,
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
            token = self._create_session(conn, user_id)
            return user_dict, token

    def logout(self, token: str) -> None:
        with self._lock, self._connect() as conn:
            conn.execute("DELETE FROM sessions WHERE token = ?", (token,))

    def delete_account(self, user_id: str) -> None:
        with self._lock, self._connect() as conn:
            conn.execute("DELETE FROM users WHERE id = ?", (user_id,))

    # ── 인트로 ──────────────────────────────────────────────────────
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

    # ── 캐릭터 ──────────────────────────────────────────────────────
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

    # ── 할 일 ──────────────────────────────────────────────────────
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


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Pydantic 요청 모델
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class SignupRequest(BaseModel):
    id: str
    password: str


class LoginRequest(BaseModel):
    id: str
    password: str


class SocialLoginRequest(BaseModel):
    provider: str = "kakao"
    accountId: Optional[str] = None
    email: Optional[str] = None


class KakaoAuthRequest(BaseModel):
    accessToken: Optional[str] = None
    code: Optional[str] = None
    redirectUri: Optional[str] = None


class KakaoWebAuthRequest(BaseModel):
    code: str
    redirectUri: str


class CharacterRequest(BaseModel):
    type: str = "cat"
    color: str = "#FFFFFF"
    name: str = "피피"
    level: int = 1
    exp: int = 0
    stage: str = "baby"
    intimacy: int = 50
    coins: int = 100
    snacks: int = 5
    ownedItems: list = []
    equippedItems: list = []
    lastVisit: Optional[str] = None


class TaskCreateRequest(BaseModel):
    id: str
    title: str
    durationMin: int = 60
    goal: str = ""
    startDate: str
    endDate: str
    alertBefore: int = 0
    priority: str = "medium"
    category: str = "personal"
    placedDate: Optional[str] = None
    startTime: Optional[str] = None
    status: str = "placed"
    proofImagePath: Optional[str] = None
    completedAt: Optional[str] = None


class TaskUpdateRequest(BaseModel):
    title: str
    durationMin: int = 60
    goal: str = ""
    startDate: str
    endDate: str
    alertBefore: int = 0
    priority: str = "medium"
    category: str = "personal"
    placedDate: Optional[str] = None
    startTime: Optional[str] = None
    status: str = "placed"
    proofImagePath: Optional[str] = None
    completedAt: Optional[str] = None


class CompleteTaskRequest(BaseModel):
    proofImagePath: str = "camera_proof"


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# FastAPI 의존성 (Dependency Injection)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
def get_db(request: Request) -> PipiDatabase:
    """요청별로 앱에 주입된 DB 인스턴스를 반환합니다."""
    return request.app.state.db


def get_bearer_token(authorization: Optional[str] = Header(None)) -> Optional[str]:
    """Authorization 헤더에서 Bearer 토큰을 추출합니다."""
    if authorization and authorization.startswith("Bearer "):
        return authorization[7:].strip()
    return None


def require_user(
    db: PipiDatabase = Depends(get_db),
    token: Optional[str] = Depends(get_bearer_token),
) -> dict[str, Any]:
    """인증된 사용자를 반환합니다. 미인증 시 401 에러."""
    if not token:
        raise HTTPException(status_code=401, detail="인증이 필요합니다.")
    user = db.get_user_by_token(token)
    if user is None:
        raise HTTPException(status_code=401, detail="인증이 필요합니다.")
    return user


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# API 라우터
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
router = APIRouter(prefix="/api")


# ── 1. 헬스체크 ─────────────────────────────────────────────────────
@router.get("/health")
def health_check():
    return {"status": "ok", "service": "pipi-backend"}


# ── 2. 인증 ─────────────────────────────────────────────────────────
@router.post("/auth/signup", status_code=201)
def signup(body: SignupRequest, db: PipiDatabase = Depends(get_db)):
    try:
        user, token = db.signup(body.id, body.password)
        return {"user": user, "token": token}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except LookupError as e:
        raise HTTPException(status_code=409, detail=str(e))


@router.post("/auth/login")
def login(body: LoginRequest, db: PipiDatabase = Depends(get_db)):
    try:
        user, token = db.login(body.id, body.password)
        return {"user": user, "token": token}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except LookupError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except PermissionError as e:
        raise HTTPException(status_code=401, detail=str(e))


@router.post("/auth/social")
def social_login(body: SocialLoginRequest, db: PipiDatabase = Depends(get_db)):
    user, token = db.social_login(
        body.provider,
        account_id=body.accountId or body.email,
    )
    return {"user": user, "token": token}


def verify_kakao_token_and_login(access_token: str, db: PipiDatabase) -> dict[str, Any]:
    """카카오 공식 API 서버로 Access Token을 전송하여 사용자 정보를 조회하고 PP 회원을 식별합니다."""
    token_str = access_token.strip()
    if not token_str:
        raise HTTPException(status_code=400, detail="카카오 액세스 토큰이 필요합니다.")

    url = "https://kapi.kakao.com/v2/user/me"
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {token_str}",
            "Content-Type": "application/x-www-form-urlencoded;charset=utf-8",
        },
        method="GET",
    )

    try:
        with urllib.request.urlopen(req, timeout=7) as response:
            res_data = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        raise HTTPException(
            status_code=401,
            detail=f"유효하지 않거나 만료된 카카오 토큰입니다 ({e.code}).",
        )
    except Exception as e:
        raise HTTPException(
            status_code=502,
            detail=f"카카오 인증 서버에 연결할 수 없습니다: {e}",
        )

    kakao_id = res_data.get("id")
    if not kakao_id:
        raise HTTPException(
            status_code=400, detail="카카오 회원 식별자를 확인할 수 없습니다."
        )

    kakao_account = res_data.get("kakao_account", {})
    email = kakao_account.get("email")
    profile = kakao_account.get("profile", {})
    nickname = profile.get("nickname")

    user, pp_token = db.kakao_login(str(kakao_id), email=email, nickname=nickname)
    return {"user": user, "token": pp_token}


def exchange_kakao_code_for_token(code: str, redirect_uri: str) -> str:
    """웹 OAuth 2.0 Authorization Code를 카카오 토큰 API와 통신하여 Access Token으로 교환합니다."""
    client_id = (
        os.environ.get("KAKAO_REST_API_KEY")
        or os.environ.get("KAKAO_CLIENT_ID")
        or ""
    ).strip()
    if not client_id:
        raise HTTPException(
            status_code=500,
            detail="서버에 KAKAO_REST_API_KEY 환경 변수가 설정되지 않았습니다. Render 대시보드에서 환경 변수를 등록해주세요.",
        )
    client_secret = os.environ.get("KAKAO_CLIENT_SECRET", "").strip()

    token_url = "https://kauth.kakao.com/oauth/token"
    token_params = {
        "grant_type": "authorization_code",
        "client_id": client_id,
        "redirect_uri": redirect_uri.strip(),
        "code": code.strip(),
    }
    if client_secret:
        token_params["client_secret"] = client_secret

    encoded = urllib.parse.urlencode(token_params).encode("utf-8")
    req = urllib.request.Request(
        token_url,
        data=encoded,
        headers={
            "Content-Type": "application/x-www-form-urlencoded;charset=utf-8",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=7) as response:
            token_res = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="ignore")
        try:
            err_json = json.loads(err_body)
            err_msg = err_json.get("error_description") or err_json.get("error") or str(e)
        except Exception:
            err_msg = str(e)
        raise HTTPException(
            status_code=400,
            detail=f"카카오 인가 코드 교환 실패: {err_msg}",
        )
    except Exception as e:
        raise HTTPException(
            status_code=502,
            detail=f"카카오 토큰 서버 연결 오류: {e}",
        )

    access_token = token_res.get("access_token")
    if not access_token:
        raise HTTPException(
            status_code=400, detail="카카오 액세스 토큰을 수신하지 못했습니다."
        )
    return str(access_token)


@router.post("/auth/kakao")
def kakao_login_route(body: KakaoAuthRequest, db: PipiDatabase = Depends(get_db)):
    """카카오 공식 API 인증. 모바일(accessToken)과 웹(code+redirectUri)을 모두 지원합니다."""
    # 1. 모바일: 클라이언트가 이미 발급받은 accessToken을 직접 전달한 경우
    if body.accessToken and body.accessToken.strip():
        return verify_kakao_token_and_login(body.accessToken, db)

    # 2. 웹: 클라이언트가 인가 코드(code)와 redirectUri를 전달한 경우 (백엔드 토큰 교환)
    if body.code and body.code.strip() and body.redirectUri and body.redirectUri.strip():
        access_token = exchange_kakao_code_for_token(body.code, body.redirectUri)
        return verify_kakao_token_and_login(access_token, db)

    raise HTTPException(
        status_code=400,
        detail="카카오 액세스 토큰 또는 인가 코드(code, redirectUri)가 필요합니다.",
    )


@router.post("/auth/kakao/web")
def kakao_web_login_route(body: KakaoWebAuthRequest, db: PipiDatabase = Depends(get_db)):
    """웹 전용 OAuth 2.0 Authorization Code 인증 엔드포인트."""
    access_token = exchange_kakao_code_for_token(body.code, body.redirectUri)
    return verify_kakao_token_and_login(access_token, db)


@router.get("/auth/me")
def get_me(user: dict = Depends(require_user)):
    return {
        "id": user["id"],
        "createdAt": user["created_at"],
        "introSeen": bool(user["intro_seen"]),
    }


@router.post("/auth/logout")
def logout(
    db: PipiDatabase = Depends(get_db),
    token: Optional[str] = Depends(get_bearer_token),
):
    if token:
        db.logout(token)
    return {"ok": True}


@router.delete("/auth/account")
def delete_account(
    db: PipiDatabase = Depends(get_db),
    user: dict = Depends(require_user),
):
    db.delete_account(user["id"])
    return {"ok": True}


# ── 3. 인트로 ───────────────────────────────────────────────────────
@router.get("/intro/status")
def intro_status(
    db: PipiDatabase = Depends(get_db),
    user: dict = Depends(require_user),
):
    return {"introSeen": db.get_intro_seen(user["id"])}


@router.post("/intro/seen")
def intro_seen(
    db: PipiDatabase = Depends(get_db),
    user: dict = Depends(require_user),
):
    db.mark_intro_seen(user["id"])
    return {"introSeen": True}


# ── 4. 캐릭터 ───────────────────────────────────────────────────────
@router.get("/character")
def get_character(
    db: PipiDatabase = Depends(get_db),
    user: dict = Depends(require_user),
):
    char = db.get_character(user["id"])
    if char is None:
        raise HTTPException(status_code=404, detail="캐릭터가 없습니다.")
    return char


@router.post("/character")
def create_character(
    body: CharacterRequest,
    db: PipiDatabase = Depends(get_db),
    user: dict = Depends(require_user),
):
    saved = db.save_character(user["id"], body.model_dump())
    return saved


@router.put("/character")
def update_character(
    body: CharacterRequest,
    db: PipiDatabase = Depends(get_db),
    user: dict = Depends(require_user),
):
    saved = db.save_character(user["id"], body.model_dump())
    return saved


@router.post("/character/feed")
def feed_character(
    db: PipiDatabase = Depends(get_db),
    user: dict = Depends(require_user),
):
    try:
        return db.feed_character(user["id"])
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except LookupError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.post("/character/play")
def play_character(
    db: PipiDatabase = Depends(get_db),
    user: dict = Depends(require_user),
):
    try:
        return db.play_character(user["id"])
    except LookupError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.delete("/character")
def delete_character_route(
    db: PipiDatabase = Depends(get_db),
    user: dict = Depends(require_user),
):
    db.delete_character(user["id"])
    return {"ok": True}


# ── 5. 할 일 (Tasks) ───────────────────────────────────────────────
@router.get("/tasks")
def list_tasks(
    db: PipiDatabase = Depends(get_db),
    user: dict = Depends(require_user),
):
    return {"tasks": db.list_tasks(user["id"])}


@router.post("/tasks", status_code=201)
def create_task(
    body: TaskCreateRequest,
    db: PipiDatabase = Depends(get_db),
    user: dict = Depends(require_user),
):
    saved = db.upsert_task(user["id"], body.model_dump())
    return saved


@router.put("/tasks/{task_id}")
def update_task(
    task_id: str,
    body: TaskUpdateRequest,
    db: PipiDatabase = Depends(get_db),
    user: dict = Depends(require_user),
):
    data = body.model_dump()
    data["id"] = task_id
    saved = db.upsert_task(user["id"], data)
    return saved


@router.post("/tasks/{task_id}/complete")
def complete_task(
    task_id: str,
    body: CompleteTaskRequest,
    db: PipiDatabase = Depends(get_db),
    user: dict = Depends(require_user),
):
    try:
        updated = db.complete_task(user["id"], task_id, body.proofImagePath)
        return updated
    except LookupError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.delete("/tasks/{task_id}")
def delete_task(
    task_id: str,
    db: PipiDatabase = Depends(get_db),
    user: dict = Depends(require_user),
):
    db.delete_task(user["id"], task_id)
    return {"ok": True}


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 앱 팩토리 (모바일 앱 전용 RESTful API 서버)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
def create_app(
    db_path: str = DEFAULT_DB_PATH,
) -> FastAPI:
    """FastAPI 앱을 생성합니다. 테스트 시 db_path를 오버라이드할 수 있습니다."""
    _app = FastAPI(title="PIPI Mobile Backend", version="1.0.0")

    # 상태 주입
    _app.state.db = PipiDatabase(db_path=db_path)

    cors_origins = [
        origin.strip()
        for origin in os.environ.get(
            "ALLOWED_ORIGINS",
            "http://localhost:3000,http://127.0.0.1:3000",
        ).split(",")
        if origin.strip()
    ]

    # CORS 미들웨어 (Cloudflare Pages 도메인 및 로컬/지정 오리진 허용, Bearer 토큰이므로 credentials=False)
    _app.add_middleware(
        CORSMiddleware,
        allow_origins=cors_origins,
        allow_origin_regex=r"^https://[a-zA-Z0-9-]+\.pages\.dev$",
        allow_credentials=False,
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["Content-Type", "Authorization", "Accept"],
    )

    # 커스텀 에러 핸들러: 프론트엔드 호환 {"error": "..."} 형식
    @_app.exception_handler(HTTPException)
    async def http_exception_handler(request: Request, exc: HTTPException):
        return JSONResponse(
            status_code=exc.status_code,
            content={"error": exc.detail},
        )

    @_app.exception_handler(RequestValidationError)
    async def validation_exception_handler(
        request: Request, exc: RequestValidationError
    ):
        return JSONResponse(
            status_code=400,
            content={"error": "요청 데이터가 올바르지 않습니다."},
        )

    # API 라우터 등록
    _app.include_router(router)

    # 모바일 웹 직접 테스트 및 QR 실시간 시연 시 브라우저(사파리/크롬) 캐싱 방지
    @_app.middleware("http")
    async def add_no_cache_header(request: Request, call_next):
        response = await call_next(request)
        response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate, max-age=0"
        response.headers["Pragma"] = "no-cache"
        response.headers["Expires"] = "0"
        return response

    # 모바일 웹 직접 테스트 및 QR 실시간 시연 지원 (build/web 이 존재할 경우)
    frontend_web = os.path.realpath(os.path.join(BASE_DIR, "..", "PIPI - frontend", "build", "web"))
    if os.path.isdir(frontend_web):
        _app.mount("/", StaticFiles(directory=frontend_web, html=True), name="static")
    else:
        # 루트 엔드포인트: 모바일 API 서버 상태
        @_app.get("/")
        def root():
            return {
                "service": "pipi-mobile-backend",
                "status": "running",
                "mode": "mobile_app_only",
            }

    return _app


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 기본 앱 인스턴스 — uvicorn server:app 으로 실행 시 사용
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
app = create_app()


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 직접 실행: python3 server.py
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
if __name__ == "__main__":
    host = os.environ.get("HOST", "0.0.0.0")
    port = int(os.environ.get("PORT", "3000"))
    print("=" * 42)
    print(" Starting PIPI Backend Server (FastAPI)")
    print(f" Host: http://{host}:{port}")
    print("=" * 42)
    print(f"PIPI Backend Server running on http://{host}:{port} (db: {DEFAULT_DB_PATH})")
    uvicorn.run(app, host=host, port=port)
