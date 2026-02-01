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
| `native_tokens_earned` | Native 광고 **클릭** 보상 | `_onAdClicked()` → `add_native_bonus_tokens` RPC |

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
│  ── 6메시지 도달 → 인터벌 Native 광고 (1회) ──                     │
│    → 노출만: 토큰 0, 스킵 가능 (CPM 수익만)                        │
│    → 클릭 시: +30,000 토큰 (≈4교환 추가, CPC $0.10~$0.50)         │
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
│  │   +20,000 토큰 (≈3교환)   │  │   +30,000 토큰 (≈4교환)   │     │
│  │   영상 끝까지 시청 필수     │  │   ★ 클릭해야 토큰 지급 ★   │     │
│  └────────────┬─────────────┘  └────────────┬─────────────┘     │
│               │                              │                   │
│               ▼                              ▼                   │
│  [경로 1] Rewarded Video       [경로 2] Native Ad               │
│  - 15~30초 영상 시청 필수       - 광고 클릭 시에만 토큰 지급        │
│  - 끝까지 봐야 보상             - 노출만으로는 토큰 0 (수익만)      │
│  - trackRewarded() 호출        - _onAdClicked() 호출             │
│  - → rewarded_tokens_earned    - → native_tokens_earned          │
│  - +20,000 토큰                - +30,000 토큰                    │
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

## 3. 인터벌 광고 (대화 중 Native Ad)

대화 중간에 자연스럽게 삽입되는 Native 광고.

### 트리거 조건
- `messageCount >= 6` (3번째 교환 후부터)
- `messageCount % 6 == 0` (매 3교환마다)
- 토큰 소진 트리거보다 **우선순위 낮음** (토큰 체크 먼저)
- 유저가 **스킵 가능** (토큰 없이 대화 계속)

### 토큰 보상 (클릭 시에만)
| 이벤트 | 토큰 | DB 컬럼 |
|--------|------|---------|
| Impression (노출) | **0** (미지급) | - |
| Click (클릭) | **+30,000** | `native_tokens_earned` |

### 설정값 (`ad_strategy.dart`)
```
inlineAdMessageInterval = 6   (매 3교환마다)
inlineAdMinMessages = 6        (3교환 후 시작)
inlineAdMaxCount = 9999        (세션당 제한 없음)
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
| 보상 토큰 | **30,000** (≈4교환) |
| 보상 조건 | **클릭 시에만** (노출만으로는 0) |
| DB 컬럼 | `native_tokens_earned` |
| 저장 방식 | `_onAdClicked()` → `_saveNativeBonusToServer()` → `add_native_bonus_tokens` RPC |

| 유저 행동 | 광고 수익 | 토큰 지급 | API 비용 | 순이익 |
|----------|----------|----------|---------|--------|
| 노출만 (클릭 안 함) | $0.003~0.007 (eCPM) | 0 | $0 | **+$0.003~0.007 (100%)** |
| 클릭 (eCPM $5) | $0.005 | 30,000 | $0.0057 | **-$0.0007 (⚠️ 소폭 적자)** |
| 클릭 (높은CTR, eCPM $10+) | $0.010+ | 30,000 | $0.0057 | **+$0.004+ (43%+ 흑자)** |

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
**→ 30,000 토큰은 공격적 설정 (eCPM $5 기준 손익분기 근접), 실측 후 조정 필요**

### 기본 비용 구조
```
Gemini Flash 비용 per 토큰:
  Input:  $0.10 / 1,000,000 tokens = $0.0000001/token
  Output: $0.40 / 1,000,000 tokens = $0.0000004/token
  가중 평균 (input 70% + output 30%): ~$0.00000019/token

1교환 (7,200 토큰) 비용: ~$0.001
```

### 광고 유형별 최대 지급 가능 토큰

#### Native Ad 노출만 (CPM)
```
한국 시장 Native eCPM: $3 ~ $7 (보수적 $3 기준)
1회 노출 수익 = $0.003

손익분기 토큰 = $0.003 / $0.00000019 = ~15,800 토큰 (≈2.2교환)

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
= $0.005 / $0.00000019 = ~26,300 토큰 (≈3.7교환)

현재 설정: 30,000 토큰 (≈4.2교환, 클릭 시에만)
→ 비용: 30,000 × $0.00000019 = $0.0057
→ eCPM $5 기준: ($0.005 - $0.0057) = -$0.0007 (소폭 적자)
→ eCPM $7 기준: ($0.007 - $0.0057) = +$0.0013 (소폭 흑자)
→ eCPM $10+ (높은 CTR): ($0.01 - $0.0057) = +$0.0043 (흑자)
→ ⚠️ 공격적 설정. 출시 후 실측 eCPM 확인하고 조정 필요
```

#### Rewarded Video
```
한국 시장 Rewarded eCPM: $15 ~ $30 (보수적 $15 기준)
1회 수익 = $0.015

손익분기 토큰 = $0.015 / $0.00000019 = ~79,000 토큰 (≈11교환)
50% 마진 적용 = ~39,500 토큰 (≈5.5교환)

현재 설정: 20,000 토큰 (≈3교환)
→ 손익분기의 25% → 75% 마진
→ ✅ 넉넉
```

### 요약 비교표

| 광고 유형 | 1회 수익 (보수적) | 손익분기 토큰 | 현재 지급 | 마진 |
|----------|-----------------|-------------|----------|------|
| Native 노출만 | $0.003~0.007 (eCPM) | ~26,300 | **0** | **100%** |
| Native 클릭 | $0.005 (eCPM $5) | ~26,300 | **30,000** | **⚠️ -14%** |
| Native 클릭 (높은 CTR) | $0.010+ (eCPM $10+) | ~52,600 | **30,000** | **43%+** |
| Rewarded Video | $0.015~0.030 (eCPM) | ~79,000 | **20,000** | **75%** |

### 결론
- **Rewarded Video($0.015~$0.030)가 Native($0.003~$0.007)보다 3~5배 수익 높음**
- **Rewarded Video 20,000 (≈3교환)**: 안정적 75% 마진
- **Native 30,000 (≈4교환)**: 공격적 설정. 일반 eCPM $5면 소폭 적자
  - 우리 앱 CTR이 높아서 eCPM $10+이면 흑자 전환 (실측 필요)
  - 유저 만족도 높음 (Rewarded보다 토큰 많고, 클릭만 하면 됨)
- **Native 노출 0**: 올바른 판단. 노출만으로는 비용 $0 → 순수 수익
- **⚠️ 출시 후 AdMob 대시보드에서 실제 eCPM 확인 → 적자면 토큰 하향 조정**

---

## 6. 수익 시뮬레이션: 일반 유저 1일 세션

### 시나리오: 10교환 대화 (약 20분)

```
[무료] 교환 1~3: ~21,600 토큰 소비
  ── 6메시지 도달 → 인터벌 Native 1회 ──
  → 노출만: eCPM 수익 $0.003~0.007, 토큰 0
  → 클릭 시: +30,000 토큰 (eCPM 수익은 노출과 동일)

  누적 ~21,600 → quota 소진!

[소진] Native 클릭 → +30,000 토큰
  교환 4~7: ~28,800 토큰 소비 → 소진!

[소진] Rewarded Video → +20,000 토큰 ($0.015~0.030 수익)
  교환 8~10: ~21,600 토큰 소비
  ── 인터벌 Native 1회 (6메시지 도달 시) ──
  소진!
```

### 보수적 수익 (클릭 0회, 노출만)

| 항목 | 값 |
|------|-----|
| GPT-5.2 분석 (1회, 고정) | -$0.02 |
| Gemini 비용 (10교환) | -$0.010 |
| Rewarded Video × 2 ($0.015 each) | +$0.030 |
| Native 노출 × 3 ($0.003 each, CPM) | +$0.009 |
| **일일 순이익 (보수적)** | **+$0.009** |

### 낙관적 수익 (Native 클릭 2회 + Rewarded eCPM $25)

| 항목 | 값 |
|------|-----|
| GPT-5.2 분석 (1회, 고정) | -$0.02 |
| Gemini 비용 (10교환) | -$0.010 |
| Rewarded Video × 1 ($0.025) | +$0.025 |
| Native 노출 × 3 ($0.005 each, eCPM) | +$0.015 |
| 토큰 API 비용 (Native 30k×1 + Rewarded 20k×1) | -$0.0095 |
| **일일 순이익 (낙관적)** | **+$0.0005** |

> ⚠️ 30,000 토큰은 손익분기 근접. Native eCPM이 $5 이하면 적자 가능.
> 출시 후 실측 eCPM에 따라 토큰 조정 필요.

### 무한 루프 시뮬레이션 (유저가 계속 Native 클릭만 하는 경우)

```
토큰 소진 체크(100%)가 인터벌 체크보다 항상 우선 → checkTrigger() 참조
→ 소진 → Native 클릭(+30,000) → 4교환 소비(28,800) → 소진 → Native 클릭(+30,000) → ...

루프 1회: eCPM 수익 $0.005 (eCPM $5 기준), 토큰 비용 $0.0057, 4교환 대화
```

| 루프 | 누적 교환 | 누적 수익 (eCPM $5) | 누적 토큰 비용 | 누적 손익 |
|------|---------|-------------------|------------|---------|
| 무료 3교환 | 3 | $0 | $0.003 | -$0.003 |
| Native 1회 | 7 | $0.005 | $0.0087 | -$0.004 |
| Native 2회 | 11 | $0.010 | $0.0144 | -$0.004 |
| Native 5회 | 23 | $0.025 | $0.0315 | -$0.007 |
| Native 10회 | 43 | $0.050 | $0.060 | -$0.010 |

**⚠️ eCPM $5 기준 무한 루프 시 소폭 적자 누적.**
**높은 CTR로 eCPM $10+이면:**

| 루프 | 누적 교환 | 누적 수익 (eCPM $10) | 누적 토큰 비용 | 누적 손익 |
|------|---------|-------------------|------------|---------|
| 무료 3교환 | 3 | $0 | $0.003 | -$0.003 |
| Native 1회 | 7 | $0.010 | $0.0087 | +$0.001 |
| Native 5회 | 23 | $0.050 | $0.0315 | +$0.019 |
| Native 10회 | 43 | $0.100 | $0.060 | +$0.040 |

**→ eCPM $10이면 흑자. 출시 후 실측 필수.**

### 핵심 인사이트
- **Rewarded Video($0.015~$0.030)가 Native($0.003~$0.007)보다 확실히 수익 높음**
- **GPT-5.2 분석은 세션당 1회** (고정비 ~$0.02, 가장 큰 비용)
- **Gemini Flash는 교환당 ~$0.001** (매우 저렴)
- **Native 30,000 토큰은 공격적 설정** → eCPM $5면 소폭 적자, $10+이면 흑자
- **Rewarded Video가 수익 안정성 측면에서 우위** (75% 마진 확정)
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
| **보상 토큰** | 20,000 (≈3교환) | 30,000 (≈4교환) |
| **토큰 비용** | $0.0038 | $0.0057 |
| **마진 (보수적)** | **75%** | ⚠️ -14% (eCPM $5) |
| **마진 (높은 CTR)** | **75%** | 43% (eCPM $10) |

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
  - 30,000 토큰은 손익분기 근접 → 공격적 설정
```

### 수익 시뮬레이션: 동일 유저가 하루 2번 광고 볼 때

| 시나리오 | Rewarded × 2 | Native × 2 (eCPM $5) | Native × 2 (eCPM $10) |
|---------|-------------|---------------------|----------------------|
| 수익 | $0.030~0.060 | $0.010 | $0.020 |
| 토큰 지급 | 40,000 | 60,000 | 60,000 |
| API 비용 | $0.0076 | $0.0114 | $0.0114 |
| **순이익** | **$0.022~0.052** | **-$0.001** | **+$0.009** |

### 전략적 판단

| 관점 | Rewarded Video | Native 클릭 |
|------|---------------|------------|
| 수익/회 | **$0.015~0.030 (높음)** | $0.003~0.010 (낮음) |
| 마진 | **75% (안정)** | -14%~43% (불확실) |
| 유저 경험 | 시간 소비 (15~30초) | **빠름** (클릭 1번) |
| 토큰 지급 | 20,000 (≈3교환) | **30,000 (≈4교환)** |
| 유저 만족도 | 높음 | **더 높음 (토큰 더 많음)** |
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
  incrementDailyCounter        _saveNativeBonusToServer(30000)
  ('rewarded_tokens_earned')            │
           │                            ▼
           ▼                   add_native_bonus_tokens RPC
  rewarded_tokens_earned += N           │
           │                            ▼
           │                   native_tokens_earned += 30000
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
| 광고 전략 설정 | `ad/ad_strategy.dart` | `inlineAdMessageInterval=6`, `inlineAdMaxCount` |
| 토큰 트리거 로직 | `saju_chat/data/services/ad_trigger_service.dart` | `checkTrigger()`, `depletedRewardTokensVideo/Native`, `intervalClickRewardTokens` |
| 광고 상태 관리 | `saju_chat/presentation/providers/conversational_ad_provider.dart` | `_onAdClicked()`, `_saveNativeBonusToServer()` |
| 채팅 토큰 관리 | `saju_chat/presentation/providers/chat_provider.dart` | `addBonusTokens()` |
| 광고 UI | `saju_chat/presentation/widgets/conversational_ad_widget.dart` | `_buildTokenDepletedChoice()` |
| AI 전환 문구 | `saju_chat/domain/models/ad_persona_prompt.dart` | `getDefaultTransitionText()`, `getCtaText()` |
| Gemini quota 체크 | `supabase/functions/ai-gemini/index.ts` | `checkAndUpdateQuota()`, `getTodayKST()` |
| OpenAI quota 체크 | `supabase/functions/ai-openai/index.ts` | `checkQuota()`, `getTodayKST()` |
| 광고 설정값 | `ad/ad_config.dart` | `AdUnitId`, `AdMode` |
| DB RPC | Supabase Migration | `add_ad_bonus_tokens`, `add_native_bonus_tokens` |

---

## 11. 설정값 요약 (현재 v0.1.0+15)

| 상수 | 값 | 위치 |
|------|-----|------|
| `daily_quota` | 20,000 | Edge Function + DB default |
| `depletedRewardTokensVideo` | 20,000 (영상 시청) | `ad_trigger_service.dart` |
| `depletedRewardTokensNative` | 30,000 (클릭 시에만) | `ad_trigger_service.dart` |
| `intervalClickRewardTokens` | 30,000 (클릭 시에만) | `ad_trigger_service.dart` |
| `impressionRewardTokens` | 0 (노출 보상 없음) | `ad_trigger_service.dart` |
| `inlineAdMessageInterval` | 6 (매 3교환마다) | `ad_strategy.dart` |
| `inlineAdMinMessages` | 6 (3교환 후 시작) | `ad_strategy.dart` |
| `inlineAdMaxCount` | 9999 (무제한) | `ad_strategy.dart` |
| `tokenWarningThreshold` | 0.8 (비활성, warningRewardTokens=0) | `ad_trigger_service.dart` |
| `tokenDepletedThreshold` | 1.0 | `ad_trigger_service.dart` |
| 토큰 리셋 시간 | KST 00:00 | Edge Function (`getTodayKST()`) |
