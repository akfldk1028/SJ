# Purchase Providers

## 개요
Riverpod 3.0 (@riverpod annotation) 기반 구매 상태 관리.

## PurchaseNotifier
- **타입**: `AsyncNotifierProvider<PurchaseNotifier, CustomerInfo>`
- **상태**: RevenueCat `CustomerInfo` (entitlements 포함)
- **초기값**: `Purchases.getCustomerInfo()` 호출

### Entitlement 체크 (getter)
```dart
ref.read(purchaseNotifierProvider.notifier).isAdFree   // ad_free entitlement
ref.read(purchaseNotifierProvider.notifier).isAiPremium // ai_premium entitlement
ref.read(purchaseNotifierProvider.notifier).showAds     // !isAdFree
ref.read(purchaseNotifierProvider.notifier).dailyQuota  // 무제한 or 20000
```

### 액션 (method)
```dart
.purchasePackage(package)  // 구매 실행 → AsyncLoading → AsyncData/AsyncError
.restore()                 // 구매 복원 (Apple 필수)
.refresh()                 // CustomerInfo 새로고침
```

### 사용처
- `conversational_ad_provider.dart` → isAdFree 체크 (광고 스킵)
- `chat_provider.dart` → isAiPremium 체크 (토큰 소진 스킵)
- `paywall_screen.dart` → 구매 UI

## OfferingsProvider
- **타입**: `FutureProvider<Offerings?>`
- RevenueCat에서 설정한 상품 목록 조회
- PaywallScreen에서 사용

## 의존 관계
```
PaywallScreen → purchaseNotifierProvider (구매 상태)
              → offeringsProvider (상품 목록)
ConversationalAdProvider → purchaseNotifierProvider (isAdFree)
ChatProvider → purchaseNotifierProvider (isAiPremium)
```
