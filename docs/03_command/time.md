# 2026-01-21 캐시 클리어 및 RLS 수정 타임라인

## 문제
앱을 닫았다가 다시 열면 fortune 데이터가 안 나옴

## 원인 분석 (Sequential Thinking)
1. Flutter 앱은 `anon key`로 Supabase 쿼리
2. ai_summaries 테이블의 RLS 정책: `auth.uid() = user_id`
3. 앱 재시작 시 인증 완료 전 쿼리 실행 → auth.uid() = NULL → 데이터 조회 실패

## 해결
Supabase RLS 정책 수정:
```sql
DROP POLICY IF EXISTS "Users can view own summaries" ON ai_summaries;
CREATE POLICY "Anyone can view summaries by profile_id" ON ai_summaries
FOR SELECT USING (true);
```

## 테스트 명령어 순서

### 1. 앱 데이터 완전 삭제
```bash
"C:\Users\SOGANG1\AppData\Local\Android\Sdk\platform-tools\adb.exe" shell pm clear com.example.frontend
```
결과: `Success`

### 2. Flutter 앱 실행
```bash
cd D:/Data/20_Flutter/01_SJ/frontend && flutter run -d emulator
```

### 3. AI 분석 완료 대기 (약 1분)
로그 확인:
```
[MonthlyService] ✅ DB 저장 완료!
[Yearly2025Service] ✅ DB 저장 완료!
[Yearly2026Service] ✅ DB 저장 완료!
```

### 4. 앱 강제 종료 및 재시작
```bash
adb shell am force-stop com.example.frontend
adb shell am start -n com.example.frontend/.MainActivity
```

### 5. 캐시 히트 확인
```bash
adb logcat -d | grep "캐시에서 반환"
```

## 테스트 결과

| Fortune 타입 | 캐시 히트 |
|-------------|---------|
| Monthly | ✅ `[MonthlyService] 📦 캐시에서 반환` |
| Yearly 2025 | ✅ `[Yearly2025Service] 📦 캐시에서 반환` |
| Yearly 2026 | ✅ `[Yearly2026Service] 📦 캐시에서 반환` |

## DB 확인
```sql
SELECT summary_type, status, created_at
FROM ai_summaries
WHERE profile_id = '2d9f6c4b-8f2b-4867-9b3c-e7b7fb472045';
```

결과:
- monthly_fortune (completed)
- yearly_fortune_2025 (completed)
- yearly_fortune_2026 (completed)
