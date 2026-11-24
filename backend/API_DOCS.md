# 📚 PIPI REST API 명세서

PIPI 백엔드는 Python 표준 라이브러리 및 SQLite3 기반의 경량 RESTful API 서버입니다.  
Flutter 모바일/웹 클라이언트와 1:1로 매핑되는 비즈니스 로직을 제공합니다.

---

## 🌐 기본 정보

- **기본 Base URL**: `http://localhost:3000` (또는 안드로이드 에뮬레이터: `http://10.0.2.2:3000`)
- **데이터 포맷**: JSON (`Content-Type: application/json; charset=utf-8`)
- **인증 방식**: HTTP Bearer Token (`Authorization: Bearer <token>`)
- **CORS**: 모든 도메인(`*`) 허용, Preflight OPTIONS 지원

---

## 📑 목차

1. [시스템 및 상태 확인 (Health)](#1-시스템-및-상태-확인)
2. [인증 (Auth)](#2-인증-auth)
3. [인트로 (Intro)](#3-인트로-intro)
4. [캐릭터 (Character)](#4-캐릭터-character)
5. [일정 및 할 일 (Tasks)](#5-일정-및-할-일-tasks)
6. [데이터베이스 스키마](#6-데이터베이스-스키마)

---

## 1. 시스템 및 상태 확인

### 1-1. 서버 헬스체크
서버 정상 가동 여부를 확인합니다. 인증이 필요하지 않습니다.

- **Method**: `GET`
- **Path**: `/api/health`
- **Auth**: 불필요
- **Response** `200 OK`:
  ```json
  {
    "status": "ok",
    "service": "pipi-backend"
  }
  ```

---

## 2. 인증 (Auth)

### 2-1. 일반 회원가입
신규 사용자 계정을 생성하고 세션 토큰을 발급합니다.

- **Method**: `POST`
- **Path**: `/api/auth/signup`
- **Auth**: 불필요
- **Request Body**:
  ```json
  {
    "id": "myuser123",
    "password": "mypassword"
  }
  ```
  > 규칙: 아이디는 최소 3자 이상, 비밀번호는 최소 4자 이상
- **Response** `201 Created`:
  ```json
  {
    "user": {
      "id": "myuser123",
      "passwordHash": "ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f",
      "createdAt": "2026-11-22T03:30:00.000000+00:00",
      "introSeen": false
    },
    "token": "4vQy_3uK9nF1x7qWzLmP8oRsTuVwXyZaBcDeFgHiJkL"
  }
  ```
- **Error Responses**:
  - `400 Bad Request`: `{"error": "아이디는 최소 3자 이상이어야 합니다."}`
  - `409 Conflict`: `{"error": "이미 사용 중인 아이디입니다."}`

### 2-2. 일반 로그인
- **Method**: `POST`
- **Path**: `/api/auth/login`
- **Auth**: 불필요
- **Request Body**:
  ```json
  {
    "id": "myuser123",
    "password": "mypassword"
  }
  ```
- **Response** `200 OK`:
  ```json
  {
    "user": {
      "id": "myuser123",
      "passwordHash": "...",
      "createdAt": "...",
      "introSeen": false
    },
    "token": "..."
  }
  ```
- **Error Responses**:
  - `400 Bad Request`: `{"error": "아이디와 비밀번호를 입력해주세요."}`
  - `404 Not Found`: `{"error": "가입되지 않은 아이디입니다."}`
  - `401 Unauthorized`: `{"error": "비밀번호가 올바르지 않습니다."}`

### 2-3. 소셜 로그인 (카카오 / 구글)
기존 사용자가 없으면 자동 회원가입 처리 후 세션 토큰을 발급합니다.

- **Method**: `POST`
- **Path**: `/api/auth/social`
- **Auth**: 불필요
- **Request Body**:
  ```json
  {
    "provider": "kakao",
    "accountId": "kakao_user_12345"
  }
  ```
- **Response** `200 OK`:
  ```json
  {
    "user": {
      "id": "kakao_kakao_user_12345",
      "passwordHash": "...",
      "createdAt": "...",
      "introSeen": false
    },
    "token": "..."
  }
  ```

### 2-4. 현재 로그인 정보 조회
- **Method**: `GET`
- **Path**: `/api/auth/me`
- **Auth**: `Bearer <token>`
- **Response** `200 OK`:
  ```json
  {
    "id": "myuser123",
    "createdAt": "2026-11-22T03:30:00.000000+00:00",
    "introSeen": true
  }
  ```

### 2-5. 로그아웃
- **Method**: `POST`
- **Path**: `/api/auth/logout`
- **Auth**: `Bearer <token>`
- **Response** `200 OK`:
  ```json
  {
    "ok": true
  }
  ```

### 2-6. 회원 탈퇴
사용자 계정과 관련된 세션, 캐릭터, 할 일 데이터를 모두 영구 삭제합니다.
- **Method**: `DELETE`
- **Path**: `/api/auth/account`
- **Auth**: `Bearer <token>`
- **Response** `200 OK`:
  ```json
  {
    "ok": true
  }
  ```

---

## 3. 인트로 (Intro)

### 3-1. 최초 인트로 시청 여부 확인
- **Method**: `GET`
- **Path**: `/api/intro/status`
- **Auth**: `Bearer <token>`
- **Response** `200 OK`:
  ```json
  {
    "introSeen": false
  }
  ```

### 3-2. 인트로 시청 완료 기록
- **Method**: `POST`
- **Path**: `/api/intro/seen`
- **Auth**: `Bearer <token>`
- **Response** `200 OK`:
  ```json
  {
    "introSeen": true
  }
  ```

---

## 4. 캐릭터 (Character)

### 4-1. 캐릭터 정보 조회
- **Method**: `GET`
- **Path**: `/api/character`
- **Auth**: `Bearer <token>`
- **Response** `200 OK`:
  ```json
  {
    "userId": "myuser123",
    "type": "cat",
    "color": "#FFFFFF",
    "name": "눈송이",
    "level": 2,
    "exp": 45,
    "stage": "baby",
    "intimacy": 65,
    "coins": 140,
    "snacks": 4,
    "ownedItems": [],
    "equippedItems": [],
    "lastVisit": "2026-11-22T03:35:00.000000+00:00"
  }
  ```
- **Error Responses**:
  - `404 Not Found`: `{"error": "캐릭터가 없습니다."}`

### 4-2. 캐릭터 생성 및 업데이트
- **Method**: `POST` 또는 `PUT`
- **Path**: `/api/character`
- **Auth**: `Bearer <token>`
- **Request Body**:
  ```json
  {
    "type": "cat",
    "color": "#FFFFFF",
    "name": "눈송이"
  }
  ```
  > 캐릭터 종류: `cat`, `dog`, `capybara`, `duck`, `axolotl`, `dragon`
- **Response** `200 OK`: 저장된 캐릭터 객체 반환

### 4-3. 간식 주기 (Feed)
간식을 1개 소모하고 경험치(+20 EXP)와 친밀도(+5)를 획득합니다. 필요 경험치 도달 시 자동 레벨업됩니다.
- **Method**: `POST`
- **Path**: `/api/character/feed`
- **Auth**: `Bearer <token>`
- **Response** `200 OK`: 갱신된 캐릭터 객체 반환
- **Error Responses**:
  - `400 Bad Request`: `{"error": "간식이 부족합니다."}`

### 4-4. 놀아주기 (Play)
친밀도(+10), 코인(+10), 경험치(+15)를 획득합니다.
- **Method**: `POST`
- **Path**: `/api/character/play`
- **Auth**: `Bearer <token>`
- **Response** `200 OK`: 갱신된 캐릭터 객체 반환

### 4-5. 캐릭터 삭제
- **Method**: `DELETE`
- **Path**: `/api/character`
- **Auth**: `Bearer <token>`
- **Response** `200 OK`:
  ```json
  {
    "ok": true
  }
  ```

---

## 5. 일정 및 할 일 (Tasks)

### 5-1. 할 일 목록 조회
- **Method**: `GET`
- **Path**: `/api/tasks`
- **Auth**: `Bearer <token>`
- **Response** `200 OK`:
  ```json
  {
    "tasks": [
      {
        "id": "task_1",
        "userId": "myuser123",
        "title": "알고리즘 문제 풀이",
        "durationMin": 60,
        "goal": "백준 2문제 풀기",
        "startDate": "2026-11-22T00:00:00.000Z",
        "endDate": "2026-11-22T23:59:59.000Z",
        "alertBefore": 10,
        "priority": "high",
        "category": "study",
        "placedDate": "2026-11-22",
        "startTime": "14:00",
        "status": "placed",
        "proofImagePath": null,
        "completedAt": null
      }
    ]
  }
  ```

### 5-2. 할 일 생성
- **Method**: `POST`
- **Path**: `/api/tasks`
- **Auth**: `Bearer <token>`
- **Request Body**:
  ```json
  {
    "id": "task_1",
    "title": "알고리즘 문제 풀이",
    "durationMin": 60,
    "goal": "백준 2문제 풀기",
    "startDate": "2026-11-22T00:00:00.000Z",
    "endDate": "2026-11-22T23:59:59.000Z",
    "alertBefore": 10,
    "priority": "high",
    "category": "study",
    "placedDate": "2026-11-22",
    "startTime": "14:00",
    "status": "placed"
  }
  ```
- **Response** `201 Created`: 생성된 할 일 객체

### 5-3. 할 일 수정
- **Method**: `PUT`
- **Path**: `/api/tasks/{task_id}`
- **Auth**: `Bearer <token>`
- **Request Body**: 수정할 속성들
- **Response** `200 OK`: 수정된 할 일 객체

### 5-4. 할 일 완료 및 보상 획득
할 일을 완료 상태로 전환하고, 캐릭터에게 즉시 보상(+30 EXP, +20 코인, +1 간식)을 지급합니다.
- **Method**: `POST`
- **Path**: `/api/tasks/{task_id}/complete`
- **Auth**: `Bearer <token>`
- **Request Body**:
  ```json
  {
    "proofImagePath": "proof_123.jpg"
  }
  ```
- **Response** `200 OK`:
  ```json
  {
    "task": {
      "id": "task_1",
      "status": "completed",
      "proofImagePath": "proof_123.jpg",
      "completedAt": "2026-11-22T03:40:00.000000+00:00"
    },
    "reward": {
      "exp": 30,
      "coins": 20,
      "snacks": 1
    },
    "character": {
      "userId": "myuser123",
      "level": 2,
      "exp": 75,
      "coins": 160,
      "snacks": 5
    }
  }
  ```

### 5-5. 할 일 삭제
- **Method**: `DELETE`
- **Path**: `/api/tasks/{task_id}`
- **Auth**: `Bearer <token>`
- **Response** `200 OK`:
  ```json
  {
    "ok": true
  }
  ```

---

## 6. 데이터베이스 스키마

SQLite3 테이블 정의입니다. `server.py` 기동 시 자동 생성됩니다.

```sql
-- 1. 사용자 테이블
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    password_hash TEXT NOT NULL,
    created_at TEXT NOT NULL,
    intro_seen INTEGER NOT NULL DEFAULT 0
);

-- 2. 세션 테이블
CREATE TABLE IF NOT EXISTS sessions (
    token TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 3. 캐릭터 테이블
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

-- 4. 일정 및 할 일 테이블
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
```

### 성장 규칙
- 레벨 단계:
  - 1 ~ 2 레벨: `baby`
  - 3 ~ 6 레벨: `teen`
  - 7 레벨 이상: `adult`
- 레벨업 필요 경험치 공식: `level * 50`
