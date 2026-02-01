# 광고 시스템 (Ad System) - DK 담당

> 최종 업데이트: 2026-02-01

---

## 1. 토큰 할당 현황

### Supabase (`user_daily_token_usage`)

| 항목 | 값 |
|------|------|
| 일일 기본 토큰 (daily_quota) | **50,000** |
| 세션당 기본 토큰 (클라이언트) | **50,000** (`TokenCounter.defaultMaxInputTokens`) |
| 출력 안전 마진 | **18,000** (`TokenCounter.safetyMargin`) |
| 관리자 토큰 한도 | 1,000,000,000 (무제한) |
| 일일 할당량 초과 유저 비율 | 약 5% (285건 중 15건) |

### 캐싱 현황 (GPT-5.2 비용 통제)

| 분석 타입 | 프로필당 호출 | 만료 | 건당 비용 | 총 비용 |
|----------|-------------|------|----------|---------|
| `saju_base` (평생운세) | **1.0회** | 영구 | $0.08 | $4.19 |
| `yearly_fortune_2026` | **1.0회** | 2026-12-31 | $0.019 | $3.17 |
| `yearly_fortune_2025` | **1.0회** | 영구 | $0.018 | $1.52 |
| `monthly_fortune` | **1.0회** | 월말 | $0.018 | $2.93 |
| `daily_fortune` | **1.0회** | 24시간 | $0.004 | $1.40 |

> 캐싱 정상 작동 중. 기존 유저 추가 API 비용 거의 $0.

---

## 2. 광고 타입별 구조

### 트리거 → 광고 타입 매핑

| 트리거 | 조건 | 광고 타입 | 보상 토큰 | 토큰 지급 조건 | 스킵 |
|--------|------|----------|----------|--------------|------|
| `tokenDepleted` | 토큰 100% 소진 | **보상형 영상** | **10,000** | 영상 시청 완료 | 불가 |
| `tokenNearLimit` | 토큰 80%+ | **보상형 영상** | **5,000** | 영상 시청 완료 | 가능 |
| `intervalAd` | 5번째 메시지마다 | **네이티브** | **2,000** | **광고 클릭** | 가능 |

### 유저 화면 흐름

**보상형 광고 (tokenDepleted / tokenNearLimit)**
```
AI: "대화가 즐거웠어요! 광고를 보시면 더 대화할 수 있어요."
[🎁 광고 시청 후 대화를 계속할 수 있어요. +5000]  [건너뛰기*]
  → CTA 클릭 → 전체화면 영상 → 시청 완료 → 토큰 지급 → 대화 재개
  (* tokenDepleted는 건너뛰기 없음)
```

**네이티브 광고 (intervalAd)**
```
AI: "참, 추천해드리고 싶은 게 있어요.
     광고를 클릭하면 AI와 더 대화할 수 있어요!"
                                        [건너뛰기]
┌──────────────────────────┐
│     [네이티브 광고]        │  ← 여기를 클릭해야 토큰!
└──────────────────────────┘
  → 광고 클릭 → 토큰 지급 → [대화 재개] 버튼 표시
  → 건너뛰기 → 토큰 없이 대화 재개
```

---

## 3. 페이지 전환 전면광고 (Interstitial Ad)

> 2026-02-01 추가

### 전면광고 배치 위치

| 페이지 | 파일 | 라우트 |
|--------|------|--------|
| 평생운세 | `fortune_category_list.dart` | `/fortune/traditional-saju` |
| 2025운세 | `fortune_category_list.dart` | `/fortune/yearly-2025` |
| 2026운세 | `fortune_category_list.dart` | `/fortune/new-year` |
| 한달운세 | `fortune_category_list.dart` | `/fortune/monthly` |
| AI 상담 | `main_scaffold.dart` | `/saju/chat` (하단 네비 탭) |

### 구현 방식

```dart
// fortune_category_list.dart (운세 카테고리 4개)
onTap: () async {
  await AdService.instance.showInterstitialAd();
  if (context.mounted) {
    context.push(route);
  }
}

// main_scaffold.dart (AI 상담 탭)
case 2:
  await AdService.instance.showInterstitialAd();
  if (context.mounted) {
    context.go(Routes.sajuChat);
  }
```

### 메인 화면 네이티브 광고

| 위치 | 상태 | 비고 |
|------|------|------|
| 운세 카테고리 아래 (광고 #1) | ✅ 유지 | 스크롤 없이 바로 보임 |
| 내 사주 카드 아래 (광고 #2) | ❌ 제거 | 스크롤 필요, 중복 노출 |

---

## 4. 인라인 광고 설정 (`AdStrategy`)

| 설정 | 값 | 설명 |
|------|------|------|
| `inlineAdMessageInterval` | **5** | 5번째 메시지마다 (약 2.5번 대화) |
| `inlineAdMaxCount` | **10** | 세션당 최대 10회 |
| `inlineAdMinMessages` | **5** | 최소 5개 메시지 후 첫 광고 |
| `chatAdType` | nativeMedium | 채팅 버블 스타일 |

### interval 타이밍 (유저+AI 메시지 합산)

```
메시지 1~4: 광고 없음 (대화하는 느낌)
메시지 5:   첫 번째 광고 (2~3번 대화 후)
메시지 10:  두 번째 광고
메시지 15:  세 번째 광고
메시지 20:  네 번째 광고
→ 세션당 3~4회, 초반 폭격 없이 자연스러운 빈도
```

---

## 5. AI 모델 비용 비교

| 모델 | Input/1M | Output/1M | 세션당 비용 | 비고 |
|------|---------|----------|-----------|------|
| **Gemini 3.0 Flash** (현재) | $0.50 | $3.00 | ~$0.075 | 채팅 사용 |
| Gemini 2.5 Flash | $0.15 | $0.60 | ~$0.017 | 4.4x 저렴 |
| Gemini 2.5 Flash-Lite | $0.10 | $0.40 | ~$0.011 | 6.8x 저렴 |
| **GPT-5.2** | - | - | ~$0.08/건 | **비용의 99%** (사주 분석) |

> Gemini 3.0 Lite는 존재하지 않음. Lite는 Gemini 2.5 Flash-Lite만 있음.
> GPT-5.2 비용은 캐싱으로 통제됨 (프로필당 1회만 호출).

---

## 6. 수익/비용 실적 (Supabase 실데이터)

### 변경 전 (7일간)

| 날짜 | 유저수 | API 비용 | Native 노출 | Native 클릭 | 보상형 완료 | 추정 수익 | 손익 |
|------|--------|---------|------------|------------|-----------|----------|------|
| 1/30 | 15 | $2.02 | 144 | 2 | 7 | ~$0.50 | **-$1.52** |
| 1/25 | 32 | $1.81 | 181 | 3 | 2 | ~$0.40 | **-$1.41** |
| 1/23 | 14 | $2.16 | 12 | 0 | 0 | ~$0.01 | **-$2.15** |

### 변경 후 예상 (15명/일 기준)

| 항목 | 변경 전 | 변경 후 | 변화 |
|------|--------|--------|------|
| Native impression 수익 | $0.29 | $0.11 | 빈도 조정 |
| Native click 수익 | $0.40 | $0.84 | **클릭 인센티브 효과** |
| Rewarded (depleted) | $0.21 | $0.08 | 유지 |
| Rewarded (nearLimit) | $0.00 | **$0.08** | **신규 추가** |
| **총 수익** | **~$0.90** | **~$1.11** | **+23%** |
| API 비용 | $2.02 | $2.02 | 동일 |
| **손익** | **-$1.12** | **-$0.91** | 적자 축소 |

### 손익분기 조건

- 현재 15명 → 적자 ~$0.91/일
- **유저 40명+** 도달 시 손익분기 예상
- 클릭률이 8% → 15%로 오르면 25명에서 손익분기 가능
- Firebase A/B 테스트로 interval 최적화 권장

---

## 7. 변경 이력

### 2026-02-01: 광고 시스템 대폭 개편

**1. 페이지 전환 전면광고 추가**

| 파일 | 변경 |
|------|------|
| `fortune_category_list.dart` | 4개 운세 페이지 이동 시 `AdService.showInterstitialAd()` 호출 |
| `main_scaffold.dart` | AI 상담 탭 클릭 시 `AdService.showInterstitialAd()` 호출 |
| `menu_screen.dart` | 하단 네이티브 광고 #2 제거 (중복 노출 방지) |

**2. 채팅 내 광고 빈도 조정**

| 설정 | 변경 전 | 변경 후 |
|------|--------|--------|
| `inlineAdMessageInterval` | 5 (2.5왕복) | **10 (5왕복)** |
| `inlineAdMinMessages` | 5 | **10** |
| `interstitialMinInterval` | 60초 | **30초** |

**3. 토큰 보상 구조 개편 (왕복 기준)**

| 구분 | 토큰 | 왕복 대화 | 설명 |
|------|------|----------|------|
| 초기 무료 | 35,000 | 5번 | 기본 제공 |
| 🎬 영상 광고 | 35,000 | 5번 | 보상형 영상 시청 |
| 📋 네이티브 광고 | 21,000 | 3번 | 광고 보기만 |

**4. 토큰 부족 시 UI 개선**

토큰 소진 시 채팅창에 2개 버튼 선택지 제공:
```
┌─────────────────────────────────┐
│ 🔮 AI: 대화가 즐거웠어요!        │
│    토큰이 부족해서 잠시 쉬어야   │
│    할 것 같아요.                │
│                                 │
│  [🎬 영상 보고 5번 대화] ← 추천  │
│  [📋 광고 보고 3번 대화]        │
└─────────────────────────────────┘
```

### 2026-01-31 변경 이력 (총 7개 파일)

### 1차: 광고 표시 확대

| 파일 | 변경 |
|------|------|
| `ad_strategy.dart` | `inlineAdMaxCount` 3→10, `interval` 3→5, `minMessages` 2→5 |
| `ad_trigger_service.dart` | `intervalRewardTokens = 2000` 추가 |
| `ad_persona_prompt.dart` | 모든 타입 CTA 문구 추가, 보상형/네이티브 구분 |
| `saju_chat_shell.dart` | `ConversationalAdWidget` 전체 타입 렌더링 |

### 2차: 수익 극대화

| 파일 | 변경 |
|------|------|
| `conversational_ad_provider.dart` | impression→click 토큰 지급, tokenNearLimit→보상형, 클릭 Supabase 추적 |
| `conversational_ad_widget.dart` | 보상형/네이티브 UI 분리, CTA 버튼 보상형만 |
| `ad_persona_prompt.dart` | tokenNearLimit CTA "누르시면"→"보시면" (보상형 전환) |

### 광고 흐름 (최종)

```
사용자 메시지 전송
  → chat_provider.checkAndTrigger()
    → AdTriggerService.checkTrigger(tokenUsage, messageCount)
      → 1순위: 토큰 100% → tokenDepleted (보상형, 필수)
      → 2순위: 토큰 80%+ → tokenNearLimit (보상형, 스킵 가능)
      → 3순위: 5번째 메시지 → intervalAd (네이티브, 스킵 가능)
    → _activateAdMode() → 페르소나 문구 + 광고 로드
    → ConversationalAdWidget 렌더링
      → 보상형: CTA 버튼 → 영상 시청 → 토큰 지급
      → 네이티브: 광고 클릭 → 토큰 지급 / 스킵 → 토큰 없음
      → 대화 재개
```

---

## 8. 향후 수익 개선 TODO

- [ ] Firebase A/B 테스트: interval 4 vs 5 vs 6 비교
- [ ] AdMob eCPM 모니터링: 보상형 vs 네이티브 실제 수익 비교
- [ ] 유저 30명+ 확보 후 손익분기 재검증
- [ ] GPT-5.2 → 더 저렴한 모델 전환 검토 (품질 트레이드오프)
- [ ] Gemini 2.5 Flash-Lite 전환 테스트 (채팅 품질 비교)
