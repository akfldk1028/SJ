# DB 발견된 이슈 목록

> 마지막 업데이트: 2026-01-25

---

## 🔴 CRITICAL - 즉시 수정 필요

(현재 없음)

---

## 🟢 INFO - 해결됨

### 1. `is_admin_user` 함수 - 삭제된 컬럼 참조

**발견일**: 2026-01-25
**카테고리**: RPC 함수 / 스키마 불일치
**상태**: ✅ 해결됨 (2026-01-25)

**문제**:
`is_primary` 컬럼이 `saju_profiles` 테이블에서 삭제되었으나, `is_admin_user` 함수에서 여전히 참조 중.

**현재 코드**:
```sql
CREATE OR REPLACE FUNCTION is_admin_user(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM saju_profiles
    WHERE user_id = p_user_id
      AND relation_type = 'admin'
      AND is_primary = true  -- ❌ 삭제된 컬럼!
  );
END;
$$ LANGUAGE plpgsql;
```

**수정 방안**:
```sql
CREATE OR REPLACE FUNCTION is_admin_user(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM saju_profiles
    WHERE user_id = p_user_id
      AND relation_type = 'admin'
      AND profile_type = 'primary'  -- ✅ 올바른 컬럼
  );
END;
$$ LANGUAGE plpgsql;
```

**영향 범위**:
- 관리자 권한 체크 실패 가능
- RLS 정책에서 사용 시 에러 발생

**관련 마이그레이션**: `20260124171831_migrate_is_primary_to_profile_type`

---

## 🟡 WARNING - 검토 필요

### 2. `user_display_name`, `profile_display_name` NULL 삽입 문제

**발견일**: 2026-01-25
**카테고리**: Generated Class / 코드-스키마 불일치
**상태**: ✅ 해결됨 (2026-01-25)

**문제**:
`ai_summaries`, `user_daily_token_usage` 테이블에 `user_display_name`, `profile_display_name` 컬럼 추가됨 (2026-01-24).
하지만 Supadart generated class 재생성이 안 되어 Flutter에서 이 필드를 INSERT하지 않음.

**해결**:
1. ✅ DB 트리거 생성 (`trg_set_ai_summaries_display_names`, `trg_set_user_daily_token_usage_display_name`)
2. ✅ 기존 NULL 데이터 백필 완료
   - `ai_summaries`: 766건 모두 채움
   - `user_daily_token_usage`: 300/311건 채움 (11건은 primary 프로필 없음)

**관련 마이그레이션**: `20260125_add_display_name_triggers`

---

## 🟢 INFO - 참고 사항

### 3. `daily_quota` 100,000 비정상 값

**발견일**: 2026-01-25
**카테고리**: 데이터 정합성
**상태**: ✅ 해결됨

**문제**:
`user_daily_token_usage`에서 1건의 `daily_quota`가 100,000으로 설정됨 (정상: 50,000).
원인 불명 (수동 입력 또는 코드 버그 추정).

**해결**: 50,000으로 수정 완료

---

## 해결 완료 이력

| 날짜 | 이슈 | 해결 방법 |
|------|------|----------|
| 2026-01-25 | `compatibility_tokens`, `compatibility_count` 미사용 컬럼 | 삭제 완료 |
| 2026-01-25 | `memos` 테이블 미사용 | 삭제 완료 |
| 2026-01-25 | `is_primary` → `profile_type` 마이그레이션 | 트리거 재작성 후 컬럼 삭제 |
| 2026-01-25 | 월운/연운 토큰 추적 컬럼 누락 | `monthly_fortune_tokens`, `yearly_fortune_2025_tokens`, `yearly_fortune_2026_tokens` 추가 |
| 2026-01-25 | `daily_quota` 100,000 비정상 값 | 50,000으로 수정 |
| 2026-01-25 | `is_admin_user` 함수 `is_primary` 참조 | `profile_type = 'primary'`로 수정 |
| 2026-01-25 | `user_display_name`, `profile_display_name` NULL | DB 트리거 생성 + 백필 완료 |
| 2026-01-25 | Flutter `defaultMaxInputTokens` 100,000 | 50,000으로 수정 |

---

## 이슈 카테고리 설명

| 카테고리 | 설명 |
|----------|------|
| **RPC 함수** | Supabase RPC 함수 관련 이슈 |
| **스키마 불일치** | 테이블/컬럼 구조와 코드 간 불일치 |
| **트리거** | DB 트리거 관련 이슈 |
| **RLS 정책** | Row Level Security 정책 이슈 |
| **인덱스** | 성능 관련 인덱스 이슈 |
| **데이터 정합성** | 데이터 무결성 문제 |
