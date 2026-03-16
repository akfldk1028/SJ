# Ad Platform Deep Research: Start.io / Liftoff Monetize / Mintegral

**Date**: 2026-03-11
**Target App**: 사담 (com.clickaround.sadam) - AI Fortune Telling Chat App
**Platform**: Android (Flutter)
**Primary Market**: South Korea
**Current Stack**: AdMob + AdFit (Kakao)

---

## Executive Summary

| Platform | 추천 순위 | Integration Ease | Korea eCPM Potential | Native Ads | Flutter Support |
|----------|-----------|-----------------|---------------------|------------|-----------------|
| **Mintegral (via AdMob bidding)** | **1st** | Easy (AdMob adapter) | High | Yes (via AdMob) | Official adapter |
| **Liftoff Monetize (via AdMob bidding)** | **2nd** | Easy (AdMob adapter) | High | Yes (via AdMob) | Official adapter |
| **Start.io (standalone)** | **3rd** | Medium (standalone SDK) | Low-Medium | Yes (standalone) | Official plugin |

**핵심 결론**: Mintegral과 Liftoff Monetize는 AdMob bidding adapter를 통해 기존 AdMob 코드 변경 없이 추가 가능하며, 경쟁 입찰로 eCPM을 높일 수 있다. Start.io는 standalone SDK라 별도 통합이 필요하고 eCPM이 낮아 추천하지 않는다.

---

## 1. Start.io (formerly StartApp)

### A. Interstitial Ads (전면광고)

**지원 여부**: Yes - Full support

**작동 방식**:
- Fullscreen ads: static images, video, rich media
- "Autostitial" (자동 activity 전환 시), "Exit Ads" (앱 종료 시), "Standard Interstitial" (수동 호출)
- On-demand 가능: `loadAd()` 후 원하는 시점에 `showAd()` 호출
- Return Ads (앱 복귀 시 자동 광고) 기본 활성화 -- 반드시 비활성화해야 함

**eCPM (Korea)**:
- Korea 전용 데이터 없음 (Start.io가 Korea 시장에서 강하지 않음)
- US eCPM: Reddit 후기 기준 **$0.5-1.0** (매우 낮음, AdMob 대비 1/10 수준)
- 글로벌 평균: $1-3 (interstitial), 지역에 따라 큰 차이
- **Reddit quote** (r/admob): "connected startapp for a hypercasual thing last summer. got like 0.5-1 ecpm in us but admob/applovin in apodeal mediation stack did better tbh."

**Fill Rate**:
- 글로벌: 높은 편 (Start.io 자체 demand pool)
- Korea: 불확실, Korea 광고주 적어 fill rate 낮을 가능성 높음

**제한사항**:
- Return Ads, Splash Ads가 기본 활성화 -- 유저 경험에 매우 부정적
- 반드시 AndroidManifest.xml에서 비활성화 설정 필요

### B. Native Ads (네이티브 광고)

**지원 여부**: Yes - Flutter SDK에서 native format 지원

**구현 방식**:
- Flutter에서 `StartAppNativeAd` 클래스 사용
- Native Platform View로 렌더링
- `NativeAdPreferences`로 설정 커스터마이즈 가능
- Auto bitmap download 지원

**채팅 인터페이스 인라인 표시**: 기술적으로 가능하나, Flutter의 Platform View 특성상 스크롤 성능 이슈 가능

**클릭 보상 (Incentivized Click) 정책**:
- Start.io Publisher Agreement에 명시: "Publishers will not use, perform, employ, authorize, incentivize or encourage any third party to use any misleading, fraudulent or inappropriate practices"
- **클릭에 대한 직접 보상(토큰 지급)은 정책 위반 가능성 높음**
- Rewarded Video는 지원 (시청 완료 보상은 OK)

**Native Ad Format**:
- Image + title + description + CTA button
- Cover (1200x628) format
- Banner (320x50, 300x250 MREC) format

### C. Flutter / Android SDK

**공식 Flutter Plugin**: `startapp_sdk` v1.0.1
- **pub.dev**: https://pub.dev/packages/startapp_sdk
- **GitHub**: https://github.com/StartApp-SDK/flutter-plugin (6 stars, 3 forks)
- **Published**: ~21 months ago (not recently updated)
- **Likes**: 24
- **Publisher**: start.io (verified)

**지원 포맷**: Native, Rewarded Video, Interstitial, Banner

**통합 복잡도**: Medium
- 별도 App ID 필요 (Start.io Portal에서 발급)
- AndroidManifest.xml에 meta-data 추가 필요
- AdMob과 별도 독립적 SDK -- 기존 코드와 분리 관리 필요

**Flutter 관련 이슈**:
- **"Black Screen" 버그**: Flutter Platform View와 Start.io SDK 간 hybrid composition 실패 사례 보고됨 (2026-02 blog post)
- 원인: Hybrid Composition 실패, Manifest metadata 누락, lifecycle 관리 문제
- 해결 가능하지만 추가 디버깅 시간 소요

**SDK Size**: 정확한 수치 미확인, Google Play SDK Index에 등록된 SDK

### D. Korean Market Support

**Korea 광고 서빙**: 제한적
- Start.io는 전 세계 서비스하지만 Korea 전용 demand가 강하지 않음
- 주로 미국, 인도, 동남아 시장에 집중
- Korea 광고주가 적어 fill rate & eCPM 모두 낮을 것으로 예상

**Korea eCPM 데이터**: 없음 (Korea 시장 리포트에 Start.io가 거의 언급되지 않음)

**한국 개발자 경험 보고**: 발견하지 못함

**결제 방식**:
- PayPal (선호), Wire Transfer, eCheck
- 최소 지급: $50 (일부 국가 $1,030)
- NET 45 (45일 후 지급)
- KRW 직접 결제 여부: 불확실 (PayPal/Wire USD 주로)

### E. Community Feedback

**Trustpilot**:
- start.io: 2.8/5 (3 reviews) -- "Average"
- startapp.com: 2.5/5 (6 reviews) -- "Poor"

**Reddit (r/admob) 주요 피드백**:
- "got like 0.5-1 ecpm in us but admob/applovin in apodeal mediation stack did better tbh" -- very low eCPM
- "Start.io (StartApp formally) Opinion Required" -- 대부분 부정적 의견
- 여러 개발자가 AdMob 대비 eCPM이 현저히 낮다고 보고

**Making Money With Android 포럼**:
- "Super bad CPM - 0.07$?" -- 극도로 낮은 CPM 보고
- "very low eCPM" -- 지속적인 불만
- "They said most of my users don't want to see ads" -- Start.io 측의 불충분한 해명

**FitGap 2026 Review**:
- Pros: Flexible ad formats, Global reach with emerging markets
- Cons: Less brand recognition, Limited advanced analytics, Variable ad quality control

**결론**: 커뮤니티 평판이 좋지 않음. eCPM이 일관되게 낮고, Korea 시장에서의 활용 사례가 거의 없음.

### F. Policy Considerations

- **Incentivized Click**: 명시적으로 금지 ("will not incentivize or encourage")
- **Rewarded Video**: 허용 (공식 지원)
- **Chat Interface 광고**: 특별한 제한 없으나, Return Ads/Splash Ads 자동 활성화에 주의
- **Account Ban 리스크**: 낮음 (AdMob보다 관대한 편)
- **최소 앱 품질 요구사항**: 낮음 (진입 장벽 낮음)

---

## 2. Liftoff Monetize (formerly Vungle)

### A. Interstitial Ads (전면광고)

**지원 여부**: Yes - Full support (bidding + waterfall)

**작동 방식**:
- Fullscreen video, static interstitial, playable ads
- AdMob Mediation을 통해 기존 AdMob interstitial 코드 그대로 사용
- Bidding: 실시간 경매로 가장 높은 가격의 광고 노출
- On-demand 가능 (기존 AdMob loadAd/show 패턴 유지)

**eCPM (Korea)**:
- Korea 전용 데이터는 공개 안 됨
- 글로벌 평균: Video interstitial $5-15 (시장별 차이 큼)
- Korea Android interstitial 시장 평균: ~$11.23 (Q4 2024 데이터)
- Liftoff는 video-heavy이므로 Korea에서 중간~높은 수준 예상

**Fill Rate**:
- 글로벌: 높음 (150,000+ apps의 supply에 접근)
- Korea: AdMob mediation으로 연결되므로 AdMob이 fill 못할 때 보완 역할
- 93% of top 100 apps가 Liftoff 사용 중

**지원 포맷 (AdMob Mediation)**:
- App Open, Banner, Interstitial, Rewarded, Rewarded Interstitial, Native

### B. Native Ads (네이티브 광고)

**지원 여부**: Yes - AdMob Mediation을 통해 native ads 지원

**구현 방식**:
- 기존 AdMob NativeAd 코드 그대로 사용
- Liftoff adapter가 GADMediaView에 video 또는 image를 자동 채움
- **주의**: "The adapter does not provide direct access to the main image asset for its native ads. Instead, the adapter populates the GADMediaView with a video or an image."

**채팅 인터페이스 인라인 표시**:
- 가능 -- AdMob NativeAd 위젯을 그대로 사용하므로, 현재 AdMob 네이티브 구현과 동일한 방식
- 기존 ChatAdWidget에 자동으로 Liftoff 광고가 서빙될 수 있음

**클릭 보상 (Incentivized Click) 정책**:
- Liftoff/Vungle 자체는 incentivized placement을 지원 (rewarded video 등)
- 그러나 **AdMob mediation 경유 시, AdMob 정책이 적용됨**
- AdMob 정책: 네이티브 광고 클릭에 대한 인센티브 제공 금지
- **결론**: 현재 구조(AdFit 클릭 10K 토큰, AdMob 클릭 0)와 동일하게 운영해야 함

**Native Ad Format**:
- Video 또는 Image 기반
- Title, body, CTA, icon 등 표준 native 요소
- Custom rendering 지원

### C. Flutter / Android SDK

**공식 Flutter Adapter**: `gma_mediation_liftoffmonetize`
- **pub.dev**: https://pub.dev/packages/gma_mediation_liftoffmonetize
- **Publisher**: google.dev (Google 공식)
- **Latest Version**: ^1.4.3 (actively maintained)
- **Android adapter**: v7.5.1.0
- **iOS adapter**: v7.5.3.0
- **Tested with**: google_mobile_ads v6.0.0

**통합 복잡도**: **Low (매우 쉬움)**
- `pubspec.yaml`에 dependency 추가
- AdMob 대시보드에서 Liftoff Monetize를 bidding partner로 추가
- Liftoff 대시보드에서 App ID, Placement ID 발급
- **앱 코드 변경 불필요** -- 기존 AdMob 코드 그대로 사용

**실제 구현 예시** (pubspec.yaml):
```yaml
dependencies:
  google_mobile_ads: ^6.0.0
  gma_mediation_liftoffmonetize: ^1.4.3
```

**Flutter 관련 이슈**:
- Google 공식 adapter이므로 안정성 높음
- 별도 Platform Channel 구현 불필요
- AdMob mediation 설정만으로 자동 동작

**SDK Size**:
- Core Vungle SDK: ~5MB 이하 (lightweight 강조)
- Adapter는 추가 경량
- 전체 APK 영향: 2-5MB 증가 예상

### D. Korean Market Support

**Korea 광고 서빙**: Yes
- Liftoff/Vungle은 글로벌 네트워크로 Korea 포함
- 주요 gaming/brand 광고주 접근 가능
- AdMob mediation 경유 시 Korea demand 자동 매칭

**Korea eCPM 데이터**:
- 직접 공개 데이터 없음
- Korea Android interstitial 시장 평균 $11.23 기준, Liftoff는 $5-12 범위 예상
- Video heavy이므로 video interstitial에서 강세

**한국 개발자 경험**:
- 직접적인 한국 개발자 후기는 발견하지 못함
- AdMob mediation 사용자들은 대체로 긍정적

**결제 방식**:
- Tipalti를 통한 결제 (PayPal, Wire Transfer, eCheck 등)
- 최소 지급: payment method에 따라 다름 (정확한 금액 미공개, 일반적으로 $50-100)
- **NET 60** (60일 후 지급 -- 비교적 느림)
- Mintegral via AdMob bidding인 경우, AdMob이 직접 정산 → Liftoff 별도 결제 불필요

**중요**: AdMob bidding으로 사용하면, **Liftoff에서 별도로 결제 받을 필요 없음**. AdMob이 통합 정산.

### E. Community Feedback

**Reddit (r/admob) "My experience with the various ad-networks for Admob mediation"**:
- "Mostly a pretty tight set. AdMob as the base, then Meta and Liftoff/Vungle for most setups. Unity, InMobi, and Mintegral depending on geo."
- Liftoff/Vungle를 기본 mediation stack에 포함시키는 개발자 다수

**업계 평가**:
- AppsFlyer Performance Index: 상위권 유지
- Supply: 150,000+ apps, top 100의 93%가 사용
- "lag-free rewarded and interstitial video" -- 비디오 광고 품질 인정
- "re-branded Vungle SDK keeps its reputation"

**주요 장점**:
- Video ad quality 업계 최고 수준
- AdMob bidding 지원으로 통합 간편
- 안정적인 대형 플랫폼

**주요 단점**:
- NET 60 결제 (standalone 사용 시)
- 소규모 앱에서는 fill rate 문제 가능
- "CPAs can spike without granular analytics controls"

### F. Policy Considerations

- **Incentivized Engagement**: Rewarded video는 허용, native ad 클릭 인센티브는 AdMob 정책 따름
- **Chat Interface 광고**: 제한 없음 (AdMob mediation이므로 AdMob 정책 준수)
- **Account Ban 리스크**: 낮음 (AdMob mediation 경유 시 별도 Liftoff 계정 필요하나, 밴 리스크 매우 낮음)
- **최소 앱 품질**: 표준적 (Store listing 필요)

---

## 3. Mintegral (via AdMob Bidding)

### A. Interstitial Ads (전면광고)

**지원 여부**: Yes - Full support (bidding + waterfall, AdMob mediation)

**작동 방식**:
- Fullscreen: video, playable, interactive, static image
- AdMob Mediation 통합 -- 기존 코드 변경 없이 bidding 추가
- "New Interstitial Ad Format" -- interactive/playable 지원
- AI 기반 광고 최적화 (Mintegral 강점)

**eCPM (Korea)**:
- Korea 직접 데이터 미공개
- Mintegral은 **AppsFlyer Performance Index 2025에서 Android 2위, iOS 3위** (Gaming Volume Ranking)
- Korea Android interstitial 시장 평균: ~$11.23
- Mintegral은 특히 아시아에서 강세 (본사: 중국 Mobvista, Singapore 오피스)
- **Asia eCPM**: $3-15 (ad format, vertical에 따라)
- Korea에서는 $5-12 범위 예상 (gaming 앱 기준 더 높을 수 있음)

**Fill Rate**:
- 높음 -- 중국 + 글로벌 premium demand 보유
- AdMob bidding으로 다른 네트워크와 경쟁 입찰
- Korea는 아시아 내 high-value 시장으로 fill rate 양호할 것으로 예상

### B. Native Ads (네이티브 광고)

**지원 여부**: Yes - AdMob Mediation을 통해 native ads 지원

**구현 방식**:
- Mintegral 대시보드에서 "Native (Custom Rendering)" AD Format 선택
- 기존 AdMob NativeAd 코드 그대로 사용
- AI 기반으로 engagement 높은 광고 자동 선택

**채팅 인터페이스 인라인 표시**:
- 가능 -- AdMob NativeAd 위젯 동일 사용
- 현재 ChatAdWidget과 완벽 호환
- Mintegral의 AI 최적화로 engagement 높은 광고 서빙

**클릭 보상 (Incentivized Click) 정책**:
- **AdMob mediation 경유 시, AdMob 정책이 적용**
- 네이티브 광고 클릭 인센티브 제공: AdMob 정책상 금지
- Mintegral 자체 정책: Rewarded video에서만 보상 허용
- **결론**: 현재 AdMob과 동일한 정책 (클릭 보상 0)

**Native Ad Format**:
- Image, video, title, description, CTA
- Custom rendering 지원
- AI 기반 creative 최적화

### C. Flutter / Android SDK

**공식 Flutter Adapter**: `gma_mediation_mintegral`
- **pub.dev**: https://pub.dev/packages/gma_mediation_mintegral
- **Publisher**: google.dev (Google 공식)
- **Latest Version**: 적극 유지보수 중 (2025-09 이후 업데이트 확인)
- **Android adapter**: v16.9.91.0
- **iOS adapter**: v7.7.9.0
- **Tested with**: google_mobile_ads v6.0.0
- **Android API**: Level 23+ 필요

**통합 복잡도**: **Low (매우 쉬움)**
- `pubspec.yaml`에 dependency 추가
- AdMob 대시보드에서 Mintegral를 bidding partner로 추가
- Mintegral 대시보드에서 App Key, App ID, Placement ID, Ad Unit ID 발급
- **앱 코드 변경 불필요**

**실제 구현 (pubspec.yaml)**:
```yaml
dependencies:
  google_mobile_ads: ^6.0.0
  gma_mediation_mintegral: ^1.4.0  # bidding 전체 포맷 지원 시
```

**실제 경험 보고** (Medium blog by Juanma Del Boca):
- Mintegral + Meta + Applovin 3개 bidder 추가 후 eCPM $0.94 → $1.14 (21% 증가)
- "only 0.5% of ads were served by the new bidding platforms, but this competition encouraged AdMob to serve higher eCPM ads immediately"
- **핵심**: Bidding network 추가 자체가 AdMob의 eCPM을 높이는 효과

**Flutter 관련 이슈**:
- Google 공식 adapter이므로 안정적
- 별도 코드 변경 불필요 (AdMob mediation 자동 동작)
- Documentation: Google Developer 공식 가이드 존재

**SDK Size**:
- Mintegral Android SDK: ~3-5MB 예상 (adapter 포함)
- Adapter: 경량

### D. Korean Market Support

**Korea 광고 서빙**: **Strong (아시아 강세)**
- Mintegral (Mobvista 자회사)은 중국/아시아 기반으로 아시아 시장에 강함
- Singapore 오피스, 아시아 전역 coverage
- Korea는 아시아 내 high-value 시장으로 premium demand 접근 가능

**Korea eCPM 데이터**:
- 직접 Korea 전용 eCPM 데이터 미공개
- 하지만 아시아 전반에서 높은 성과 보고
- AppsFlyer 2025: Android Gaming Volume 2위
- "higher eCPMs/bid price: Our premium traffic and algorithms enable us to offer higher bids"

**한국 개발자 경험**:
- 직접적인 한국 개발자 후기는 발견하지 못함
- AdMob mediation 경유 사용자들은 긍정적
- Reddit r/admob: "Unity, InMobi, and Mintegral depending on geo" -- geo별로 추가하는 패턴

**결제 방식**:
- **AdMob bidding 경유 시: AdMob이 통합 정산 (별도 Mintegral 결제 불필요)**
- Mintegral 직접 사용 시:
  - 최소 지급: **$1,000** (높은 편!)
  - NET 30
  - Reddit: "If youre using their sdk, you have to meet a certain threshold of revenue before they pay out"
  - 소규모 앱에서는 직접 정산 도달 어려움 → **AdMob bidding 경유가 필수적**

### E. Community Feedback

**Reddit (r/admob)**:
- "Who among you has tried receiving money from Mintegral?" -- 직접 결제 시 $1,000 threshold 우려
- AdMob mediation으로 사용하면 이 문제 해결됨

**업계 평가**:
- **AppsFlyer Performance Index 2025: Android 2위, iOS 3위** (Gaming Volume)
- **Singular ROI Index**: 주요 플랫폼으로 인정
- "leading global mobile ad platform with in-depth understanding of local markets"
- Tenjin Benchmark Report에서 주요 ad network으로 포함

**PublisherGrowth (7 Best Gaming App Monetization Platform)**:
- Mintegral이 5위로 선정
- "developers on Reddit don't hold back... it's about SDK stability, support quality, fill rates across geos"

**주요 장점**:
- 아시아 시장 coverage 강함 (Korea 포함)
- AI 기반 광고 최적화
- AdMob bidding 통합으로 기존 코드 변경 최소
- AppsFlyer 상위권 -- 신뢰할 수 있는 대형 플랫폼

**주요 단점**:
- 직접 결제 시 $1,000 threshold (AdMob bidding 경유 시 해당 없음)
- 과거 "click hijacking" 논란 있었으나 해명 완료
- 소규모 앱에서는 standalone 사용 어려움

### F. Policy Considerations

- **Incentivized Engagement**: AdMob mediation 경유 시 AdMob 정책 적용
- **Chat Interface 광고**: 제한 없음
- **Account Ban 리스크**: 매우 낮음 (대형 플랫폼, AdMob 경유)
- **개인정보**: 설정 시 privacy regulation 관련 설정 필요 (AdMob mediation guide에 포함)

---

## 4. 비교 분석 및 추천

### 4.1 Integration Effort 비교

| 항목 | Start.io | Liftoff Monetize | Mintegral |
|------|----------|-----------------|-----------|
| **통합 방식** | Standalone SDK | AdMob Mediation Adapter | AdMob Mediation Adapter |
| **Flutter Plugin** | `startapp_sdk` v1.0.1 | `gma_mediation_liftoffmonetize` ^1.4.3 | `gma_mediation_mintegral` ^1.4.0+ |
| **Publisher** | start.io | google.dev | google.dev |
| **코드 변경** | 전면 새 코드 필요 | pubspec.yaml만 추가 | pubspec.yaml만 추가 |
| **대시보드 설정** | Start.io Portal | AdMob + Liftoff Dashboard | AdMob + Mintegral Dashboard |
| **유지보수** | 별도 SDK 업데이트 관리 | Google adapter 자동 관리 | Google adapter 자동 관리 |

### 4.2 Revenue Potential 비교

| 항목 | Start.io | Liftoff Monetize | Mintegral |
|------|----------|-----------------|-----------|
| **Korea Interstitial eCPM** | $0.5-2 (낮음) | $5-12 (중~높음) | $5-12 (중~높음) |
| **Bidding Competition** | 없음 (standalone) | AdMob 입찰 경쟁 ↑ | AdMob 입찰 경쟁 ↑ |
| **Native eCPM** | $0.1-1 (낮음) | $1-5 (중간) | $1-5 (중간) |
| **Video 강도** | 보통 | 강함 (Vungle DNA) | 강함 (Interactive) |
| **Asia 강점** | 약함 | 중간 | **강함** |

### 4.3 Payment 비교

| 항목 | Start.io | Liftoff Monetize | Mintegral |
|------|----------|-----------------|-----------|
| **AdMob 경유 정산** | N/A | **Yes (추천)** | **Yes (추천)** |
| **직접 정산 최소** | $50 | $50-100 | **$1,000** |
| **직접 정산 주기** | NET 45 | NET 60 | NET 30 |
| **방법** | PayPal, Wire, eCheck | Tipalti (PayPal, Wire) | PayPal, Wire |

### 4.4 Korea 시장 적합성

| 항목 | Start.io | Liftoff Monetize | Mintegral |
|------|----------|-----------------|-----------|
| **Korea demand** | 약함 | 중간 | **강함 (아시아 기반)** |
| **Korea 광고주** | 적음 | 글로벌 브랜드 | 아시아+글로벌 |
| **현지화** | 없음 | 없음 | 아시아 이해도 높음 |
| **Fill rate (Korea)** | 낮을 것으로 예상 | 중간 | 높을 것으로 예상 |

---

## 5. 사담 앱 적용 추천

### 5.1 즉시 추천: Mintegral + Liftoff (AdMob Bidding)

**이유**:
1. **코드 변경 최소**: pubspec.yaml에 2줄 추가 + AdMob 대시보드 설정만으로 완료
2. **eCPM 향상**: 실제 사례에서 bidding network 추가만으로 21% eCPM 증가 확인
3. **Korea 시장**: Mintegral이 아시아 강세, Liftoff가 글로벌 보완
4. **결제 간편**: AdMob이 통합 정산하므로 별도 결제 관리 불필요
5. **정책 안전**: AdMob mediation이므로 기존 정책 그대로 유지

**구현 단계**:

```yaml
# pubspec.yaml 추가
dependencies:
  gma_mediation_mintegral: ^1.4.0
  gma_mediation_liftoffmonetize: ^1.4.3
```

1. Mintegral 계정 생성 → App Key, App ID, Placement IDs 발급
2. Liftoff Monetize 계정 생성 → App ID, Placement Reference IDs 발급
3. AdMob 대시보드 → Mediation Groups → Bidding에 Mintegral, Liftoff 추가
4. `flutter pub get` → 앱 빌드
5. Ad Inspector로 테스트

### 5.2 Start.io: 추천하지 않음

**이유**:
1. eCPM이 현저히 낮음 ($0.5-1 vs AdMob $11+)
2. Korea 시장에서 demand 부족
3. 별도 SDK 관리 필요 (유지보수 비용)
4. 커뮤니티 평판 나쁨 (Trustpilot 2.5/5)
5. Intrusive ad defaults (Return Ads, Splash Ads)
6. Flutter plugin 업데이트 빈도 낮음 (21개월 전)

### 5.3 Incentivized Ads (토큰 보상) 정리

| 보상 유형 | Start.io | Liftoff (AdMob) | Mintegral (AdMob) |
|----------|----------|-----------------|-------------------|
| **Rewarded Video 시청 → 토큰** | OK | OK | OK |
| **Interstitial 시청 → 토큰** | OK (주의) | OK (현재 구조 유지) | OK (현재 구조 유지) |
| **Native Click → 토큰** | 금지 | AdMob 정책상 금지 | AdMob 정책상 금지 |
| **Native Impression → 추적** | OK | OK | OK |

**현재 사담 앱 구조와의 호환성**:
- 전면 광고(interstitial) 시청 → 14K 토큰: **문제없이 호환** (Mintegral/Liftoff 모두)
- AdFit 네이티브 클릭 → 10K 토큰: AdFit 전용 (CPC 모델이므로 OK)
- AdMob 네이티브 클릭 → 0 토큰: **그대로 유지** (Mintegral/Liftoff 경유해도 동일)

---

## 6. 최종 요약

### DO (추천)
- [x] Mintegral AdMob bidding adapter 추가 (아시아 강세)
- [x] Liftoff Monetize AdMob bidding adapter 추가 (글로벌 보완)
- [x] AdMob 대시보드에서 bidding 설정
- [x] Ad Inspector로 테스트 후 프로덕션 배포

### DO NOT (비추천)
- [ ] Start.io standalone 통합 (낮은 ROI, 높은 유지보수)
- [ ] Mintegral 직접 SDK 사용 (AdMob mediation이 훨씬 효율적)
- [ ] Native ad 클릭 보상 (모든 플랫폼에서 정책 위반)

### 예상 효과
- **eCPM 증가**: 10-20% (bidding 경쟁 효과)
- **Fill Rate 향상**: AdMob 미충족 시 추가 network가 fill
- **구현 시간**: 1-2시간 (pubspec + dashboard 설정)
- **리스크**: 매우 낮음 (Google 공식 adapter)

---

## Sources

### Official Documentation
- [Integrate Mintegral with mediation | Flutter](https://developers.google.com/admob/flutter/mediation/mintegral)
- [Integrate Liftoff Monetize with mediation | Flutter](https://developers.google.com/admob/flutter/mediation/liftoff-monetize)
- [Start.io Flutter Integration](https://support.start.io/hc/en-us/articles/4414596841618-Flutter-Integration)
- [Start.io Flutter Ad Formats](https://support.start.io/hc/en-us/articles/4414615770130-Flutter-Ad-Formats)

### pub.dev Packages
- [startapp_sdk v1.0.1](https://pub.dev/packages/startapp_sdk)
- [gma_mediation_liftoffmonetize](https://pub.dev/packages/gma_mediation_liftoffmonetize)
- [gma_mediation_mintegral](https://pub.dev/packages/gma_mediation_mintegral)

### eCPM & Market Data
- [Mobile Ads eCPM: Basics and Latest Data (MAF)](https://maf.ad/en/blog/mobile-ads-ecpm/) -- Korea Android interstitial $11.23
- [Tenjin Ad Monetization Benchmark Report 2025](https://tenjin.com/blog/ad-mon-gaming-2025/)
- [MonetizeMore eCPM Insights 2024-25](https://www.monetizemore.com/blog/ecpm-insights/)
- [Bidlogic eCPM Growth Q1-Q2 2025](https://bidlogic.io/2025/07/25/ecpm-growth-in-mobile-apps-q1-q2-2025-analysis-and-insights/)

### Community & Reviews
- [Reddit r/admob: StartApp honest feedback](https://www.reddit.com/r/admob/comments/1oqyxac/anyone_here_earning_well_from_startapp_startio/)
- [Reddit r/admob: My experience with ad-networks for Admob mediation](https://www.reddit.com/r/admob/comments/1oy8gjd/my_experience_with_the_various_adnetworks_for/)
- [Reddit r/admob: Mintegral payment](https://www.reddit.com/r/admob/comments/1ewnlqy/who_among_you_has_tried_receiving_money_from/)
- [Trustpilot: Start.io 2.8/5](https://nz.trustpilot.com/review/start.io)
- [Trustpilot: StartApp 2.5/5](https://www.trustpilot.com/review/startapp.com)
- [FitGap: Start.io reviews 2026](https://us.fitgap.com/products/011000/start-io)

### Bidding Experience
- [Flutter AdMob Bidding: How I Boosted My eCPM (Medium)](https://medium.com/@juanmadelboca/flutter-admob-bidding-how-i-boosted-my-ecpm-with-bidding-744142cc8d40)
- [Google AdMob Mediation Updates July 2025](https://ppc.land/google-launches-major-admob-mediation-updates-with-new-bidding-partners/)

### Industry Reports
- [Mintegral AppsFlyer Performance Index 2025](https://www.mintegral.com/en/blog/mintegral-appsflyer-performance-index-2025)
- [TopOn H1 2025 Global Mobile Games Monetization Report](https://mores.toponad.com/reports/TopOn%20Global%20Mobile%20Games%20Monetization%20Report%20_%202025%20H1.pdf)
- [Liftoff Non-Gaming Ad Monetization Trends Report](https://liftoff.cn/blog/maximizing-conversions-and-roi-non-gaming-ad-monetization-trends-report/)

### Payment Info
- [Start.io Payment Details](https://support.start.io/hc/en-us/articles/224850088-Everything-You-Need-to-Know-About-Your-Payment)
- [Liftoff Getting Paid](https://support.vungle.com/hc/en-us/articles/203813080-Getting-Paid-Everything-You-Need-to-Know)
- [Mintegral Billing & Payments](https://www.mintegral.com/en/monetization/guide-billing-payments/)
- [Start.io Publisher Agreement](https://www.start.io/policy/publisher-terms/)
