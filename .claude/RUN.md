# Flutter 프로젝트 실행 가이드 (만톡 SJ)

## TL;DR - 지금 바로 실행

**PowerShell에 복사-붙여넣기**:
```powershell
powershell.exe -NoProfile -Command "cd 'D:\Data\20_Flutter\01_SJ\frontend'; D:\development\flutter\bin\flutter.bat run -d chrome --web-port=9999"
```

접속: **http://localhost:9999**

---

## 프로젝트 정보

| 항목 | 값 |
|------|-----|
| 프로젝트 | 만톡 (Mantok) - AI 사주 챗봇 |
| Flutter SDK | `D:\development\flutter` |
| 프로젝트 경로 | `D:\Data\20_Flutter\01_SJ\frontend` |
| Supabase Ref | `kfciluyxkomskyxjaeat` |
| 기본 웹 포트 | `9999` |

---

## 실행 명령어 모음

### 1. 디바이스 확인
```powershell
powershell.exe -NoProfile -Command "cd 'D:\Data\20_Flutter\01_SJ\frontend'; D:\development\flutter\bin\flutter.bat devices"
```

### 2. 의존성 설치
```powershell
powershell.exe -NoProfile -Command "cd 'D:\Data\20_Flutter\01_SJ\frontend'; D:\development\flutter\bin\flutter.bat pub get"
```

### 3. 코드 생성 (Riverpod/Freezed 변경 시)
```powershell
powershell.exe -NoProfile -Command "cd 'D:\Data\20_Flutter\01_SJ\frontend'; dart run build_runner build --delete-conflicting-outputs"
```

### 4. 웹 실행 (Chrome)
```powershell
powershell.exe -NoProfile -Command "cd 'D:\Data\20_Flutter\01_SJ\frontend'; D:\development\flutter\bin\flutter.bat run -d chrome --web-port=9999"
```

### 5. Windows 데스크톱 실행
```powershell
powershell.exe -NoProfile -Command "cd 'D:\Data\20_Flutter\01_SJ\frontend'; D:\development\flutter\bin\flutter.bat run -d windows"
```

### 6. 웹 빌드 (배포용)
```powershell
powershell.exe -NoProfile -Command "cd 'D:\Data\20_Flutter\01_SJ\frontend'; D:\development\flutter\bin\flutter.bat build web"
```

---

## 팀원별 빠른 시작

### DK (총괄/광고/라우터)
```powershell
# 전체 빌드 + 실행
powershell.exe -NoProfile -Command "cd 'D:\Data\20_Flutter\01_SJ\frontend'; D:\development\flutter\bin\flutter.bat pub get; dart run build_runner build -d; D:\development\flutter\bin\flutter.bat run -d chrome --web-port=9999"
```

### SH (UI/UX)
```powershell
# 핫 리로드용 웹 실행 → 터미널에서 r 키로 핫 리로드
powershell.exe -NoProfile -Command "cd 'D:\Data\20_Flutter\01_SJ\frontend'; D:\development\flutter\bin\flutter.bat run -d chrome --web-port=9999"
```

### JH_BE (Supabase)
```powershell
# 앱 실행 후 DevTools에서 네트워크 탭으로 API 확인
powershell.exe -NoProfile -Command "cd 'D:\Data\20_Flutter\01_SJ\frontend'; D:\development\flutter\bin\flutter.bat run -d chrome --web-port=9999"
```
DevTools: 실행 로그에 출력되는 URL 참조

### JH_AI / Jina (AI 모듈)
```powershell
# AI 관련 로그 확인하며 실행
powershell.exe -NoProfile -Command "cd 'D:\Data\20_Flutter\01_SJ\frontend'; D:\development\flutter\bin\flutter.bat run -d chrome --web-port=9999"
```

---

## 핫 리로드 / 핫 리스타트

실행 중 터미널에서:
- `r` : Hot reload (UI 변경사항 즉시 반영)
- `R` : Hot restart (상태 초기화 + 재시작)
- `q` : 종료
- `d` : Detach (앱은 유지, 터미널만 종료)

---

## 사용 가능한 디바이스

| 디바이스 | ID | 비고 |
|---------|-----|------|
| Windows | `windows` | 데스크톱 앱 |
| Chrome | `chrome` | 웹 **(기본값)** |
| Edge | `edge` | 웹 |

---

## 문제 해결

### Flutter가 멈춤 / 응답 없음
```powershell
# 모든 Flutter/Dart 프로세스 종료
taskkill /f /im dart.exe
taskkill /f /im flutter.bat
# 이후 다시 실행
```

### bash에서 D: 드라이브 경로 오류
- Windows에서는 `bash` 대신 `powershell.exe` 사용
- WSL bash는 D: 드라이브를 `/mnt/d/`로 접근해야 함

### pub get 실패
```powershell
# 캐시 정리 후 재시도
powershell.exe -NoProfile -Command "cd 'D:\Data\20_Flutter\01_SJ\frontend'; D:\development\flutter\bin\flutter.bat clean; D:\development\flutter\bin\flutter.bat pub get"
```

### 빌드 오류 (Generated 파일 관련)
```powershell
# 생성 파일 재생성
powershell.exe -NoProfile -Command "cd 'D:\Data\20_Flutter\01_SJ\frontend'; dart run build_runner build --delete-conflicting-outputs"
```

### 포트 9999 이미 사용 중
```powershell
# 다른 포트로 실행
powershell.exe -NoProfile -Command "cd 'D:\Data\20_Flutter\01_SJ\frontend'; D:\development\flutter\bin\flutter.bat run -d chrome --web-port=8888"
```

---

## Claude Code에서 실행

Claude Code 세션에서 앱 실행 시:
```
"flutter run -d chrome --web-port=9999 실행해줘"
```

---

**최종 업데이트**: 2025-12-27
