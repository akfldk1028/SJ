# Purchase Providers

## 개요
Riverpod 3.0 (`@Riverpod(keepAlive: true)`) 기반 구매 상태 관리.

## PurchaseNotifier
- **타입**: `AsyncNotifierProvider<PurchaseNotifier, CustomerInfo>`
- **상태**: RevenueCat `CustomerInfo` (entitlements 포함)
- **초기값**: `Purchases.getCustomerInfo()` 호출
- **keepAlive**: 앱 전역 유지 (autoDispose 시 구매 상태 소실 방지)

### Premium 체크 (getter)
```dart
ref.read(purchaseNotifierProvider.notifier).isPremium    // 4단계 fallback
ref.read(purchaseNotifierProvider.notifier).expiresAt     // 만료 시각
ref.read(purchaseNotifierProvider.notifier).activePlanName // 현재 플랜명
ref.read(purchaseNotifierProvider.notifier).isExpiringSoon // 24시간 이내 만료
```

### isPremium 4단계 Fallback (v0.1.0)

```
1. Entitlement 체크 (subscription only)
   → sadam_monthly의 premium entitlement isActive

2. Active Subscriptions 체크
   → customerInfo.activeSubscriptions에 sadam_monthly 포함 여부

3. Non-Subscription Transactions 체크 (day_pass/week_pass)
   → purchaseDate + duration으로 만료 시각 직접 계산
   → RevenueCat entitlement은 Consumable 상품에 대해 isActive 영구 true → 사용 불가

4. _forcePremium 플래그
   → ITEM_ALREADY_OWNED 등 예외 상황 대응
```

> **핵심**: day_pass/week_pass는 Consumable 상품이므로 RevenueCat entitlement 만료 추적이 안 됨. `purchaseDate + duration` 직접 계산 필수.

### 액션 (method)
```dart
.purchasePackage(package)  // 구매 실행 → AsyncLoading → AsyncData/AsyncError
.restore()                 // 구매 복원 (Apple 필수)
.refresh()                 // CustomerInfo 새로고침
```

### 사용처
- `conversational_ad_provider.dart` → isPremium 체크 (광고 스킵)
- `chat_provider.dart` → isPremium 체크 (토큰 소진 스킵)
- `paywall_screen.dart` → 구매 UI
- `ad_trigger_service.dart` → isPremium이면 강제 광고 차단

## OfferingsProvider
- **타입**: `FutureProvider<Offerings?>`
- RevenueCat에서 설정한 상품 목록 조회
- PaywallScreen에서 사용

## 의존 관계
```
PaywallScreen → purchaseNotifierProvider (구매 상태)
              → offeringsProvider (상품 목록)
ConversationalAdProvider → purchaseNotifierProvider (isPremium)
ChatProvider → purchaseNotifierProvider (isPremium)
AdTriggerService → purchaseNotifierProvider (isPremium)
```
