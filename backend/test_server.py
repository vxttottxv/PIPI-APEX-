from __future__ import annotations

import os
import tempfile
import unittest

from fastapi.testclient import TestClient

from server import create_app


class PipiBackendApiTests(unittest.TestCase):
    """PIPI 백엔드 FastAPI 통합 테스트."""

    def setUp(self) -> None:
        self.tmp_db = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
        self.tmp_db.close()
        self.app = create_app(db_path=self.tmp_db.name)
        self.client = TestClient(self.app)

    def tearDown(self) -> None:
        if os.path.exists(self.tmp_db.name):
            os.unlink(self.tmp_db.name)

    def _request(
        self, method: str, path: str, body=None, token: str | None = None
    ) -> tuple[int, dict]:
        headers = {}
        if token:
            headers["Authorization"] = f"Bearer {token}"
        resp = self.client.request(method, path, json=body, headers=headers)
        return resp.status_code, resp.json()

    def test_full_user_lifecycle(self) -> None:
        # 1. Health check
        status, health = self._request("GET", "/api/health")
        self.assertEqual(status, 200)
        self.assertEqual(health["status"], "ok")

        # 2. SignUp
        status, signup_res = self._request(
            "POST", "/api/auth/signup", {"id": "alice", "password": "secret123"}
        )
        self.assertEqual(status, 201)
        token = signup_res["token"]
        self.assertFalse(signup_res["user"]["introSeen"])

        # Duplicate signup blocked
        status, _ = self._request(
            "POST", "/api/auth/signup", {"id": "alice", "password": "secret123"}
        )
        self.assertEqual(status, 409)

        # 3. Intro seen one-time flag
        status, intro = self._request("GET", "/api/intro/status", token=token)
        self.assertEqual(status, 200)
        self.assertFalse(intro["introSeen"])

        status, intro = self._request("POST", "/api/intro/seen", {}, token=token)
        self.assertEqual(status, 200)
        self.assertTrue(intro["introSeen"])

        # 4. Select character & feed / play
        status, char_res = self._request(
            "POST",
            "/api/character",
            {"type": "cat", "color": "#FFFFFF", "name": "눈송이"},
            token=token,
        )
        self.assertEqual(status, 200)
        self.assertEqual(char_res["name"], "눈송이")

        status, fed = self._request("POST", "/api/character/feed", {}, token=token)
        self.assertEqual(status, 200)
        self.assertEqual(fed["snacks"], 4)
        self.assertEqual(fed["exp"], 20)

        status, played = self._request("POST", "/api/character/play", {}, token=token)
        self.assertEqual(status, 200)
        self.assertEqual(played["coins"], 110)
        self.assertEqual(played["exp"], 35)

        # 5. Create task, list tasks, complete task & verify reward
        task_payload = {
            "id": "task_1",
            "title": "영어 공부",
            "durationMin": 60,
            "goal": "",
            "startDate": "2026-11-10T00:00:00",
            "endDate": "2026-11-10T00:00:00",
            "alertBefore": 0,
            "priority": "medium",
            "category": "study",
            "placedDate": "2026-11-10T00:00:00",
            "startTime": "18:00",
            "status": "placed",
        }
        status, created_task = self._request(
            "POST", "/api/tasks", task_payload, token=token
        )
        self.assertEqual(status, 201)
        self.assertEqual(created_task["title"], "영어 공부")

        status, listed = self._request("GET", "/api/tasks", token=token)
        self.assertEqual(status, 200)
        self.assertEqual(len(listed["tasks"]), 1)

        status, completed = self._request(
            "POST",
            "/api/tasks/task_1/complete",
            {"proofImagePath": "photo.jpg"},
            token=token,
        )
        self.assertEqual(status, 200)
        self.assertEqual(completed["status"], "completed")

        # Character received completion reward (+30 EXP, +20 coins, +1 snack)
        status, updated_char = self._request("GET", "/api/character", token=token)
        self.assertEqual(updated_char["exp"], 65)
        self.assertEqual(updated_char["coins"], 130)
        self.assertEqual(updated_char["snacks"], 5)

        # 6. Logout & re-login
        status, _ = self._request("POST", "/api/auth/logout", {}, token=token)
        self.assertEqual(status, 200)
        status, _ = self._request("GET", "/api/character", token=token)
        self.assertEqual(status, 401)

        status, login_res = self._request(
            "POST", "/api/auth/login", {"id": "alice", "password": "secret123"}
        )
        self.assertEqual(status, 200)
        self.assertTrue(login_res["user"]["introSeen"])
        new_token = login_res["token"]

        # 7. Delete account removes everything
        status, _ = self._request("DELETE", "/api/auth/account", token=new_token)
        self.assertEqual(status, 200)
        status, _ = self._request(
            "POST", "/api/auth/login", {"id": "alice", "password": "secret123"}
        )
        self.assertEqual(status, 404)

        # 8. Social login isolates distinct accountId entries
        status, k_res = self._request(
            "POST",
            "/api/auth/social",
            {"provider": "kakao", "accountId": "demo1@kakao.com"},
        )
        self.assertEqual(status, 200)
        self.assertEqual(k_res["user"]["id"], "kakao_demo1@kakao.com")

        status, g_res = self._request(
            "POST",
            "/api/auth/social",
            {"provider": "google", "accountId": "demo2@gmail.com"},
        )
        self.assertEqual(status, 200)
        self.assertEqual(g_res["user"]["id"], "google_demo2@gmail.com")
        self.assertNotEqual(k_res["token"], g_res["token"])

        # 9. Kakao auth endpoint validation (empty token rejected)
        status, err_res = self._request("POST", "/api/auth/kakao", {"accessToken": "   "})
        self.assertEqual(status, 400)

        # 10. Kakao DB direct identification & session issue
        k_user, k_token = self.app.state.db.kakao_login("123456789", email="test@kakao.com")
        self.assertEqual(k_user["id"], "kakao_123456789")
        self.assertTrue(len(k_token) > 20)
        user_from_db = self.app.state.db.get_user_by_token(k_token)
        self.assertEqual(user_from_db["id"], "kakao_123456789")

    def test_session_lifecycle_and_security(self) -> None:
        """세션 만료(7일), 비정상 created_at, 로그아웃, 미존재 토큰 검증."""
        from datetime import datetime, timezone, timedelta
        import sqlite3

        # 1. 회원가입 및 정상 토큰 발급
        status, signup_res = self._request(
            "POST", "/api/auth/signup", {"id": "sec_user", "password": "password123"}
        )
        self.assertEqual(status, 201)
        valid_token = signup_res["token"]

        # 2. 정상 토큰 인증 확인 (200 OK)
        status, me_res = self._request("GET", "/api/auth/me", token=valid_token)
        self.assertEqual(status, 200)
        self.assertEqual(me_res["id"], "sec_user")

        # 3. 만료된 토큰 검증 (8일 전 생성된 세션 직접 주입)
        now = datetime.now(timezone.utc)
        eight_days_ago = (now - timedelta(days=8)).isoformat()
        expired_token = "expired_token_test_123"

        with sqlite3.connect(self.tmp_db.name) as conn:
            conn.execute(
                "INSERT INTO sessions (token, user_id, created_at) VALUES (?, ?, ?)",
                (expired_token, "sec_user", eight_days_ago),
            )
            conn.commit()

        # 만료 토큰으로 인증 시도 -> 401 Unauthorized 반환
        status, _ = self._request("GET", "/api/auth/me", token=expired_token)
        self.assertEqual(status, 401)

        # 만료된 세션이 DB에서 실제로 삭제(폐기)되었는지 확인
        with sqlite3.connect(self.tmp_db.name) as conn:
            row = conn.execute(
                "SELECT 1 FROM sessions WHERE token = ?", (expired_token,)
            ).fetchone()
            self.assertIsNone(row, "만료된 세션은 DB에서 즉시 폐기되어야 합니다.")

        # 4. created_at이 비정상 포맷인 토큰 검증 ("invalid-date-format")
        malformed_token = "malformed_token_test_456"
        with sqlite3.connect(self.tmp_db.name) as conn:
            conn.execute(
                "INSERT INTO sessions (token, user_id, created_at) VALUES (?, ?, ?)",
                (malformed_token, "sec_user", "invalid-date-format"),
            )
            conn.commit()

        status, _ = self._request("GET", "/api/auth/me", token=malformed_token)
        self.assertEqual(status, 401)

        # 비정상 세션도 DB에서 삭제되었는지 확인
        with sqlite3.connect(self.tmp_db.name) as conn:
            row = conn.execute(
                "SELECT 1 FROM sessions WHERE token = ?", (malformed_token,)
            ).fetchone()
            self.assertIsNone(row, "비정상 형식의 세션은 DB에서 즉시 폐기되어야 합니다.")

        # 5. created_at이 빈 문자열인 토큰 검증
        empty_created_at_token = "empty_created_at_token_789"
        with sqlite3.connect(self.tmp_db.name) as conn:
            conn.execute(
                "INSERT INTO sessions (token, user_id, created_at) VALUES (?, ?, ?)",
                (empty_created_at_token, "sec_user", ""),
            )
            conn.commit()

        status, _ = self._request("GET", "/api/auth/me", token=empty_created_at_token)
        self.assertEqual(status, 401)

        # 6. 로그아웃된 토큰 검증
        status, _ = self._request("POST", "/api/auth/logout", {}, token=valid_token)
        self.assertEqual(status, 200)

        status, _ = self._request("GET", "/api/auth/me", token=valid_token)
        self.assertEqual(status, 401)

        # 7. 전혀 존재하지 않는 가짜 토큰 검증
        status, _ = self._request("GET", "/api/auth/me", token="fake_nonexistent_token")
        self.assertEqual(status, 401)

        # 8. cleanup_expired_sessions() 일괄 정리 배치 검증
        batch_expired_token = "batch_expired_token_999"
        with sqlite3.connect(self.tmp_db.name) as conn:
            conn.execute(
                "INSERT INTO sessions (token, user_id, created_at) VALUES (?, ?, ?)",
                (batch_expired_token, "sec_user", (now - timedelta(days=10)).isoformat()),
            )
            conn.commit()

        cleaned_count = self.app.state.db.cleanup_expired_sessions()
        self.assertGreaterEqual(cleaned_count, 1)

        with sqlite3.connect(self.tmp_db.name) as conn:
            row = conn.execute(
                "SELECT 1 FROM sessions WHERE token = ?", (batch_expired_token,)
            ).fetchone()
            self.assertIsNone(row)


if __name__ == "__main__":
    unittest.main()
