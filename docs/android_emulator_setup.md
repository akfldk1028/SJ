# Android Emulator 세팅 및 실행 가이드

## 사용 가능한 AVD

| AVD 이름 | 기기 | Android 버전 | Play Store | 상태 |
|----------|------|-------------|------------|------|
| **Galaxy_S24_Ultra** | Samsung Galaxy S24 Ultra | Android 16 (API 36.1) | O | **권장 (최신)** |
| Pixel_7_API_36 | Google Pixel 7 | Android 16 (API 36.1) | O | - |
| Pixel_7_API_35 | Google Pixel 7 | Android 15 (API 35) | O | - |
| Pixel_7_API_34 | Google Pixel 7 | Android 14 (API 34) | X | - |

---

## 1. 에뮬레이터 실행 방법

### 방법 1: Android Studio (권장)

1. **Android Studio** 실행
2. 우측 상단 **Device Manager** 아이콘 클릭 (또는 `Tools → Device Manager`)
3. **Galaxy_S24_Ultra** 옆 ▶ (재생) 버튼 클릭
4. 에뮬레이터 부팅 완료까지 대기

### 방법 2: 터미널

```bash
# CMD / PowerShell
C:\Users\SS\AppData\Local\Android\sdk\emulator\emulator\emulator.exe -avd Galaxy_S24_Ultra

# Git Bash / WSL
/c/Users/SS/AppData/Local/Android/sdk/emulator/emulator/emulator.exe -avd Galaxy_S24_Ultra
```

> **참고**: CLI 실행 시 GPU 관련 문제로 크래시될 수 있음. Android Studio 실행 권장.

---

## 2. Flutter 앱 실행

```bash
# 프로젝트 폴더
cd L:\SJ\SJ\frontend

# 연결된 디바이스 확인
flutter devices

# 앱 실행
flutter run

# 특정 디바이스 지정
flutter run -d emulator-5554
```

---

## 3. AVD 설정 파일

### Galaxy S24 Ultra (권장)

**스펙:**
| 항목 | 값 |
|------|-----|
| 해상도 | 1440 x 3120 |
| DPI | 505 |
| RAM | 12GB |
| CPU 코어 | 8 |
| 저장소 | 8GB |

**INI 파일**: `C:\Users\SS\.android\avd\Galaxy_S24_Ultra.ini`
```ini
avd.ini.encoding=UTF-8
path=L:\Android\avd\Galaxy_S24_Ultra.avd
path.rel=avd\Galaxy_S24_Ultra.avd
target=android-36
```

**Config 파일**: `L:\Android\avd\Galaxy_S24_Ultra.avd\config.ini`
```ini
AvdId=Galaxy_S24_Ultra
PlayStore.enabled=true
abi.type=x86_64
avd.ini.displayname=Galaxy S24 Ultra
hw.lcd.density=505
hw.lcd.height=3120
hw.lcd.width=1440
hw.ramSize=12288
hw.cpu.ncore=8
image.sysdir.1=system-images\android-36.1\google_apis_playstore\x86_64\
```

---

## 4. 주요 경로

| 항목 | 경로 |
|------|------|
| Android SDK | `C:\Users\SS\AppData\Local\Android\sdk` |
| Emulator 실행파일 | `C:\Users\SS\AppData\Local\Android\sdk\emulator\emulator\emulator.exe` |
| ADB | `C:\Users\SS\AppData\Local\Android\sdk\platform-tools\adb.exe` |
| sdkmanager | `C:\Users\SS\AppData\Local\Android\sdk\cmdline-tools\latest\bin\sdkmanager.bat` |
| 시스템 이미지 | `C:\Users\SS\AppData\Local\Android\sdk\system-images\` |
| AVD 목록 | `C:\Users\SS\.android\avd\` |
| AVD 데이터 | `L:\Android\avd\` |

---

## 5. 유용한 명령어

```bash
# AVD 목록 확인
emulator -list-avds

# ADB 디바이스 확인
adb devices

# ADB 서버 재시작
adb kill-server && adb start-server

# 에뮬레이터 종료
adb -s emulator-5554 emu kill

# 콜드 부팅 (스냅샷 없이)
emulator -avd Galaxy_S24_Ultra -no-snapshot-load

# GPU 문제 시 소프트웨어 렌더링
emulator -avd Galaxy_S24_Ultra -gpu swiftshader_indirect
```

---

## 6. 시스템 이미지 설치 (sdkmanager)

```bash
# Java 17 필요
set JAVA_HOME=C:\Program Files\Microsoft\jdk-17.0.17.10-hotspot
set ANDROID_SDK_ROOT=C:\Users\SS\AppData\Local\Android\sdk

# 사용 가능한 이미지 목록
sdkmanager --list | findstr system-images

# API 36.1 설치
sdkmanager "system-images;android-36.1;google_apis_playstore;x86_64"

# API 35 설치
sdkmanager "system-images;android-35;google_apis_playstore;x86_64"
```

---

## 7. 문제 해결

### 디스크 공간 부족
```
FATAL | Not enough space to create userdata partition
```
**해결**: C: 드라이브 임시 파일 정리
```bash
rd /s /q %TEMP%
```

### 에뮬레이터가 flutter devices에 안 보임
```bash
adb kill-server
adb start-server
flutter devices
```

### GPU/그래픽 오류로 크래시
**해결**: Android Studio에서 실행 (권장)

### 한국어 설정
1. 에뮬레이터 부팅 후 **Settings** 앱 실행
2. **System → Languages & input → Languages**
3. **Add a language → 한국어** 선택
4. 한국어를 맨 위로 드래그

---

## 8. 설치된 시스템 이미지

| API | Android 버전 | 이미지 타입 | 경로 |
|-----|-------------|------------|------|
| 36.1 | Android 16 | google_apis_playstore | `system-images\android-36.1\google_apis_playstore\x86_64` |
| 35 | Android 15 | google_apis_playstore | `system-images\android-35\google_apis_playstore\x86_64` |
| 34 | Android 14 | google_apis | `system-images\android-34\google_apis\x86_64` |

---

## 9. 캐시 정리 (디스크 공간 확보)

| 폴더 | 경로 | 삭제 가능 |
|------|------|----------|
| 임시 파일 | `C:\Users\SS\AppData\Local\Temp` | O |
| npm 캐시 | `C:\Users\SS\AppData\Local\npm-cache` | O |
| .android | `C:\Users\SS\.android` | X (키스토어 등 중요 파일) |

```bash
# Temp 폴더 정리
rm -rf /c/Users/SS/AppData/Local/Temp/*

# npm 캐시 정리
npm cache clean --force
```
