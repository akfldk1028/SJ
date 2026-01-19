# Android Emulator 실행 가이드

## 에뮬레이터 정보

| 항목 | 값 |
|------|-----|
| AVD 이름 | Pixel_7_API_34 |
| 디바이스 | Pixel 7 |
| Android 버전 | Android 14 (API 34) |
| 시스템 이미지 | google_apis / x86_64 |
| AVD 경로 | `L:\Android\avd\Pixel_7_API_34.avd` |

---

## 에뮬레이터 실행

### 방법 1: 터미널에서 직접 실행

```bash
# Git Bash / WSL
/c/Users/SS/AppData/Local/Android/sdk/emulator/emulator/emulator.exe -avd Pixel_7_API_34

# CMD / PowerShell
C:\Users\SS\AppData\Local\Android\sdk\emulator\emulator\emulator.exe -avd Pixel_7_API_34
```

### 방법 2: 백그라운드 실행

```bash
# Git Bash
/c/Users/SS/AppData/Local/Android/sdk/emulator/emulator/emulator.exe -avd Pixel_7_API_34 &
```

---

## Flutter 앱 실행

```bash
# 프로젝트 폴더로 이동
cd L:\SJ\SJ\frontend

# 에뮬레이터가 연결됐는지 확인
flutter devices

# 앱 실행 (에뮬레이터 자동 선택)
flutter run

# 특정 디바이스 지정
flutter run -d emulator-5554
```

---

## 유용한 명령어

```bash
# AVD 목록 확인
/c/Users/SS/AppData/Local/Android/sdk/emulator/emulator/emulator.exe -list-avds

# ADB 디바이스 확인
/c/Users/SS/AppData/Local/Android/sdk/platform-tools/adb.exe devices

# 에뮬레이터 콜드 부팅 (스냅샷 없이 시작)
/c/Users/SS/AppData/Local/Android/sdk/emulator/emulator/emulator.exe -avd Pixel_7_API_34 -no-snapshot-load
```

---

## 경로 요약

| 항목 | 경로 |
|------|------|
| Android SDK | `C:\Users\SS\AppData\Local\Android\sdk` |
| Emulator | `C:\Users\SS\AppData\Local\Android\sdk\emulator\emulator\emulator.exe` |
| ADB | `C:\Users\SS\AppData\Local\Android\sdk\platform-tools\adb.exe` |
| AVD 설정 | `C:\Users\SS\.android\avd\Pixel_7_API_34.ini` |
| AVD 데이터 | `L:\Android\avd\Pixel_7_API_34.avd` |

---

## 문제 해결

### 에뮬레이터가 flutter devices에 안 보일 때
```bash
# ADB 서버 재시작
adb kill-server
adb start-server
```

### 디스크 공간 부족 오류
AVD 데이터가 L: 드라이브에 저장되도록 설정됨 (C: 드라이브 공간 부족 방지)
