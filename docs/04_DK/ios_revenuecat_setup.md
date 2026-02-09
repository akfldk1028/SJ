# iOS RevenueCat 설정 가이드

> **담당**: Mac 유저 (iOS 빌드 담당자)
> **최종 업데이트**: 2026-02

---

## 목차

1. [사전 준비](#1-사전-준비)
2. [App Store Connect 설정](#2-app-store-connect-설정)
3. [RevenueCat 설정](#3-revenuecat-설정)
4. [Flutter 프로젝트 설정](#4-flutter-프로젝트-설정)
5. [테스트](#5-테스트)
6. [트러블슈팅](#6-트러블슈팅)

---

## 1. 사전 준비

### 필요한 계정

| 계정 | 용도 | 비용 |
|------|------|------|
| Apple Developer | App Store 배포 | $99/년 |
| RevenueCat | IAP 관리 | 무료 (월 $2,500 매출까지) |

### 필요한 정보

- Apple Developer Team ID
- App Bundle ID: `com.example.sadam` (실제 값으로 교체)
- App Store Connect App ID

---

## 2. App Store Connect 설정

### 2.1 앱 생성

1. [App Store Connect](https://appstoreconnect.apple.com) 로그인
2. **앱** → **+** → **새로운 앱**
3. 정보 입력:
   - 플랫폼: iOS
   - 이름: 사담
   - 기본 언어: 한국어
   - 번들 ID: `com.example.sadam`
   - SKU: `sadam-ios`

### 2.2 인앱 구매 상품 생성

**앱** → **인앱 구매** → **관리** → **+**

#### 상품 1: 1일 이용권

| 필드 | 값 |
|------|-----|
| 유형 | 비소모성 |
| 참조 이름 | 1일 이용권 |
| 제품 ID | `sadam_day_pass` |
| 가격 | Tier 3 (₩3,900) |

#### 상품 2: 1주일 이용권

| 필드 | 값 |
|------|-----|
| 유형 | 비소모성 |
| 참조 이름 | 1주일 이용권 |
| 제품 ID | `sadam_week_pass` |
| 가격 | Tier 6 (₩6,900) |

#### 상품 3: 월간 구독

| 필드 | 값 |
|------|-----|
| 유형 | 자동 갱신 구독 |
| 참조 이름 | 월간 프리미엄 |
| 제품 ID | `sadam_monthly` |
| 구독 그룹 | 프리미엄 |
| 가격 | Tier 5 (₩8,900/월) |

### 2.3 App Store Connect API 키 생성

1. **사용자 및 액세스** → **키** → **App Store Connect API**
2. **+** 클릭
3. 이름: `RevenueCat`
4. 액세스: **관리자**
5. 키 다운로드 (`.p8` 파일) - **한 번만 다운로드 가능!**
6. 메모:
   - Issuer ID: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
   - Key ID: `XXXXXXXXXX`

### 2.4 Shared Secret 생성

1. **앱** → **인앱 구매** → **관리**
2. 우측 상단 **앱 공유 암호** 클릭
3. **생성** 또는 기존 암호 복사
4. 메모: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

---

## 3. RevenueCat 설정

### 3.1 프로젝트 생성

1. [RevenueCat Dashboard](https://app.revenuecat.com) 로그인
2. **+ New Project** 클릭
3. 프로젝트 이름: `Sadam`

### 3.2 iOS 앱 추가

1. 프로젝트 선택 → **Apps** → **+ New App**
2. 플랫폼: **App Store**
3. 정보 입력:
   - App name: `Sadam iOS`
   - Bundle ID: `com.example.sadam`

### 3.3 App Store Connect 연동

1. **Apps** → **Sadam iOS** → **App Store Connect API**
2. 정보 입력:
   - Issuer ID: (2.3에서 메모한 값)
   - Key ID: (2.3에서 메모한 값)
   - Private Key: (`.p8` 파일 내용 붙여넣기)
3. **Shared Secret**: (2.4에서 메모한 값)
4. **Save** → **Verify credentials**

### 3.4 상품 가져오기

1. **Products** → **+ New**
2. **Import from App Store Connect** 클릭
3. 3개 상품 선택 후 **Import**

### 3.5 Entitlement 생성

1. **Entitlements** → **+ New**
2. Identifier: `premium`
3. **Create**
4. 3개 상품 모두 이 entitlement에 연결:
   - `sadam_day_pass` → `premium`
   - `sadam_week_pass` → `premium`
   - `sadam_monthly` → `premium`

### 3.6 Offering 생성

1. **Offerings** → **+ New**
2. Identifier: `default`
3. **Create**
4. **Packages** → **+ New Package** (3개):

| Identifier | Product |
|------------|---------|
| `$rc_daily` | `sadam_day_pass` |
| `$rc_weekly` | `sadam_week_pass` |
| `$rc_monthly` | `sadam_monthly` |

5. **Current Offering**으로 설정

### 3.7 API 키 복사

1. **Project Settings** → **API Keys**
2. **Public API Key (iOS)** 복사
3. 형식: `appl_xxxxxxxxxxxxxxxxxxxxxxxx`

---

## 4. Flutter 프로젝트 설정

### 4.1 purchase_config.dart 수정

```dart
// frontend/lib/purchase/purchase_config.dart

static const String revenueCatApiKeyIos = 'appl_여기에_키_입력';
```

### 4.2 iOS 프로젝트 설정

#### Info.plist (자동 설정됨)

`ios/Runner/Info.plist`에 이미 설정되어 있음:

```xml
<key>SKAdNetworkItems</key>
<array>
  <dict>
    <key>SKAdNetworkIdentifier</key>
    <string>cstr6suwn9.skadnetwork</string>
  </dict>
</array>
```

#### StoreKit 설정 (테스트용)

1. Xcode에서 `ios/Runner.xcworkspace` 열기
2. **Runner** → **Signing & Capabilities**
3. **+ Capability** → **In-App Purchase** 추가

### 4.3 빌드 & 실행

```bash
cd frontend
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release
```

---

## 5. 테스트

### 5.1 Sandbox 테스터 생성

1. [App Store Connect](https://appstoreconnect.apple.com) → **사용자 및 액세스**
2. **Sandbox** → **테스터** → **+**
3. 테스트용 Apple ID 생성 (실제 이메일 필요)

### 5.2 테스트 방법

1. iOS 기기에서 **설정** → **App Store**
2. **샌드박스 계정**에 테스터 계정 로그인
3. 앱 실행 → 구매 테스트
4. Sandbox에서는 실제 결제 안 됨

### 5.3 RevenueCat 대시보드 확인

1. [RevenueCat Dashboard](https://app.revenuecat.com) → **Customers**
2. 테스트 구매 내역 확인
3. **Events** 탭에서 이벤트 로그 확인

---

## 6. 트러블슈팅

### 상품이 안 보임

```
[offerings] IAP 비활성화 → null 반환
```

**원인**: API 키 미설정 또는 잘못됨

**해결**:
1. `purchase_config.dart`에서 iOS 키 확인
2. RevenueCat 대시보드에서 키 재복사

---

### 구매 실패 - Invalid Product

```
[PurchaseNotifier] PlatformException: invalid_product_identifiers
```

**원인**: App Store Connect 상품 ID와 RevenueCat 상품 ID 불일치

**해결**:
1. App Store Connect에서 상품 ID 확인
2. RevenueCat **Products**에서 동일한 ID인지 확인
3. 상품 상태가 "승인 대기중" 또는 "승인됨"인지 확인

---

### 구매 성공했지만 isPremium = false

```
[PurchaseNotifier] entitlement 미반영이지만 구매 상품 확인됨 → 강제 프리미엄
```

**원인**: RevenueCat Entitlement 매핑 누락

**해결**:
1. RevenueCat **Entitlements** → `premium`
2. 3개 상품이 모두 연결되어 있는지 확인

---

### Sandbox 계정 로그인 안 됨

**원인**: iOS 버전 문제 또는 계정 문제

**해결**:
1. iOS 설정 → App Store → 로그아웃 → 재로그인
2. 새 Sandbox 테스터 생성

---

## 체크리스트

### App Store Connect
- [ ] 앱 생성
- [ ] 인앱 구매 상품 3개 생성 (`sadam_day_pass`, `sadam_week_pass`, `sadam_monthly`)
- [ ] API 키 생성 (`.p8` 파일 보관)
- [ ] Shared Secret 생성

### RevenueCat
- [ ] 프로젝트 생성
- [ ] iOS 앱 추가
- [ ] App Store Connect 연동 & 검증
- [ ] 상품 가져오기
- [ ] Entitlement `premium` 생성 & 상품 연결
- [ ] Offering `default` 생성 & 패키지 추가
- [ ] API 키 복사

### Flutter
- [ ] `purchase_config.dart`에 iOS 키 입력
- [ ] Xcode에서 In-App Purchase capability 추가
- [ ] 빌드 테스트

### 테스트
- [ ] Sandbox 테스터 생성
- [ ] 구매 테스트
- [ ] RevenueCat 대시보드에서 이벤트 확인

---

## 관련 파일

| 파일 | 용도 |
|------|------|
| `lib/purchase/purchase_config.dart` | API 키 설정 |
| `lib/purchase/purchase_service.dart` | SDK 초기화 |
| `lib/purchase/providers/purchase_provider.dart` | 상태 관리 |
| `ios/Runner/Info.plist` | iOS 설정 |

---

## 참고 링크

- [RevenueCat iOS 가이드](https://www.revenuecat.com/docs/getting-started/installation/ios)
- [App Store Connect 인앱 구매 가이드](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/)
- [Sandbox 테스트 가이드](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_with_sandbox)
