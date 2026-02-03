# Purchase Data Layer

## 개요
Supabase `subscriptions` 테이블과 통신하는 데이터 계층.
주요 구독 관리는 **RevenueCat webhook → purchase-webhook Edge Function**이 담당.
여기서는 보조적 클라이언트 측 기록/조회만 수행.

## 구조
```
data/
├── purchase_data.dart           # Barrel export
├── queries/
│   └── purchase_queries.dart    # 구독 상태 조회 (SELECT)
└── mutations/
    └── purchase_mutations.dart  # 구매 성공 시 기록 (UPSERT)
```

## queries/purchase_queries.dart
- `getActiveSubscriptions(userId)` → 활성 구독 목록 조회
- `hasActiveSubscription(userId, productId)` → 특정 상품 구독 여부

## mutations/purchase_mutations.dart
- `recordPurchase(CustomerInfo)` → RevenueCat 구매 성공 후 subscriptions 테이블에 기록
- 클라이언트 측 보조 기록 (메인은 webhook이 담당)
- `upsert` 사용하여 중복 방지 (user_id + product_id unique)

## DB 스키마 (subscriptions)
| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID PK | 자동 생성 |
| user_id | UUID FK | auth.users 참조 |
| product_id | TEXT | sadam_ad_removal / sadam_ai_premium / sadam_combo |
| platform | TEXT | ios / android |
| status | TEXT | active / cancelled / expired |
| is_lifetime | BOOLEAN | 영구 구매 여부 (ad_removal) |
| expires_at | TIMESTAMPTZ | 구독 만료 시간 (null = 영구) |
