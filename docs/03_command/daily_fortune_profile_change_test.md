# Daily Fortune 프로필 변경 테스트

> 테스트 날짜: 2026-02-04 (KST)
> 목적: 프로필 이름 변경 시 기존 daily_fortune 데이터 유지 여부 확인

---

## 테스트 시나리오

### 현재 상태 (변경 전)

| 항목 | 값 |
|------|-----|
| user_id | `29efeaf9-b8fe-4eb3-91f0-fc153c50fb2c` |
| profile_id | `db7ad2bf-5ed6-4eaa-b12e-a41d6949dddf` |
| 현재 display_name | `불재현` |
| 프로필 생성일 | 2026-02-03 17:49:09 KST |
| 프로필 수정일 | 2026-02-04 02:52:21 KST |

### 현재 ai_summaries 데이터

| summary_type | target_date | profile_display_name | created_kst |
|--------------|-------------|---------------------|-------------|
| daily_fortune | 2026-02-04 | 불재현 | 2026-02-04 02:52:44 |
| yearly_fortune_2026 | - | 불재현 | 2026-02-04 02:54:44 |
| yearly_fortune_2025 | - | 불재현 | 2026-02-04 02:55:05 |
| monthly_fortune | - | 불재현 | 2026-02-04 02:56:45 |
| saju_base | - | 불재현 | 2026-02-04 03:15:27 |

**총 5개 레코드**

---

## 테스트 계획

### Step 1: 2월 5일 daily_fortune 생성 확인
- [ ] 2026-02-05 00:00 KST 이후 daily_fortune 조회
- [ ] target_date = '2026-02-05' 레코드 생성 확인

### Step 2: 프로필 이름 변경
- [ ] `불재현` → 새 이름으로 변경
- [ ] 변경 시간 기록: ________________

### Step 3: 변경 후 확인
- [ ] ai_summaries의 profile_display_name 변경 확인
- [ ] 기존 daily_fortune (2/4, 2/5) 데이터 유지 확인
- [ ] v31 트리거 정상 동작 확인

---

## 테스트 결과 (2월 5일 작성 예정)

### 변경 전 스냅샷

```sql
-- 이 쿼리로 확인
SELECT
  id,
  summary_type,
  target_date,
  profile_display_name,
  created_at AT TIME ZONE 'Asia/Seoul' as created_kst
FROM ai_summaries
WHERE profile_id = 'db7ad2bf-5ed6-4eaa-b12e-a41d6949dddf'
ORDER BY created_at;
```

### 변경 후 스냅샷

(테스트 후 작성)

---

## 예상 결과

v31 트리거가 정상 동작한다면:
1. 모든 ai_summaries의 `profile_display_name`이 새 이름으로 변경됨
2. 기존 데이터(daily_fortune 등)는 **삭제되지 않음**
3. profile_id FK 연결은 유지됨

---

## 관련 문서

- [db_schema_integrated.md](./db_schema_integrated.md) - v31 트리거 문서
- 트리거 함수: `sync_user_display_name()`
