# 광고 + 토큰 유저 플로우

> 만톡 AI 사주 챗봇의 광고 수익화 및 토큰 시스템 전체 흐름
> 마지막 업데이트: 2026-02-02

---

## 1. 토큰 시스템 개요

### 일일 토큰
- **일일 무료 quota**: 20,000 토큰 (모든 유저 동일)
- **리셋 시점**: 매일 **한국시간(KST) 자정 00:00** (Edge Function에서 `Asia/Seoul` 기준 날짜 사용)
- **리셋 방식**: 별도 cron 없음. 새 날짜에 첫 메시지 → `user_daily_token_usage` 테이블에 새 레코드 자동 생성 (`chatting_tokens=0`, `daily_quota=20000`)

### 토큰 소비량 (실측 평균)
- **1교환** (유저 메시지 + AI 응답) ≈ **7,200 토큰**
- 짧은 대화: 2,000~4,000 / 교환
- 일반 대화: 6,000~9,000 / 교환
- 긴 대화: 10,000~13,000 / 교환 (컨텍스트 누적)

### Quota 공식
```
is_quota_exceeded = chatting_tokens >= (daily_quota + bonus_tokens + rewarded_tokens_earned + native_tokens_earned)
```

| 컬럼 | 용도 | 누가 기록 |
|------|------|----------|
| `daily_quota` | 일일 무료 할당 (20,000) | Edge Function (레코드 생성 시) |
| `bonus_tokens` | 관리자 수동 지급 | admin RPC |
| `rewarded_tokens_earned` | Rewarded Video 광고 보상 | `trackRewarded()` → `incrementDailyCounter` |
| `native_tokens_earned` | Native 광고 **클릭** 보상 (인라인/인터벌/소진 모두) | `_onAdClicked()` 또는 `TokenRewardService.grantNativeAdTokens()` → `add_native_bonus_tokens` RPC |

### 핵심 원칙: Native 광고는 클릭해야만 토큰 지급
- **노출(impression)**: 토큰 0 → 광고 수익만 발생 (비용 $0)
- **클릭(click)**: 토큰 지급 → CPC 수익이 API 비용보다 훨씬 높음
- 인터벌/소진 모두 동일 규칙

---

## 2. 유저 세션 플로우 (무료 유저)

```
┌─────────────────────────────────────────────────────────────────┐
│  앱 시작 → 채팅 화면 진입                                          │
│  daily_quota = 20,000 (≈ 3교환 가능)                              │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  [Phase A] 무료 대화 구간                                         │
│                                                                 │
│  교환 1: 유저 질문 → AI 응답 (~7,200 토큰 소비)                     │
│  교환 2: 유저 질문 → AI 응답 (~7,200 토큰 소비)                     │
│  교환 3: 유저 질문 → AI 응답 (~7,200 토큰 소비)                     │
│  ── 4메시지 도달 → 인라인/인터벌 Native 광고 ──                    │
│    → 노출만: 토큰 0, 스킵 가능 (CPM 수익만)                        │
│    → 클릭 시: +7,000 토큰 (≈1교환 추가, CPC $0.10~$0.50)          │
│                                                                 │
│  누적: ~21,600 토큰 → quota 초과 → 소진!                          │
│  (인터벌 클릭했으면 50,000까지 가능 → 교환 6~7회)                   │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  [Phase B] 토큰 소진 → 2개 버튼 선택                               │
│                                                                 │
│  AI: "대화가 즐거웠어요! 토큰이 부족해서 잠시 쉬어야 할 것 같아요."     │
│                                                                 │
│  ┌──────────────────────────┐  ┌──────────────────────────┐     │
│  │ ▶ 영상 보고 대화 계속하기   │  │ ☐ 광고 확인하고 대화 이어가기│     │
│  │   (Rewarded Video)        │  │   (Native Ad)             │     │
│  │   +20,000 토큰 (≈3교환)   │  │   +7,000 토큰 (≈1교환)    │     │
│  │   영상 끝까지 시청 필수     │  │   ★ 클릭해야 토큰 지급 ★   │     │
│  └────────────┬─────────────┘  └────────────┬─────────────┘     │
│               │                              │                   │
│               ▼                              ▼                   │
│  [경로 1] Rewarded Video       [경로 2] Native Ad               │
│  - 15~30초 영상 시청 필수       - 광고 클릭 시에만 토큰 지급        │
│  - 끝까지 봐야 보상             - 노출만으로는 토큰 0 (수익만)      │
│  - trackRewarded() 호출        - _onAdClicked() 호출             │
│  - → rewarded_tokens_earned    - → native_tokens_earned          │
│  - +20,000 토큰                - +7,000 토큰                     │
│  - 수익: $0.015~0.030           - 수익: $0.10~0.50 (CPC)          │
│  - 비용: $0.003                - 비용: $0.001                    │
│  - 손익: +$0.012~+$0.027      - 손익: +$0.099~+$0.499           │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  [Phase C] 광고 후 대화 재개                                      │
│                                                                 │
│  "대화 재개 (+N 토큰 획득!)" 버튼 → 대화 계속                       │
│                                                                 │
│  Rewarded Video 선택 시: 3교환 추가 가능 → Phase A로 복귀           │
│  Native Ad 클릭 시: 1교환 추가 → 바로 다시 소진 → Phase B로 복귀    │
│  Native Ad 노출만: 토큰 0 → 즉시 Phase B로 복귀                    │
│                                                                 │
│  ※ Native → 금방 소진 → Rewarded Video 자연 유도 (의도된 설계)      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. 인라인 광고 (대화 중 ChatAdWidget)

채팅 메시지 사이에 정적으로 삽입되는 Native 광고. **대화 중 유일한 광고.**

> ~~인터벌 AdNativeBubble~~ → v28에서 비활성화. 인라인 ChatAdWidget이 대체.

### 삽입 조건
- `messageCount >= 4` (2번째 교환 후부터)
- AI 응답 뒤에만 삽입 (유저↔AI 대화쌍 사이 금지)
- `ChatMessageList._calculateItemsWithAds()`에서 계산

### 토큰 보상 (클릭 시에만)
| 이벤트 | 토큰 | DB 컬럼 |
|--------|------|---------|
| Impression (노출) | **0** (미지급) | - |
| Click (클릭) | **+7,000** | `native_tokens_earned` |

### 안내 문구
- "관심 있는 광고를 살펴보시면 대화가 더 많아져요" (토큰 있을 때)

### 설정값 (`ad_strategy.dart`)
```
inlineAdMessageInterval = 4   (매 2교환마다)
inlineAdMinMessages = 4        (2교환 후 시작)
inlineAdMaxCount = 9999        (세션당 제한 없음)
intervalClickRewardTokens = 7000   (클릭 시 보상)
```

---

## 4. 토큰 소진 광고 (Depleted)

토큰 100% 소진 시 표시. 필수 광고 (스킵 불가).

### Rewarded Video (영상 광고)
| 항목 | 값 |
|------|-----|
| 보상 토큰 | **20,000** (≈3교환) |
| 보상 조건 | 영상 끝까지 시청 |
| DB 컬럼 | `rewarded_tokens_earned` |
| 저장 방식 | `trackRewarded()` → `incrementDailyCounter` |
| AdMob 수익 | eCPM $10~50 → **$0.01~0.05/회** |
| API 비용 | 3교환 × $0.001 = **$0.003** |
| **순이익** | **+$0.007 ~ +$0.047** |

### Native Ad (네이티브 광고)
| 항목 | 값 |
|------|-----|
| 보상 토큰 | **7,000** (≈1교환) |
| 보상 조건 | **클릭 시에만** (노출만으로는 0) |
| DB 컬럼 | `native_tokens_earned` |
| 저장 방식 | `_onAdClicked()` → `_saveNativeBonusToServer()` → `add_native_bonus_tokens` RPC |

| 유저 행동 | 광고 수익 | 토큰 지급 | API 비용 | 순이익 |
|----------|----------|----------|---------|--------|
| 노출만 (클릭 안 함) | $0.003~0.007 (eCPM) | 0 | $0 | **+$0.003~0.007 (100%)** |
| 클릭 (eCPM $5) | $0.005 | 7,000 | $0.0013 | **+$0.0037 (흑자)** |
| 클릭 (높은CTR, eCPM $10+) | $0.010+ | 7,000 | $0.0013 | **+$0.009+ (흑자)** |

---

## 5. 수익성 분석: 최대 지급 가능 토큰

> 출처: [Playwire AdMob Benchmarks](https://www.playwire.com/blog/admob-ecpm-benchmarks-what-publishers-should-expect), [Maf.ad eCPM Data](https://maf.ad/en/blog/mobile-ads-ecpm/), [Business of Apps](https://www.businessofapps.com/ads/research/mobile-app-advertising-cpm-rates/)

### 실제 AdMob 수익 데이터 (한국 = Tier 1 시장)

> **중요**: eCPM은 이미 클릭 수익(CPC)을 포함한 수치. CPC를 별도로 더하면 이중 계산.
> eCPM = (전체 수익 / 전체 노출) × 1000 → CPM 수익 + CPC 수익 모두 포함.

| 광고 유형 | eCPM (Tier 1) | 1회 수익 | 비고 |
|----------|-------------|---------|------|
| **Rewarded Video** | $15~$30 | **$0.015~0.030** | 가장 높음. 영상 완시청 기준 |
| **Native** | $3~$7 | **$0.003~0.007** | 클릭 수익 이미 포함 |
| **Banner** | $0.50~$1.50 | $0.0005~0.0015 | 가장 낮음 |

**핵심: Rewarded Video가 Native보다 3~5배 수익 높음**
**→ 하지만 우리 앱은 CTR이 높아서(클릭 유도) 실제 Native eCPM이 더 올라갈 가능성 있음**
**→ 7,000 토큰은 보수적 설정 (eCPM $5 기준 확실한 흑자)**

### 기본 비용 구조
```
Gemini 3.0 Flash 비용 per 토큰:
  Input:  $0.50 / 1,000,000 tokens = $0.0000005/token
  Output: $3.00 / 1,000,000 tokens = $0.000003/token
  가중 평균 (input 60% + output 40%): ~$0.0000015/token

1교환 (7,200 토큰) 비용: ~$0.011

GPT-5-mini (월운/신년운/회고):
  Input:  $0.25 / 1,000,000 tokens
  Output: $2.00 / 1,000,000 tokens
  1건 평균 비용: ~$0.022

GPT-5.2 (평생운세 saju_base만):
  Input:  $1.75 / 1,000,000 tokens
  Output: $14.00 / 1,000,000 tokens
  Cached: $0.175 / 1,000,000 (90% 할인)
  1건 비용: ~$0.196 (프로필당 1회, 이후 캐시)
```

### 광고 유형별 최대 지급 가능 토큰

#### Native Ad 노출만 (CPM)
```
한국 시장 Native eCPM: $3 ~ $7 (보수적 $3 기준)
1회 노출 수익 = $0.003

손익분기 토큰 = $0.003 / $0.0000015 = ~2,000 토큰 (≈0.3교환)

현재 설정: 0 토큰 (노출만으로는 미지급)
→ 100% 마진
→ ✅ 올바른 설정
```

#### Native Ad (eCPM 기반, 클릭 수익 이미 포함)
```
한국 시장 Native eCPM: $3 ~ $7 (보수적 $3, 중간 $5 기준)
1회 노출 수익 = $0.003 ~ $0.007 (클릭 여부 무관, eCPM에 이미 포함)

※ 우리 앱은 CTR 높음 (클릭 유도 설계) → 실제 eCPM 상승 가능
※ 높은 CTR로 eCPM $10~$20까지 올라갈 수 있음 (실측 필요)

손익분기 토큰 (eCPM $5 기준):
= $0.005 / $0.0000015 = ~3,333 토큰 (≈0.5교환)

현재 설정: 7,000 토큰 (≈1교환, 클릭 시에만)
→ 비용: 7,000 × $0.0000015 = $0.0105
→ eCPM $5 기준: ($0.005 - $0.0105) = -$0.0055 (소폭 적자)
→ eCPM $10 기준: ($0.010 - $0.0105) = -$0.0005 (손익분기)
→ eCPM $15+ (높은 CTR): ($0.015 - $0.0105) = +$0.0045 (흑자)
→ ⚠️ 단독으로는 손익분기 근접, 전면광고+인라인 노출 순수익이 커버
```

#### Rewarded Video
```
한국 시장 Rewarded eCPM: $15 ~ $30 (보수적 $15 기준)
1회 수익 = $0.015

손익분기 토큰 = $0.015 / $0.0000015 = ~10,000 토큰 (≈1.4교환)

현재 설정: 20,000 토큰 (≈3교환)
→ 비용: 20,000 × $0.0000015 = $0.030
→ eCPM $13 (한국 Android 보수적): $0.013 - $0.030 = -$0.017 (적자)
→ eCPM $29 (한국 iOS): $0.029 - $0.030 = -$0.001 (손익분기)
→ ⚠️ 유저 리텐션 투자로 정당화. 전면광고+인라인 수익이 커버
```

### 요약 비교표

| 광고 유형 | 1회 수익 (보수적) | 손익분기 토큰 | 현재 지급 | 단독 손익 |
|----------|-----------------|-------------|----------|------|
| Native 노출만 | $0.003~0.007 (eCPM) | ~3,333 | **0** | **100% 순수익** |
| Native 클릭 | $0.005 (eCPM $5) | ~3,333 | **7,000** | ⚠️ -$0.006 (적자) |
| Native 클릭 (높은 CTR) | $0.010+ (eCPM $10+) | ~6,667 | **7,000** | ≈ 손익분기 |
| Rewarded Video | $0.013~0.029 (eCPM) | ~10,000 | **20,000** | ⚠️ 손익분기 |

> 핵심: Native 클릭과 Rewarded는 단독으로 소폭 적자지만, **전면광고 + 인라인 노출**(비용 $0)이 커버.

### 결론
- **Rewarded Video($0.015~$0.030)가 Native($0.003~$0.007)보다 3~5배 수익 높음**
- **Rewarded Video 20,000 (≈3교환)**: 손익분기 (eCPM $13~29, 비용 $0.030)
- **Native 7,000 (≈1교환)**: 손익분기 근접 (eCPM $5 기준, 비용 $0.0105)
  - 토큰 비용 $0.0013으로 수익 대비 매우 낮음
  - 유저가 클릭하면 1교환 추가, 안 해도 손해 없음
- **Native 노출 0**: 올바른 판단. 노출만으로는 비용 $0 → 순수 수익
- 출시 후 AdMob 대시보드에서 실제 eCPM 확인 → 수익 좋으면 토큰 상향 검토 가능

---

## 6. 수익 시뮬레이션: 일반 유저 1일 세션

### 시나리오: 10교환 대화 (약 20분)

```
[무료] 교환 1~3: ~21,600 토큰 소비
  ── 6메시지 도달 → 인터벌 Native 1회 ──
  → 노출만: eCPM 수익 $0.003~0.007, 토큰 0
  → 클릭 시: +7,000 토큰 (eCPM 수익은 노출과 동일)

  누적 ~21,600 → quota 소진!

[소진] Native 클릭 → +7,000 토큰
  교환 4: ~7,200 토큰 소비 → 소진!

[소진] Rewarded Video → +20,000 토큰 ($0.015~0.030 수익)
  교환 8~10: ~21,600 토큰 소비
  ── 인터벌 Native 1회 (6메시지 도달 시) ──
  소진!
```

### 보수적 수익 (클릭 0회, 노출만, 기존 유저)

| 항목 | 값 |
|------|-----|
| GPT/운세 분석 (캐시, 기존 유저) | $0 |
| Gemini 채팅 비용 (10교환) | -$0.110 |
| 전면광고 × 3 ($0.010 each) | +$0.030 |
| Rewarded Video × 2 ($0.013 each) | +$0.026 |
| 인라인 Native 노출 × 3 ($0.003 each) | +$0.009 |
| Rewarded 토큰 비용 (20k×2) | -$0.060 |
| **일일 순이익 (보수적)** | **-$0.105** |

### 낙관적 수익 (전면광고 + Native 클릭 + Rewarded eCPM $25)

| 항목 | 값 |
|------|-----|
| GPT/운세 분석 (캐시, 기존 유저) | $0 |
| Gemini 채팅 비용 (10교환) | -$0.110 |
| 전면광고 × 5 ($0.015 each) | +$0.075 |
| Rewarded Video × 1 ($0.025) | +$0.025 |
| 인라인 Native 노출 × 3 ($0.005 each) | +$0.015 |
| 토큰 비용 (Native 7k×2 + Rewarded 20k×1) | -$0.051 |
| **일일 순이익 (낙관적)** | **-$0.046** |

> Gemini 3.0 Flash 실제 가격 반영 시, 토큰 보상의 API 비용이 이전 추정보다 높음.
> 하지만 전면광고 + 인라인 노출(비용 $0)이 보상 적자를 커버하는 구조.

### 무한 루프 시뮬레이션 (유저가 계속 Native 클릭만 하는 경우)

```
토큰 소진 체크(100%)가 인터벌 체크보다 항상 우선 → checkTrigger() 참조
→ 소진 → Native 클릭(+7,000) → 1교환 소비(7,200) → 소진 → Native 클릭(+7,000) → ...

루프 1회:
  광고 수익 $0.005 (eCPM $5)
  토큰 비용 $0.0105 (7,000 × $0.0000015)
  Gemini 비용 $0.011 (1교환)
  순손익: $0.005 - $0.0105 - $0.011 = -$0.0165
```

| 루프 | 누적 교환 | 누적 광고 수익 | 누적 AI 비용 | 누적 손익 |
|------|---------|-------------|------------|---------|
| 무료 3교환 | 3 | $0 | $0.033 | -$0.033 |
| Native 1회 | 4 | $0.005 | $0.054 | -$0.049 |
| Native 5회 | 8 | $0.025 | $0.139 | -$0.114 |
| Native 10회 | 13 | $0.050 | $0.249 | -$0.199 |

**⚠️ Native 클릭만으로는 적자 누적. 이유: Gemini 채팅 비용($0.011/교환)이 큼.**
**하지만 실제로는 전면광고(3~5회, +$0.030~0.075) + 인라인 노출(+$0.006~0.021)이 추가됨.**

| 루프 | 전면+인라인 수익 포함 | 누적 손익 (eCPM $10) |
|------|-------------------|-------------------|
| 무료 3교환 | +$0.036~$0.096 | -$0.033 + $0.066 = **+$0.033** |
| +Native 5회 | 위 + 추가 인라인 | **손익분기 근접** |

**→ 전면광고+인라인 노출이 핵심 수입원. Native/Rewarded 보상은 유저 유지 투자.**

### 핵심 인사이트
- **전면광고 + 인라인 노출 = 비용 $0 순수익** → 핵심 수입원
- **Rewarded/Native 토큰 보상은 Gemini 비용($0.011/교환) 때문에 단독 적자**
- **GPT-5.2는 saju_base만** ($0.196, 1회성). 월운/신년운은 GPT-5-mini ($0.022/건)
- **Gemini 3.0 Flash는 교환당 ~$0.011** (이전 추정 $0.001보다 11배 비쌈)
- **수익화 핵심: 전면광고 빈도 최적화 + Gemini 모델 다운그레이드 검토**
- **Rewarded Video와 Native 모두 단독 손익분기** → 전면광고가 실질 수입원
- **Native는 유저 만족도 전략** (빠른 클릭, 토큰 더 많음 → 리텐션)
- **⚠️ 출시 후 AdMob 대시보드에서 Native eCPM 실측 → 적자면 토큰 하향 조정**

---

## 7. Rewarded Video vs Native 클릭 수익 비교

> 출처: [Quora - AdMob Average CPC](https://www.quora.com/What-is-an-average-CPC-on-the-AdMob-network), [Playwire - Rewarded Video](https://www.playwire.com/blog/admob-rewarded-video-ads-implementation-and-revenue-optimization), [Construct Forum - AdMob Pay Per Click](https://www.construct.net/en/forum/game-development/distribution-and-publishing-26/admob-average-pay-per-click-72716), [AdCPMRates](https://adcpmrates.com/2021/02/24/admob-ecpm-and-cpc-rates-in-the-us-2021-edition/)

### AdMob 수익 모델 (정정)

> **eCPM = (총 수익 / 총 노출) × 1000** → CPC 수익이 이미 eCPM에 포함됨.
> CPC를 eCPM 위에 따로 더하면 이중 계산. AdMob 평균 CPC $0.25는 "클릭당 수익"이 아니라 "클릭이 발생한 캠페인의 광고주 지불액"임.

- **Rewarded Video**: eCPM $15~$30 → 1회 시청 = **$0.015~$0.030** (가장 높음)
- **Native**: eCPM $3~$7 (일반 CTR) → 1회 노출 = **$0.003~$0.007**
- 높은 CTR 앱은 eCPM 상승 가능 ($10~$20), 하지만 실측 전까지 불확실

### 1회 상호작용당 수익 비교

| 항목 | Rewarded Video (1회 시청) | Native Ad (1회 노출) |
|------|-------------------------|---------------------|
| **eCPM** | $15~$30 | $3~$7 (일반) / $10+ (높은 CTR) |
| **1회 수익** | **$0.015~$0.030** | $0.003~$0.007 / $0.010+ |
| **유저 부담** | 15~30초 영상 시청 | 클릭 1번 (수초) |
| **보상 토큰** | 20,000 (≈3교환) | 7,000 (≈1교환) |
| **토큰 비용** | $0.030 | $0.0105 |
| **마진 (보수적)** | ⚠️ 손익분기 (eCPM $13) | ⚠️ -$0.006 (eCPM $5) |
| **마진 (높은 CTR)** | ≈ 손익분기 (eCPM $29) | ≈ 손익분기 (eCPM $10) |

### Rewarded Video가 단가에서 우위인 이유

```
Rewarded Video:
  - 유저가 15~30초 영상을 끝까지 시청 = 높은 광고 효과
  - 광고주가 "완시청" 기준으로 높은 단가 지불
  - eCPM $15~$30 → 확정적이고 안정적인 수익
  - AdMob 정책 리스크 낮음

Native Ad:
  - 기본 eCPM이 Rewarded의 1/3~1/5 수준 ($3~$7)
  - 클릭 유도로 CTR 높이면 eCPM 상승 가능하지만 불확실
  - AdMob이 비정상 CTR로 판단 시 계정 리스크
  - 7,000 토큰은 보수적 설정 → 안정적 흑자
```

### 수익 시뮬레이션: 동일 유저가 하루 2번 광고 볼 때

| 시나리오 | Rewarded × 2 | Native × 2 (eCPM $5) | Native × 2 (eCPM $10) |
|---------|-------------|---------------------|----------------------|
| 수익 | $0.030~0.060 | $0.010 | $0.020 |
| 토큰 지급 | 40,000 | 14,000 | 14,000 |
| API 비용 | $0.060 | $0.021 | $0.021 |
| **순이익** | **-$0.030~$0.000** | **-$0.011** | **-$0.001** |

### 전략적 판단

| 관점 | Rewarded Video | Native 클릭 |
|------|---------------|------------|
| 수익/회 | **$0.015~0.030 (높음)** | $0.003~0.010 (낮음) |
| 마진 | 손익분기 | ⚠️ 소폭 적자~손익분기 |
| 유저 경험 | 시간 소비 (15~30초) | **빠름** (클릭 1번) |
| 토큰 지급 | 20,000 (≈3교환) | **7,000 (≈1교환)** |
| 유저 만족도 | 높음 | 보통 (토큰 적지만 빠름) |
| 정책 리스크 | **낮음** | 주의 필요 |
| **역할** | **핵심 수익원** | **유저 리텐션 + 보조 수익** |

### AdMob 정책 주의사항
- **클릭을 직접적으로 강제하면 AdMob 정책 위반** (계정 정지 위험)
- "광고를 눌러보세요" 같은 직접적 CTA는 금지
- 우리 방식: "광고 확인하고 대화 이어가기" → 보상 연계이므로 **Rewarded 방식과 유사** → 정책 리스크 중간
- 안전하게 하려면: 버튼 텍스트를 "광고 확인하고 대화 이어가기"처럼 간접적으로 수정 가능

---

## 8. 광고 제거 구매자 (IAP)

| 구분 | 무료 유저 | 광고 제거 구매자 |
|------|----------|----------------|
| 인터벌 Native | O (스킵 가능) | **X (차단)** |
| 80% 경고 | 비활성 (warningRewardTokens=0) | **X (차단)** |
| 토큰 소진 Rewarded Video | O | **O (유저 선택, 강제 아님)** |
| 토큰 소진 Native | O (클릭해야 토큰) | **X (차단)** |

광고 제거 구매자도 토큰 소진 시 **본인이 원하면** Rewarded Video를 시청해 토큰 충전 가능 (강제 X).

---

## 9. DB 토큰 추적 경로

```
┌──────────────────────┐     ┌──────────────────────────────────┐
│  Rewarded Video       │     │  Native Ad                       │
│  (영상 끝까지 시청)    │     │  (클릭 시에만 토큰 지급)           │
└──────────┬───────────┘     └──────────┬───────────────────────┘
           │                            │
           ▼                            ▼
  trackRewarded()              _onAdClicked()
           │                            │
           ▼                            ▼
  incrementDailyCounter        _saveNativeBonusToServer(7000)
  ('rewarded_tokens_earned')            │
           │                            ▼
           ▼                   add_native_bonus_tokens RPC
  rewarded_tokens_earned += N           │
           │                            ▼
           │                   native_tokens_earned += 7000
           │                            │
           ▼                            ▼
  ┌─────────────────────────────────────────────────────┐
  │  quota 체크 (Edge Function)                          │
  │  = chatting_tokens >= (daily_quota                   │
  │    + bonus_tokens                                    │
  │    + rewarded_tokens_earned                          │
  │    + native_tokens_earned)                           │
  └─────────────────────────────────────────────────────┘

  ※ 노출(impression)만 한 경우:
     → AdTrackingService.trackNativeImpression() (분석용 기록)
     → 토큰 지급 없음, DB quota 변화 없음
     → 순수 광고 수익만 발생
```

---

## 10. 코드 위치 참조

| 역할 | 파일 | 핵심 상수/메서드 |
|------|------|----------------|
| 광고 전략 설정 + 토큰 보상 상수 | `ad/ad_strategy.dart` | `inlineAdMessageInterval=4`, `depletedRewardTokensVideo=20000`, `depletedRewardTokensNative=7000`, `intervalClickRewardTokens=7000` |
| 토큰 트리거 로직 | `saju_chat/data/services/ad_trigger_service.dart` | `checkTrigger()` (AdStrategy에 위임) |
| 광고 상태 관리 | `saju_chat/presentation/providers/conversational_ad_provider.dart` | `_onAdClicked()`, `_saveNativeBonusToServer()`, `switchToNativeAd()` |
| 채팅 토큰 관리 | `saju_chat/presentation/providers/chat_provider.dart` | `addBonusTokens()` |
| 토큰 소진 2버튼 배너 | `saju_chat/presentation/widgets/token_depleted_banner.dart` | 영상/네이티브 선택 UI |
| 네이티브 광고 버블 | `saju_chat/presentation/widgets/ad_native_bubble.dart` | 채팅 버블 스타일 광고 |
| 인라인 정적 광고 | `ad/widgets/chat_ad_factory.dart` | ChatAdWidget (ChatMessageList에 삽입, 안내 문구 포함) |
| 인라인 네이티브 위젯 | `ad/widgets/native_ad_widget.dart` | NativeAdWidget, CompactNativeAdWidget (클릭 시 토큰 보상) |
| 토큰 보상 서비스 | `ad/token_reward_service.dart` | `grantNativeAdTokens()`, `grantRewardedAdTokens()` |
| 인라인 광고 위치 계산 | `saju_chat/presentation/widgets/chat_message_list.dart` | `_calculateItemsWithAds()` (AI 응답 뒤에만 삽입) |
| 채팅 쉘 (배너+trailing) | `saju_chat/presentation/screens/saju_chat_shell.dart` | `_buildChatListWithAd()`, `_TokenDepletedBanner` |
| Gemini quota 체크 | `supabase/functions/ai-gemini/index.ts` | `checkAndUpdateQuota()`, `getTodayKST()` |
| OpenAI quota 체크 | `supabase/functions/ai-openai/index.ts` | `checkQuota()`, `getTodayKST()` |
| 광고 설정값 | `ad/ad_config.dart` | `AdUnitId`, `AdMode` |
| DB RPC | Supabase Migration | `add_ad_bonus_tokens`, `add_native_bonus_tokens` |

---

## 11. 설정값 요약 (v28, 2026-02-02)

| 상수 | 값 | 위치 |
|------|-----|------|
| `daily_quota` | 20,000 | Edge Function + DB default |
| `depletedRewardTokensVideo` | 20,000 (영상 시청) | `ad_strategy.dart` |
| `depletedRewardTokensNative` | 7,000 (클릭 시에만) | `ad_strategy.dart` |
| `intervalClickRewardTokens` | 7,000 (클릭 시에만) | `ad_strategy.dart` |
| `impressionRewardTokens` | 0 (노출 보상 없음) | `ad_trigger_service.dart` |
| `inlineAdMessageInterval` | 4 (매 2교환마다) | `ad_strategy.dart` |
| `inlineAdMinMessages` | 4 (2교환 후 시작) | `ad_strategy.dart` |
| `inlineAdMaxCount` | 9999 (무제한) | `ad_strategy.dart` |
| `tokenWarningThreshold` | 0.8 (비활성, warningRewardTokens=0) | `ad_trigger_service.dart` |
| `tokenDepletedThreshold` | 1.0 | `ad_trigger_service.dart` |
| 토큰 리셋 시간 | KST 00:00 | Edge Function (`getTodayKST()`) |
