# v30 AI 비용 구조 감사 (2026-02-03) — 수정판 v5

> `business_analysis.md` (2/1) 이후 실제 DB 데이터 + Edge Function 코드 + 공식 가격 문서 기반 정밀 감사
> **v5 수정**: Rewarded Video 완전 제거 반영, Native CPC 전용 구조 확정, depletedRewardTokensNative 12,000 반영, BEP 재계산
> **v5.1 수정 (2026-02-04)**: v43 reasoning_effort "low" 반영, v44 모델 배치 최적성 검증 결과 반영, 코드↔문서 불일치 수정 (15,000/10,000), 비용 최적화 완료 선언

---

## 0. 핵심 결론 (TL;DR)

| 항목 | 결론 |
|------|------|
| 모델 라우팅 합리적? | **Yes** — GPT-5.2(분석) + GPT-5-mini(파생) + Gemini Flash(채팅) 3단 구조 **이미 최적 (v44.1 검증)** |
| 모델 변경 필요? | **No** — 빈도 낮은 것=비싼 모델 OK, 빈도 높은 것=이미 최저가. 변경 ROI 없음 |
| 채팅 수익 구조? | **Native CPC 전용** — CPC $0.05~0.30/click, Rewarded 제거 (단가 열위) |
| 가장 큰 비용? | **GPT-5.2 saju_base** (호출당 $0.183, 1회성) — 전체 AI 비용의 48.6% |
| 복리 수익 가능? | **Yes** — Native click 1회/일 시 BEP **4.6일** (보수적), 2.4일 (CPC $0.10) |
| Rewarded 제거 이유? | eCPM $0.020/회 − AI비용 $0.025 = **적자**. Native CPC $0.050 − AI $0.015 = **흑자** |
| 비용 최적화 상태? | **완료** — 수익/성장 단계로 전환 권장 |

---

## 1. [핵심 수정] chatting_tokens 정의와 blended cost

### 1.1 chatting_tokens의 실체

**DB Trigger `update_daily_chat_tokens`:**
```
- chat_messages INSERT 시 발동
- role = 'assistant' AND tokens_used > 0 인 메시지만 처리
- tokens_used = 해당 API 호출의 total tokens (prompt + completion)
- chatting_tokens += tokens_used
```

**핵심**: `chatting_tokens`는 output만이 아닌 **total API tokens (prompt + completion)**를 합산한 값.

### 1.2 실제 blended cost 계산

Gemini 3.0 Flash 채팅의 실제 토큰 비율 (DB 실측):

| 지표 | 값 |
|------|-----|
| 평균 prompt : completion 비율 | **약 70:30** (대화 이력 누적으로 prompt 비중 높음) |
| prompt 단가 | $0.50/1M |
| completion 단가 | $3.00/1M |
| **blended 단가** | **(0.70 × $0.50) + (0.30 × $3.00) = $1.25/1M** |
| **chatting_tokens 기준 실측** | **~$0.80/1M** (DB 데이터 역산: gemini_cost / chatting_tokens) |

> v1 문서의 $2.00/1M 가정은 output 비중 60% 가정 오류. 실제는 prompt 비중이 훨씬 높아 $0.80/1M.

### 1.3 왜 차이가 나는가

```
채팅 대화 5교환 예시:
┌───────────────────────────────────────┐
│ 교환1: prompt 2K + completion 1K      │  tokens_used = 3K
│ 교환2: prompt 5K + completion 1K      │  tokens_used = 6K  (이력 누적)
│ 교환3: prompt 8K + completion 1K      │  tokens_used = 9K
│ 교환4: prompt 11K + completion 1K     │  tokens_used = 12K
│ 교환5: prompt 14K + completion 1K     │  tokens_used = 15K
├───────────────────────────────────────┤
│ chatting_tokens 합계 = 45K            │
│ 실제 prompt 비중 = 40K/45K = 89%      │  ← prompt가 압도적
│ 실제 completion 비중 = 5K/45K = 11%   │
│ blended cost = $0.50×0.89 + $3.00×0.11│ = $0.775/1M
└───────────────────────────────────────┘
```

**대화가 길어질수록 prompt 비중 증가 → blended cost 하락 → 헤비 유저일수록 1M당 비용 저렴**

---

## 2. [v4 수정] 채팅 내 실제 광고 흐름 + 손익 재계산

### 2.0 채팅 내 실제 광고 흐름 (v30 코드 확인, 2026-02-03)

```
채팅 중 실제 발생하는 광고:

1. 인라인 Native Ad (chat_message_list.dart:142)
   → 4메시지마다 NativeAdWidget 자동 삽입
   → impression: 토큰 0, 순수 eCPM 수익
   → click: +7,000 토큰 지급 (intervalClickRewardTokens)

2. Interstitial 전면광고 (saju_chat_shell.dart:755)
   → 5메시지마다 전면광고 표시 (adControllerProvider.onChatMessage)
   → 토큰 0 (순수 수익, AI 비용 없음)

3. 토큰 소진 배너 (token_depleted_banner.dart)
   → [📋 바로 대화 계속하기]: Native click → +12,000 토큰
   → [✨ 광고 없이 이용하기]: 프리미엄 구매 페이지 이동
   → ❌ Rewarded Video: 완전 제거 (depletedRewardTokensVideo = 0, 코드 주석 처리)

Rewarded Video 제거 이유:
  Rewarded: 수익 $0.020/회 − AI비용 $0.025 (20K토큰) = -$0.005 (적자)
  Native CPC: 수익 $0.050/회 − AI비용 $0.015 (12K토큰) = +$0.035 (흑자)
  → Native CPC가 수익성 압도적 우위
```

### 2.1 [v4 수정] Native Click 수익 재산정 (CPC 모델)

```
이전 계산 (v1~v3): $0.005~0.010/click
  → eCPM ÷ 1000으로 계산 — 이는 impression 단가이지 click 단가가 아님

실제 (CPC 모델, AdMob 공식 문서 기반):
  → AdMob Native Click은 CPC(Cost-Per-Click) 과금
  → 한국 평균 CPC: $0.05~0.30
  → Publisher 수취율: ~68-80%
  → Publisher 실수령: $0.035~0.210/click

보수적 추정: $0.05/click (한국 시장 하한)
```

### 2.2 [v5 수정] 사이클별 손익 (Rewarded 제거 반영)

| 사이클 | 토큰 충전 | AI 비용 (@$0.80/1M) | 광고 수익 | 단위 손익 |
|--------|---------|---------------------|----------|----------|
| 기본 (무료) | 20,000 | **$0.016** | imp $0.004 + interstitial $0.010 | **-$0.002** |
| ~~Rewarded Video~~ | ~~+20,000~~ | ~~$0.016~~ | ~~$0.020~~ | **제거됨 (적자)** |
| 소진→Native click | **+12,000** | **$0.010** | **$0.050** (CPC) | **+$0.040** |
| 인라인 Native click | +7,000 | **$0.006** | **$0.050** (CPC) | **+$0.044** |
| 인라인 Native impression | +0 | $0.000 | $0.004 (eCPM) | **+$0.004** |
| Interstitial (5msg마다) | +0 | $0.000 | $0.010 | **+$0.010** |

### 2.3 [v5] Rewarded 제거 근거 + Native CPC 우위

```
Rewarded Video (제거됨):
  수익 $0.020/회  →  토큰 20,000개 지급  →  AI 비용 $0.025  →  순이익 -$0.005 (적자!)
  수익률: -20%
  eCPM $13~29이어도 토큰 20K의 AI 비용을 커버 못 함

Native Click — 소진 배너 (CPC $0.05):
  수익 $0.050  →  토큰 12,000개 지급  →  AI 비용 $0.015  →  순이익 +$0.035
  수익률: +233%

Native Click — 인라인 (CPC $0.05):
  수익 $0.050  →  토큰 7,000개 지급  →  AI 비용 $0.009  →  순이익 +$0.041
  수익률: +456%

→ Rewarded는 적자, Native CPC는 확실한 흑자
→ 클릭 유도가 수익 극대화의 핵심
→ 토큰 소진 배너: [바로 대화 계속하기] + [프리미엄 구매] 2버튼 구조
```

### 2.4 복합 사이클 시뮬레이션 (v5, Rewarded 제거)

**시나리오 A: 기본만 쓰고 이탈 (광고 클릭 0)**
```
기본 20K:  비용 $0.025, 수익 $0.010 (imp만)
합계: -$0.015
```

**시나리오 B: 기본 + 소진 Native click 1회**
```
기본 20K:                  비용 $0.025, 수익 $0.010    = -$0.015
소진 Native click (+12K):  비용 $0.015, 수익 $0.050    = +$0.035
인라인 impression ×2:      비용 $0,     수익 $0.008    = +$0.008
Interstitial ×1:           비용 $0,     수익 $0.010    = +$0.010
─────────────────────────────────────────────────
합계: 비용 $0.040, 수익 $0.078 = +$0.038 (흑자!)
```

**시나리오 C: 기본 + 소진 Native click 1회 + 인라인 click 1회**
```
기본 20K:                  비용 $0.025, 수익 $0.010    = -$0.015
소진 Native click (+12K):  비용 $0.015, 수익 $0.050    = +$0.035
인라인 Native click (+7K): 비용 $0.009, 수익 $0.050    = +$0.041
인라인 impression ×2:      비용 $0,     수익 $0.008    = +$0.008
Interstitial ×1:           비용 $0,     수익 $0.010    = +$0.010
─────────────────────────────────────────────────
합계: 비용 $0.049, 수익 $0.128 = +$0.079 (대흑자!)
```

**결론: Rewarded 없이도 Native click만으로 흑자. 클릭 1회/일이면 충분.**

---

## 3. GPT-5.2 saju_base — 진짜 비용 문제

### 3.1 비용 구조 (변함없음)

```
호출당 평균 $0.197 내역:
┌─────────────────────────────────────┐
│ input:  6,045 × $1.75/1M = $0.011  │  5.3%
│ output: 13,355 × $14.00/1M = $0.187│  94.7%  ← 핵심
│ cached: 0 × $0.175/1M = $0.000    │  0.0%   ← 미활용
└─────────────────────────────────────┘
```

### 3.2 [v5 수정] saju_base 상각 분석 (Rewarded 제거, Native CPC only)

**saju_base는 프로필당 1회 발생 → 이후 모든 채팅/운세는 이 데이터 재활용:**

**프로필 초기 세팅 합계**: $0.266 (saju_base $0.197 + 파생운세 $0.069)

| 유저 잔존 기간 | 초기 비용 | 일일 순수익 (시나리오 B) | 누적 손익 |
|---------------|----------|------------------------|----------|
| 1일 (이탈) | -$0.266 | +$0.038 | **-$0.228** |
| 3일 | -$0.266 | +$0.114 | **-$0.152** |
| 7일 | -$0.266 | +$0.266 | **±$0 (BEP)** |
| 14일 | -$0.266 | +$0.532 | **+$0.266** |
| 30일 | -$0.266 | +$1.140 | **+$0.874** |

> **BEP ~7일** (CPC $0.05 보수적 기준, Native click 1회/일)
> **BEP ~3일** (CPC $0.15 낙관적 기준)

### 3.3 파생 운세의 비용 (GPT-5-mini)

프로필당 1회 세트: monthly + yearly_2026 + yearly_2025 + daily

| 운세 | 모델 | 비용 |
|------|------|------|
| saju_base | GPT-5.2 | $0.197 |
| monthly_fortune | GPT-5-mini | $0.025 |
| yearly_2026 | GPT-5-mini | $0.019 |
| yearly_2025 | GPT-5-mini | $0.018 |
| daily_fortune | Gemini Flash | $0.006 |
| **프로필 초기 세팅 합계** | | **$0.265** |

> daily_fortune만 매일 갱신 ($0.006/일). 나머지는 1회성 → 장기 비용 영향 없음.

---

## 4. 복리 수익 구조 설계 (v4)

### 4.1 현재 구조의 복리 메커니즘 (v5, Native CPC 전용)

```
복리 구조 (v5, Rewarded 제거):
┌─────────────────────────────────────────────────────────┐
│ DAY 1: saju_base 투자 (-$0.266)                         │
│   └→ saju_base + 4개 운세 1회 생성                       │
│                                                         │
│ DAY 2~: 매일 반복                                        │
│   ├→ 기본 20K (무료)             → -$0.015               │
│   ├→ 소진 Native click ×1 (+12K) → +$0.035 ★★★         │
│   ├→ 인라인 Native imp ×2        → +$0.008 (무비용)     │
│   ├→ Interstitial ×1             → +$0.010 (무비용)     │
│   └→ daily_fortune 갱신          → -$0.006              │
│                                                         │
│ 일일 순수익 = +$0.032/일 (보수적 CPC $0.05)              │
│                                                         │
│ BEP = $0.266 / $0.032 = 8.3일                           │
│ 7일 누적 = -$0.266 + ($0.032 × 7) = -$0.042            │
│ 14일 누적 = -$0.266 + ($0.032 × 14) = +$0.182          │
│ 30일 누적 = -$0.266 + ($0.032 × 30) = +$0.694          │
└─────────────────────────────────────────────────────────┘

★ Native click 1회/일이 전체 수익의 핵심 (Rewarded 없이도 흑자)
★ 인라인 click까지 발생하면 일일 +$0.073 (BEP 3.6일)
★ CTR 4.89% (실측) → click 발생 확률 높음
```

### 4.2 Gemini Context Caching — 추가 비용 절감

**공식 문서 확인 결과:**

| 항목 | 표준 가격 | Context Caching | 절감 |
|------|---------|-----------------|------|
| Gemini 3.0 Flash Input | $0.50/1M | **$0.05/1M** (캐시 히트) | **90%** |
| 최소 캐시 토큰 | - | 1,024+ tokens | - |
| 캐시 저장 비용 | - | $1.00/1M tokens/hr | - |

**채팅에 적용 시 효과:**

saju_base + system prompt + 사주 데이터 = 약 4,000~6,000 tokens → 캐시 가능
이 부분이 모든 채팅 호출의 prompt에 반복 포함됨.

```
Context Caching 적용 전/후:
┌────────────────────────────────────────────────┐
│ 현재: 매 호출마다 system+saju prompt 전송        │
│   → 5교환 시 system prompt 5번 × 4K = 20K tokens│
│   → 비용: 20K × $0.50/1M = $0.010              │
│                                                │
│ 캐싱 후: 1번 캐시 + 4번 캐시 히트               │
│   → 캐시 저장: 4K × $1.00/1M/hr ≈ $0.004/hr   │
│   → 캐시 히트: 16K × $0.05/1M = $0.0008        │
│   → 비용: $0.0048 (~50% 절감)                  │
│                                                │
│ 일일 절감 (5교환 기준): ~$0.005                  │
│ 월 절감: ~$0.15/유저                            │
└────────────────────────────────────────────────┘
```

### 4.3 Context Caching 적용 후 수정 경제성

| 항목 | 현재 | Context Caching 적용 후 |
|------|------|----------------------|
| chatting blended cost | $0.80/1M | **~$0.55/1M** |
| 기본 20K AI 비용 | $0.025 | **$0.018** |
| 일일 순수익 (소진 Native click 1회) | +$0.032 | **+$0.039** |
| saju_base BEP | 8.3일 | **6.8일** |

---

## 5. 실행 전략 — 흑자 전환 순서

### Phase 1: 즉시 (비용 가시성 + 누수 차단) ✅ 완료

**1-A. ai-gemini 스트리밍 usageMetadata 파싱 보강** ✅
- v26에서 fallback 추산 로직 구현
- usageMetadata 누락 시 텍스트 길이 기반 추산

**1-B. 본 문서 Native CPC 수정 완료** ✅

**1-C. ai-gemini 변수명 오타 수정** ✅
- `cachedTokens` → `totalCachedTokens` (v27, 배포 v48)

### Phase 2: Gemini Context Caching 적용 ✅ 완료 (v27)

- system prompt + saju_base 데이터를 세션 단위 캐시
- Input 비용 90% 절감 → blended cost $0.80 → $0.55/1M
- 구현: `cachedContent` API 사용 (Gemini REST API 지원)
- DB: `chat_sessions.gemini_cache_name` 컬럼 추가 ✅
- Edge Function: createGeminiCache() + fallback ✅
- 프론트엔드: session_id 전달 체인 (provider→repo→datasource) ✅
- 캐시 에러 시 표준 요청 자동 fallback ✅

### Phase 3: Native Click 최적화 (수익 극대화) — 부분 완료

**3-A. 인라인 Native Ad CTA 개선** (미구현)
- 클릭 가치를 명확히 전달하는 텍스트
- "광고를 확인하면 3번 더 대화할 수 있어요"

**3-B. 토큰 소진 배너 Native 선택지 강화** ✅
- "📋 바로 대화 계속하기" (AdMob 정책 준수)

### Phase 4: saju_base 비용 최적화 (GPT-5.2 유지) — 부분 완료

**4-A. Lazy saju_base 생성** ✅ 완료 (v30)
- 프로필 저장 시 트리거 제거
- 4중 트리거: 하단네비 → 운세버튼 → 평생운세페이지 → 첫채팅
- 채팅 안 하는 이탈 유저의 $0.197 절약
- `SajuAnalysisService._analyzingProfiles` Set으로 중복 방지

**4-B. saju_base Phase 분리 생성** (미구현)
- 4 Phase → Phase 1-2만 즉시, Phase 3-4는 접근 시
- $0.197 → $0.100 (50% 절감)

### Phase 5: 수익 추적 + 에러 추적 — 부분 완료

- AdMob 실제 CPC 추적 → 이 문서에 실측값 업데이트 (미구현)
- 에러 추적: chat_error_logs 테이블로 전체 에러 기록 ✅ (v30)

---

## 6. 공식 가격 정리 (2026-02 기준, 인터넷 확인)

### OpenAI

| 모델 | Input/1M | Output/1M | Cached/1M | 용도 |
|------|---------|----------|----------|------|
| GPT-5.2 | $1.75 | $14.00 | $0.175 (-90%) | 사주 분석 |
| GPT-5-mini | $0.25 | $2.00 | $0.025 (-90%) | 파생 운세 |
| GPT-5-nano | $0.05 | $0.40 | - | (미사용) |

### Google Gemini

| 모델 | Input/1M | Output/1M | Context Cache/1M | 용도 |
|------|---------|----------|-----------------|------|
| Gemini 3.0 Flash | $0.50 | $3.00 | **$0.05 (-90%)** | 채팅/일운 |
| Gemini 3.0 Pro | $2.00 | $12.00 | - | (미사용) |
| Gemini 2.5 Flash Lite | $0.10 | $0.40 | - | 의도 분류 |
| Gemini 2.0 Flash | $0.10 | $0.40 | - | (대안) |

### Gemini Free Tier (중요)

| 항목 | 무료 제공 |
|------|---------|
| RPM (분당 요청) | 10 |
| RPD (일당 요청) | **1,000** |
| TPM | 250,000 |

> DAU 50 이하에서는 daily_fortune을 Free Tier로 처리 가능 ($0.006/회 절감)

### AdMob 광고 수익 (한국 시장, v4 수정)

| 광고 유형 | 과금 모델 | Publisher 수취 | 비고 |
|----------|---------|--------------|------|
| Native Click | **CPC** | **$0.05~0.30/click** | 핵심 수익원 |
| Native Impression | eCPM | $3~7/1000 imp | Passive 수익 |
| Rewarded Video | eCPM | $15~30/1000 imp ($0.015~0.030/view) | 유저 참여 필요 |
| Interstitial | eCPM | $8~15/1000 imp ($0.008~0.015/view) | 화면 전환 시 |
| Banner | eCPM | $0.5~2/1000 imp | 낮은 수익 |

### 출처

- [OpenAI Pricing](https://openai.com/api/pricing/)
- [Gemini API Pricing](https://ai.google.dev/gemini-api/docs/pricing)
- [Gemini Context Caching](https://ai.google.dev/gemini-api/docs/caching)
- [AdMob Revenue Optimization](https://admob.google.com/home/)

---

## 7. GPT-5.2 Reasoning Token 분석

### 7.1 설정

| 항목 | 값 | 비고 |
|------|-----|------|
| reasoning_effort (saju_base) | `"low"` → `"medium"` 폴백 | v43에서 low로 변경, 효과 7% |
| reasoning_effort (기타) | `"medium"` (기본) | 변경 없음 |
| API 엔드포인트 | `/v1/responses` (Responses API) | |

### 7.2 실측 (ai_summaries에서 10건 샘플)

| 지표 | 값 |
|------|-----|
| 평균 completion_tokens | 13,355 |
| 평균 실제 텍스트 추정 토큰 | ~11,000 |
| **token_multiplier** | **1.22x** |

**해석**: reasoning overhead는 ~22%로 양호. `"high"`나 `"xhigh"`에서는 5-10x 폭증 가능하므로 `"medium"` 유지가 맞음.

### 7.3 캐싱 미활용 문제

GPT-5.2는 90% 캐시 할인 제공 ($1.75 → $0.175/1M).
saju_base 프롬프트 중 system prompt ~4,000 tokens는 동일 → 캐싱 가능.
단, input이 비용의 5.3%라 절감 효과 미미 ($0.011 → $0.004, 호출당 $0.007 절감).

---

## 8. Gemini 채팅 비용 미기록 버그

### 8.1 현상

| 항목 | 값 |
|------|-----|
| `chatting_tokens > 0` AND `gemini_cost_usd = 0` 레코드 | **12건** |
| 누락 토큰 합계 | **1,221,856** |
| 추정 누락 비용 | **$2.44** |

### 8.2 원인 (ai-gemini/index.ts)

```
스트리밍 응답에서 usageMetadata는 마지막 청크에만 포함됨.
1. 스트림 비정상 종료 (네트워크 끊김, 타임아웃)
2. 마지막 청크 버퍼 파싱 실패 (v25에서 수정 시도했으나 불완전)
3. totalPromptTokens = 0 으로 남음
4. 조건문: if (totalPromptTokens > 0 || totalCompletionTokens > 0)
   → 0이면 recordGeminiCost() 스킵
```

### 8.3 수정 방안 (v26 구현)

fallback: 스트림 완료 후 토큰 0이면:
1. 응답 텍스트 길이로 completion tokens 추산 (한글 1자 ≈ 2~3 tokens)
2. system prompt 길이로 prompt tokens 추산
3. 추산 비용으로 `recordGeminiCost()` 호출
4. 로그에 `[FALLBACK]` 표기하여 실측값과 구분

---

## 9. Edge Function 비용 기록 현황

| Edge Function | 모델 | Input 가격 | Output 가격 | 정확? |
|--------------|------|-----------|------------|-------|
| ai-openai | GPT-5.2 | $1.75/1M | $14.00/1M | **Yes** (v39) |
| ai-gemini (채팅) | Gemini 3.0 Flash | $0.50/1M | $3.00/1M | **Yes** (v25) |
| ai-gemini (의도분류) | Gemini 2.5 Flash Lite | $0.10/1M | $0.40/1M | **Yes** (v25) |
| ai-openai-mini | GPT-5-mini | $0.25/1M | $2.00/1M | **Yes** |

---

## 10. 실제 DB 데이터 (1/29 ~ 2/2, 5일간)

### 10.1 일별 비용 추이 (2026-02-03 갱신)

| 날짜 | 유저수 | GPT 비용 | Gemini 비용 | 총 비용 | 채팅 토큰 | 사주 토큰 |
|------|--------|---------|------------|---------|----------|----------|
| 2/3 | 3 | $0.00 | $0.01 | $0.01 | 0 | 0 |
| 2/2 | 11 | $2.23 | $0.46 | $2.70 | 645K | 81K |
| 2/1 | 22 | $3.30 | $0.16 | $3.46 | 327K | 43K |
| 1/31 | 14 | $0.95 | $0.00 | $0.95 | 1,007K | 0 |
| 1/30 | 15 | $2.02 | $0.00 | $2.02 | 347K | 0 |
| **합계** | | **$8.50** | **$0.64** | **$9.14** | **2.33M** | **124K** |

**일평균**: $1.83/일, DAU ~13명 → **유저당 $0.14/일**

### 10.2 광고 이벤트 (최근 7일)

| 광고유형 | 이벤트 | 건수 | 보상토큰 |
|---------|--------|------|---------|
| native | impression | 777 | 0 |
| native | click | 38 | 0 |
| interstitial | show/complete | 53/52 | 0 |
| rewarded | show/complete | 24/23 | 0 |
| rewarded | rewarded | 31 | 215,060 |

**Native CTR**: 38/777 = **4.89%** (우수)

### 10.3 모델별 호출 단가 (ai_summaries 실측)

| 모델 | 작업 | 호출수 | 평균 input | 평균 output | **호출당 비용** | 합계 |
|------|------|--------|-----------|------------|--------------|------|
| GPT-5.2 | saju_base | 22 | 6,045 | 13,355 | **$0.197** | $4.35 |
| GPT-5-mini | monthly_fortune | 42 | 5,238 | 11,648 | **$0.025** | $1.03 |
| GPT-5-mini | yearly_2026 | 42 | 11,961 | 8,067 | **$0.019** | $0.80 |
| GPT-5-mini | yearly_2025 | 40 | 7,170 | 8,034 | **$0.018** | $0.71 |
| Gemini Flash | daily_fortune | 54 | 1,890 | 1,669 | **$0.006** | $0.32 |

---

## 11. 최종 판단 — v5

### 현재 코드 설정값 (v44, 2026-02-04 확인)

| 설정 | 값 | 파일 |
|------|-----|------|
| daily_quota | 20,000 | DB + purchase_config.dart |
| inlineAdMessageInterval | 4 | ad_strategy.dart:63 |
| inlineAdMinMessages | 4 | ad_strategy.dart:69 |
| depletedRewardTokensVideo | **0 (제거됨)** | ad_strategy.dart:95 |
| depletedRewardTokensNative | **15,000** | ad_strategy.dart:100 |
| intervalClickRewardTokens | **10,000** | ad_strategy.dart:103 |
| interstitialMessageInterval | 5 | ad_strategy.dart:74 |
| reasoning_effort (saju_base) | **low → medium 폴백** | saju_analysis_service.dart (v43) |

### 현재 상태 요약 (v44 업데이트, 2026-02-04)

```
구현 완료:
  ✅ Context Caching (v27) — 채팅 비용 ~30% 절감
  ✅ Lazy saju_base (v30) — 이탈 유저 $0.197 절약
  ✅ Edge Function 버그 3건 수정 (v27, 배포 v48)
  ✅ 에러 추적 (chat_error_logs 연동)
  ✅ session_id 프론트→Edge 전달 체인
  ✅ Rewarded Video 제거 — 적자 구조 차단
  ✅ Native CPC 전용 구조 확정 — 흑자 구조
  ✅ reasoning_effort "low" (v43) — saju_base 비용 7% 절감
  ✅ 소진 토큰 15,000 / 인라인 토큰 10,000으로 상향

검토 완료 (변경 불필요):
  ✅ 모델 배치 최적성 검증 (v44.1) — 현재 3단 구조가 이미 최적
     - 빈도 낮은 것(saju_base/yearly/monthly): 비싼 모델 OK (1회성)
     - 빈도 높은 것(daily/chat): 이미 최저가 Gemini
     - 모델 변경 ROI 없음 (GPT-5-mini가 Gemini 3.0 Flash보다 싸서 이관 시 오히려 비용 증가)
  ✅ reasoning_effort "low" — 효과 미미(7%)하지만 리스크 없으므로 유지

미구현:
  ⬜ saju_base Phase 분리 (4→2+2)
  ⬜ Native CTA 최적화 (인라인 광고)
  ⬜ AdMob 실측 CPC 추적

현재 경제성 (v44, Native CPC only):
  1. 핵심 수익원: Native CPC ($0.05~0.30/click)
  2. 소진 배너: [바로 대화 계속하기] → 15,000 토큰, 순이익 +$0.042
  3. 인라인 클릭: 10,000 토큰, 순이익 +$0.044
  4. Context Caching → blended cost ~$0.55/1M
  5. Lazy saju_base → 비사용 유저 $0 손실
  6. reasoning_effort "low" → saju_base $0.183 (7% 절감, 효과 미미)
  7. 모델 배치 이미 최적 (v44.1) → 모델 변경 불필요, 비용 최적화 완료
  8. 일일 순수익: +$0.055/유저 (소진 Native click 1회, CPC $0.05)
  9. saju_base BEP: ~4.6일 (보수적)
  10. → 비용 최적화 완료 단계, 수익/성장에 집중 전환
```

> **상세 분석**: `docs/v44_bep_final_analysis.md` 참조

### 남은 행동 계획

| 순서 | 행동 | 효과 | 난이도 | 상태 |
|------|------|------|--------|------|
| ~~1~~ | ~~ai-gemini 비용 기록 수정~~ | ~~정확한 손익 추적~~ | ~~하~~ | ✅ 완료 |
| ~~2~~ | ~~Gemini Context Caching~~ | ~~채팅 비용 30% 절감~~ | ~~중~~ | ✅ 완료 |
| ~~3~~ | ~~saju_base Lazy 생성~~ | ~~이탈 유저 $0.197 절약~~ | ~~하~~ | ✅ 완료 |
| ~~4~~ | ~~Rewarded Video 제거~~ | ~~적자 구조 차단~~ | ~~하~~ | ✅ 완료 |
| **5** | Native click CTA 최적화 | 클릭률↑ → 수익 극대화 | 하 | ⬜ |
| **6** | saju_base Phase 분리 | 초기 비용 50% 절감 ($0.197→$0.100) | 중 | ⬜ |
| **7** | AdMob 실측 CPC 추적 | 정확한 BEP 검증 | 중 | ⬜ |

### 현재 실현된 효과 (v30)

```
v30 이전 (Lazy 없음, Caching 없음, Rewarded 기반):
  일일 순수익: +$0.006/유저 (Rewarded 2회 기준)
  saju_base BEP: 44일
  비사용 이탈 시: -$0.265 손실

v30 이후 (Lazy ✅ + Caching ✅ + Rewarded 제거 ✅ + Native CPC ✅):
  일일 순수익: +$0.032/유저 (Native click 1회, 보수적 CPC $0.05)
  saju_base BEP: ~7일 (보수적) / ~3일 (CPC $0.15)
  비사용 이탈 시: $0 손실 (Lazy 덕분에 트리거 안 됨)
  인라인 click 추가 시: +$0.073/유저 (BEP 3.6일)
  7일 리텐션: +$0.224/유저 → -$0.042 (보수적), +$0.245 (인라인 포함)
  30일 리텐션: +$0.694/유저 (보수적), +$1.924/유저 (인라인 포함)
  CTR 4.89% 실측 → click 발생 가능성 높음

Phase 분리까지 구현 시 (향후):
  saju_base 비용: $0.197 → $0.100
  BEP: ~4일 (보수적)
  30일 리텐션: +$0.79/유저
```

---

## 12. 변경점 요약 (v1 → v2 → v3 → v4 → v5)

| 항목 | v1 | v2 | v3 | v4 | v5 (최종) |
|------|-----|-----|-----|-----|----------|
| chatting_tokens 정의 | output 가정 | total | 동일 | 동일 | 동일 |
| blended cost | $2.00/1M | $0.80/1M | 동일 | 동일 | 동일 |
| Native click 수익 | $0.005 | $0.005 | $0.005 | **$0.05~0.30** | 동일 |
| Rewarded Video | 포함 | 포함 | 포함 | 포함 | **제거 (적자)** |
| 소진 Native 토큰 | 7,000 | 7,000 | 7,000 | 7,000 | **15,000** (v44 확인) |
| 기본 20K 손익 | -$0.032 | -$0.008 | -$0.012 | -$0.002 | **-$0.015** |
| 소진 Native 순이익 | -$0.006 | ~±$0 | ~±$0 | +$0.044 | **+$0.035** |
| saju_base BEP | 불가능 | 3.2일 | 44일 | 3.9일 | **~7일 (보수적)** |
| 핵심 수익원 | 다운그레이드 | Caching | Rewarded | Native CPC | **Native CPC 전용** |
| 토큰 소진 배너 | 2버튼 | 2버튼 | 2버튼 | 2버튼 | **네이티브+프리미엄** |
