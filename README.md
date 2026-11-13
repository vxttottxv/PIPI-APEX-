# 🐾 PIPI (계획으로 나만의 반려동물을 키워보세요!)

> **갓생 루틴과 함께 성장하는 레트로 픽셀 아트 반려동물 육성 앱**  
> Flutter 크로스 플랫폼 프론트엔드 + 경량 Python REST API / SQLite 백엔드

---

## 📱 실시간 웹 시연 (영구 고정 QR 코드)

별도 설치 없이 스마트폰 기본 카메라로 QR 코드를 스캔하거나 링크를 클릭하면 즉시 앱을 체험할 수 있습니다.  
GitHub Pages를 통해 24시간 365일 언제나 동일한 주소로 유지됩니다.

- **체험 링크**: [https://vxttottxv.github.io/PIPI-APEX-/](https://vxttottxv.github.io/PIPI-APEX-/)

| 📱 스마트폰 스캔용 영구 고정 QR 코드 |
| :---: |
| <img src="pipi_permanent_qr.png" alt="PIPI Permanent Demo QR" width="220" /> |
| [https://vxttottxv.github.io/PIPI-APEX-/](https://vxttottxv.github.io/PIPI-APEX-/) |

---

## ✨ 핵심 기능

1. **최초 1회 인트로 컷신 & 갈무리11 픽셀 대사창**
   - 신규 가입 시 1회만 재생되는 비 오는 밤거리 인트로 스토리 연출
   - 네오 레트로 감성의 계단형 픽셀 대사창 & 한글 `Galmuri11` 픽셀 폰트 적용
   - 감상 완료 시 상태가 백엔드/로컬 저장소에 영구 동기화되어 재노출 방지

2. **반려동물 캐릭터 육성 & 반응형 픽셀 룸**
   - 아홀로틀, 카피바라, 고양이, 강아지, 드래곤, 오리 등 6종 캐릭터
   - 어떤 스마트폰 기종이든(소형, 21:9 긴 폰, 태블릿, PC) 가구 잘림 없이 자동 조정되는 일본식 야경 픽셀 룸
   - 터치 및 유휴 상태 반응형 대사 및 애니메이션, 간식 주기, 놀아주기, 애정도/경험치/레벨 시스템

3. **일정 관리 (타임라인 & 캘린더)**
   - 오늘 할 일 추가, 시간대별 타임라인 조회, 월간 캘린더 뷰
   - 할 일 완료 시 경험치(+30 EXP), 코인(+20), 간식(+1) 보상 지급

4. **실제 정각 휴대폰 알람 지원**
   - `flutter_local_notifications` + `timezone` 기반 정확한 정각 알림 스케줄링
   - Android Exact Alarm & iOS UserNotifications 네이티브 권한 완비

5. **소셜 로그인 & 데모 계정 분리**
   - 카카오 / 구글 계정 선택 및 정보 제공 동의 다이얼로그 지원
   - 시연 시 사용자별 이메일/ID로 독립된 세션 생성 및 데이터 분리

6. **하이브리드 백엔드 아키텍처**
   - Python 표준 라이브러리(`ThreadingHTTPServer`) + SQLite3 기반 REST API (`backend/server.py`)
   - 서버 오프라인 또는 독립 웹 배포 시 `SharedPreferences` 기반 완벽한 로컬 폴백 동작

---

## 🛠️ 기술 스택

- **Frontend**: Flutter 3.x, Dart, Provider, Shared Preferences, Flutter Local Notifications, Timezone
- **Font & Design**: 갈무리11 (Galmuri11) Pixel TTF, CustomPixelPainter
- **Backend**: Python 3.9+, SQLite3, Pure Standard Library (No external pip dependency needed)
- **Deployment**: GitHub Pages, GitHub Actions, Cloudflare Tunnel

---

## 🚀 로컬 실행 방법

### 1. 백엔드 서버 실행
```bash
python3 backend/server.py
# http://localhost:3000 에서 실행됩니다.
```

### 2. 프론트엔드 앱 실행 (Flutter)
```bash
flutter pub get

# Chrome 웹으로 실행
flutter run -d chrome

# Android 에뮬레이터 또는 기기
flutter run -d android

# iOS 시뮬레이터 또는 기기
flutter run -d ios
```

### 3. 모바일 시연 터널 및 QR 생성 스크립트
```bash
./start_demo.sh
```

---

## 📄 명세서
자세한 기획 및 화면별 개발 스펙은 [PIPI_명세서.md](PIPI_명세서.md)를 참고하세요.
