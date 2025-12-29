# AI API 로그 시스템

Supabase `ai_api_logs` 테이블을 폴링하여 txt 파일로 자동 저장합니다.

---

## 빠른 시작

```bash
# 1. tools 폴더로 이동
cd D:\Data\20_Flutter\01_SJ\tools

# 2. 로그 감시 시작
npm run watch
```

끝! 이제 5초마다 새 로그를 감지합니다.

---

## 첫 설치 (최초 1회)

```bash
cd D:\Data\20_Flutter\01_SJ\tools
npm install
```

---

## 파일 구조

```
tools/
├── log-watcher.js    # 메인 스크립트
├── .env              # Supabase 인증정보
└── .last-log-time    # 마지막 로그 시간 (자동 생성)

frontend/assets/log/
├── README.md         # 이 파일
└── 2025-12-28.txt    # 날짜별 로그 파일 (자동 생성)
```

---

## 로그 파일 형식

```
╔──────────────────────────────────────────────────────────────────────╗
║ [10:26:33] ✅ google - daily_fortune
╠──────────────────────────────────────────────────────────────────────╣
║ 모델: gemini-3-flash-preview
║ 토큰: prompt=801, completion=512
║ 비용: $0.001937
╠──────────────────────────────────────────────────────────────────────╣
║ 응답:
║   { "date": "2025년 12월 28일", ... }
╚──────────────────────────────────────────────────────────────────────╝
```

---

## 문제 해결

### 로그가 안 보여요
```bash
# Supabase 연결 확인
cd tools
node -e "require('dotenv').config(); console.log(process.env.SUPABASE_URL)"
```

### 권한 오류
Supabase에서 `ai_api_logs` 테이블 RLS 정책 확인:
```sql
-- anon 읽기 허용 정책 필요
CREATE POLICY "Allow anon read" ON ai_api_logs FOR SELECT TO anon USING (true);
```

### 처음부터 다시 수집
```bash
# .last-log-time 삭제하면 오늘 로그 전체 다시 수집
del tools\.last-log-time
npm run watch
```

---

## 종료

`Ctrl + C` 로 종료
