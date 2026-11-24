# 🐾 PIPI Backend API Server

> **PIPI 앱 전용 Python RESTful API & SQLite 백엔드 독립 프로젝트**  
> 외부 패키지 의존성 없이 Python 3.9+ 표준 라이브러리(`ThreadingHTTPServer` + `sqlite3`)만으로 가볍고 빠르게 동작합니다.

---

## 📁 디렉터리 구조

```
PIPI-backend/
├── server.py              # 메인 API 서버 및 SQLite DB 핸들러
├── test_server.py         # 백엔드 API 통합/단위 테스트 스위트
├── API_DOCS.md            # 전체 REST API 명세서 및 DB 스키마 상세 문서
├── run.sh                 # 로컬 서버 실행 스크립트
├── test.sh                # 테스트 실행 스크립트
├── requirements.txt       # 런타임 의존성 (표준 라이브러리 사용)
├── requirements-dev.txt   # 개발 및 테스트 도구 (pytest, flake8 등)
├── Dockerfile             # Docker 컨테이너 빌드 파일
├── docker-compose.yml     # Docker Compose 실행 설정
├── .env.example           # 환경 변수 예시 파일
└── .gitignore             # Python / DB / OS 무시 파일 목록
```

---

## 🚀 빠른 시작 (Quick Start)

### 1. 로컬 환경에서 바로 실행

별도의 `pip install` 없이 시스템에 설치된 Python 3.9 이상으로 즉시 실행할 수 있습니다.

```bash
# 실행 권한 부여 (최초 1회)
chmod +x run.sh test.sh

# 서버 실행
./run.sh

# 또는 직접 실행:
python3 server.py
```

서버가 정상 실행되면 콘솔에 아래 메시지가 출력됩니다:
```text
==========================================
 Starting PIPI Backend Server
 Host: http://0.0.0.0:3000
==========================================
PIPI Backend Server running on http://0.0.0.0:3000 (db: /Users/.../pipi.db)
```

### 2. 테스트 실행

```bash
./test.sh

# 또는 unittest 직접 실행:
python3 test_server.py
```

---

## ⚙️ 환경 설정 (.env)

`.env.example`을 복사하여 `.env` 파일을 생성하고 설정을 변경할 수 있습니다.

```bash
cp .env.example .env
```

| 환경 변수 | 기본값 | 설명 |
| :--- | :--- | :--- |
| `HOST` | `0.0.0.0` | 서버 바인딩 호스트 |
| `PORT` | `3000` | 서버 수신 포트 |
| `DB_PATH` | `pipi.db` | SQLite 데이터베이스 파일 경로 |
| `WEB_BUILD_DIR` | (선택) | Flutter Web 빌드 파일 경로 (정적 파일 서빙 시) |

---

## 🐳 Docker 실행

Docker를 사용하여 격리된 환경에서 실행할 수도 있습니다.

### Docker Compose로 실행 (권장)
```bash
docker compose up -d --build
```
- 데이터베이스 파일은 `./data/pipi.db`로 마운트되어 컨테이너가 재시작되어도 보존됩니다.

### Docker CLI로 직접 실행
```bash
docker build -t pipi-backend .
docker run -d -p 3000:3000 -v $(pwd)/data:/app/data --name pipi-backend pipi-backend
```

---

## 📱 프론트엔드(Flutter) 연동 방법

프론트엔드 프로젝트(`PIPI-APEX--main`)의 `lib/services/api_client.dart`와 완벽히 호환됩니다.

- **로컬 웹 브라우저 (Chrome)**: `http://localhost:3000`
- **Android 에뮬레이터**: `http://10.0.2.2:3000`
- **실제 스마트폰 테스트**: 같은 Wi-Fi에 연결 후 Mac의 IP 주소로 접속 (예: `http://192.168.0.x:3000`)
- **CORS**: `Access-Control-Allow-Origin: *` 가 기본 활성화되어 있어 웹 크로스 오리진 요청을 자유롭게 수신합니다.

---

## 🛠️ 백엔드 기능 수정 및 추가 가이드

1. **새로운 API 엔드포인트 추가**:
   - `server.py`의 `PipiRequestHandler` 클래스 내부 메서드(`do_GET`, `do_POST`, `do_PUT`, `do_DELETE`)에 라우팅 경로를 추가합니다.
   - 비즈니스 로직 및 DB 처리는 `PipiDatabase` 클래스에 메서드를 추가하여 캡슐화합니다.
2. **데이터베이스 스키마 수정**:
   - `PipiDatabase._init_schema()` 메서드에서 테이블 정의를 수정합니다.
3. **API 명세서 확인**:
   - 엔드포인트별 요청/응답 스펙은 [API_DOCS.md](API_DOCS.md)를 참고하세요.
