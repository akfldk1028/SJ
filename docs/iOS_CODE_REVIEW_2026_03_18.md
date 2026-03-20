# iOS 배포 코드 리뷰 (2026-03-18)

> 작업자: DK (Claude 지원)
> 목적: App Store 재심사 전 iOS 관련 코드 전수 점검

---

## 변경 파일 요약

| 파일 | 변경 내용 | 상태 |
|------|----------|:----:|
| `pubspec.yaml` | `app_tracking_transparency: ^2.0.6` 추가 | ✅ |
| `lib/main.dart` | ATT import + iOS 추적 동의 요청 코드 추가 | ✅ |
| `lib/ad/ad_config.dart` | iOS 광고 단위 ID 5개 placeholder → 실제 ID | ✅ |
| `ios/Runner/Info.plist` | NSUserTrackingUsageDescription + GADApplicationIdentifier iOS ID | ✅ |

---

## 1. AdMob iOS 광고 단위 ID (`ad_config.dart`)

### 변경 전 (placeholder)
```dart
static const String appIdIos = 'YOUR_IOS_APP_ID';
static const String bannerIos = 'YOUR_BANNER_IOS_ID';
static const String interstitialIos = 'YOUR_INTERSTITIAL_IOS_ID';
static const String rewardedIos = 'YOUR_REWARDED_IOS_ID';
static const String nativeIos = 'YOUR_NATIVE_IOS_ID';
```

### 변경 후 (실제 ID)
```dart
static const String appIdIos = 'ca-app-pub-7140787344231420~6791926286';
static const String bannerIos = 'ca-app-pub-7140787344231420/8787534233';
static const String interstitialIos = 'ca-app-pub-7140787344231420/8169554734';
static const String rewardedIos = 'ca-app-pub-7140787344231420/9186288783';
static const String nativeIos = 'ca-app-pub-7140787344231420/1303795883';
```

**검증**: AdMob 대시보드에서 직접 생성한 ID와 일치 확인 ✅

---

## 2. Info.plist 변경

### 추가: ATT (App Tracking Transparency)
```xml
<key>NSUserTrackingUsageDescription</key>
<string>We use your data to provide personalized ads and improve your experience.</string>
```
- iOS 14+ 필수 — AdMob/Unity Ads 사용 시 없으면 광고 수익 감소 + 리젝 가능

### 변경: GADApplicationIdentifier
```xml
<!-- 변경 전: Android와 동일한 ID 사용 (잘못됨) -->
<string>ca-app-pub-7140787344231420~3931921704</string>

<!-- 변경 후: iOS 전용 App ID -->
<string>ca-app-pub-7140787344231420~6791926286</string>
```
- Android ID는 `AndroidManifest.xml`에서 별도 관리 → 충돌 없음 ✅

### 기존 유지: SKAdNetwork 76개
- 이미 2026-03-17에 추가 완료 ✅

---

## 3. ATT 구현 (`main.dart`)

```dart
// iOS ATT (App Tracking Transparency) 요청 — AdMob 초기화 전 필수
if (isMobile && Platform.isIOS) {
  try {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await Future.delayed(const Duration(seconds: 1));
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
    debugPrint('[ATT] status: $status');
  } catch (e) {
    debugPrint('[ATT] 요청 실패: $e');
  }
}
```

**검증 포인트**:
- ✅ AdMob 초기화(`AdService.instance.initialize()`) **전에** 호출
- ✅ `Platform.isIOS` 분기 — Android에 영향 없음
- ✅ `notDetermined`일 때만 요청 (이미 응답한 사용자에게 재요청 안 함)
- ✅ 1초 딜레이 (Apple HIG 권장: 앱 시작 직후 팝업 지양)
- ✅ try-catch로 감싸서 ATT 실패해도 앱 크래시 없음
- ⚠️ 참고: `runApp()` 전에 호출하므로 UI 없이 시스템 다이얼로그 표시. 심사 통과에는 문제없으나, 향후 스플래시/온보딩 후로 이동 고려

---

## 4. Unity Ads iOS 설정

### 코드 (`unity_ads_config.dart`)
```dart
static const String gameIdIos = '6064428';
static const String interstitialIos = 'Interstitial_iOS';
static const String rewardedIos = 'Rewarded_iOS';
```

### Unity 대시보드 확인 결과
| Placement | Dashboard | 코드 | 일치? |
|-----------|-----------|------|:----:|
| Game ID iOS | `6064428` | `6064428` | ✅ |
| Interstitial_iOS | 활성 | `Interstitial_iOS` | ✅ |
| Rewarded_iOS | 활성 | `Rewarded_iOS` | ✅ |
| Banner_iOS | 활성 | (AdMob 미디에이션) | ✅ |

---

## 5. ID 크로스체크 (전체 정합성)

| 서비스 | 위치 | ID | 일치? |
|--------|------|-----|:----:|
| AdMob iOS App ID | Info.plist | `~6791926286` | ✅ |
| AdMob iOS App ID | ad_config.dart | `~6791926286` | ✅ |
| AdMob iOS App ID | AdMob 대시보드 | `6791926286` | ✅ |
| AdMob Android App ID | AndroidManifest.xml | `~3931921704` | ✅ |
| AdMob Android App ID | ad_config.dart | `~3931921704` | ✅ |
| Unity iOS Game ID | unity_ads_config.dart | `6064428` | ✅ |
| Unity iOS Game ID | Unity 대시보드 | `6064428` | ✅ |
| RevenueCat iOS | RevenueCat 대시보드 | `appacfbf8f138` (Valid) | ✅ |

---

## 6. 외부 서비스 iOS 등록 현황

| 서비스 | 등록 | 설정 | 코드 반영 |
|--------|:----:|:----:|:--------:|
| AdMob iOS | ✅ | ✅ 광고 단위 4개 | ✅ |
| Unity Ads iOS | ✅ | ✅ Placement 3개 | ✅ |
| RevenueCat iOS | ✅ | ✅ P8 키 Valid | ✅ (기존) |
| SKAdNetwork | - | ✅ 76개 | ✅ |
| ATT | - | ✅ Info.plist | ✅ main.dart |

---

## 7. 버전 상태

| 항목 | 값 |
|------|-----|
| 현재 pubspec.yaml | `0.1.6+54` |
| 이전 iOS 제출 | `0.1.0` (빌드 `0.0.9`, 빌드번호 `9`) |
| 상태 | **이미 충분히 높음** — 그대로 제출 가능 |

> Apple은 빌드 번호만 이전보다 높으면 됨. 54 > 9 ✅

---

## 8. 남은 작업 (코드 외)

| 작업 | 담당 | 비고 |
|------|------|------|
| `flutter pub get` | 터미널 | ATT 패키지 설치 |
| iOS 실기기 빌드 + 테스트 | 직접 | Xcode → Archive |
| 화면 녹화 (iPhone) | 직접 | 2~5분, 핵심 플로우 |
| App Review Notes 작성 | 영문 | `iOS_APP_STORE_GUIDE.md` 템플릿 참조 |
| S2S URL → App Store Connect | 직접 | RevenueCat 웹훅 URL |
| 새 빌드 App Store Connect 업로드 | Xcode | Archive → Distribute |
| 앱 심사에 회신 + 재제출 | 직접 | App Store Connect |
