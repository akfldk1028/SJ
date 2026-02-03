# 만톡 v29 광고 비즈니스 로직 정리

**작성일**: 2026-02-01
**최종 업데이트**: 2026-02-02
**버전**: v29 (v28 + Native Click 추적 수정 + iOS 가드 + AI Summary Lock)

---

## 1. 현재 코드 설정값 (실제 적용 중)

### ad_strategy.dart

| 설정 | 값 | 설명 |
|------|-----|------|
| `inlineAdMessageInterval` | **4** | 4메시지(=2교환)마다 인라인 광고 1회 |
| `inlineAdMaxCount` | **9999** | 세션당 무제한 |
| `inlineAdMinMessages` | **4** | 2교환 후부터 광고 가능 |
| `chatAdType` | `nativeMedium` | 채팅 버블 스타일 Native 광고 |
| `depletedRewardTokensVideo` | **20,000** | 영상 광고 보상 (≈3교환) |
| `depletedRewardTokensNative` | **7,000** | 네이티브 클릭 보상 (≈1교환) |
| `intervalClickRewardTokens` | **7,000** | 인라인 광고 클릭 보상 (모든 Native 공통) |

### ad_trigger_service.dart

| 상수 | 값 | 용도 |
|------|-----|------|
| `impressionRewardTokens` | **0** | 노출만으로는 토큰 미지급 |
| `warningRewardTokens` | **0** | 80% 경고 비활성화 |
| `tokenDepletedThreshold` | 100% | 토큰 소진 임계값 |
| `intervalAd` 트리거 | **비활성화** | 인라인 ChatAdWidget이 대체 |

### DB: user_daily_token_usage

| 컬럼 | 설명 |
|------|------|
| `daily_quota` | 20,000 (매일 리셋) |
| `bonus_tokens` | Rewarded Ad 보상으로 적립 (`add_ad_bonus_tokens` RPC) |
| `rewarded_tokens_earned` | Rewarded Video 시청으로 적립 (`trackRewarded`) |
| `native_tokens_earned` | Native 광고 **클릭** 보상으로 적립 (`add_native_bonus_tokens` RPC) |
| `is_quota_exceeded` | `chatting_tokens >= (daily_quota + bonus_tokens + rewarded_tokens_earned + native_tokens_earned)` |

---

## 2. 광고 흐름 (2가지 경로)

### 경로 A: 인라인 Native 광고 (정적 삽입, `ChatAdWidget`)

채팅 리스트에 정적으로 삽입되는 Native 광고. 대화 중 유일한 광고.

```
메시지 4개(=2교환) 이후
    ↓
ChatMessageList._calculateItemsWithAds()
  → AI 응답 뒤에만 광고 삽입 (유저↔AI 대화쌍 사이 금지)
  → ChatAdWidget 렌더링 (정적, 스크롤 중 자연스럽게 노출)
  → 안내 문구: "관심 있는 광고를 살펴보시면 대화가 더 많아져요"
    ↓
┌─────────────────────────────────────────────┐
│ 노출만: 토큰 0 (eCPM 수익만 발생, 100% 마진)  │
│ 클릭 시: +7,000 토큰                          │
│   → AdTrackingService.trackNativeClick()      │
│   → TokenRewardService.grantNativeAdTokens()  │
│   → add_native_bonus_tokens RPC               │
│   → native_tokens_earned += 7,000             │
└─────────────────────────────────────────────┘
```

**수익 계산:**
- 노출: eCPM $3~7 → 1회 $0.003~0.007 (순수 수익, 토큰 비용 $0)
- 클릭: 토큰 7,000 비용 $0.0105, eCPM $5 기준 수익 $0.005 → 손익분기 근접

### 경로 B: 토큰 소진 - 2버튼 선택 (`TokenDepletedBanner`)

토큰 100% 소진 시 채팅 입력 필드 위에 배너로 표시.

```
chatting_tokens >= daily_quota + bonus_tokens + rewarded_tokens_earned + native_tokens_earned
    ↓
checkAndTrigger() → tokenDepleted
    ↓
TokenDepletedBanner (입력 필드 위에 표시):
┌──────────────────────────────────────────────┐
│  토큰이 소진되었어요! 광고를 보면 대화를        │
│  계속할 수 있어요                              │
│                                              │
│  [🎬 영상 보고 대화 계속하기]  ← 20,000 토큰   │
│  [📋 광고 확인하고 대화 이어가기] ← 7,000 토큰  │
└──────────────────────────────────────────────┘
    ↓ (유저가 영상 선택)
showRewardedAd(rewardTokens: 20,000)
    ↓
15~30초 영상 광고 전체 시청
    ↓
onUserEarnedReward 콜백
  → trackRewarded(rewardAmount: 20,000)
    → rewarded_tokens_earned += 20,000 (DB)
  → onAdWatched(rewardTokens: 20,000)
  → addBonusTokens(20,000) → 채팅 재개
    ↓
≈3교환 추가 채팅 가능
```

```
    ↓ (유저가 네이티브 선택)
switchToNativeAd(rewardTokens: 7,000)
    ↓
AdNativeBubble 표시 (채팅 리스트 끝)
안내: "관심 있는 광고를 살펴보시면 대화를 이어갈 수 있어요"
    ↓
노출만: 토큰 0 (유저는 대화 재개 불가)
클릭 시: +7,000 토큰 → 채팅 자동 재개
```

**수익 계산 (영상):**
- Rewarded eCPM $13~29 (한국): 수입 $0.013~0.029
- 토큰 비용: 20,000 × $0.0000015 = $0.030
- **마진: 손익분기** (eCPM $30 이상이면 흑자, 유저 유지 가치로 정당화)

**수익 계산 (네이티브):**
- 노출만: eCPM $0.003~0.007, 토큰 비용 $0 → **100% 마진**
- 클릭 시: 토큰 7,000 비용 $0.0105
  - eCPM $5: $0.005 - $0.0105 = **-$0.0055 (소폭 적자)**
  - eCPM $10+: $0.010 - $0.0105 = **-$0.0005 (손익분기)**
  - 단, 노출 eCPM 수익이 별도 발생 → 총합 흑자 가능

---

## 3. 순차 흐름 (유저 시점)

```
[앱 시작] daily_quota = 20,000

메시지 1~3 (교환 1~1.5): 광고 없음
    ↓
메시지 4 (교환 2): 첫 인라인 광고 (ChatAdWidget)
  → "관심 있는 광고를 살펴보시면 대화가 더 많아져요"
  → 클릭 시 +7,000 토큰 / 노출만은 0
    ↓
메시지 5~8 (교환 3~4): 메시지 8에서 또 인라인 광고
    ↓
... 계속 4메시지마다 인라인 광고 반복 ...
    ↓
토큰 소진 (chatting_tokens >= effective_quota)
  → 메시지 전송 차단
  → TokenDepletedBanner 표시 (입력 필드 위)
    ↓
[영상 선택] → 시청 완료 → +20,000 토큰 → 대화 재개
[네이티브 선택] → AdNativeBubble 표시
  → "관심 있는 광고를 살펴보시면 대화를 이어갈 수 있어요"
  → 클릭 시 +7,000 토큰 → 대화 재개
    ↓
다시 위로 반복 (무한 루프)
```

### 안내 문구 분기

| 상황 | 문구 | 위치 |
|------|------|------|
| 토큰 있음 (인라인 광고) | "관심 있는 광고를 살펴보시면 대화가 **더 많아져요**" | `chat_ad_factory.dart` |
| 토큰 소진 (네이티브 선택) | "관심 있는 광고를 살펴보시면 대화를 **이어갈 수 있어요**" | `saju_chat_shell.dart` |

---

## 4. v28 변경사항 (2026-02-02)

### 4-1. 청운도사 페르소나 제거

| 항목 | Before (v27) | After (v28) |
|------|-------------|-------------|
| 광고 UI | `ConversationalAdWidget` (청운도사 헤더 + 전환 메시지 + CTA) | `TokenDepletedBanner` (간결한 2버튼) |
| 페르소나 | 청운도사 캐릭터 헤더 + AI 전환 문구 | 없음 (깔끔한 배너) |

### 4-2. 인터벌 광고 제거

| 항목 | Before (v27) | After (v28) |
|------|-------------|-------------|
| 대화 중 광고 | 인터벌 `AdNativeBubble` trailing + 인라인 `ChatAdWidget` (겹침) | **인라인 `ChatAdWidget`만** |
| 인터벌 트리거 | `checkIntervalTrigger()` → `intervalAd` | **비활성화** (`return AdTriggerResult.none`) |
| `AdNativeBubble` 사용처 | 인터벌 + 토큰 소진 | **토큰 소진 시에만** |

### 4-3. 인라인 광고 클릭 시 토큰 보상 추가

| 항목 | Before (v27) | After (v28) |
|------|-------------|-------------|
| 인라인 광고 클릭 | DB 추적만 (`native_clicks += 1`) | DB 추적 + **토큰 7,000 지급** |
| 처리 코드 | `AdTrackingService.trackNativeClick()` | + `TokenRewardService.grantNativeAdTokens(7,000)` |
| 적용 위젯 | - | `NativeAdWidget`, `CompactNativeAdWidget` |

### 4-4. 토큰 보상 정리

| 항목 | v27 | v28 |
|------|-----|-----|
| `impressionRewardTokens` | 1,500 | **0** |
| `depletedRewardTokensVideo` | 35,000 | **20,000** |
| `depletedRewardTokensNative` | 21,000 | **7,000** |
| `intervalClickRewardTokens` | 1,500 | **7,000** |
| `inlineAdMessageInterval` | 2 | **4** |
| `inlineAdMinMessages` | 2 | **4** |

### 4-5. 안내 문구 분기

- 인라인 (토큰 있을 때): "대화가 더 **많아져요**"
- 소진 (토큰 없을 때): "대화를 **이어갈 수 있어요**"

### 4-6. AdWidget 에러 수정

- `AdNativeBubble` → `StatefulWidget`으로 변경, `AdWidget` 인스턴스 캐싱
- 인터벌 광고 비활성화로 "AdWidget is already in the Widget tree" 에러 근본 해결

---

## 5. 서버 추적 흐름 (v29)

```
[Flutter App]                              [Supabase DB]
    │                                           │
    │  채팅 메시지 전송                           │
    ├─── insert_chat RPC ───────────────────────► chatting_tokens += N
    │                                           │ (DB Trigger 자동)
    │                                           │
    │  Native 광고 impression (모든 위젯 공통)     │
    ├─── trackNativeImpression ─────────────────► ad_events INSERT
    │    (토큰 보상 없음, 추적만)                  │ native_impressions += 1
    │                                           │
    │  Native 광고 클릭 (4개 호출부 모두 동일 패턴) │
    │  ① CardNativeAdWidget (메뉴 카드)  ← v29 수정 │
    │  ② NativeAdWidget (채팅 버블)               │
    │  ③ CompactNativeAdWidget (컴팩트)           │
    │  ④ ConversationalAdProvider (대화형)         │
    ├─── trackNativeClick(rewardTokens: 7000) ──► ad_events INSERT (reward_amount: 7000)
    │    │                                      │ native_clicks += 1
    │    │  (native_tokens_earned는 여기서 증가 안 함 — 이중 카운팅 방지)
    │    │                                      │
    ├─── grantNativeAdTokens(7,000) ────────────► native_tokens_earned += 7,000
    │    (add_native_bonus_tokens RPC)           │ ads_watched += 1
    │                                           │
    │  토큰 소진 → 영상 선택 → 시청 완료           │
    ├─── trackRewarded(20,000) ─────────────────► rewarded_tokens_earned += 20,000
    │                                           │ rewarded_completes += 1
    │                                           │
    │  is_quota_exceeded 체크                     │
    │  (GENERATED 컬럼, 실시간 계산)               │
    │  chatting_tokens >= daily_quota             │
    │                   + bonus_tokens            │
    │                   + rewarded_tokens_earned   │
    │                   + native_tokens_earned     │
```

### 이중 카운팅 방지 원칙 (v29)

| DB 컬럼 | 증가 경로 | 호출 횟수/클릭 |
|---------|----------|--------------|
| `ad_events` row | `trackNativeClick` → `_trackEvent` | 1 |
| `native_clicks` | `trackNativeClick` → `increment_ad_counter` | 1 |
| `native_tokens_earned` | `grantNativeAdTokens` → `add_native_bonus_tokens` **만** | 1 |
| `ads_watched` | `add_native_bonus_tokens` **만** | 1 |

> `trackNativeClick()`에서 `native_tokens_earned`를 증가시키면 `add_native_bonus_tokens`와 **이중 카운팅** 발생.
> 따라서 `trackNativeClick`은 `native_clicks`만 증가, 토큰은 별도 RPC에서만 처리.

---

## 6. 코드 위치 참조

| 역할 | 파일 |
|------|------|
| 광고 전략 설정 + 토큰 보상 상수 | `ad/ad_strategy.dart` |
| 토큰 트리거 로직 (인터벌 비활성화) | `saju_chat/data/services/ad_trigger_service.dart` |
| 광고 상태 관리 | `saju_chat/presentation/providers/conversational_ad_provider.dart` |
| 채팅 토큰 관리 | `saju_chat/presentation/providers/chat_provider.dart` |
| 토큰 소진 2버튼 배너 | `saju_chat/presentation/widgets/token_depleted_banner.dart` |
| 소진→네이티브 광고 버블 | `saju_chat/presentation/widgets/ad_native_bubble.dart` |
| 인라인 광고 팩토리 + 힌트 | `ad/widgets/chat_ad_factory.dart` |
| 인라인 네이티브 위젯 (클릭 보상) | `ad/widgets/native_ad_widget.dart` |
| **메뉴 카드 네이티브 위젯** (v29 수정) | `ad/widgets/card_native_ad_widget.dart` |
| 토큰 보상 서비스 | `ad/token_reward_service.dart` |
| **광고 추적 서비스** (rewardTokens 추가) | `ad/ad_tracking_service.dart` |
| **광고 ID 설정** (iOS assert 가드) | `ad/ad_config.dart` |
| 채팅 쉘 (배너 + trailing) | `saju_chat/presentation/screens/saju_chat_shell.dart` |
| 인라인 광고 위치 계산 | `saju_chat/presentation/widgets/chat_message_list.dart` |

---

## 7. v29 변경사항 (2026-02-02)

### 7-1. CardNativeAdWidget 토큰 지급 버그 수정

| 항목 | Before | After |
|------|--------|-------|
| 메뉴 카드 광고 클릭 | `trackNativeClick()` 만 → 토큰 0 | + `grantNativeAdTokens(7000)` → 토큰 7,000 |
| `ad_events.reward_amount` | 항상 `null` | `7000` 기록 |

### 7-2. `trackNativeClick()` rewardTokens 파라미터

- 4개 호출부 모두 `rewardTokens: 7000` 전달
- `ad_events` 테이블에 `reward_amount` 기록 (분석 가능)
- `native_tokens_earned` 증가는 `add_native_bonus_tokens` RPC에서만 (이중 카운팅 방지)

### 7-3. `increment_ad_counter` RPC 동기화

- TEXT 버전 + DATE 버전 **모두** `native_tokens_earned` 허용 추가
- DATE 버전에 누락된 `ads_watched`, `bonus_tokens_earned`도 추가

### 7-4. iOS Ad Unit ID assert 가드

- `ad_config.dart`의 `banner/interstitial/rewarded/native` getter
- debug 모드에서 `YOUR_*_IOS_ID` placeholder 사용 시 assert 에러

### 7-5. `_ensureAiSummary()` Completer Lock

- `Completer<AiSummary?>` 패턴으로 진행 중인 Future 재사용
- 빠른 연속 메시지 시 Edge Function 중복 호출 방지
- `clearSession()` 시 리셋

### 7-6. DB 비정상 데이터 원인

| 날짜 | 현상 | 원인 |
|------|------|------|
| 2/1 | 모든 유저 `native_tokens_earned = 0` | CardNativeAdWidget 미지급 버그 |
| 2/2 | 일부 유저 30,000/click | 이전 APK(`62f829c`, 상수 30,000) 사용자 |
| 2/2 | `271121f6` 만 7,000/click | 새 APK(`adfdd7d`, 상수 7,000) 사용자 |

---

**문서 끝**
