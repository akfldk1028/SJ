# AdMob 대체 광고 수익화 방안

> **상황**: AdMob 무효 트래픽으로 광고 게재 제한 (최대 30일, 자동 해제 대기)
> **목표**: 제한 기간 동안 수익 공백 최소화

---

## 1. AdMob 제한 현황 정리

- **제한 기간**: 일반적으로 30일 미만, 경우에 따라 더 길어질 수 있음
- **해제 방식**: Google이 자동 모니터링 후 자동 해제 (수동 해제 불가)
- **할 수 있는 것**: 기다리기 + 무효 트래픽 원인 제거
- **원인 추정**: 개발 중 프로덕션 광고 직접 클릭, 또는 테스터 과다 클릭
- **참고**: [AdMob 광고 게재 제한 안내](https://support.google.com/admob/answer/9493252?hl=ko)

### 재발 방지 조치
1. 개발 시 반드시 `AdMode.test` 사용 (`ad_config.dart`)
2. 테스터 기기를 테스트 디바이스로 등록
3. 광고 클릭 유도 문구 제거 (현재 "관심 있는 광고를 살펴보시면 대화가 더 많아져요" → 정책 위반 소지)
4. 앱 내 광고 클릭 빈도 제한 (같은 유저가 단시간 반복 클릭 방지)

---

## 2. 빠르게 적용 가능한 대안 (난이도순)

### A. 쿠팡 파트너스 (WebView 배너) ⭐ 가장 빠름

| 항목 | 내용 |
|------|------|
| **수수료** | 구매 금액의 3~15% (카테고리별 차등) |
| **구현 방식** | WebView로 쿠팡 파트너스 배너/검색 위젯 삽입 |
| **Flutter 연동** | `webview_flutter` 패키지로 배너 URL 로드 |
| **장점** | 가입 즉시 사용 가능, 한국 유저 대상 높은 전환율 |
| **단점** | CPC/CPM이 아닌 CPA (구매 발생 시에만 수익), SDK 없음 |
| **예상 수익** | 월 DAU 1000 기준 5~30만원 (전환율에 따라 큰 차이) |
| **적용 시간** | 1~2시간 |
| **링크** | [쿠팡 파트너스](https://partners.coupang.com/) |

**구현 방법:**
```dart
// 쿠팡 파트너스 배너를 WebView로 표시
WebViewWidget(
  controller: WebViewController()
    ..loadHtmlString('<iframe src="쿠팡_파트너스_배너_URL" .../>'),
)
```

**주의**: 쿠팡 파트너스는 "앱" 채널 승인이 필요. 가입 시 활동 채널에 앱 등록 필수.

---

### B. 카카오 애드핏 (AdFit) ⭐ 한국 특화

| 항목 | 내용 |
|------|------|
| **수익 모델** | CPM + CPC |
| **광고 유형** | 배너, 네이티브, BizBoard |
| **Flutter 패키지** | [`flutter_adfit`](https://pub.dev/packages/flutter_adfit) (비공식) |
| **장점** | 한국 트래픽 최적화, 카카오 광고주 풀, 가입 간편 |
| **단점** | 비공식 Flutter 플러그인 (안정성 리스크), 글로벌 대비 낮은 eCPM |
| **예상 eCPM** | 배너 $0.5~$2, 네이티브 $1~$5 (한국) |
| **적용 시간** | 반나절~1일 |
| **링크** | [카카오 애드핏](https://adfit.kakao.com/info), [가이드](https://adfit.github.io/) |

**구현 방법:**
```yaml
# pubspec.yaml
dependencies:
  flutter_adfit: ^latest
```
```dart
AdFitBanner(adId: 'YOUR_AD_UNIT_ID', adSize: AdFitBannerSize.BANNER)
```

---

### C. Unity Ads ⭐ 보상형 광고 강자

| 항목 | 내용 |
|------|------|
| **수익 모델** | CPM (보상형 영상이 주력) |
| **광고 유형** | 보상형 영상, 전면, 배너 |
| **Flutter 패키지** | [`unity_ads_plugin`](https://pub.dev/packages/unity_ads_plugin) (공식급) |
| **장점** | 높은 보상형 eCPM ($15~$30), 안정적인 Flutter 플러그인 |
| **단점** | 배너/네이티브 약함, 게임 앱 위주 광고주 |
| **예상 eCPM** | 보상형 $15~$30, 전면 $5~$15, 배너 $0.5~$2 |
| **적용 시간** | 반나절~1일 |
| **참고** | 워터폴 미디에이션 2026/01/31 종료, 비딩 전환 필요 |
| **링크** | [Unity Ads Flutter](https://pub.dev/packages/unity_ads_plugin) |

---

### D. AppLovin MAX ⭐⭐ 미디에이션 올인원

| 항목 | 내용 |
|------|------|
| **수익 모델** | CPM (미디에이션으로 여러 네트워크 경쟁) |
| **광고 유형** | 전면, 보상형, 배너, 네이티브, MREC |
| **Flutter 패키지** | [`applovin_max`](https://pub.dev/packages/applovin_max) (공식) |
| **장점** | **미디에이션 내장** → 여러 네트워크 자동 경쟁, 높은 fill rate |
| **단점** | 설정 복잡, AdMob 제한 해제 후에도 병행 운영 권장 |
| **예상 eCPM** | 미디에이션 시 20~40% 수익 증가 효과 |
| **적용 시간** | 1~2일 |
| **링크** | [AppLovin MAX Flutter](https://pub.dev/packages/applovin_max) |

---

### E. Pangle (ByteDance/TikTok) — 아시아 강세

| 항목 | 내용 |
|------|------|
| **수익 모델** | CPM |
| **광고 유형** | 전면, 보상형, 네이티브, 스플래시 |
| **Flutter 패키지** | [`pangle_flutter`](https://pub.dev/packages/pangle_flutter) |
| **장점** | 아시아 시장 높은 eCPM, TikTok 광고주 풀 |
| **단점** | 한국 직접 지원 제한적, 중국 기반 |
| **한국 가용성** | 한국 포함 (Asia Pacific 지역) |
| **적용 시간** | 1~2일 |
| **링크** | [Pangle](https://www.pangleglobal.com/) |

---

### F. Meta Audience Network (Facebook/Instagram)

| 항목 | 내용 |
|------|------|
| **수익 모델** | CPM + CPC |
| **광고 유형** | 배너, 전면, 보상형, 네이티브 |
| **Flutter 연동** | AdMob 미디에이션 또는 AppLovin MAX 미디에이션 통해 연동 |
| **장점** | 페이스북/인스타 광고주 풀, 높은 타겟팅 정확도 |
| **단점** | **단독 사용 불가** (미디에이션 통해서만), ATT 동의 필요 |
| **적용 시간** | 미디에이션 설정 포함 2~3일 |
| **링크** | [gma_mediation_meta](https://pub.dev/documentation/gma_mediation_meta/latest/) |

---

### G. IronSource (LevelPlay) — 미디에이션 특화

| 항목 | 내용 |
|------|------|
| **수익 모델** | CPM (미디에이션) |
| **광고 유형** | 전면, 보상형, 배너, 오퍼월 |
| **Flutter 패키지** | LevelPlay Flutter 플러그인 |
| **장점** | 자동 최적화 알고리즘, 높은 fill rate, 게이밍 강세 |
| **단점** | Unity 합병 후 방향 불투명 |
| **적용 시간** | 1~2일 |
| **링크** | [LevelPlay Flutter](https://docs.unity.com/en-us/grow/levelplay/sdk/flutter/plugin-integration) |

---

## 3. 추천 전략 (우선순위)

### 즉시 (오늘~내일): 수익 공백 최소화

| 순서 | 작업 | 이유 |
|------|------|------|
| 1 | **쿠팡 파트너스 배너** 삽입 | 가입 즉시 가능, WebView로 1~2시간 구현 |
| 2 | **카카오 애드핏** 배너 추가 | 한국 특화, Flutter 패키지 있음 |

### 이번 주: 본격 대체

| 순서 | 작업 | 이유 |
|------|------|------|
| 3 | **Unity Ads** 보상형 연동 | 토큰 소진 시 보상형 광고 대체 |
| 4 | 기존 코드에서 **광고 클릭 유도 문구 제거** | AdMob 재발 방지 |

### 중장기: 미디에이션 도입

| 순서 | 작업 | 이유 |
|------|------|------|
| 5 | **AppLovin MAX** 미디에이션 도입 | AdMob + Unity + Meta + Pangle 동시 경쟁 |
| 6 | AdMob 제한 해제 후 미디에이션에 AdMob 추가 | 수익 20~40% 증가 |

---

## 4. 구현 아키텍처 제안

```
현재:  AdService (AdMob only)
       ├── BannerAd
       ├── InterstitialAd
       ├── RewardedAd
       └── NativeAd

변경:  AdService (추상화)
       ├── AdMobAdapter      (제한 해제 후 복귀)
       ├── KakaoAdFitAdapter  (한국 배너)
       ├── UnityAdsAdapter    (보상형)
       ├── CoupangBanner      (WebView 어필리에이트)
       └── AppLovinMAX        (미디에이션, 중장기)
```

광고 서비스를 추상화해서 네트워크 전환을 쉽게 만들 것.

---

## 5. eCPM 비교표 (한국 시장 추정)

| 네트워크 | 배너 | 전면 | 보상형 | 네이티브 |
|----------|------|------|--------|----------|
| AdMob | $1~$3 | $5~$11 | $15~$30 | $3~$15 |
| 카카오 애드핏 | $0.5~$2 | - | - | $1~$5 |
| Unity Ads | $0.5~$2 | $5~$15 | **$15~$30** | - |
| AppLovin | $1~$3 | $5~$12 | $10~$25 | $3~$10 |
| Pangle | $0.5~$2 | $3~$10 | $8~$20 | $2~$8 |
| 쿠팡 파트너스 | CPA 3~15% | - | - | - |

---

## 6. 핵심 주의사항

1. **AdMob 제한 중에도 AdMob SDK는 유지** — 제한 해제 시 즉시 복귀 가능
2. **광고 클릭 유도 금지** — `chat_ad_factory.dart`의 "관심 있는 광고를 살펴보시면" 문구 제거/수정 필요
3. **테스트 시 반드시 테스트 모드** — `ad_config.dart`에서 `AdMode.test` 확인
4. **미디에이션은 AdMob 해제 후 도입** — AdMob 제한 중 AdMob 미디에이션 사용 불가
5. **쿠팡 파트너스 앱 채널 승인** — 가입 후 앱 URL 등록해야 배너 사용 가능

---

## Sources

- [AdMob 광고 게재 제한](https://support.google.com/admob/answer/9493252?hl=ko)
- [무효 트래픽 방지](https://support.google.com/admob/answer/3342099?hl=ko)
- [Flutter Ad Serving Packages](https://fluttergems.dev/ad-serving/)
- [Top AdMob Alternatives](https://www.metacto.com/blogs/admob-competitors-and-alternatives-in-2024-comprehensive-guide)
- [10 Best AdMob Alternatives with High eCPM](https://publishergrowth.com/blog-details/10-best-admob-alternative-with-high-ecpm)
- [쿠팡 파트너스](https://partners.coupang.com/)
- [카카오 애드핏](https://adfit.kakao.com/info)
- [Unity Ads Flutter Plugin](https://pub.dev/packages/unity_ads_plugin)
- [AppLovin MAX Flutter](https://pub.dev/packages/applovin_max)
- [Pangle Flutter](https://pub.dev/packages/pangle_flutter)
- [Ad Mediation: AdMob and Unity Ads in Flutter 2025](https://johal.in/ad-mediation-admob-and-unity-ads-in-flutter-apps-2025/)
