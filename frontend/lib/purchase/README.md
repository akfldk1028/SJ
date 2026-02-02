# Purchase Module (IAP - In-App Purchase)

## 개요
RevenueCat SDK 기반 인앱 결제 시스템. 프리미엄 이용권(광고 제거 + AI 무제한) 관리.

## 아키텍처
```
PurchaseService (singleton)     → RevenueCat SDK 초기화 + 핵심 API
PurchaseNotifier (@riverpod)    → 상태 관리 (CustomerInfo 기반)
PaywallScreen                   → 구매 UI (3개 상품 카드)
```

---

## 상품 구성 (2026-02-02 확정)

| Product ID | 유형 | 가격(KRW) | 설명 |
|-----------|------|-----------|------|
| `sadam_day_pass` | Non-consumable (일회성) | ₩1,100 | 24시간 프리미엄 |
| `sadam_week_pass` | Non-consumable (일회성) | ₩4,900 | 7일 프리미엄 |
| `sadam_monthly` | Auto-renewable subscription | ₩8,900/월 | 월간 자동갱신 구독 |

> 전 상품 177개국 가격 자동 환산 적용됨 (Google Play Console)

## Entitlement (RevenueCat)

| Entitlement ID | 포함 상품 | 효과 |
|---------------|----------|------|
| `premium` | `sadam_day_pass`, `sadam_week_pass`, `sadam_monthly` | 광고 제거 + AI 무제한 |

> 단일 entitlement 구조: 3개 상품 중 하나라도 활성이면 premium 권한 부여

---

## 스토어/대시보드 설정 현황

### Google Play Console (완료)

| 상품 | 타입 | 상태 | 비고 |
|------|------|------|------|
| `sadam_day_pass` | 일회성 (purchase option: sadam-day-pass-default) | 활성 | ₩1,100 |
| `sadam_week_pass` | 일회성 (purchase option: sadam-week-pass-default) | 활성 | ₩4,900 |
| `sadam_monthly` | 구독 (base plan: sadam-monthly-default) | 활성 | ₩8,900/월, 유예기간 7일, 계정 보류 53일 |

- 패키지명: `com.clickaround.sadam`
- 177개국 가격 설정 완료

### RevenueCat Dashboard (완료)

**프로젝트**: 사담 (Sadam)
- 프로젝트 ID: `8e37c887`
- Play Store 앱 ID: `appfbb2d0e00b`

**API Keys**:
| 플랫폼 | 키 | 상태 |
|--------|-----|------|
| Android (Public) | `goog_DfwxpejDQNZHDxDNdLVPSWZVDvR` | 코드 반영 완료 |
| iOS (Public) | `appl_xxx` | TODO: 실제 키로 교체 |
| Test | `test_aNIFEBjTUTcYZGJjnBPDNqLtdbV` | 테스트용 |

**Products (Play Store)**:
| RevenueCat ID | Display Name | Type |
|---------------|-------------|------|
| `sadam_monthly:sadam-monthly-default` | 월간 구독 | Subscription |
| `sadam_day_pass` | 1일 이용권 | Non-consumable |
| `sadam_week_pass` | 1주일 이용권 | Non-consumable |

**Entitlement**: `premium` → 3개 상품 모두 연결됨

**Offering**: `default`
| Package ID | 상품 |
|------------|------|
| `$rc_monthly` | sadam_monthly (월간 구독) |
| `day_pass` (custom) | sadam_day_pass (1일 이용권) |
| `week_pass` (custom) | sadam_week_pass (1주일 이용권) |

### App Store Connect (미완료)
- iOS 출시 시 별도 설정 필요
- RevenueCat iOS 앱 추가 + 상품 등록 필요

---

## 남은 작업 (TODO)

### Android 프로덕션 (완료)
- [x] **Service Account Credentials** - 완료
  - 서비스 계정: `revenuecat@sadam-486214.iam.gserviceaccount.com`
  - JSON 키: `docs/04_DK/sadam-486214-e3cc46240b0e.json` (.gitignore 등록됨)
  - RevenueCat 업로드: 완료
  - Google Play Console 권한 부여: 완료 (앱 정보 보기, 재무 데이터, 주문/구독 관리)
- [x] **RevenueCat 이메일 인증** - 완료
- [x] **라이선스 테스터 등록** - 완료 (CGXR 이메일 목록 14명)
- [x] **Supabase webhook 연동** - 완료 (2026-02-02)
  - `purchase-webhook` v3 배포 (JWT OFF, Bearer 인증)
  - `ai-gemini` v50 배포 (quota 상품 ID: day_pass/week_pass/monthly)
  - `subscriptions` 테이블 생성 (FK auth.users, RLS, UNIQUE(user_id,product_id))
  - RevenueCat Webhook 등록 + `REVENUECAT_WEBHOOK_SECRET` 설정 완료
  - 테스트 이벤트 200 OK + chat_error_logs 기록 확인

### 프론트엔드 광고 해제 로직 (완료)

> `purchaseNotifierProvider.isPremium`이 구매 기간 동안 `true`를 반환. RevenueCat SDK가 entitlement 만료를 자동 관리. 프론트에서는 `isPremium` 체크만 하면 됨.

- [x] **BannerAdWidget premium 체크** - `ConsumerStatefulWidget` 전환 + `ref.watch(purchaseNotifierProvider)` → premium이면 `SizedBox.shrink()`
  - 파일: `frontend/lib/ad/widgets/banner_ad_widget.dart`
- [x] **MainScaffold 전면광고 premium 체크** - `ConsumerWidget` 전환 + `isPremium`이면 `showInterstitialAd()` 스킵
  - 파일: `frontend/lib/features/home/presentation/screens/main_scaffold.dart`
- [x] **fortune_category_list 전면광고 premium 체크** - `isPremium`이면 `showInterstitialAd()` 스킵
  - 파일: `frontend/lib/features/menu/presentation/widgets/fortune_category_list.dart`
- [x] **구매 성공 후 광고 즉시 제거 UX** - `BannerAdWidget`이 `ref.watch`로 반응하므로 구매 성공 → `state` 갱신 → 배너 자동 숨김

### 프론트엔드 구매 UI 연동 (일부 완료)

- [x] **설정 화면에서 프리미엄 메뉴 항목** - "구독 관리" 섹션 추가 + isPremium이면 "이용중" 뱃지
  - 파일: `frontend/lib/features/settings/presentation/screens/settings_screen.dart`
  - 라우트: `/settings/premium` → `PaywallScreen`

- [x] **토큰 소진 시 구매 유도 버튼** - 2버튼: "바로 대화 계속하기" (네이티브 광고) + "광고 없이 이용하기" (PaywallScreen)
  - 파일: `frontend/lib/features/saju_chat/presentation/widgets/token_depleted_banner.dart`
  - 영상 광고 버튼은 주석 처리 (추후 활성화 가능)
  - 구매 버튼이 primary(강조) 스타일

- [ ] **PremiumBadgeWidget 앱 내 노출** (선택사항, 나중에)
  - 파일: `frontend/lib/purchase/widgets/premium_badge_widget.dart` (이미 구현됨)
  - 노출 위치: 설정 화면, 채팅 화면 상단 등
  - premium 유저만 표시

### iOS 출시 시 (미완료)
- [ ] **App Store Connect 상품 등록** - 3개 상품 (sadam_day_pass, sadam_week_pass, sadam_monthly) 동일 구성
- [ ] **RevenueCat iOS 앱 추가** - RevenueCat Dashboard > Apps > + New App > Apple App Store
- [ ] **RevenueCat iOS API 키 발급** - 발급 후 아래 파일 교체
- [ ] **`purchase_config.dart`의 `revenueCatApiKeyIos` 교체** - 현재 `appl_xxx` 플레이스홀더 → 실제 키로 변경
- [ ] **Xcode 설정** - Signing & Capabilities > In-App Purchase capability 추가
- [ ] **서버 측 변경 불필요** - purchase-webhook, ai-gemini, subscriptions 테이블은 iOS도 그대로 사용 (platform 필드가 "ios"로 들어올 뿐)

### 기타 (미완료)
- [ ] **W-8BEN 세금 양식 제출 완료 확인** - Google Play Console에서 상태 확인
- [ ] **Service Account 권한 반영 확인** - RevenueCat Dashboard > Apps > Play Store 앱 > Service credentials > Validate credentials (등록 후 24~36시간 소요)

---

## 연동 포인트

### 광고 시스템 연동 (premium 체크 현황)

| 컴포넌트 | 파일 | premium 체크 | 상태 |
|---------|------|------------|------|
| `conversational_ad_provider` | `saju_chat/.../conversational_ad_provider.dart:98` | `purchaseNotifierProvider` 읽어서 isPremium 전달 | OK |
| `ad_trigger_service` | `saju_chat/.../ad_trigger_service.dart:67` | isPremium이면 강제 광고 차단, tokenDepleted만 허용 | OK |
| `ad_provider` (canShowInterstitial) | `ad/providers/ad_provider.dart:96` | `purchaseNotifierProvider.notifier.isPremium` | OK |
| `ad_provider` (onNewSession) | `ad/providers/ad_provider.dart:138` | isPremium이면 스킵 | OK |
| `ad_provider` (onNewSessionRewarded) | `ad/providers/ad_provider.dart:164` | isPremium이면 스킵 | OK |
| `chat_provider` (sendMessage quota) | `saju_chat/.../chat_provider.dart:596` | isPremium이면 토큰 소진 체크 스킵 | OK |
| `BannerAdWidget` | `ad/widgets/banner_ad_widget.dart` | `ref.watch(purchaseNotifierProvider)` → premium이면 숨김 | OK |
| `MainScaffold _onTap` | `home/.../main_scaffold.dart:61` | `isPremium`이면 `showInterstitialAd()` 스킵 | OK |
| `fortune_category_list` | `menu/.../fortune_category_list.dart:74` | `isPremium`이면 `showInterstitialAd()` 스킵 | OK |

- **premium 광고 정책**: 강제 광고(인터벌, 토큰 80% 경고) = 차단 / 보상형 광고(토큰 100% 소진) = 허용 (유저 선택)
- **서버 측**: `ai-gemini`에서 `subscriptions` 테이블의 active 상태 확인 → premium이면 quota 면제

### Quota 시스템 연동
- `chat_provider.dart:596` → `isPremium`이면 토큰 소진 체크 스킵
- premium 사용자: `premiumDailyQuota = 1,000,000,000` (사실상 무제한)
- 무료 사용자: `freeDailyQuota = 20,000`
- 서버(ai-gemini): `subscriptions` 테이블에서 `status='active'` + `product_id in (day_pass, week_pass, monthly)` 확인

### 기간별 만료 관리
- **RevenueCat SDK가 자동 관리**: entitlement 만료 시 `isPremium` → `false` 자동 전환
- **서버 webhook**: EXPIRATION 이벤트 → `subscriptions.status = 'expired'` 자동 업데이트
- **day_pass** (24시간): RevenueCat이 `expiration_at_ms` 기준으로 만료 처리
- **week_pass** (7일): 동일
- **monthly** (자동갱신): RENEWAL 이벤트로 `expires_at` 자동 갱신, 미갱신 시 EXPIRATION

---

## 파일 구조
```
purchase/
├── README.md                  # 이 문서
├── purchase.dart              # Barrel export
├── purchase_config.dart       # 상수 (Product ID, Entitlement ID, API Key)
├── purchase_service.dart      # RevenueCat 초기화 (singleton)
├── data/
│   ├── purchase_data.dart     # Data barrel
│   ├── queries/
│   │   └── purchase_queries.dart   # Supabase 구독 조회
│   └── mutations/
│       └── purchase_mutations.dart # 구매 이벤트 기록
├── providers/
│   ├── purchase_provider.dart  # @riverpod PurchaseNotifier + offerings
│   └── purchase_provider.g.dart
└── widgets/
    ├── paywall_screen.dart     # 구매 선택 화면 (3개 상품 카드)
    ├── premium_badge_widget.dart   # PRO 뱃지
    └── restore_button_widget.dart  # 구매 복원 (Apple 필수)
```

## 모듈화 규칙

### Import 규칙
```
외부 → purchase 모듈: barrel export만 사용
   import 'purchase/purchase.dart';

외부 → purchase 내부 파일 직접 참조 금지
```

### 의존성 방향 (단방향)
```
purchase_config.dart          ← 의존 없음 (상수만)
    ↓
purchase_service.dart         ← config + supabase_service
    ↓
purchase_provider.dart        ← service + config
    ↓
paywall_screen.dart           ← provider
premium_badge_widget.dart     ← provider + config
restore_button_widget.dart    ← provider
```

---

## 초기화 순서 (main.dart)
1. `WidgetsFlutterBinding.ensureInitialized()`
2. Hive, Supabase 초기화
3. `PurchaseService.instance.initialize()` (모바일만)
4. AdService 초기화

## 라우트
- `/settings/premium` → PaywallScreen

---

## 서버 연동 상세 (Webhook + Quota)

### Edge Functions 배포 현황

| Function | 버전 | JWT | 용도 |
|----------|------|-----|------|
| `purchase-webhook` | v3 | OFF | RevenueCat 이벤트 수신 → `subscriptions` 테이블 upsert |
| `ai-gemini` | v50 | ON | 채팅 시 `subscriptions` 조회 → premium이면 quota 면제 |

### purchase-webhook 이벤트 처리

| RevenueCat Event | DB 동작 | status |
|-----------------|---------|--------|
| `INITIAL_PURCHASE` | `subscriptions` upsert | `active` |
| `NON_RENEWING_PURCHASE` | `subscriptions` upsert | `active` (expires_at 설정) |
| `RENEWAL` | `subscriptions` update | `active` (expires_at 갱신) |
| `CANCELLATION` | `subscriptions` update | `cancelled` |
| `UNCANCELLATION` | `subscriptions` update | `active` (취소 철회) |
| `BILLING_ISSUE` | `subscriptions` update | `billing_issue` |
| `EXPIRATION` | `subscriptions` update | `expired` |
| `TEST` | 로그만 기록 | - |

- 모든 이벤트 결과(성공/실패)를 `chat_error_logs` 테이블에 기록
- `logError` FK 위반 시 `user_id: null`로 자동 재시도 (테스트 이벤트 등 미등록 유저 대응)
- 인증: `REVENUECAT_WEBHOOK_SECRET` 환경변수로 Bearer 토큰 검증

### subscriptions 테이블 스키마

```sql
CREATE TABLE public.subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id text NOT NULL,        -- sadam_day_pass / sadam_week_pass / sadam_monthly
  platform text NOT NULL DEFAULT 'android',  -- android / ios
  status text NOT NULL DEFAULT 'active',     -- active / cancelled / expired / billing_issue
  original_transaction_id text,
  starts_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  is_lifetime boolean NOT NULL DEFAULT false,
  cancelled_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, product_id)
);
-- RLS: SELECT만 자기 자신 (service_role은 bypass)
-- Index: (user_id, status)
```

### ai-gemini quota 체크 로직 (line ~104)

```typescript
// premium 구독 확인: day_pass/week_pass/monthly 중 active가 있으면 quota 면제
const { data: subs } = await supabase
  .from("subscriptions")
  .select("id")
  .eq("user_id", userId)
  .eq("status", "active")
  .in("product_id", ["sadam_day_pass", "sadam_week_pass", "sadam_monthly"])
  .limit(1);
```

### Webhook URL & 인증

| 항목 | 값 |
|------|-----|
| Webhook URL | `https://kfciluyxkomskyxjaeat.supabase.co/functions/v1/purchase-webhook` |
| Authorization | `Bearer {REVENUECAT_WEBHOOK_SECRET}` |
| RevenueCat Webhook ID | `whintgr7006704ac6` |
| Environment | Both Production and Sandbox |
| Events | All events, All apps |

---

## 테스트 방법

### 프리미엄 구매 테스트 (Android Sandbox)

1. **라이선스 테스터 계정으로 로그인** (Google Play Console에 등록된 CGXR 이메일 14명 중 하나)
2. 설정 → 구독 관리 → "프리미엄 이용권" 탭 → PaywallScreen
3. 상품 선택 → Google Play 결제 (테스터 계정은 실제 과금 안 됨)
4. 구매 완료 확인:
   - 배너 광고 즉시 사라짐
   - 하단 탭 "상담소" 클릭 시 전면광고 안 나옴
   - 운세 카테고리 클릭 시 전면광고 안 나옴
   - 설정 → 구독 관리에 "이용중" 뱃지 표시

### 프리미엄 해제/되돌리기 (테스트 후 원래대로)

**방법 1: RevenueCat Dashboard (권장)**
1. RevenueCat Dashboard > Customers > 유저 검색 (app_user_id = Supabase auth UUID)
2. 해당 Customer의 Active Entitlements 확인
3. "Revoke" 클릭 → premium entitlement 즉시 해제
4. 앱에서 `PurchaseNotifier.refresh()` 호출 또는 앱 재시작

**방법 2: Google Play 테스트 구독 관리**
- 테스트 구독은 5분 갱신 주기 → 취소하면 빠르게 만료됨
- Google Play > 구독 탭 > 해당 구독 취소

**방법 3: Supabase DB 직접 조작 (서버 측만)**
```sql
-- 특정 유저의 구독 상태를 expired로 변경
UPDATE subscriptions SET status = 'expired', updated_at = now()
WHERE user_id = '유저UUID';

-- 또는 완전 삭제
DELETE FROM subscriptions WHERE user_id = '유저UUID';

-- 전체 테스트 데이터 초기화
DELETE FROM subscriptions;
```
> 주의: DB 조작은 서버 측(ai-gemini quota)만 영향. 앱의 프리미엄 체크는 RevenueCat SDK 기준이므로 앱에서는 변화 없음.

**방법 4: 테스트용 구독 강제 추가 (서버 측만)**
```sql
-- 프리미엄 구독 강제 추가 (서버 quota 테스트용)
INSERT INTO subscriptions (user_id, product_id, platform, status, starts_at, expires_at)
VALUES ('유저UUID', 'sadam_day_pass', 'android', 'active', now(), now() + interval '1 day')
ON CONFLICT (user_id, product_id) DO UPDATE SET status = 'active', expires_at = now() + interval '1 day', updated_at = now();
```

### Webhook 테스트
1. RevenueCat Dashboard > Integrations > Webhooks > "Send test event"
2. Response 200 확인
3. DB 확인:
```sql
SELECT id, user_id, error_message, operation, created_at
FROM chat_error_logs
WHERE operation LIKE 'purchase-webhook:%'
ORDER BY created_at DESC LIMIT 5;
```

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-02-02 | 상품 구조 변경: 3종(ad_removal/ai_premium/combo) → 3종(day_pass/week_pass/monthly) 단일 premium entitlement |
| 2026-02-02 | Google Play Console 3개 상품 등록 + 활성화 (177개국 가격) |
| 2026-02-02 | RevenueCat 대시보드 설정 완료 (Products, Entitlement, Offering) |
| 2026-02-02 | Android API 키 코드 반영: `goog_DfwxpejDQNZHDxDNdLVPSWZVDvR` |
| 2026-02-02 | W-8BEN 미국 세금 양식 제출 |
| 2026-02-02 | Service Account Credentials 설정 완료 |
| 2026-02-02 | 라이선스 테스터 등록 완료 (CGXR 14명) |
| 2026-02-02 | purchase-webhook v3 배포 (에러 로깅 + FK fallback + 이벤트 8종) |
| 2026-02-02 | ai-gemini v50 배포 (quota 상품 ID: day_pass/week_pass/monthly) |
| 2026-02-02 | subscriptions 테이블 생성 (RLS + 인덱스 + FK) |
| 2026-02-02 | RevenueCat Webhook 등록 + REVENUECAT_WEBHOOK_SECRET 설정 |
| 2026-02-02 | 테스트 이벤트 검증 완료 (200 OK + chat_error_logs 기록) |
| 2026-02-03 | 설정 화면 "구독 관리" 섹션 + 프리미엄 타일 추가 (settings_screen.dart) |
| 2026-02-03 | BannerAdWidget → ConsumerStatefulWidget 전환 + premium 숨김 |
| 2026-02-03 | MainScaffold → ConsumerWidget 전환 + 전면광고 premium 스킵 |
| 2026-02-03 | fortune_category_list 전면광고 premium 스킵 추가 |
| 2026-02-03 | 토큰 소진 배너: 영상 광고 → 프리미엄 구매 버튼으로 교체 |
