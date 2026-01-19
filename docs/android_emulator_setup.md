# Android Emulator 세팅 및 실행 가이드

## 개요

| 항목 | 값 |
|------|-----|
| AVD 이름 | Pixel_7_API_34 |
| 디바이스 | Pixel 7 |
| Android 버전 | Android 14 (API 34) |
| 시스템 이미지 | google_apis / x86_64 |

---

## 1. 에뮬레이터 실행 방법

### 방법 1: Android Studio (권장)

1. **Android Studio** 실행
2. 우측 상단 **Device Manager** 아이콘 클릭 (또는 `Tools → Device Manager`)
3. **Pixel_7_API_34** 옆 ▶ (재생) 버튼 클릭
4. 에뮬레이터 부팅 완료까지 대기

### 방법 2: 터미널

```bash
# CMD / PowerShell
C:\Users\SS\AppData\Local\Android\sdk\emulator\emulator\emulator.exe -avd Pixel_7_API_34

# Git Bash / WSL
/c/Users/SS/AppData/Local/Android/sdk/emulator/emulator/emulator.exe -avd Pixel_7_API_34
```

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

## 3. AVD 세팅 (수동 생성 방법)

### 3.1 필요 파일

| 파일 | 경로 |
|------|------|
| AVD 설정 (ini) | `C:\Users\SS\.android\avd\Pixel_7_API_34.ini` |
| AVD 데이터 | `L:\Android\avd\Pixel_7_API_34.avd\` |
| 시스템 이미지 | `C:\Users\SS\AppData\Local\Android\sdk\system-images\android-34\google_apis\x86_64\` |

### 3.2 AVD ini 파일 (`Pixel_7_API_34.ini`)

```ini
avd.ini.encoding=UTF-8
path=L:\Android\avd\Pixel_7_API_34.avd
path.rel=avd\Pixel_7_API_34.avd
target=android-34
```

### 3.3 AVD config 파일 (`config.ini`)

```ini
AvdId=Pixel_7_API_34
PlayStore.enabled=false
abi.type=x86_64
avd.ini.displayname=Pixel 7 API 34
avd.ini.encoding=UTF-8
disk.dataPartition.size=2147483648
hw.accelerometer=yes
hw.audioInput=yes
hw.battery=yes
hw.camera.back=virtualscene
hw.camera.front=emulated
hw.cpu.arch=x86_64
hw.cpu.ncore=4
hw.device.manufacturer=Google
hw.device.name=pixel_7
hw.gps=yes
hw.gpu.enabled=yes
hw.gpu.mode=auto
hw.keyboard=yes
hw.lcd.density=420
hw.lcd.height=2400
hw.lcd.width=1080
hw.ramSize=2048
hw.sdCard=yes
image.sysdir.1=system-images\android-34\google_apis\x86_64\
sdcard.size=512M
skin.name=pixel_7
skin.path=C:\Users\SS\AppData\Local\Android\sdk\skins\pixel_7
tag.display=Google APIs
tag.id=google_apis
vm.heapSize=228
```

> **참고**: AVD 데이터가 L: 드라이브에 저장됨 (C: 드라이브 공간 부족 방지)

---

## 4. 주요 경로

| 항목 | 경로 |
|------|------|
| Android SDK | `C:\Users\SS\AppData\Local\Android\sdk` |
| Emulator 실행파일 | `C:\Users\SS\AppData\Local\Android\sdk\emulator\emulator\emulator.exe` |
| ADB | `C:\Users\SS\AppData\Local\Android\sdk\platform-tools\adb.exe` |
| 시스템 이미지 | `C:\Users\SS\AppData\Local\Android\sdk\system-images\` |
| AVD 목록 | `C:\Users\SS\.android\avd\` |
| AVD 데이터 | `L:\Android\avd\Pixel_7_API_34.avd\` |

---

## 5. 유용한 명령어

```bash
# AVD 목록 확인
emulator -list-avds

# ADB 디바이스 확인
adb devices

# ADB 서버 재시작
adb kill-server && adb start-server

# 콜드 부팅 (스냅샷 없이)
emulator -avd Pixel_7_API_34 -no-snapshot-load

# GPU 문제 시 소프트웨어 렌더링
emulator -avd Pixel_7_API_34 -gpu swiftshader_indirect
```

---

## 6. 문제 해결

### 디스크 공간 부족
```
FATAL | Not enough space to create userdata partition
```
**해결**: C: 드라이브 임시 파일 정리
```bash
# Windows 임시 파일 삭제
rd /s /q %TEMP%
```

### 에뮬레이터가 flutter devices에 안 보임
```bash
adb kill-server
adb start-server
flutter devices
```

### GPU/그래픽 오류로 크래시
**해결**: Android Studio에서 실행하거나 소프트웨어 렌더링 사용
```bash
emulator -avd Pixel_7_API_34 -gpu swiftshader_indirect
```

### AVD 새로 생성하기 (Android Studio)
1. Android Studio → Tools → Device Manager
2. Create Virtual Device
3. Pixel 7 선택 → Next
4. UpsideDownCake (API 34) 선택 → Next → Finish

---

## 7. 캐시 정리 (디스크 공간 확보)

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
