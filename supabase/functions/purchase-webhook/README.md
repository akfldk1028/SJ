# purchase-webhook Edge Function

## 개요
RevenueCat에서 발생하는 구매/구독 이벤트를 수신하여
Supabase `subscriptions` 테이블을 관리하는 webhook 엔드포인트.

## 이벤트 → DB 매핑

| RevenueCat Event | DB 동작 | status |
|-----------------|---------|--------|
| `INITIAL_PURCHASE` | INSERT | active |
| `NON_RENEWING_PURCHASE` | INSERT (is_lifetime: true) | active |
| `RENEWAL` | UPDATE expires_at | active |
| `CANCELLATION` | UPDATE cancelled_at | cancelled |
| `EXPIRATION` | UPDATE | expired |

## 인증
- `REVENUECAT_WEBHOOK_SECRET` 환경변수 설정 시 Bearer token 검증
- 미설정 시 인증 없이 수신 (개발 환경)

## 배포
```bash
supabase functions deploy purchase-webhook
supabase secrets set REVENUECAT_WEBHOOK_SECRET=your_secret_here
```

## RevenueCat 대시보드 설정
1. Project Settings > Webhooks
2. URL: `https://<project-ref>.supabase.co/functions/v1/purchase-webhook`
3. Authorization: `Bearer <REVENUECAT_WEBHOOK_SECRET>`

## ai-gemini 연동
`ai-gemini/index.ts`의 `checkAndUpdateQuota`에서:
- `subscriptions` 테이블 조회
- `sadam_ai_premium` 또는 `sadam_combo` 활성 구독 → quota 면제
- 만료 시간 자동 체크 (is_lifetime이면 항상 유효)
