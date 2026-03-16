# AdMob 수익화 구조 개편 v3 (2026-03-08)

## 핵심 변경: 네이티브 클릭 → 토큰 보상 제거 (AdMob 정책 위반 해소)

---

## 변경 파일 요약

| # | 파일 | 변경 내용 |
|---|------|----------|
| 1 | `lib/ad/ad_strategy.dart` | 상수 수정 (토큰 보상 0, 전면 광고 제한) |
| 2 | `lib/features/saju_chat/presentation/providers/conversational_ad_provider.dart` | 네이티브 클릭 → 토큰 지급 삭제, tracking만 유지 |
| 3 | `lib/ad/widgets/native_ad_widget.dart` | 클릭 토큰 제거, 광고 라벨 15px+ |
| 4 | `lib/ad/widgets/card_native_ad_widget.dart` | 클릭 토큰 제거, 광고 라벨 15px+ |
| 5 | `lib/shared/widgets/fortune_category_chip_section.dart` | 보상형 광고 → 전면 광고로 전환 |
| 6 | `lib/features/saju_chat/presentation/widgets/token_depleted_banner.dart` | 전면 광고 5초 → 토큰 20K 충전 |
| 7 | `lib/features/saju_chat/presentation/widgets/conversational_ad_widget.dart` | 네이티브 CTA 제거, 광고 라벨 수정 |
| 8 | `lib/features/saju_chat/presentation/widgets/ad_native_bubble.dart` | "후원자 소개" → "광고" 15px+ |

---

## Step 1: 상수 수정 (`ad_strategy.dart`)

```
depletedRewardTokensNative:  15000 → 0    (네이티브 클릭 보상 제거)
intervalClickRewardTokens:   10000 → 0    (인터벌 클릭 보상 제거)
depletedRewardTokensVideo:       0 → 20000 (전면 광고 후 충전량)
interstitialDailyLimit:       9999 → 15
interstitialCooldownSeconds:     0 → 60
newSessionInterstitialDailyLimit: 9999 → 5
```

## Step 2: 네이티브 클릭 → 토큰 보상 제거 (`conversational_ad_provider.dart`)

- `_onAdClicked()`: `TokenRewardService.grantNativeAdTokens()` 삭제 → tracking만
- `_grantNativeTokensAndUpdateState()`: 메서드 전체 삭제
- `TokenRewardService` import 제거

## Step 3: 네이티브 위젯 클릭 보상 제거

**`native_ad_widget.dart`** (NativeAdWidget + CompactNativeAdWidget):
- `onAdClicked` → `TokenRewardService.grantNativeAdTokens()` 제거
- `rewardTokens: 0`으로 tracking만

**`card_native_ad_widget.dart`**:
- 동일하게 토큰 지급 제거

## Step 4: 운세 칩 해금 — 전면 광고 (`fortune_category_chip_section.dart`)

- `_showRewardedAdAndUnlock()` → `_showInterstitialAndUnlock()` 대체
- `AdService.instance.showInterstitialAd()` 사용
- 전면 광고 실패 시 → 무료 해금 (UX 우선)
- `adEnabled=false` → 무료 해금 (기존: 다이얼로그)
- `_showAdNotReadyDialog()` 삭제
- `_unlockAndExpand()` 공통 헬퍼 추가

## Step 5: 토큰 소진 배너 — 전면 광고 (`token_depleted_banner.dart`)

- 버튼1: "📋 바로 대화 계속하기" → **"▶ 계속하기"** (전면 광고 5초 → 토큰 20K)
- 버튼2: "✨ 광고 없이 이용하기" → **"✨ 프리미엄"**
- `_handleNativeAd()` → `_handleInterstitialAndContinue()` 대체
- 성공: `addBonusTokens(20000)` + `dismissAd()`
- 실패: `addBonusTokens(5000)` + SnackBar 안내 + 재로드
- `chat_provider.dart` import 복원

## Step 6: ConversationalAdWidget 정리 (`conversational_ad_widget.dart`)

- tokenDepleted CTA 제거 (TokenDepletedBanner에서 처리)
- `_handleVideoAdPressed()` 삭제
- `_handleNativeAdPressed()` 삭제
- `secondaryCtaText` (네이티브 CTA) → `null`
- `InlineAdWidget`: "후원자 소개" → "광고" fontSize 15
- `AdTriggerService` import 제거

## Step 7: 광고 라벨 정책 준수

| 파일 | 변경 |
|------|------|
| `ad_native_bubble.dart` | "후원자 소개" → "광고", fontSize 10→15, fontWeight w600 |
| `native_ad_widget.dart` | 광고 라벨 fontSize 10→15 / 9→15, fontWeight w600 |
| `card_native_ad_widget.dart` | 광고 라벨 fontSize 10→15, fontWeight w600 |
| `conversational_ad_widget.dart` (InlineAdWidget) | "후원자 소개" → "광고", fontSize 10→15 |

---

## 듀얼 모드 동작

| 상황 | `adEnabled=false` | `adEnabled=true` |
|------|-------------------|-------------------|
| 운세 칩 탭 | 무료 해금 | 전면 광고 5초 → 해금 (실패 시 무료) |
| 토큰 소진 | 구매 버튼만 | "▶ 계속하기" → 전면 광고 → 20K 충전 |
| 네이티브 클릭 | 미표시 | tracking만 (토큰 0) |
| 채팅 내 네이티브 | 미표시 | 순수 CPM (보상 없음) |

---

## 쿨다운 체계

- `AdStrategy.interstitialCooldownSeconds = 60` — 전면 광고 전략 쿨다운
- `AdSettings.interstitialMinInterval = 30` — AdService 안전장치 (기존)
- 두 레이어가 독립적으로 동작, 충돌 없음

---

## Flutter Analyze 결과

```
1 issue found (pre-existing info-level lint, 변경과 무관)
```
