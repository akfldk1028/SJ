# AdMob 프로덕션 전환 작업 목록

## 현재 상태
- **광고 모드**: `AdMode.test` (가짜 테스트 광고)
- **App ID** (AndroidManifest.xml): `ca-app-pub-7140787344231420~3931921704` (실제 ID 설정됨)
- **광고 단위 ID**: 전부 Google 테스트 ID (`ca-app-pub-3940256099942544/...`)
- **Production ID**: 전부 placeholder (`YOUR_XXX_ID`)

---

## 수정 파일: `lib/ad/ad_config.dart`

### 1단계: AdMob 콘솔에서 광고 단위 생성
AdMob 콘솔(https://admob.google.com)에서 아래 광고 단위를 생성하고 ID를 받아온다:

| 광고 유형 | Android | iOS |
|----------|---------|-----|
| Banner | 필요 | 필요 |
| Interstitial (전면) | 필요 | 필요 |
| Rewarded (보상형) | 필요 | 필요 |

### 2단계: ProductionAdUnitIds 클래스에 실제 ID 입력 (53~69번 줄)
```dart
abstract class ProductionAdUnitIds {
  static const String appIdAndroid = '실제_APP_ID';
  static const String appIdIos = '실제_APP_ID';
  static const String bannerAndroid = '실제_BANNER_ID';
  static const String bannerIos = '실제_BANNER_ID';
  static const String interstitialAndroid = '실제_INTERSTITIAL_ID';
  static const String interstitialIos = '실제_INTERSTITIAL_ID';
  static const String rewardedAndroid = '실제_REWARDED_ID';
  static const String rewardedIos = '실제_REWARDED_ID';
}
```

### 3단계: 광고 모드를 production으로 변경 (15번 줄)
```dart
// 변경 전
const AdMode currentAdMode = AdMode.test;

// 변경 후
const AdMode currentAdMode = AdMode.production;
```

### 4단계: rewardedInterstitial, native, appOpen도 production 분기 추가 (106~122번 줄)
현재 `rewardedInterstitial`, `native`, `appOpen` getter는 test ID만 반환하고 production 분기가 없음. `banner`/`interstitial`/`rewarded`처럼 `currentAdMode` 분기 추가 필요.

---

## 수정 파일: `android/app/src/main/AndroidManifest.xml`
- App ID는 이미 실제 ID 설정됨: `ca-app-pub-7140787344231420~3931921704`
- AD_ID 퍼미션 추가 완료
- **추가 작업 없음**

---

## Google Play Console 추가 작업
- **광고 ID 선언**: 앱 콘텐츠 → 광고 ID → "예, 광고 ID를 사용합니다" 선택

---

## 체크리스트
- [ ] AdMob 콘솔에서 광고 단위 ID 생성 (Banner, Interstitial, Rewarded)
- [ ] `ad_config.dart` ProductionAdUnitIds에 실제 ID 입력
- [ ] `ad_config.dart` rewardedInterstitial/native/appOpen에 production 분기 추가
- [ ] `ad_config.dart` currentAdMode를 `AdMode.production`으로 변경
- [ ] Google Play Console에서 광고 ID 선언 완료
- [ ] 빌드 & 테스트
