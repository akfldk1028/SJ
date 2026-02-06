# iOS In-App Purchase 설정 가이드

> 작성일: 2026-02-06
> 상태: ✅ 설정 완료

---

## 1. App Store Connect 설정

### 1.1 상품 목록

| 상품명 | 제품 ID | 유형 | 가격 (KRW) | 상태 |
|--------|---------|------|------------|------|
| 1일 이용권 | `sadam_day_pass` | 비갱신 구독 | ₩1,100 | ✅ 제출 준비 중 |
| 1주 이용권 | `sadam_week_pass` | 비갱신 구독 | ₩4,900 | ✅ 제출 준비 중 |
| 월간 프리미엄 | `sadam_monthly` | 자동 갱신 구독 | ₩12,900 | ✅ 제출 준비 중 |

### 1.2 현지화 (한국어)

| 상품 | 표시 이름 | 설명 |
|------|-----------|------|
| 1일 이용권 | 1일 프리미엄 | 24시간 동안 광고 제거 및 AI 무제한 이용 |
| 1주 이용권 | 1주 프리미엄 | 7일 동안 광고 제거 및 AI 무제한 이용 |
| 월간 구독 | 월간 프리미엄 | 광고 제거 + AI 무제한 사용 |

### 1.3 사용 가능 여부

- ✅ 모든 상품: 175개국 활성화

### 1.4 심사 제출 전 필요사항

- ⚠️ **심사용 스크린샷**: 각 상품에 스크린샷 추가 필요
- ⚠️ **앱 버전 연결**: 앱 심사 제출 시 IAP 상품 선택 필요

---

## 2. RevenueCat 설정

### 2.1 앱 구성

| 플랫폼 | 앱 이름 | 상태 |
|--------|---------|------|
| Android | 사담 (Sadam) (Play Store) | ✅ 활성 |
| iOS | 사담 (Sadam) (App Store) | ✅ 활성 |

### 2.2 iOS 앱 설정

```
Bundle ID: com.clickaround.sadam
Key ID: KLY86P289Y
Issuer ID: 02b01583-0bb4-4400-9f97-6056f0680604
P8 파일: SubscriptionKey_KLY86P289Y.p8 (백업 필수!)
```

### 2.3 API Keys

| 플랫폼 | API Key |
|--------|---------|
| Android | `goog_DfwxpejDQNZHDxDNdLVPSWZVDvR` |
| iOS | `appl_XVHtNdLmfGXiACGixJipPUkiAmf` |

---

## 3. Flutter 코드 구조

### 3.1 파일 구조

```
frontend/lib/purchase/
├── purchase.dart              # 모듈 exports
├── purchase_config.dart       # API 키 & 상품 ID 설정
├── purchase_service.dart      # RevenueCat 초기화
├── data/
│   ├── purchase_data.dart
│   ├── queries/
│   └── mutations/
├── providers/
│   ├── purchase_provider.dart # Riverpod 상태 관리
│   └── purchase_provider.g.dart
└── widgets/
    ├── paywall_screen.dart    # 구매 화면 UI
    ├── premium_badge_widget.dart
    └── restore_button_widget.dart
```

### 3.2 핵심 설정 (purchase_config.dart)

```dart
abstract class PurchaseConfig {
  // RevenueCat API Keys
  static const String revenueCatApiKeyAndroid = 'goog_DfwxpejDQNZHDxDNdLVPSWZVDvR';
  static const String revenueCatApiKeyIos = 'appl_XVHtNdLmfGXiACGixJipPUkiAmf';

  // Entitlements
  static const String entitlementPremium = 'premium';

  // Product IDs
  static const String productDayPass = 'sadam_day_pass';
  static const String productWeekPass = 'sadam_week_pass';
  static const String productMonthly = 'sadam_monthly';

  // Quota
  static const int premiumDailyQuota = 1000000000; // 무제한
  static const int freeDailyQuota = 20000;
}
```

### 3.3 의존성 (pubspec.yaml)

```yaml
dependencies:
  purchases_flutter: ^9.10.8
```

---

## 4. iOS 빌드 시 필수 작업 (Mac)

### 4.1 Xcode에서 In-App Purchase Capability 추가

```
1. Xcode에서 Runner.xcodeproj 열기
2. 좌측 Navigator에서 Runner 타겟 선택
3. "Signing & Capabilities" 탭 클릭
4. "+ Capability" 버튼 클릭
5. "In-App Purchase" 검색 및 추가
```

> ⚠️ Windows에서는 Xcode를 실행할 수 없어 이 작업은 Mac에서만 가능합니다.

---

## 5. 코드 동작 흐름

### 5.1 초기화 (main.dart)

```dart
await PurchaseService.instance.initialize();
```

### 5.2 프리미엄 체크 로직 (purchase_provider.dart)

```
1. entitlement 'premium' 활성 여부 체크
2. activeSubscriptions에 'sadam_monthly' 포함 여부
3. nonSubscriptionTransactions에서 1일/1주 이용권 만료 시간 계산
4. ITEM_ALREADY_OWNED 에러 시 강제 프리미엄 적용
```

### 5.3 구매 흐름

```
사용자 → PaywallScreen → purchasePackage() → RevenueCat → Store → 결과 처리
```

---

## 6. 테스트 체크리스트

### 6.1 Android (완료)

- [x] 1일 이용권 구매 테스트
- [x] 구매 복원 테스트
- [x] 프리미엄 상태 반영 확인

### 6.2 iOS (Mac 필요)

- [ ] Xcode에서 Capability 추가
- [ ] Sandbox 테스터 계정 설정
- [ ] 각 상품 구매 테스트
- [ ] 구매 복원 테스트
- [ ] 구독 취소/갱신 테스트

---

## 7. 문제 해결

### 7.1 "상품 정보를 불러올 수 없습니다"

- RevenueCat 대시보드에서 Offerings 설정 확인
- API 키가 올바른지 확인
- 상품 ID가 스토어와 일치하는지 확인

### 7.2 "구매는 됐지만 프리미엄 미반영"

- RevenueCat 대시보드에서 Entitlements 매핑 확인
- `premium` entitlement에 모든 상품이 연결되어 있는지 확인

### 7.3 iOS에서 "Unable to purchase"

- Xcode에서 In-App Purchase Capability 추가 확인
- Sandbox 테스터 계정으로 로그인 확인

---

## 8. 백업 파일

| 파일 | 위치 | 용도 |
|------|------|------|
| SubscriptionKey_KLY86P289Y.p8 | `C:\Users\SOGANG1\Downloads\` | App Store Server API 인증 |

> ⚠️ P8 키는 **한 번만 다운로드 가능**합니다. 분실 시 새로 생성해야 합니다.

---

## 9. 관련 링크

- [App Store Connect](https://appstoreconnect.apple.com/)
- [RevenueCat Dashboard](https://app.revenuecat.com/)
- [RevenueCat iOS 문서](https://www.revenuecat.com/docs/ios-products)
- [StoreKit 2 가이드](https://developer.apple.com/storekit/)
