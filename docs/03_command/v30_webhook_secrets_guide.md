# RevenueCat Webhook + Supabase 연동 가이드

> 최종 업데이트: 2026-02-02 (모든 작업 완료)

---

## 배포 완료 현황

| Edge Function | 버전 | JWT 검증 | 상태 | 비고 |
|--------------|------|---------|------|------|
| `purchase-webhook` | **v3** | OFF | ACTIVE | RevenueCat Bearer 인증, FK fallback 포함 |
| `ai-gemini` | **v50** | ON | ACTIVE | quota 상품 ID: day_pass/week_pass/monthly |

| DB 테이블 | 상태 | 비고 |
|----------|------|------|
| `subscriptions` | 생성 완료 | FK auth.users, RLS, UNIQUE(user_id,product_id), idx(user_id,status) |
| `chat_error_logs` | 기존 존재 | webhook 로그 기록용 (operation: `purchase-webhook:*`) |

| RevenueCat | 상태 |
|-----------|------|
| Webhook URL | 등록 완료 (`whintgr7006704ac6`) |
| `REVENUECAT_WEBHOOK_SECRET` | Supabase secrets에 등록 완료 |
| 테스트 이벤트 | 200 OK + chat_error_logs 기록 확인 |

---

## 1. Supabase Secrets 목록

| Secret 이름 | 용도 | 상태 |
|-------------|------|------|
| `SUPABASE_URL` | Supabase 프로젝트 URL | **자동 주입** (설정 불필요) |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role 키 | **자동 주입** (설정 불필요) |
| `GEMINI_API_KEY` | Gemini API 키 | 등록 완료 |
| `REVENUECAT_WEBHOOK_SECRET` | Webhook Bearer 토큰 | 등록 완료 |

### Secret 변경이 필요한 경우
```bash
# CLI
supabase secrets set REVENUECAT_WEBHOOK_SECRET="새_값"

# 또는 Supabase Dashboard
# Project Settings > Edge Functions > Secrets Management
```

> RevenueCat Dashboard의 Authorization header 값과 반드시 동일해야 함

---

## 2. RevenueCat Webhook 설정 현황

| 필드 | 값 |
|------|-----|
| Webhook Name | Supabase purchase-webhook |
| Webhook ID | `whintgr7006704ac6` |
| URL | `https://kfciluyxkomskyxjaeat.supabase.co/functions/v1/purchase-webhook` |
| Authorization | `Bearer {REVENUECAT_WEBHOOK_SECRET}` |
| Environment | Both Production and Sandbox |
| Events | All events |
| Apps | All apps |

### 위치
RevenueCat Dashboard > 프로젝트 사담 (8e37c887) > Integrations > Webhooks

---

## 3. 검증 방법

### 테스트 이벤트 발송
1. RevenueCat Dashboard > Integrations > Webhooks > Supabase purchase-webhook
2. "Send test event" 클릭
3. Response 200 확인

### DB 로그 확인
```sql
-- webhook 로그 조회
SELECT id, user_id, error_message, operation, created_at
FROM chat_error_logs
WHERE operation LIKE 'purchase-webhook:%'
ORDER BY created_at DESC
LIMIT 10;

-- 구독 상태 조회
SELECT * FROM subscriptions
ORDER BY updated_at DESC
LIMIT 10;
```

### Edge Function 로그 확인
```bash
# Supabase Dashboard > Edge Functions > purchase-webhook > Logs
# 또는
supabase functions logs purchase-webhook
```

---

## 4. 인증 로직 설명

```typescript
// purchase-webhook/index.ts
if (REVENUECAT_WEBHOOK_SECRET) {
  // secret이 설정되어 있으면 Bearer 토큰 검증
  const authHeader = req.headers.get("authorization");
  if (authHeader !== `Bearer ${REVENUECAT_WEBHOOK_SECRET}`) {
    return 401; // Unauthorized
  }
}
// secret 미설정 시 인증 스킵 (개발 환경용)
```

---

## 5. 알려진 동작

### FK fallback (logError)
- `chat_error_logs.user_id`에 `users` 테이블 FK 제약 존재
- RevenueCat 테스트 이벤트의 `app_user_id`는 가짜 UUID → FK 위반
- `logError` 함수가 FK 위반 시 `user_id: null`로 자동 재시도
- 실제 구매 이벤트에서는 Supabase auth UUID가 전달되므로 정상 동작

### RevenueCat ↔ Supabase UUID 동기화
- `purchase_service.dart`에서 `Purchases.logIn(userId)` 호출
- `userId` = `SupabaseService.currentUserId` (auth.users UUID)
- RevenueCat의 `app_user_id` = Supabase의 `auth.users.id`
- webhook의 `event.app_user_id`가 곧 Supabase user UUID

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-02-02 | purchase-webhook v2 배포 (에러 로깅 + 이벤트 3종 추가) |
| 2026-02-02 | ai-gemini v49→v50 배포 (quota 상품 ID 업데이트 + 주석 수정) |
| 2026-02-02 | subscriptions 테이블 생성 (migration) |
| 2026-02-02 | REVENUECAT_WEBHOOK_SECRET 등록 |
| 2026-02-02 | RevenueCat Webhook URL 등록 (whintgr7006704ac6) |
| 2026-02-02 | purchase-webhook v3 배포 (logError FK fallback 추가) |
| 2026-02-02 | 테스트 이벤트 검증 완료 (200 OK + DB 로그) |
| 2026-02-02 | 본 가이드 최종 업데이트 |
