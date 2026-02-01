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
| `native_tokens_earned` | Native 광고 보상 (impression/click) | `add_native_bonus_tokens` RPC |

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
│  ── 6메시지 도달 → 인터벌 Native 광고 (1회) ──                     │
│  교환 3: 유저 질문 → AI 응답 (~7,200 토큰 소비)                     │
│                                                                 │
│  누적: ~21,600 토큰 → quota 20,000 초과 → 소진!                   │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  [Phase B] 토큰 소진 → 2개 버튼 선택                               │
│                                                                 │
│  AI: "대화가 즐거웠어요! 토큰이 부족해서 잠시 쉬어야 할 것 같아요."     │
│                                                                 │
│  ┌──────────────────────────┐  ┌──────────────────────────┐     │
│  │ ▶ 영상 보고 대화 계속하기   │  │ ☐ 간단히 보고 조금 더 대화  │     │
│  │   (Rewarded Video)        │  │   (Native Ad)             │     │
│  │   +20,000 토큰 (≈3교환)   │  │   +7,000 토큰 (≈1교환)    │     │
│  └────────────┬─────────────┘  └────────────┬─────────────┘     │
│               │                              │                   │
│               ▼                              ▼                   │
│  [경로 1] Rewarded Video       [경로 2] Native Ad               │
│  - 15~30초 영상 시청 필수       - 광고 노출만으로 토큰 지급          │
│  - 끝까지 봐야 보상             - 클릭 불필요                      │
│  - trackRewarded() 호출        - _saveNativeBonusToServer() 호출  │
│  - → rewarded_tokens_earned    - → native_tokens_earned          │
│  - +20,000 토큰                - +7,000 토큰                     │
│  - 수익: $0.01~0.05            - 수익: $0.0005~0.002             │
│  - 비용: $0.003                - 비용: $0.001                    │
│  - 손익: +$0.007~+$0.047      - 손익: ≈본전                      │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│  [Phase C] 광고 후 대화 재개                                      │
│                                                                 │
│  "대화 재개 (+N 토큰 획득!)" 버튼 → 대화 계속                       │
│                                                                 │
│  Rewarded Video 선택 시: 3교환 추가 가능 → Phase A로 복귀           │
│  Native Ad 선택 시: 1교환 추가 → 바로 다시 소진 → Phase B로 복귀     │
│                                                                 │
│  ※ Native → 금방 소진 → Rewarded Video 자연 유도 (의도된 설계)      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. 인터벌 광고 (대화 중 Native Ad)

대화 중간에 자연스럽게 삽입되는 Native 광고.

### 트리거 조건
- `messageCount >= 4` (2번째 교환 후부터)
- `messageCount % 4 == 0` (매 2교환마다)
- 토큰 소진 트리거보다 **우선순위 낮음** (토큰 체크 먼저)

### 토큰 보상
| 이벤트 | 토큰 | DB 컬럼 |
|--------|------|---------|
| Impression (노출) | 0 (미지급) | - |
| Click (클릭) | **+7,000** | `native_tokens_earned` |
| **합계 (노출만)** | **0** | |
| **합계 (클릭 시)** | **7,000** (≈1교환) | |

### 설정값 (`ad_strategy.dart`)
```
inlineAdMessageInterval = 4   (매 2교환마다)
inlineAdMinMessages = 4        (2교환 후 시작)
inlineAdMaxCount = 9999        (세션당 제한 없음)
```

---

## 4. 토큰 소진 광고 (Depleted)

토큰 100% 소진 시 표시. 필수 광고 (스킵 불가).

### Rewarded Video (영상 광고)
| 항목 | 값 |
|------|-----|
| 보상 토큰 | **20,000** (≈3교환) |
| DB 컬럼 | `rewarded_tokens_earned` |
| 저장 방식 | `trackRewarded()` → `incrementDailyCounter` |
| AdMob 수익 | eCPM $10~50 → **$0.01~0.05/회** |
| API 비용 | 3교환 × $0.001 = **$0.003** |
| **순이익** | **+$0.007 ~ +$0.047** |

### Native Ad (네이티브 광고)
| 항목 | 값 |
|------|-----|
| 보상 토큰 | **7,000** (≈1교환) |
| 보상 조건 | **클릭 시에만** (노출만으로는 미지급) |
| DB 컬럼 | `native_tokens_earned` |
| 저장 방식 | `_onAdClicked()` → `_saveNativeBonusToServer()` → `add_native_bonus_tokens` RPC |
| AdMob 수익 (노출만) | eCPM $0.50~2.00 → **$0.0005~0.002/회** (토큰 0 → **순이익**) |
| AdMob 수익 (클릭 시) | CPC $0.05~0.30 → 추가 수익 |
| API 비용 (클릭 시) | 1교환 × $0.001 = **$0.001** |
| **순이익 (노출만)** | **+$0.0005~+$0.002 (100% 이익)** |
| **순이익 (클릭 시)** | **+$0.05~+$0.30 (고수익)** |

---

## 5. 수익 시뮬레이션: 일반 유저 1일 세션

### 시나리오: 10교환 대화 (약 20분)

```
[무료] 교환 1~3: 20,000 토큰 소비 (비용 $0.003, 수익 $0)
  └─ 인터벌 Native 1회 (수익 $0.0005~0.002)

[소진] Native 선택 → +7,000 토큰
  └─ 교환 4: 7,000 토큰 소비 (비용 $0.001, 수익 $0.0005)

[소진] Rewarded Video 선택 → +20,000 토큰
  └─ 교환 5~7: 20,000 토큰 소비 (비용 $0.003, 수익 $0.025)
  └─ 인터벌 Native 1회 (수익 $0.0005~0.002)

[소진] Rewarded Video 선택 → +20,000 토큰
  └─ 교환 8~10: 20,000 토큰 소비 (비용 $0.003, 수익 $0.025)
  └─ 인터벌 Native 1회 (수익 $0.0005~0.002)
```

| 항목 | 값 |
|------|-----|
| 총 교환 수 | 10 |
| 총 토큰 소비 | ~67,000 |
| GPT-5.2 분석 (1회) | -$0.02 |
| Gemini 비용 (10교환) | -$0.010 |
| Rewarded Video × 2 | +$0.050 |
| Native (소진) × 1 | +$0.001 |
| Native (인터벌) × 3 | +$0.003 |
| **일일 순이익** | **+$0.024** |

### 핵심 인사이트
- **GPT-5.2 분석은 세션당 1회** (고정비 ~$0.02)
- **Gemini Flash는 교환당 ~$0.001** (매우 저렴)
- **Rewarded Video 1회 수익($0.025)이 10교환 Gemini 비용($0.01)보다 큼**
- **→ Rewarded Video 1번만 보면 그 세션은 흑자**

---

## 6. 광고 제거 구매자 (IAP)

| 구분 | 무료 유저 | 광고 제거 구매자 |
|------|----------|----------------|
| 인터벌 Native | O | **X (차단)** |
| 80% 경고 | 비활성 (warningRewardTokens=0) | **X (차단)** |
| 토큰 소진 Rewarded Video | O | **O (유저 선택, 강제 아님)** |
| 토큰 소진 Native | O | **X (차단)** |

광고 제거 구매자도 토큰 소진 시 **본인이 원하면** Rewarded Video를 시청해 토큰 충전 가능 (강제 X).

---

## 7. DB 토큰 추적 경로

```
┌──────────────────────┐     ┌──────────────────────────────────┐
│  Rewarded Video       │     │  Native Ad                       │
│  (영상 끝까지 시청)    │     │  (노출 or 클릭)                   │
└──────────┬───────────┘     └──────────┬───────────────────────┘
           │                            │
           ▼                            ▼
  trackRewarded()              _saveNativeBonusToServer()
           │                            │
           ▼                            ▼
  incrementDailyCounter        add_native_bonus_tokens RPC
  ('rewarded_tokens_earned')            │
           │                            ▼
           ▼                   native_tokens_earned += N
  rewarded_tokens_earned += N           │
           │                            │
           ▼                            ▼
  ┌─────────────────────────────────────────────────────┐
  │  is_quota_exceeded (GENERATED 컬럼)                  │
  │  = chatting_tokens >= (daily_quota                   │
  │    + bonus_tokens                                    │
  │    + rewarded_tokens_earned                          │
  │    + native_tokens_earned)                           │
  └─────────────────────────────────────────────────────┘
           │
           ▼
  Edge Function quota 체크 (ai-gemini, ai-openai)
  → 동일 공식으로 4개 컬럼 합산
```

---

## 8. 코드 위치 참조

| 역할 | 파일 | 핵심 상수/메서드 |
|------|------|----------------|
| 광고 전략 설정 | `ad/ad_strategy.dart` | `inlineAdMessageInterval`, `inlineAdMaxCount` |
| 토큰 트리거 로직 | `saju_chat/data/services/ad_trigger_service.dart` | `checkTrigger()`, `depletedRewardTokensVideo/Native` |
| 광고 상태 관리 | `saju_chat/presentation/providers/conversational_ad_provider.dart` | `onAdImpression`, `_saveNativeBonusToServer` |
| 채팅 토큰 관리 | `saju_chat/presentation/providers/chat_provider.dart` | `addBonusTokens()` |
| 광고 UI | `saju_chat/presentation/widgets/conversational_ad_widget.dart` | `_buildTokenDepletedChoice()` |
| Gemini quota 체크 | `supabase/functions/ai-gemini/index.ts` | `checkAndUpdateQuota()` |
| OpenAI quota 체크 | `supabase/functions/ai-openai/index.ts` | `checkAndUpdateQuota()` |
| 광고 설정값 | `ad/ad_config.dart` | `AdUnitId`, `AdMode` |
| DB RPC | Supabase Migration | `add_ad_bonus_tokens`, `add_native_bonus_tokens` |

---

## 9. 설정값 요약 (현재)

| 상수 | 값 | 위치 |
|------|-----|------|
| `daily_quota` | 20,000 | Edge Function + DB default |
| `depletedRewardTokensVideo` | 20,000 | `ad_trigger_service.dart` |
| `depletedRewardTokensNative` | 7,000 (클릭 시에만) | `ad_trigger_service.dart` |
| `impressionRewardTokens` | 0 (노출 보상 없음) | `ad_trigger_service.dart` |
| `intervalClickRewardTokens` | 7,000 (클릭 시에만) | `ad_trigger_service.dart` |
| `inlineAdMessageInterval` | 4 | `ad_strategy.dart` |
| `inlineAdMinMessages` | 4 | `ad_strategy.dart` |
| `inlineAdMaxCount` | 9999 | `ad_strategy.dart` |
| `tokenWarningThreshold` | 0.8 (비활성) | `ad_trigger_service.dart` |
| `tokenDepletedThreshold` | 1.0 | `ad_trigger_service.dart` |
| 토큰 리셋 시간 | KST 00:00 | Edge Function (`getTodayKST()`) |
