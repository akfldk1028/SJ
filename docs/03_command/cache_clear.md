# Flutter 앱 캐시 초기화 및 재실행 명령어

## 1. Android 앱 데이터 완전 초기화

### adb 경로
```
C:\Users\SOGANG1\AppData\Local\Android\Sdk\platform-tools\adb.exe
```

### 앱 데이터 삭제 (Hive 캐시 포함)
```bash
adb shell pm clear com.example.frontend
```

또는 전체 경로:
```bash
"C:\Users\SOGANG1\AppData\Local\Android\Sdk\platform-tools\adb.exe" shell pm clear com.example.frontend
```

**결과**: `Success` 출력되면 성공

## 2. Flutter 프로젝트 클린 빌드

```bash
cd D:/Data/20_Flutter/01_SJ/frontend

# Flutter 캐시 삭제 (build 폴더, .dart_tool 등)
flutter clean

# 의존성 재설치
flutter pub get

# 코드 생성 (Riverpod, Freezed 등)
dart run build_runner build --delete-conflicting-outputs
```

## 3. 앱 실행

```bash
# 에뮬레이터에서 실행
flutter run -d emulator

# 특정 디바이스에서 실행
flutter run -d <device_id>

# 디바이스 목록 확인
flutter devices
```

## 4. 전체 초기화 + 재실행 (한번에)

```bash
# 1단계: 앱 데이터 삭제
"C:\Users\SOGANG1\AppData\Local\Android\Sdk\platform-tools\adb.exe" shell pm clear com.example.frontend

# 2단계: Flutter 재실행
cd D:/Data/20_Flutter/01_SJ/frontend && flutter run -d emulator
```

## 5. 참고: 삭제되는 데이터

| 항목 | 설명 |
|------|------|
| Hive 박스 | saju_profiles, chat_sessions, chat_messages 등 |
| SharedPreferences | 앱 설정 |
| 캐시 파일 | 임시 파일 |

---

## 문제 해결

### Developer Mode 오류
```
Building with plugins requires symlink support.
Please enable Developer Mode in your system settings.
```

해결:
```bash
start ms-settings:developers
```
→ Windows 설정에서 "개발자 모드" 활성화

### adb 못 찾을 때
환경변수 PATH에 추가:
```
C:\Users\SOGANG1\AppData\Local\Android\Sdk\platform-tools
```
