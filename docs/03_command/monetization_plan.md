user_daily_token_usage# 만톡 수익화 계획 (2026-02-01)

## 목표: 무료 사용자 광고 수익 > AI 비용 (흑자)

---

## 1. 실제 DB 데이터 기반 현황

### 1.1 메시지당 토큰 (chat_messages 실측)

| 항목 | 값 |
|------|-----|
| 평균 tokens_used/메시지 | **7,460** |
| 중앙값 | 8,045 |
| P90 | 12,242 |
| 최소 | 1,785 |
| 최대 | 17,173 |

### 1.2 일반 사용자 일일 chatting_tokens 분포 (quota=50,000)

| 토큰 구간 | 사용자·일 수 | 평균 메시지 수 |
|-----------|------------|--------------|
| 0-5K | 4 | 1 |
| 5K-10K | 5 | 3 |
| 10K-15K | 5 | 4 |
| 20K-30K | 1 | 7 |
| 30K-50K | 1 | 5 |
| 50K+ (초과) | 5 | 36 |

**핵심 인사이트**: 대부분 사용자는 **일 1~4개 메시지** (5K-15K 토큰)로 충분.
50K 초과 5건은 quota 체크 미적용 시점 또는 admin 계정 추정.

### 1.3 세션별 메시지 수

| 세션 메시지 수 | 세션 수 | 비율 |
|---------------|---------|------|
| 1-5 | 31 | **74%** |
| 6-10 | 5 | 12% |
| 11-15 | 2 | 5% |
| 16-20 | 1 | 2% |
| 20+ | 3 | 7% |

**핵심**: 74%의 세션이 5개 이하 메시지. 대부분 짧은 대화.

### 1.4 현재 광고 실적

| 광고 유형 | 이벤트 | 횟수 |
|-----------|--------|------|
| Native | impression | 473 |
| Native | click | 14 (CTR 2.96%) |
| Interstitial | show/complete | 26 |
| Rewarded | show/complete | 19 |
| Rewarded | rewarded (토큰 지급) | 21 (avg 3,812 tokens) |

### 1.5 실제 AI 가격 (2026-02 기준)

| 모델 | Input | Output | 용도 |
|------|-------|--------|------|
| GPT-5.2 | $1.75/1M | $14.00/1M | 사주 분석 (캐시됨) |
| Gemini 3.0 Flash | $0.50/1M | $3.00/1M | 채팅 대화 |
| Gemini 2.5 Flash Lite | $0.10/1M | $0.40/1M | 의도 분류 |

---

## 2. daily_quota 최적화

### 2.1 현재 문제: 50,000이 너무 높음

```
메시지당 평균 7,460 tokens
50,000 / 7,460 = 약 6.7개 메시지 (무료)

비용: 50,000 tokens × Gemini 3.0 Flash
  = Input ~40,000 × $0.50/1M + Output ~10,000 × $3.00/1M
  = $0.020 + $0.030 = $0.050/day

이 $0.050을 광고로 커버하려면:
  Native eCPM $5 기준 → 10회 impression 필요
  BUT 6.7개 메시지 / interval 5 = 1.3회 native ad
  → 수익 $0.005~$0.008 << 비용 $0.050
  → 적자
```

### 2.2 적정 quota 계산 (역산)

**목표**: 무료 사용자 광고 수익 ≥ AI 비용

```
Native Ad eCPM (한국 시장 현실적): $5~$10
Native 1회 수익: $0.005~$0.010

광고 수익을 최대화하려면:
  - 메시지 수를 어느 정도 보장해야 native ad 노출 기회 확보
  - 너무 적으면 사용자 이탈 (UX 문제)
  - 너무 많으면 비용 초과

최적 밸런스 포인트:
  - 무료 메시지: 3~4개 → native ad 1~2회
  - 토큰: 3 × 7,460 = 22,380 → 약 20,000~25,000
```

### 2.3 추천: daily_quota = 20,000

| 항목 | 값 | 근거 |
|------|-----|------|
| **daily_quota** | **20,000** | 약 2~3개 메시지 무료 |
| 무료 메시지 수 | 2.7개 (20,000 ÷ 7,460) | 사주 질문 2~3개 가능 |
| AI 비용 | **$0.020/day** | Input 16K×$0.50 + Output 4K×$3.00 |
| Native Ad 횟수 | 1회 (interval 3일 때) | 메시지 3개 후 1회 |
| Native 수익 | $0.005~$0.010 | eCPM $5~10 |
| **일일 손익** | **-$0.010~-$0.015** | 아직 적자이지만 폭 최소화 |

→ quota 20,000만으로는 흑자 어려움. **광고 전략 병행 필수**.

---

## 3. 광고 전략: Native 중심 (Rewarded 최소화)

### 3.1 Native Ad 최적화

사용자가 짜증나지 않으면서 자연스럽게 수익 내는 방법.

#### (A) 채팅 내 Native Ad 빈도 증가

| 설정 | 현재 | 변경 | 이유 |
|------|------|------|------|
| `inlineAdMessageInterval` | 5 | **3** | 메시지 3개마다 native |
| `inlineAdMinMessages` | 5 | **2** | 2번째 메시지 후부터 |
| `inlineAdMaxCount` | 10 | **5** | 세션당 최대 5회 |

#### (B) 채팅 외 Native Ad 배치 (신규)

| 위치 | 빈도 | eCPM 기대 |
|------|------|----------|
| **홈 화면** (운세 카드 사이) | 앱 실행시 1회 | $5~10 |
| **운세 결과 하단** (일운/월운/연운) | 결과 조회시 1회 | $5~15 (관심도 높음) |
| **사주 상세 페이지** | 페이지 진입시 1회 | $5~10 |
| **인연 관계도** | 리스트 사이 1회 | $3~8 |

**기대 효과**: 채팅 외 native 3~5회/day 추가 → +$0.015~$0.050/day

#### (C) Native Ad 클릭율 향상

| 전략 | 구현 | 기대 CTR |
|------|------|----------|
| **콘텐츠 매칭** | 운세 관련 광고 카테고리 필터 | 5~8% |
| **자연스러운 디자인** | 채팅 버블과 유사한 카드 형태 | 4~6% |
| **CTA 텍스트** | "더 알아보기", "무료 상담" 등 | 3~5% |
| 현재 CTR | - | 2.96% |

### 3.2 Rewarded Ad: 최소한으로

**원칙**: 사용자가 **자발적으로 선택**할 때만.

| 상황 | 현재 | 변경 |
|------|------|------|
| Token 80% warning | Rewarded 팝업 | **제거** → Native만 |
| Token 100% depleted | 강제 Rewarded | **선택적** → "광고 보고 3개 더 대화" 버튼 |
| Server 429 | 강제 Rewarded | **선택적** → "오늘의 추가 대화" 버튼 |
| Feature unlock | Rewarded | 유지 (유저가 원해서 보는 것) |

### 3.3 Interstitial: 전략적 사용

| 상황 | 빈도 | eCPM |
|------|------|------|
| **세션 종료 시** (채팅 나갈 때) | 하루 최대 2회 | $10~20 |
| **운세 결과 로딩 중** (자연스러운 대기) | 분석당 1회 | $10~20 |
| ~~채팅 중 강제 삽입~~ | ~~X~~ | ~~짜증~~ |

---

## 4. 보너스 토큰 재설계

### 4.1 현재 문제

| 항목 | 현재 | 문제점 |
|------|------|--------|
| warningRewardTokens | 5,000 | 80% 도달 시 → 너무 관대 |
| depletedRewardTokens | 10,000 | 100% 도달 시 → 거의 무제한 확장 |
| intervalRewardTokens | 2,000 | Native 클릭 시 → 의미 없음 (클릭 안 함) |

### 4.2 변경안

| 항목 | 변경 | 근거 |
|------|------|------|
| **warningRewardTokens** | 삭제 (warning 자체 삭제) | Native로 대체 |
| **depletedRewardTokens** | **3,000** (10,000→3,000) | 메시지 0.4개분. 짧은 마무리 대화 가능 |
| **intervalRewardTokens** | **0** (2,000→0) | Native 클릭 보상 제거 (광고 자체가 보상) |
| **일일 보너스 상한** | **6,000** (신규) | 하루 최대 보너스 2회까지 |

### 4.3 Bonus 토큰의 서버 반영 (버그 수정)

현재 bonus는 client-side ConversationWindowManager만 확장.
Server-side daily_quota에는 반영 안 됨 → 429 무한루프.

**수정 필요**:
```
광고 시청 완료
  → addBonusTokens(3,000) [client-side]
  → Supabase RPC: increase_daily_quota(user_id, 3,000) [server-side]
  → daily_quota += 3,000 (20,000 → 23,000)
```

또는 `daily_quota` 대신 `bonus_tokens` 컬럼 추가:
```sql
is_quota_exceeded = chatting_tokens >= (daily_quota + COALESCE(bonus_tokens, 0))
```

---

## 5. 수정된 수익 시뮬레이션

### 5.1 무료 사용자 1인 1일

#### Scenario A: 가벼운 사용자 (메시지 2~3개)

```
[메시지 1] 질문 → AI 응답 (7,460 tokens)
[메시지 2] 후속 질문 → AI 응답 (7,460 tokens)
  → 여기서 Native Ad 1회 (interval=3이면 메시지 2 후)
[메시지 3] 마무리 → AI 응답 (7,460 tokens)
  → quota 도달 (22,380/20,000) → "오늘의 무료 대화가 끝났습니다"

비용: $0.020 (Gemini)
수익: Native 1회 = $0.005~$0.010
      + 홈 Native 1회 = $0.005~$0.010
      + 운세 결과 Native 1회 = $0.005~$0.010
      = $0.015~$0.030

손익: -$0.005 ~ +$0.010
```

#### Scenario B: 적극적 사용자 (메시지 3개 + 광고로 추가)

```
[메시지 1~3] → quota 도달
  → Native Ad 1회
  → "광고 보고 대화 더 하기" 선택
  → Rewarded Ad 1회 → +3,000 tokens → 메시지 0.4개
[메시지 4] 짧은 마무리 → 완전 종료

비용: $0.027 (23,000 tokens)
수익: Native 1회 (채팅) = $0.005~$0.010
      + Rewarded 1회 = $0.010~$0.030
      + 채팅 외 Native 2~3회 = $0.010~$0.030
      = $0.025~$0.070

손익: -$0.002 ~ +$0.043
```

#### Scenario C: Feature Unlock 사용자

```
[사주 상세 조회] → Feature Unlock Ad (Rewarded)
[월운 조회] → Feature Unlock Ad (Rewarded)
[일반 채팅 3개] → Native 1회

비용: $0.020 (채팅) + 운세는 캐시됨 = $0.020
수익: Feature Rewarded 2회 = $0.020~$0.060
      + Native 2~3회 = $0.010~$0.030
      = $0.030~$0.090

손익: +$0.010 ~ +$0.070
```

### 5.2 전체 사용자 가중 평균 (예상)

| 사용자 유형 | 비율 | 일 손익 |
|------------|------|---------|
| 가벼운 사용자 (1~3 msg) | 65% | +$0.003 |
| 적극적 사용자 (3+ msg + ad) | 25% | +$0.020 |
| Feature 활용 사용자 | 10% | +$0.040 |
| **가중 평균** | 100% | **+$0.009/user/day** |

### 5.3 규모별 월 수익 예측

| DAU | 월 수익 | 월 비용 | 월 손익 |
|-----|---------|---------|---------|
| 22 (현재) | $5.94 | $13.20 | -$7.26 |
| 100 | $27.00 | $60.00 | -$33.00 |
| 500 | $135.00 | $300.00 | -$165.00 |
| 1,000 | $270.00 | $600.00 | -$330.00 |

→ **Native 광고만으로는 완전 흑자 어려움**. 하지만 적자 폭을 최소화.

---

## 6. 흑자 달성 전략 (순차적 로드맵)

### Phase 1: 즉시 수정 (비용 절감 + 버그 수정)

| # | 작업 | 효과 | 파일 |
|---|------|------|------|
| 1-1 | **daily_quota 50,000 → 20,000** | 비용 60% 절감 | DB migration |
| 1-2 | **inlineAdMessageInterval 5 → 3** | Native 노출 50% 증가 | `ad_strategy.dart` |
| 1-3 | **inlineAdMinMessages 5 → 2** | 첫 광고 더 빨리 | `ad_strategy.dart` |
| 1-4 | **depletedRewardTokens 10,000 → 3,000** | 보너스 비용 70% 절감 | `ad_trigger_service.dart` |
| 1-5 | **warningRewardTokens 5,000 → 0** (80% 경고 제거) | Rewarded 빈도 감소 | `ad_trigger_service.dart` |
| 1-6 | **429 bonus 서버 반영 버그 수정** | 무한루프 해결 | `chat_provider.dart` + DB |
| 1-7 | **Edge Function 가격 상수 수정** | 정확한 비용 추적 | `ai-openai-result`, `ai-gemini` |

### Phase 2: Native Ad 확장 (채팅 외 배치)

| # | 작업 | 기대 수익 | 파일 |
|---|------|----------|------|
| 2-1 | **홈 화면 Native Ad** | +$0.005~$0.010/day | 홈 화면 위젯 |
| 2-2 | **운세 결과 하단 Native Ad** | +$0.005~$0.010/day | 운세 결과 화면 |
| 2-3 | **사주 상세 Native Ad** | +$0.005/day | 사주 상세 화면 |
| 2-4 | **Interstitial: 세션 종료 시** (하루 2회) | +$0.020~$0.040/day | 채팅 종료 로직 |

### Phase 3: Feature Unlock (콘텐츠 게이팅)

| # | 기능 | 광고 유형 | 기대 |
|---|------|----------|------|
| 3-1 | **월운 첫 조회** → Rewarded Ad 필요 | Rewarded | 자발적 시청 |
| 3-2 | **연운 조회** → Rewarded Ad 필요 | Rewarded | 자발적 시청 |
| 3-3 | **궁합 분석** → Rewarded Ad 필요 | Rewarded | 자발적 시청 |
| 3-4 | 일운은 무료 유지 (매일 방문 유도) | - | 리텐션 |

### Phase 4: 프리미엄 구독 (확실한 흑자)

| 플랜 | 가격 | 혜택 | 손익 |
|------|------|------|------|
| **무료** | ₩0 | 일 3 메시지 + 광고 | ±$0 |
| **베이직** | ₩2,900/월 | 일 10 메시지 + 광고 감소 | +₩2,500/월 |
| **프리미엄** | ₩5,900/월 | 무제한 + 광고 없음 | +₩4,000/월 |
| **일일 패스** | ₩500/회 | 24시간 무제한 | +₩350/회 |

---

## 7. Phase 1 상세 구현 계획

### 7.1 DB Migration: daily_quota 변경

```sql
-- 일반 사용자 daily_quota: 50,000 → 20,000
-- admin은 유지 (1,000,000,000)
ALTER TABLE user_daily_token_usage
  ALTER COLUMN daily_quota SET DEFAULT 20000;

-- 기존 일반 사용자 업데이트
UPDATE user_daily_token_usage
SET daily_quota = 20000
WHERE daily_quota = 50000;

-- bonus_tokens 컬럼 추가
ALTER TABLE user_daily_token_usage
  ADD COLUMN IF NOT EXISTS bonus_tokens int DEFAULT 0;

-- is_quota_exceeded 재정의: bonus_tokens 포함
-- (generated column 재생성 필요)
```

### 7.2 Client-side Window 동기화

```
ConversationWindowManager:
  _baseMaxInputTokens: 50,000 → 20,000

TokenCounter:
  defaultMaxInputTokens: 50,000 → 20,000
```

### 7.3 ad_strategy.dart 수정

```dart
// Before
static const int inlineAdMessageInterval = 5;
static const int inlineAdMinMessages = 5;

// After
static const int inlineAdMessageInterval = 3;
static const int inlineAdMinMessages = 2;
```

### 7.4 ad_trigger_service.dart 수정

```dart
// Before
static const int warningRewardTokens = 5000;
static const int depletedRewardTokens = 10000;
static const int intervalRewardTokens = 2000;
static const double tokenWarningThreshold = 0.8;

// After
static const int depletedRewardTokens = 3000;
static const int intervalRewardTokens = 0;    // Native 클릭 보상 제거
static const double tokenWarningThreshold = 1.0; // 80% warning 실질 비활성화
// (또는 tokenNearLimit 케이스 자체를 Native로 변경)
```

### 7.5 429 버그 수정

```dart
// chat_provider.dart - QUOTA_EXCEEDED 처리
if (errorMsg.contains('QUOTA_EXCEEDED')) {
  // AS-IS: 광고 보여주고 client-side bonus만 추가
  // TO-BE: 광고 시청 후 서버에도 bonus 반영

  // Supabase RPC 호출하여 bonus_tokens 증가
  await supabase.rpc('add_bonus_tokens', params: {
    'p_user_id': userId,
    'p_bonus': 3000,
  });
}
```

### 7.6 Edge Function 가격 수정

```typescript
// ai-openai-result/index.ts
const cost = (promptTokens * 1.75 / 1000000) + (completionTokens * 14.00 / 1000000);

// ai-gemini/index.ts
const cost = (promptTokens * 0.50 / 1000000) + (completionTokens * 3.00 / 1000000);
```

---

## 8. 최종 손익 시뮬레이션 (Phase 1~3 완료 후)

### 무료 사용자

```
비용:
  - 채팅: 20,000 tokens × Gemini 3.0 = $0.014/day
  - 운세: 캐시됨 = ~$0.002/day (분산)
  - 합계: $0.016/day

수익:
  - 채팅 내 Native: 1회 × $0.005 = $0.005
  - 채팅 외 Native: 2~3회 × $0.005 = $0.010~$0.015
  - Interstitial (세션 종료): 0.5회 × $0.015 = $0.008
  - Feature Unlock Rewarded: 0.3회 × $0.020 = $0.006
  - 합계: $0.029~$0.034

손익: +$0.013~$0.018/user/day ✅ 흑자
```

### DAU별 월 수익

| DAU | 월 수익 | 월 비용 | 월 손익 | 연 손익 |
|-----|---------|---------|---------|---------|
| 22 | $22.44 | $10.56 | **+$11.88** | +$142 |
| 100 | $102.00 | $48.00 | **+$54.00** | +$648 |
| 500 | $510.00 | $240.00 | **+$270.00** | +$3,240 |
| 1,000 | $1,020 | $480 | **+$540** | +$6,480 |
| 1,000 + 구독 10% | $1,020 + $590 | $630 | **+$980** | +$11,760 |

---

## 9. 핵심 정리

### 즉시 해야 할 것 (Phase 1)

1. **daily_quota: 50,000 → 20,000** (비용 60% 절감)
2. **Native interval: 5 → 3** (노출 증가)
3. **Rewarded bonus: 10,000 → 3,000** (보너스 70% 절감)
4. **80% warning 제거** (Rewarded 빈도 감소)
5. **429 무한루프 버그 수정** (서버 bonus 반영)
6. **Edge Function 가격 상수 수정** (정확한 추적)

### 하지 않는 것

- ❌ App Open Ad (UX 해침)
- ❌ 채팅 중 강제 Rewarded (짜증)
- ❌ Banner Ad (수익 낮고 못생김)
- ❌ 너무 공격적인 quota 제한 (5,000 이하는 사용자 이탈)

### 왜 20,000인가?

```
20,000 tokens = 약 2.7개 메시지

- 사주 질문 2~3개는 무료로 가능 (기본 UX 보장)
- 대부분 사용자(65%)가 이 범위 내에서 사용
- AI 비용 $0.014/day로 Native 광고 3~4회면 커버 가능
- 너무 적으면 (10,000 = 1.3개) → 사용자가 앱 가치를 못 느낌
- 너무 많으면 (30,000 = 4개) → 광고 수익으로 커버 불가
```

---

## 10. Phase 1 실행 결과 (2026-02-01)

### 10.1 적용된 변경사항

| # | 작업 | 적용 결과 | 파일 |
|---|------|----------|------|
| 1 | DB: `bonus_tokens` 컬럼 추가 | `INT DEFAULT 0` | Supabase migration |
| 2 | DB: `is_quota_exceeded` 재정의 | `chatting_tokens >= (daily_quota + COALESCE(bonus_tokens, 0))` | Supabase migration |
| 3 | DB: `add_bonus_tokens` RPC 생성 | `SECURITY DEFINER`, upsert 방식 | Supabase migration |
| 4 | DB: `daily_quota` 기본값 변경 | `50000 → 20000` | Supabase migration |
| 5 | ai-gemini: quota 체크에 bonus 포함 | `effectiveQuota = baseQuota + bonusTokens` | `ai-gemini/index.ts` v23 |
| 6 | ai-gemini: 가격 상수 수정 | 채팅 $0.50/$3.00, Intent $0.10/$0.40 | `ai-gemini/index.ts` |
| 7 | ai-openai: 가격 상수 수정 | $1.75/$14.00 | `ai-openai/index.ts` |
| 8 | ai-openai-result: 가격 상수 수정 | $1.75/$14.00 | `ai-openai-result/index.ts` |
| 9 | ai-openai/ai-gemini: DAILY_QUOTA 변경 | `50000 → 20000` | Edge Functions |
| 10 | chat_provider: 서버 bonus 반영 | `addBonusTokens()` → RPC `add_bonus_tokens` 호출 | `chat_provider.dart` |
| 11 | Native Ad: impression 보상 | impression 시 `adWatched=true` (1,500 tokens) | `conversational_ad_provider.dart` |
| 12 | Ad interval: 5 → 3 | `inlineAdMessageInterval = 3` | `ad_strategy.dart` |
| 13 | Ad minMessages: 5 → 2 | `inlineAdMinMessages = 2` | `ad_strategy.dart` |
| 14 | depletedRewardTokens: 10,000 → 3,000 | 소진 시 보너스 70% 절감 | `ad_trigger_service.dart` |
| 15 | warningRewardTokens: 5,000 → 0 | 80% warning 비활성화 | `ad_trigger_service.dart` |
| 16 | intervalRewardTokens: 2,000 → 500 | impression 보상과 통일 | `ad_trigger_service.dart` |
| 17 | Client token limit: 50,000 → 20,000 | `defaultMaxInputTokens` | `token_counter.dart` |

### 10.2 실제 적용된 가격

| 모델 | Input $/1M | Output $/1M | 용도 |
|------|-----------|------------|------|
| GPT-5.2 | $1.75 | $14.00 | 사주 분석 (캐시됨, 1회성) |
| Gemini 3.0 Flash | $0.50 | $3.00 | 채팅 대화 (스트리밍) |
| Gemini 2.5 Flash Lite | $0.10 | $0.40 | 의도 분류 |

### 10.3 실제 적용된 Quota/광고 설정

| 설정 | 값 |
|------|-----|
| daily_quota | 20,000 |
| inlineAdMessageInterval | 3 |
| inlineAdMinMessages | 2 |
| inlineAdMaxCount | 10 |
| depletedRewardTokens | 3,000 |
| warningRewardTokens | 0 (비활성화) |
| intervalRewardTokens | 500 |
| impressionRewardTokens | 1,500 |

---

## 11. Phase 2~4 로드맵 상태 (2026-02-01)

### Phase 2: Native Ad 확장 (채팅 외 배치) - 미구현

| # | 작업 | 상태 | 기대 수익 | 우선순위 | 구현 대상 파일 |
|---|------|------|----------|---------|--------------|
| 2-1 | 홈 화면 Native Ad (운세 카드 사이) | ⬜ 예정 | +$0.005~$0.010/day | 높음 | 홈 화면 위젯 (SH 담당) |
| 2-2 | 운세 결과 하단 Native Ad | ⬜ 예정 | +$0.005~$0.010/day | 높음 | 운세 결과 화면 (SH 담당) |
| 2-3 | 사주 상세 Native Ad | ⬜ 예정 | +$0.005/day | 중간 | 사주 상세 화면 |
| 2-4 | Interstitial: 세션 종료 시 (하루 2회) | ⬜ 예정 | +$0.020~$0.040/day | 높음 | 채팅 종료 로직 |

**Phase 2 기대 효과**: 채팅 외 Native 3~5회/day 추가 → +$0.015~$0.050/day

**구현 시 주의사항**:
- 홈 화면 Native는 운세 카드 리스트 사이에 자연스럽게 배치
- 운세 결과 하단은 콘텐츠 끝난 후 배치 (스크롤 유도)
- Interstitial은 세션 종료 시만 (채팅 중 강제 삽입 금지)
- AdMob 정책: 페이지당 Native 1개 권장 (3개 이하)

---

### Phase 3: Feature Unlock (콘텐츠 게이팅) - 미구현

| # | 기능 | 상태 | 광고 유형 | 기대 수익 | 구현 대상 |
|---|------|------|----------|----------|----------|
| 3-1 | 월운 첫 조회 → Rewarded Ad | ⬜ 예정 | Rewarded | $0.010~$0.030/회 | `feature_unlocks` 테이블 활용 |
| 3-2 | 연운 조회 → Rewarded Ad | ⬜ 예정 | Rewarded | $0.010~$0.030/회 | `feature_unlocks` 테이블 활용 |
| 3-3 | 궁합 분석 → Rewarded Ad | ⬜ 예정 | Rewarded | $0.010~$0.030/회 | `feature_unlocks` 테이블 활용 |
| 3-4 | 일운은 무료 유지 | ✅ 현재 무료 | - | 리텐션 유지 | 변경 없음 |

**Phase 3 원칙**: 사용자가 **자발적으로** 광고 시청 선택. 강제 아님.

**구현 시 참고**:
- `feature_unlocks` 테이블 이미 존재 (8건 데이터)
- `ad_events` 테이블에 `purpose: feature_unlock` 이미 지원
- UI: "광고 보고 열기" 버튼 → Rewarded Ad → 해금 기록 → 콘텐츠 표시
- 해금 만료: 연운=해당 연도말, 월운=해당 월말

---

### Phase 4: 프리미엄 구독 (확실한 흑자) - 미구현

| 플랜 | 가격 | 혜택 | 예상 손익 | 상태 |
|------|------|------|----------|------|
| **무료** | ₩0 | 일 2~3 메시지 + 광고 | ±$0 | ✅ 현재 적용 |
| **베이직** | ₩2,900/월 | 일 10 메시지 + 광고 감소 | +₩2,500/월 | ⬜ 예정 |
| **프리미엄** | ₩5,900/월 | 무제한 + 광고 없음 | +₩4,000/월 | ⬜ 예정 |
| **일일 패스** | ₩500/회 | 24시간 무제한 | +₩350/회 | ⬜ 예정 |

**Phase 4 구현 요소**:
- Google Play / App Store 인앱 결제 연동
- Supabase에 구독 상태 테이블 (`subscriptions`)
- 구독 사용자: `daily_quota` 대폭 상향 또는 무제한
- 광고 표시 조건에 구독 상태 체크 추가
- RevenueCat 또는 직접 구현 선택 필요

**구현 우선순위**: DAU 500+ 이후 도입 검토 (현재 DAU 22)

---

### 전체 Phase 진행 상태 요약

```
Phase 1: ✅ 완료 (2026-02-01)
  - daily_quota 20,000, 가격 수정, 429 버그 수정, 광고 설정 조정

Phase 2: ⬜ 미구현 (다음 우선순위)
  - 채팅 외 Native Ad 배치 → 적자 폭 최소화
  - 예상 추가 수익: +$0.015~$0.050/user/day

Phase 3: ⬜ 미구현
  - Feature Unlock (월운/연운/궁합 게이팅)
  - 예상 추가 수익: +$0.006~$0.020/user/day

Phase 4: ⬜ 미구현 (DAU 500+ 이후)
  - 프리미엄 구독 → 확실한 흑자
  - 예상: 구독자 10%면 +₩590/day (DAU 1,000 기준)
```
