# AdMob 대체 광고 마이그레이션 플랜

> **상황**: AdMob 무효 트래픽으로 광고 게재 제한 (2026-02-10~)
> **핵심 요건**: 네이티브 광고 + onAdClicked 콜백 (클릭 → 토큰 보상 비즈니스 모델)
> **현재 상태**: AppLovin MAX 가입 완료 (승인 대기), IronSource LevelPlay 가입 진행 중

---

## 1. 현재 AdMob 구현 현황

### 파일 구조
```
frontend/lib/ad/
├── ad.dart                    # barrel exports
├── ad_config.dart             # Ad Unit IDs, AdMode (test/production)
├── ad_service.dart            # Singleton: init, load, show (interstitial/rewarded)
├── ad_strategy.dart           # 전략 상수 (간격, 토큰량, 일일 한도)
├── ad_tracking_service.dart   # Supabase ad_events 추적
├── token_reward_service.dart  # 토큰 보상 RPC (add_native_bonus_tokens)
├── feature_unlock_service.dart
├── providers/
│   └── ad_provider.dart       # Riverpod AdController
├── widgets/
│   ├── native_ad_widget.dart      # NativeAdWidget (Medium) + CompactNativeAdWidget (Small)
│   ├── inline_ad_widget.dart      # InlineAdWidget (Banner)
│   ├── banner_ad_widget.dart      # BannerAdWidget
│   ├── card_native_ad_widget.dart # CardNativeAdWidget
│   └── chat_ad_factory.dart       # ChatAdFactory (광고 위젯 팩토리)
└── data/
    └── ...
```

### 핵심 비즈니스 로직: 클릭 → 토큰 보상
```dart
// native_ad_widget.dart (line 88-94)
onAdClicked: (ad) {
  AdTrackingService.instance.trackNativeClick(
    rewardTokens: AdStrategy.intervalClickRewardTokens,  // 10,000 토큰
  );
  TokenRewardService.grantNativeAdTokens(AdStrategy.intervalClickRewardTokens);
}
```

### Ad Unit IDs (Production)
- Banner: `ca-app-pub-7140787344231420/8692228132`
- Native: `ca-app-pub-7140787344231420/4565280863`
- Interstitial: ad_config.dart 참조
- Rewarded: ad_config.dart 참조

---

## 2. 대체 네트워크 비교 (네이티브 + 클릭 콜백 기준)

| 네트워크 | Flutter 네이티브 | onAdClicked | 상태 | 한국 시장 | 추천도 |
|----------|-----------------|-------------|------|----------|--------|
| **AppLovin MAX** | MaxNativeAdView (Manual) | `onAdClickedCallback(MaxAd)` | **정식** | 25+ 네트워크 미디에이션 | ⭐⭐⭐ |
| **IronSource LevelPlay** | LevelPlayNativeAdView | `onAdClicked(nativeAd, adInfo)` | **베타** | AdMob만 확인 | ⭐⭐ |
| 카카오 애드핏 | Platform Channel 필요 | `OnAdClickListener.onAdClicked(View)` | 정식(네이티브SDK) | 한국 특화 | ⭐ |
| 쿠팡 파트너스 | 커스텀 UI + API | onTap 직접 구현 | N/A | CPA 3~15% | ⭐ |
| Unity Ads | 없음 | 배너만 onClick | 정식 | 게임 위주 | ❌ |
| Pangle | 미디에이션 통해 | 간접 | - | 아시아 강세 | ⭐ |

### 결론: **AppLovin MAX 우선, IronSource 병행**

---

## 3. AppLovin MAX 상세

### 계정 상태
- **가입일**: 2026-02-11
- **이메일**: clickaround8@gmail.com
- **상태**: Account disabled (승인 대기)
- **Play Store URL**: https://play.google.com/store/apps/details?id=com.clickaround.sadam
- **다음 단계**: account-approval@applovin.com 에 승인 요청 메일

### Flutter 연동
```yaml
# pubspec.yaml
dependencies:
  applovin_max: ^4.6.1
```

### Android 설정
```gradle
// android/app/build.gradle
dependencies {
    implementation 'com.applovin.mediation:google-adapter:+'  // AdMob
    implementation 'com.applovin.mediation:facebook-adapter:+' // Meta
    implementation 'com.applovin.mediation:bytedance-adapter:+' // Pangle
}
```

### 네이티브 광고 코드 (AppLovin MAX)
```dart
MaxNativeAdView(
  adUnitId: 'YOUR_AD_UNIT_ID',
  controller: _controller,
  listener: NativeAdListener(
    onAdLoadedCallback: (MaxAd ad) {
      setState(() => _isLoaded = true);
    },
    onAdLoadFailedCallback: (String adUnitId, MaxError error) {
      setState(() => _loadFailed = true);
    },
    onAdClickedCallback: (MaxAd ad) {
      // 토큰 보상 (현재 AdMob과 동일 로직)
      TokenRewardService.grantNativeAdTokens(AdStrategy.intervalClickRewardTokens);
      AdTrackingService.instance.trackNativeClick(
        rewardTokens: AdStrategy.intervalClickRewardTokens,
      );
    },
    onAdRevenuePaidCallback: (MaxAd ad) {
      // 수익 추적
    },
  ),
  child: Column(children: [
    MaxNativeAdIconView(width: 40, height: 40),
    MaxNativeAdTitleView(style: TextStyle(fontWeight: FontWeight.bold)),
    MaxNativeAdBodyView(style: TextStyle(fontSize: 12)),
    MaxNativeAdMediaView(),
    MaxNativeAdCallToActionView(),
    MaxNativeAdOptionsView(width: 20, height: 20), // 필수
  ]),
)
```

### 콜백 매핑
| AdMob | AppLovin MAX |
|-------|-------------|
| `onAdLoaded(ad)` | `onAdLoadedCallback(MaxAd)` |
| `onAdFailedToLoad(ad, error)` | `onAdLoadFailedCallback(adUnitId, MaxError)` |
| `onAdClicked(ad)` | `onAdClickedCallback(MaxAd)` |
| `onAdImpression(ad)` | (자동 추적) |
| `onPaidEvent(ad, micros, precision, currency)` | `onAdRevenuePaidCallback(MaxAd)` |

### 미디에이션 네트워크 (한국 시장 우선순위)
1. Google AdMob (Bidding) — 제한 해제 후 최강
2. AppLovin Exchange — 기본 내장
3. Meta Audience Network
4. Pangle (TikTok)
5. Mintegral
6. Moloco (한국 회사)

### 핵심: AdMob 제한은 AdMob 자체 수요만 영향
> "Limited ad serving applies to AdMob Network only and doesn't affect third-party mediation"
> — Google 공식 문서

---

## 4. IronSource LevelPlay 상세

### 계정 상태
- **가입일**: 2026-02-11
- **이메일**: clickaround8@gmail.com (Unity 계정 연동)
- **Unity Organization**: clickaround8 (ID: 14569710318622)
- **상태**: 등록 실패 — Unity API 연동 오류 (`"No valid user-data header found"`, HTTP 400)
- **원인**: IronSource 서버 → Unity API 토큰 전달 실패 (플랫폼 측 문제)
- **다음 단계**: 일반 브라우저에서 직접 재시도, 또는 IronSource 지원팀 문의

### Flutter 연동
```yaml
# pubspec.yaml
dependencies:
  unity_levelplay_mediation: '>=9.0.0 <9.1.0'
```

### 네이티브 광고 코드 (LevelPlay)
```dart
// 1. 광고 생성
_nativeAd = LevelPlayNativeAd.builder()
    .withPlacementName('chat_native')
    .withListener(this)  // implements LevelPlayNativeAdListener
    .build();

// 2. 리스너 구현
@override
void onAdLoaded(LevelPlayNativeAd? nativeAd, IronSourceAdInfo? adInfo) {
  setState(() => _isLoaded = true);
}

@override
void onAdClicked(LevelPlayNativeAd? nativeAd, IronSourceAdInfo? adInfo) {
  // 토큰 보상
  TokenRewardService.grantNativeAdTokens(AdStrategy.intervalClickRewardTokens);
}

// 3. 위젯
LevelPlayNativeAdView(
  height: 350,
  width: double.infinity,
  nativeAd: _nativeAd!,
  templateType: LevelPlayTemplateType.MEDIUM,  // or SMALL
)
```

### 주의사항
- 네이티브 광고 **오픈 베타** (2024.11~)
- 네이티브 수요 네트워크: **AdMob만 확인됨** (다양성 부족)
- `google_mobile_ads` 패키지와 **공존 불가** (의존성 충돌)
- 계정 승인 소요: 수일~1개월+ (불확실)

---

## 5. 카카오 애드핏 (Platform Channel 방식)

### Android SDK
- 최신 버전: **3.21.17**
- 네이티브 광고 **정식 지원**
- `AdFitNativeAdBinder.OnAdClickListener.onAdClicked(View)` — 클릭 콜백 있음

### 구현 방식
- `flutter_adfit` 패키지는 배너만 지원 → **Platform Channel 브릿지 직접 구현 필요**
- Android: `AdFitNativeAdLoader` + `AdFitNativeAdBinder` + PlatformView
- iOS: AdFit iOS SDK + UiKitView
- MethodChannel로 onAdClicked → Flutter 전달

### 예상 공수: 1~2일 (Platform Channel 경험 있으면)

---

## 6. 쿠팡 파트너스 (커스텀 UI 방식)

### 특징
- SDK 없음, REST API로 상품 데이터 조회
- HMAC-SHA256 인증
- CPS 모델 (구매당 3~15%), CPC 아님
- API 호출 제한: **시간당 10회** → 캐시 필수
- API 활성화 조건: 누적 매출 15만원 이상

### 구현 방식
- Supabase Edge Function → 쿠팡 API 프록시 + 캐시
- Flutter: 커스텀 상품 카드 위젯 (onTap에서 클릭 감지)
- url_launcher로 외부 브라우저에서 쿠팡 열기

### 주의: 토큰 보상 비용은 자체 부담 (쿠팡은 구매 시에만 수익)

---

## 7. 마이그레이션 계획 (우선순위)

### Phase 1: 즉시 (지금)
- [x] AppLovin MAX 가입 완료 (승인 대기)
- [ ] IronSource LevelPlay 가입
- [ ] account-approval@applovin.com 승인 요청 메일 발송
- [ ] chat_ad_factory.dart "관심 있는 광고를 살펴보시면" 문구 제거 (AdMob 정책 위반)

### Phase 2: 승인 후 (1~2주 내)
- [ ] 먼저 승인되는 플랫폼으로 코드 전환
- [ ] ad_config.dart 새 Ad Unit ID 등록
- [ ] ad_service.dart 초기화 코드 변경
- [ ] native_ad_widget.dart 리라이트
- [ ] 테스트 광고로 검증

### Phase 3: 최적화 (1개월)
- [ ] 미디에이션 네트워크 추가 (Meta, Pangle, Mintegral)
- [ ] AdMob 제한 해제 후 미디에이션에 AdMob 추가
- [ ] eCPM 모니터링 및 워터폴 최적화

---

## 8. 변경 불필요 파일 (광고 플랫폼 독립적)

| 파일 | 이유 |
|------|------|
| `token_reward_service.dart` | Supabase RPC만 호출, 광고 SDK 무관 |
| `ad_strategy.dart` | 순수 상수값 (토큰량, 간격 등) |
| `ad_tracking_service.dart` | Supabase 이벤트 로깅, 최소 수정 |
| `feature_unlock_service.dart` | 광고 플랫폼 무관 |

---

## 9. eCPM 비교 (한국 시장 추정)

| 네트워크 | 배너 | 전면 | 보상형 | 네이티브 |
|----------|------|------|--------|----------|
| AdMob | $1~3 | $5~11 | $15~30 | $3~15 |
| AppLovin MAX (미디에이션) | $1~3 | $5~12 | $10~25 | $1~5 |
| LevelPlay (미디에이션) | $0.5~2 | $4~10 | $15~29 | $2~8 |
| 카카오 애드핏 | $0.5~2 | - | - | $1~5 |
| 쿠팡 파트너스 | CPA 3~15% | - | - | - |

---

## Sources

- [AppLovin MAX Flutter Docs](https://support.axon.ai/en/max/flutter/ad-formats/native-ads/)
- [applovin_max pub.dev](https://pub.dev/packages/applovin_max)
- [IronSource Flutter Native Ads](https://developers.is.com/ironsource-mobile/flutter/native-ads-integration-for-flutter-2/)
- [unity_levelplay_mediation pub.dev](https://pub.dev/packages/unity_levelplay_mediation)
- [Kakao AdFit Android SDK](https://github.com/adfit/adfit-android-sdk)
- [AdFit Native Ad Guide](https://github.com/adfit/adfit-android-sdk/blob/master/docs/NATIVEAD.md)
- [Coupang Partners API](https://developers.coupangcorp.com/)
- [Google AdMob Ad Serving Limits](https://support.google.com/admob/answer/9493252)
