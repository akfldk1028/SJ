# Purchase Module (IAP - In-App Purchase)

## 개요
RevenueCat SDK 기반 인앱 결제 시스템. 광고 제거, AI 프리미엄, 콤보 구독 관리.

## 아키텍처
```
PurchaseService (singleton)     → RevenueCat SDK 초기화 + 핵심 API
PurchaseNotifier (@riverpod)    → 상태 관리 (CustomerInfo 기반)
PaywallScreen                   → 구매 UI (3개 상품 카드)
```

## 상품 구성 (Product IDs)

| Product ID | 유형 | 가격 | 설명 |
|-----------|------|------|------|
| `sadam_ad_removal` | Non-consumable (영구) | ₩2,900 | 모든 광고 제거 |
| `sadam_ai_premium` | Auto-renewable subscription | ₩9,900/월 | AI 무제한 |
| `sadam_combo` | Auto-renewable subscription | ₩11,000/월 | 광고 제거 + AI 무제한 |

## Entitlements (RevenueCat)

| Entitlement ID | 포함 상품 | 효과 |
|---------------|----------|------|
| `ad_free` | `sadam_ad_removal`, `sadam_combo` | 모든 광고 비표시 |
| `ai_premium` | `sadam_ai_premium`, `sadam_combo` | daily_quota 무제한 |

## 연동 포인트

### 광고 시스템 연동 (isAdFree 분기 로직)
- `ad_trigger_service.dart` → `isAdFree` 구매자 광고 정책:
  - 인터벌(강제) 광고: **차단**
  - 토큰 경고(80%) 광고: **차단**
  - 토큰 소진(100%) 보상형 광고: **허용** ← 토큰 충전 수단
- `conversational_ad_provider.dart` → `purchaseNotifierProvider`에서 isAdFree 체크

> **핵심**: 광고 제거 = 강제 광고만 제거. 토큰 소진 시 보상형 광고는 유저가 직접 선택 가능.
> 이렇게 해야 광고 제거 구매자도 토큰 충전 수단이 있음.

### Quota 시스템 연동
- `chat_provider.dart` → `isAiPremium`이면 토큰 소진 체크 스킵
- `ai-gemini/index.ts` → subscriptions 테이블에서 활성 구독 확인 → quota 면제

### DB 연동
- `subscriptions` 테이블 → RevenueCat webhook이 관리
- `purchase-webhook` Edge Function → 이벤트별 upsert/update

## 파일 구조
```
purchase/
├── purchase.dart               # Barrel export
├── purchase_config.dart        # 상수 (Product ID, Entitlement ID, API Key)
├── purchase_service.dart       # RevenueCat 초기화 (singleton)
├── data/
│   ├── purchase_data.dart      # Data barrel
│   ├── queries/
│   │   └── purchase_queries.dart   # Supabase 구독 조회
│   └── mutations/
│       └── purchase_mutations.dart # 구매 이벤트 기록
├── providers/
│   ├── purchase_provider.dart  # @riverpod PurchaseNotifier + offerings
│   └── purchase_provider.g.dart
└── widgets/
    ├── paywall_screen.dart     # 구매 선택 화면
    ├── premium_badge_widget.dart   # PRO/AD FREE 뱃지
    └── restore_button_widget.dart  # 구매 복원 (Apple 필수)
```

## 모듈화 규칙

### Import 규칙
```
✅ 외부 → purchase 모듈: barrel export만 사용
   import 'purchase/purchase.dart';

❌ 외부 → purchase 내부 파일 직접 참조 금지
   import 'purchase/providers/purchase_provider.dart';  // WRONG
   import 'purchase/purchase_config.dart';               // WRONG
```

- **외부 파일**은 반드시 `purchase/purchase.dart` 하나만 import
- **모듈 내부** 파일 간에는 relative import 사용 (circular import 방지)
- 폴더 구조 변경 시 `purchase.dart` barrel만 수정하면 외부 영향 없음

### 의존성 방향 (단방향)
```
purchase_config.dart          ← 의존 없음 (상수만)
    ↓
purchase_service.dart         ← config + supabase_service
purchase_mutations.dart       ← config + supabase
purchase_queries.dart         ← supabase
    ↓
purchase_provider.dart        ← mutations + config
    ↓
paywall_screen.dart           ← provider
premium_badge_widget.dart     ← provider + config
restore_button_widget.dart    ← provider
```

### 외부 연동 파일 (4곳)
| 파일 | import | 사용 |
|------|--------|------|
| `main.dart` | `purchase/purchase.dart` | `PurchaseService.instance.initialize()` |
| `app_router.dart` | `purchase/purchase.dart` | `PaywallScreen` 라우트 |
| `chat_provider.dart` | `purchase/purchase.dart` | `PurchaseConfig.entitlementAiPremium` 체크 |
| `conversational_ad_provider.dart` | `purchase/purchase.dart` | `PurchaseConfig.entitlementAdFree` 체크 |

### 상수 관리
- 모든 Product ID, Entitlement ID는 `purchase_config.dart`에서 중앙 관리
- hardcoded string 사용 금지 → `PurchaseConfig.entitlementAdFree` 등 사용

---

## 초기화 순서 (main.dart)
1. `WidgetsFlutterBinding.ensureInitialized()`
2. Hive, Supabase 초기화
3. `PurchaseService.instance.initialize()` ← 모바일만
4. AdService 초기화

## 라우트
- `/settings/premium` → PaywallScreen

---

## 스토어 설정 (수동 작업)

### Google Play Console
1. **수익 창출 > 제품 > 인앱 상품**
   - `sadam_ad_removal` (관리되는 상품, 비소모성)
   - 가격: ₩2,900
   - 설명: "모든 광고를 영구적으로 제거합니다"

2. **수익 창출 > 제품 > 구독**
   - 구독 그룹: "사담 프리미엄" 생성
   - `sadam_ai_premium` (월간 구독)
     - 가격: ₩9,900/월
     - 설명: "AI 대화 무제한, 모든 운세 제한 해제"
   - `sadam_combo` (월간 구독)
     - 가격: ₩11,000/월
     - 설명: "광고 제거 + AI 대화 무제한"

3. **라이선스 테스트**
   - 설정 > 라이선스 테스트 > Gmail 추가
   - 테스트 구매는 5분 후 자동 갱신/만료

### App Store Connect
1. **인앱 구입 > 비소모성**
   - `sadam_ad_removal`
   - 참조 이름: "광고 제거"
   - 가격: Tier 3 (₩2,900)

2. **인앱 구입 > 자동 갱신 구독**
   - 구독 그룹: "Sadam Premium" 생성
   - `sadam_ai_premium`
     - 참조 이름: "AI 프리미엄"
     - 기간: 1개월
     - 가격: ₩9,900
   - `sadam_combo`
     - 참조 이름: "올인원"
     - 기간: 1개월
     - 가격: ₩11,000

3. **Xcode 설정**
   - Signing & Capabilities → "+ Capability" → "In-App Purchase" 추가

4. **Sandbox 테스트**
   - 사용자 및 액세스 > Sandbox > 테스터 추가
   - Sandbox 구독은 5분 = 1개월

### RevenueCat Dashboard
1. **Projects** → 앱 생성 (iOS/Android 각각)
2. **Products** → 3개 상품 등록
   - iOS: App Store Connect의 Product ID 연결
   - Android: Google Play Console의 Product ID 연결
3. **Entitlements** 생성:
   - `ad_free` → `sadam_ad_removal`, `sadam_combo` 매핑
   - `ai_premium` → `sadam_ai_premium`, `sadam_combo` 매핑
4. **Offerings** → `default` offering 생성 → 3개 패키지 추가
5. **Webhooks** → Supabase Edge Function URL 등록:
   - URL: `https://<project-ref>.supabase.co/functions/v1/purchase-webhook`
   - Authorization: Bearer token (REVENUECAT_WEBHOOK_SECRET)
6. **API Keys** 복사 → `purchase_config.dart`에 입력:
   - Android: `goog_xxx` → `revenueCatApiKeyAndroid`
   - iOS: `appl_xxx` → `revenueCatApiKeyIos`

### Supabase 설정
1. **subscriptions 테이블 생성** (SQL Editor에서 실행):
```sql
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  product_id TEXT NOT NULL,
  platform TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  original_transaction_id TEXT,
  starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  is_lifetime BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);

ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own subscriptions" ON subscriptions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role full access" ON subscriptions
  FOR ALL USING (auth.role() = 'service_role');

CREATE INDEX idx_subscriptions_user_status
  ON subscriptions(user_id, status);
```

2. **Edge Function 배포**:
```bash
supabase functions deploy purchase-webhook
```

3. **환경 변수 설정**:
```bash
supabase secrets set REVENUECAT_WEBHOOK_SECRET=your_secret_here
```
