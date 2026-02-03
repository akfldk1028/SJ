# RevenueCat + In-App Purchase 연동 가이드

> 최종 업데이트: 2026-02-03
> 담당: DK

---

## 1. 전체 구조 한눈에 보기

```
[Google Play Console]          [RevenueCat Dashboard]           [Flutter App]
 - 상품 3개 등록                - Project: 사담                  - purchases_flutter SDK
 - 라이선스 테스터              - Products 3개                   - purchase_config.dart (API Key)
 - 서비스 계정 JSON             - Entitlement: premium           - purchase_provider.dart (상태관리)
                                - Offerings: default             - paywall_screen.dart (구매 UI)
        │                              │                                │
        └──── Service Account JSON ────►│                                │
                                        │◄──── API Key (goog_xxx) ──────┘
                                        │                                │
        [Google Cloud Console]          │                                │
         - Google Play Developer API ✅  │                                │
         - Cloud Pub/Sub API ✅          │                                │
         - Service Account 생성          │                                │
```

---

## 2. 우리가 사용하는 상품 구조

### 상품 3개 (현재)

| Product ID | 유형 | 가격 | 기간 | 설명 |
|-----------|------|------|------|------|
| `sadam_day_pass` | 비소모성 (One-time) | ₩1,900 | 24시간 | 1일 이용권 |
| `sadam_week_pass` | 비소모성 (One-time) | ₩4,900 | 7일 | 1주일 이용권 |
| `sadam_monthly` | 구독 (Subscription) | ₩8,900/월 | 자동갱신 | 월간 구독 |

### Entitlement 1개

| Entitlement ID | 연결 Products | 의미 |
|---------------|--------------|------|
| `premium` | sadam_day_pass, sadam_week_pass, sadam_monthly | 프리미엄 (광고 제거 + AI 무제한) |

> 이전 계획(ad_removal, ai_premium, combo 3종)에서 **단일 premium 통합**으로 변경함.
> 이유: 상품 구조를 단순화하고 사용자 혼란 방지.

### 프리미엄 혜택

| 혜택 | 무료 | 프리미엄 |
|------|------|---------|
| 광고 | 표시됨 (Native, Interstitial, Rewarded) | **제거** |
| AI 채팅 | daily_quota 20,000 (~3회) | **무제한** (1,000,000,000) |
| PRO 뱃지 | 없음 | **표시** |

---

## 3. 연동에 필요한 계정/서비스 목록

| 서비스 | URL | 용도 |
|--------|-----|------|
| Google Play Console | https://play.google.com/console | 앱 등록, 인앱 상품 등록, 테스터 설정 |
| Google Cloud Console | https://console.cloud.google.com | Service Account 생성, API 활성화 |
| RevenueCat | https://app.revenuecat.com | 구독 관리 플랫폼 (중간 레이어) |

---

## 4. 설정 순서 (Step by Step)

### Step 1: Google Play Console - 상품 등록

**경로**: Play Console > 앱 선택 > 수익 창출 > 제품

#### 1-A. 인앱 상품 등록 (비소모성)

"인앱 상품" 탭 > "상품 만들기"

| 항목 | sadam_day_pass | sadam_week_pass |
|------|---------------|-----------------|
| Product ID | sadam_day_pass | sadam_week_pass |
| 이름 | 1일 이용권 | 1주일 이용권 |
| 설명 | 24시간 프리미엄 이용 | 7일간 프리미엄 이용 |
| 가격 | ₩1,900 | ₩4,900 |
| 상태 | **활성** | **활성** |

#### 1-B. 구독 등록

"구독" 탭 > "구독 만들기"

| 항목 | 값 |
|------|-----|
| Product ID | sadam_monthly |
| 이름 | 월간 구독 |
| 가격 | ₩8,900/월 |
| 기간 | 1개월, 자동 갱신 |
| 상태 | **활성** |

#### 1-C. 라이선스 테스터 등록

**경로**: Play Console > 설정 > 라이선스 테스트

- 테스트할 Gmail 주소 추가 (예: clickaround8@gmail.com)
- 라이선스 응답: "RESPOND_NORMALLY"
- 이 계정으로 구매 시 실제 결제 안 됨

> **주의**: 앱이 최소 **내부 테스트 트랙**에 APK/AAB 업로드되어 있어야 인앱 결제 테스트 가능

---

### Step 2: Google Cloud Console - Service Account 생성

이 단계가 RevenueCat이 Google Play와 통신할 수 있게 해주는 핵심.

#### 2-A. Google Cloud 프로젝트 확인

**URL**: https://console.cloud.google.com

- 프로젝트: `sadam-486214`
- Service Account: `revenuecat@sadam-486214.iam.gserviceaccount.com`

#### 2-B. 필요한 API 활성화 (**매우 중요**)

**경로**: Google Cloud Console > API 및 서비스 > 라이브러리

| API 이름 | 상태 | 용도 |
|---------|------|------|
| Google Play Android Developer API | ✅ 활성 | RevenueCat → Google Play 구매 검증 |
| Cloud Pub/Sub API | ✅ 활성 | 실시간 구매 알림 수신 |

> **2026-02-03 이슈**: Cloud Pub/Sub API가 비활성화 상태여서 RevenueCat에서
> "Credentials need attention" 에러 발생. 활성화 후 "Valid credentials"로 변경됨.

#### 2-C. Service Account JSON Key 생성

1. Google Cloud Console > IAM 및 관리 > 서비스 계정
2. `revenuecat@sadam-486214.iam.gserviceaccount.com` 선택
3. 키 > 키 추가 > 새 키 만들기 > JSON
4. 다운로드된 JSON 파일을 RevenueCat에 업로드

#### 2-D. Play Console에서 서비스 계정 권한 부여

**경로**: Play Console > 설정 > API 액세스

1. "서비스 계정 연결" 에서 위 서비스 계정 연결
2. 권한: **재무 데이터 보기** + **주문 관리** 필요

---

### Step 3: RevenueCat Dashboard 설정

**URL**: https://app.revenuecat.com

#### 3-A. 프로젝트 정보

| 항목 | 값 |
|------|-----|
| Project Name | 사담 (Sadam) |
| Project ID | `8e37c887` |
| App | Android - `com.clickaround.sadam` |
| App ID | `appfbb2d0e00b` |

#### 3-B. API Key 확인

**경로**: RevenueCat > Project > Apps & providers > Android app

| 항목 | 값 |
|------|-----|
| Public API Key | `goog_DfwxpejDQNZHDxDNdLVPSWZVDvR` |

이 키가 Flutter 앱의 `purchase_config.dart`에 들어감.

#### 3-C. Service Account Credentials 업로드

**경로**: RevenueCat > Project > Apps & providers > Android app > Service Account credentials

1. "Upload a new credential" 클릭
2. Step 2-C에서 다운로드한 JSON 파일 업로드
3. 상태가 **"Valid credentials"** 인지 확인

> "Credentials need attention" 이면 → Google Cloud에서 API 활성화 확인 (Step 2-B)

#### 3-D. Products 등록

**경로**: RevenueCat > Project > Product catalog > Products

| Store Product ID | Store |
|-----------------|-------|
| sadam_day_pass | Google Play |
| sadam_week_pass | Google Play |
| sadam_monthly | Google Play |

> "Import Products" 버튼으로 Google Play에서 자동 가져오기 가능

#### 3-E. Entitlements 설정

**경로**: RevenueCat > Project > Product catalog > Entitlements

| Entitlement ID | 연결된 Products |
|---------------|----------------|
| `premium` | sadam_day_pass, sadam_week_pass, sadam_monthly |

**작동 방식**: 사용자가 위 3개 상품 중 어느 것이든 구매하면 `premium` entitlement가 활성화됨.

#### 3-F. Offerings 설정

**경로**: RevenueCat > Project > Product catalog > Offerings

| Offering | 설명 |
|----------|------|
| `default` | 기본 Offering (앱에서 이것만 사용) |

default Offering 안에 3개 Package:

| Package | Product | Type |
|---------|---------|------|
| sadam_day_pass | sadam_day_pass | Custom |
| sadam_week_pass | sadam_week_pass | Custom |
| sadam_monthly | sadam_monthly | Monthly |

---

### Step 4: Flutter 앱 코드

#### 4-A. 패키지 설치

`pubspec.yaml`:
```yaml
dependencies:
  purchases_flutter: ^8.x.x
```

#### 4-B. 코드 파일 구조

```
frontend/lib/purchase/
├── purchase_config.dart        # API Key, 상품ID, Entitlement ID 상수
├── purchase_service.dart       # RevenueCat SDK 초기화 (Singleton)
├── purchase.dart               # barrel export
├── providers/
│   ├── purchase_provider.dart  # Riverpod 상태 관리 (핵심)
│   └── purchase_provider.g.dart
├── widgets/
│   ├── paywall_screen.dart     # 구매 화면 UI
│   ├── premium_badge_widget.dart # PRO 뱃지
│   └── restore_button_widget.dart # 구매 복원 버튼
└── data/
    ├── purchase_data.dart
    ├── mutations/
    │   └── purchase_mutations.dart  # Supabase 구매 기록
    └── queries/
        └── purchase_queries.dart
```

#### 4-C. 핵심 파일 설명

**`purchase_config.dart`** - 상수 정의
```dart
abstract class PurchaseConfig {
  static const String revenueCatApiKeyAndroid = 'goog_DfwxpejDQNZHDxDNdLVPSWZVDvR';
  static const String entitlementPremium = 'premium';
  static const String productDayPass = 'sadam_day_pass';
  static const String productWeekPass = 'sadam_week_pass';
  static const String productMonthly = 'sadam_monthly';
  static const int premiumDailyQuota = 1000000000;  // 무제한
  static const int freeDailyQuota = 20000;
}
```

**`purchase_service.dart`** - SDK 초기화
- main.dart에서 `PurchaseService.instance.initialize()` 호출
- Supabase userId와 RevenueCat userId를 `Purchases.logIn(userId)`로 동기화
- 모바일 전용 (Web에서는 호출 안 함)

**`purchase_provider.dart`** - 상태 관리 (가장 중요)
- `@Riverpod(keepAlive: true)` → 앱 전체 수명 동안 유지
- `isPremium` getter: 3단계 fallback으로 프리미엄 판별
  1. `_forcePremium` 플래그 (ITEM_ALREADY_OWNED 대응)
  2. RevenueCat entitlement 체크
  3. activeSubscriptions 체크 (월간 구독)
  4. nonSubscriptionTransactions 체크 (1일/1주 이용권 - 구매일 + 기간으로 직접 계산)
- `purchasePackage()`: 구매 실행 + ITEM_ALREADY_OWNED 처리
- `restore()`: 구매 복원

**`paywall_screen.dart`** - 구매 화면
- 3개 상품 카드 표시 (1일, 1주, 월간)
- Offerings API로 가격/제목 자동 로드
- 구매 성공 → "프리미엄 적용 완료" 다이얼로그
- 구매 처리 중 → "잠시 후 재시작" 안내

---

## 5. 구매 흐름 (Flow)

### 5-1. 정상 구매 흐름

```
사용자가 Paywall에서 상품 선택
    │
    ▼
[Purchases.purchasePackage(package)]
    │
    ▼
Google Play 결제 다이얼로그 표시
    │
    ▼
결제 완료 → RevenueCat이 Google Play에서 검증
    │
    ▼
CustomerInfo 반환 (entitlements.premium.isActive = true)
    │
    ▼
isPremium = true → 광고 제거 + AI 무제한 + PRO 뱃지
    │
    ▼
Supabase subscriptions 테이블에 기록 (보조)
```

### 5-2. ITEM_ALREADY_OWNED 흐름

```
사용자가 이전에 이미 구매한 상품을 다시 구매 시도
    │
    ▼
PlatformException: productAlreadyPurchasedError
    │
    ▼
_forcePremium = true (메모리 내 강제 프리미엄)
    │
    ▼
restorePurchases() 호출 → RevenueCat에 기록 복원 시도
    │
    ▼
isPremium = true (forcePremium 플래그로)
```

### 5-3. 구매 복원 흐름

```
사용자가 설정 > 구매 복원 클릭
    │
    ▼
[Purchases.restorePurchases()]
    │
    ▼
RevenueCat이 Google Play에서 과거 구매 기록 조회
    │
    ▼
CustomerInfo 반환 → entitlement 활성 여부 확인
    │
    ▼
isPremium 업데이트
```

---

## 6. isPremium 판별 로직 (3단계 fallback)

RevenueCat의 entitlement가 즉시 반영 안 되는 경우가 있어서 3단계 fallback 적용:

```dart
bool get isPremium {
  // 0차: ITEM_ALREADY_OWNED로 Google Play가 확인한 경우
  if (_forcePremium) return true;

  final info = state.valueOrNull;
  if (info == null) return false;

  // 1차: RevenueCat entitlement (정상 케이스)
  if (info.entitlements.all['premium']?.isActive == true) return true;

  // 2차: 활성 구독 직접 체크 (월간 구독)
  if (info.activeSubscriptions.contains('sadam_monthly')) return true;

  // 3차: 비구독 상품 (1일/1주) - 구매일 + 기간으로 직접 계산
  for (final tx in info.nonSubscriptionTransactions) {
    // sadam_day_pass → 24시간, sadam_week_pass → 7일
    // purchaseDate + duration > now 이면 활성
  }

  return false;
}
```

### 왜 3단계가 필요한가?

| 상황 | 1차 (entitlement) | 2차 (subscription) | 3차 (transaction) |
|------|-------------------|-------------------|-------------------|
| 정상 구매 후 | ✅ | - | - |
| entitlement 매핑 안 된 경우 | ❌ | ✅ (구독) | ✅ (비구독) |
| RevenueCat 서버 지연 | ❌ | ✅ | ✅ |
| Credentials 깨졌을 때 | ❌ | ❌ | ❌ → _forcePremium |

---

## 7. 앱에서 isPremium을 사용하는 곳

모든 파일에서 `ref.read(purchaseNotifierProvider.notifier).isPremium`으로 통일:

| 파일 | 용도 |
|------|------|
| `banner_ad_widget.dart` | 프리미엄이면 광고 안 보임 |
| `card_native_ad_widget.dart` | 프리미엄이면 광고 안 보임 |
| `inline_ad_widget.dart` | 프리미엄이면 광고 안 보임 |
| `native_ad_widget.dart` | 프리미엄이면 광고 안 보임 |
| `chat_provider.dart` | 프리미엄이면 AI quota 무제한 |
| `conversational_ad_provider.dart` | 프리미엄이면 대화형 광고 비활성 |
| `fortune_category_chip_section.dart` | 프리미엄이면 운세 잠금 해제 |
| `fortune_monthly_step_section.dart` | 프리미엄이면 월운 잠금 해제 |
| `fortune_monthly_chip_section.dart` | 프리미엄이면 월운 잠금 해제 |
| `fortune_weekly_chip_section.dart` | 프리미엄이면 주간운 잠금 해제 |
| `lifetime_fortune_screen.dart` | 프리미엄이면 평생운 잠금 해제 |
| `settings_screen.dart` | 프리미엄이면 "이용중" 표시 |
| `menu_screen.dart` | 프리미엄이면 PRO 뱃지 표시 |
| `premium_badge_widget.dart` | PRO 뱃지 위젯 |

---

## 8. 트러블슈팅 체크리스트

### "Credentials need attention" (RevenueCat)

| 확인사항 | 해결 |
|---------|------|
| Google Cloud에서 **Google Play Android Developer API** 활성화? | API 라이브러리에서 활성화 |
| Google Cloud에서 **Cloud Pub/Sub API** 활성화? | API 라이브러리에서 활성화 |
| Service Account JSON이 올바른 프로젝트? | `sadam-486214` 프로젝트의 키여야 함 |
| Play Console에서 서비스 계정 권한? | 재무 데이터 + 주문 관리 |

### 구매 후 entitlements가 빈 배열 []

| 원인 | 해결 |
|------|------|
| RevenueCat credentials 깨짐 | 위 "Credentials need attention" 해결 |
| Entitlement에 Product 미연결 | RevenueCat > Entitlements에서 product 연결 |
| 이전 sandbox 구매가 credentials 깨진 상태에서 됨 | 앱에서 "구매 복원" 또는 새로 구매 |

### ITEM_ALREADY_OWNED 에러

- Google Play가 "이미 이 상품 구매했음"이라고 알려주는 것
- 코드에서 `_forcePremium = true` + `restorePurchases()`로 처리됨
- 비소모성 상품(day_pass, week_pass)에서 발생 가능

### Sandbox 테스트 구독 주기

Google Play 테스트 환경에서의 구독 갱신 주기:

| 실제 기간 | 테스트 기간 |
|-----------|-----------|
| 1주일 | 5분 |
| 1개월 | 5분 |
| 3개월 | 10분 |
| 1년 | 30분 |

---

## 9. 현재 상태 (2026-02-03)

### 완료된 것 ✅

| # | 항목 | 상태 |
|---|------|------|
| 1 | Google Play Console: 상품 3개 등록 | ✅ |
| 2 | Google Play Console: 라이선스 테스터 등록 | ✅ |
| 3 | Google Cloud: Service Account 생성 | ✅ |
| 4 | Google Cloud: Google Play Developer API 활성화 | ✅ |
| 5 | Google Cloud: Cloud Pub/Sub API 활성화 | ✅ (2/3 수정) |
| 6 | RevenueCat: 프로젝트 생성 (사담) | ✅ |
| 7 | RevenueCat: Android 앱 등록 | ✅ |
| 8 | RevenueCat: Service Account JSON 업로드 | ✅ Valid |
| 9 | RevenueCat: Products 3개 등록 | ✅ |
| 10 | RevenueCat: Entitlement "premium" 생성 + 연결 | ✅ |
| 11 | RevenueCat: Offerings "default" + Packages 3개 | ✅ |
| 12 | 코드: purchase_config.dart API Key | ✅ |
| 13 | 코드: purchase_provider.dart 3단계 fallback | ✅ |
| 14 | 코드: ITEM_ALREADY_OWNED 처리 | ✅ |
| 15 | 코드: 모든 파일 isPremium 통일 (15개+) | ✅ |
| 16 | 코드: PaywallScreen 디버그 팝업 제거 | ✅ |

### 미완료 / 선택사항 ⬜

| # | 항목 | 상태 | 비고 |
|---|------|------|------|
| 1 | Google developer notifications (Pub/Sub topic) | ⬜ | 실시간 알림용, 핵심 구매에는 불필요 |
| 2 | RevenueCat Webhook → Supabase Edge Function | ⬜ | 서버사이드 구독 관리 (나중에) |
| 3 | _forcePremium 로컬 저장 (Hive) | ⬜ | 앱 재시작 시 초기화됨 |
| 4 | iOS 연동 (App Store Connect) | ⬜ | iOS 출시 시 |
| 5 | 구매 에러 Supabase error 테이블 기록 | ⬜ | 모니터링용 |

---

## 10. 나중에 iOS 추가할 때

1. App Store Connect에서 동일한 3개 상품 등록
2. RevenueCat에 iOS 앱 추가 → `appl_xxx` API Key 발급
3. `purchase_config.dart`의 `revenueCatApiKeyIos` 업데이트
4. Xcode에서 In-App Purchase capability 추가
5. RevenueCat Entitlement에 iOS 상품도 연결

---

## 참고 링크

- [RevenueCat 공식 문서](https://www.revenuecat.com/docs)
- [RevenueCat Flutter SDK](https://www.revenuecat.com/docs/getting-started/installation/flutter)
- [RevenueCat Google Play 설정](https://www.revenuecat.com/docs/getting-started/installation/google-play)
- [Google Play 인앱 상품 만들기](https://support.google.com/googleplay/android-developer/answer/1153481?hl=ko)
- [Google Play 라이선스 테스트](https://support.google.com/googleplay/android-developer/answer/6062777?hl=ko)
- [Google Play Billing 테스트](https://developer.android.com/google/play/billing/test)
