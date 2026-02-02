# 광고 시스템 (Ad System) - DK 담당

> 최종 업데이트: 2026-02-02

---

## 1. 토큰 할당 현황 (v28)

### Supabase (`user_daily_token_usage`)

| 항목 | 값 |
|------|------|
| 일일 기본 토큰 (daily_quota) | **20,000** |
| 세션당 기본 토큰 (클라이언트) | **20,000** (`TokenCounter.defaultMaxInputTokens`) |
| 출력 안전 마진 | **18,000** (`TokenCounter.safetyMargin`) |
| 관리자 토큰 한도 | 1,000,000,000 (무제한) |
| 쿼터 초과 판단 | `chatting_tokens >= (daily_quota + bonus_tokens + rewarded_tokens_earned + native_tokens_earned)` |

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
| `tokenDepleted` | 토큰 100% 소진 | **2버튼 선택** (TokenDepletedBanner) | 영상 **20,000** / 네이티브 **30,000** | 영상 시청 or 광고 **클릭** | 불가 |
| `tokenNearLimit` | 토큰 80%+ | ~~비활성화~~ | 0 | `warningRewardTokens=0` | - |
| ~~`intervalAd`~~ | ~~메시지마다~~ | ~~비활성화 (v28)~~ | - | 인라인 ChatAdWidget이 대체 | - |
| (인라인) | **4번째** 메시지마다 | **정적 네이티브** (ChatAdWidget) | 클릭 시 **30,000** / 노출만 **0** | **클릭 시에만** | - |

### 유저 화면 흐름

**토큰 소진 시 (TokenDepletedBanner, 입력 필드 위)**
```
┌──────────────────────────────────────────────┐
│  토큰이 소진되었어요! 광고를 보면 대화를        │
│  계속할 수 있어요                              │
│                                              │
│  [🎬 영상 보고 대화 계속하기]   +20,000 토큰   │
│  [📋 광고 확인하고 대화 이어가기] +30,000 토큰  │
└──────────────────────────────────────────────┘
  영상: CTA 클릭 → 전체화면 영상 → 시청 완료 → 토큰 지급 → 대화 재개
  네이티브: CTA 클릭 → AdNativeBubble 표시 → 클릭해야 토큰 → 대화 재개
```

**인라인 광고 (ChatAdWidget, 메시지 사이) - 대화 중 유일한 광고**
```
  [유저 메시지]
  [AI 응답]
  ────────────────
  [네이티브 광고]  ← AI 응답 뒤에만 삽입 (4메시지마다)
  "관심 있는 광고를 살펴보시면 대화가 더 많아져요"
  ────────────────
  [유저 메시지]
  → 노출만: 순수 광고 수익 (토큰 0)
  → 클릭 시: +30,000 토큰 (native_tokens_earned)
```

> ~~인터벌 광고 (AdNativeBubble)~~ → v28에서 비활성화. 인라인 ChatAdWidget이 대체.

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

## 4. 인라인 광고 설정 (`AdStrategy`) - v28

| 설정 | 값 | 설명 |
|------|------|------|
| `inlineAdMessageInterval` | **4** | 4메시지(=2교환)마다 |
| `inlineAdMaxCount` | **9999** | 무제한 |
| `inlineAdMinMessages` | **4** | 2교환 후부터 광고 가능 |
| `chatAdType` | nativeMedium | 채팅 버블 스타일 |

### 인라인 광고 타이밍 (유저+AI 메시지 합산)

```
메시지 1~3: 첫 1.5교환 (광고 없음)
메시지 4:   첫 인라인 광고 (ChatAdWidget, AI 응답 뒤에만)
            "관심 있는 광고를 살펴보시면 대화가 더 많아져요"
            → 클릭 시 +30,000 토큰 / 노출만은 0
메시지 5~8: 다음 2교환, 메시지 8에서 또 인라인 광고
...반복...
```

> 인터벌 AdNativeBubble은 v28에서 비활성화. 인라인만 사용.

### 핵심 원칙: 클릭해야만 토큰 지급

```
Native 노출: 토큰 0 → 순수 eCPM 수익 (비용 $0, 100% 마진)
Native 클릭: 토큰 30,000 → CPC/eCPM 수익으로 커버 (손익분기 근접)
→ 유저가 클릭 안 해도 손해 없음, 클릭하면 대화 연장
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

## 6. 변경 이력

### 2026-02-02: v28 청운도사 제거 + 토큰 보상 정리

**1. UI 변경**

| 항목 | Before (v27) | After (v28) |
|------|-------------|-------------|
| 토큰 소진 UI | `ConversationalAdWidget` (청운도사 헤더 + 전환 메시지) | `TokenDepletedBanner` (간결한 2버튼, 입력 필드 위) |
| 대화 중 광고 | 인터벌 `AdNativeBubble` + 인라인 `ChatAdWidget` (겹침) | **인라인 `ChatAdWidget`만** (인터벌 비활성화) |
| 인라인 광고 클릭 | DB 추적만 | DB 추적 + **토큰 30,000 지급** |

**2. 토큰 보상 변경**

| 항목 | v27 | v28 |
|------|-----|-----|
| `impressionRewardTokens` | 1,500 | **0** |
| `depletedRewardTokensVideo` | 35,000 | **20,000** |
| `depletedRewardTokensNative` | 21,000 | **30,000** |
| `intervalClickRewardTokens` | 1,500 | **30,000** |
| `inlineAdMessageInterval` | 2 | **4** |
| `inlineAdMinMessages` | 2 | **4** |

**3. 인라인 광고 배치 버그 수정**
- AI 응답 뒤에만 삽입 (유저↔AI 대화쌍 사이 삽입 금지)
- 칩 버튼 누르면 3개 연속 출력되는 버그 수정

**4. 인라인 광고 클릭 시 토큰 보상 추가**
- `NativeAdWidget.onAdClicked` → `TokenRewardService.grantNativeAdTokens(30,000)`
- `CompactNativeAdWidget.onAdClicked` → 동일 처리
- 노출만으로는 여전히 토큰 0 (순수 수익)

**5. 인터벌 광고 비활성화**
- `ad_trigger_service.dart`: `checkTrigger()` → `intervalAd` 절대 반환 안 함
- 인라인 ChatAdWidget이 대화 중 광고 역할 전부 수행
- `AdNativeBubble`은 토큰 소진 → 네이티브 선택 시에만 사용

**6. 안내 문구 분기 + AdMob 정책 준수**
- 인라인 (토큰 있을 때): "대화가 더 **많아져요**"
- 소진 (토큰 없을 때): "대화를 **이어갈 수 있어요**"
- "클릭하세요" 직접 유도 금지

**7. AdWidget 에러 수정**
- `AdNativeBubble` → `StatefulWidget`으로 변경, `AdWidget` 인스턴스 캐싱
- 인터벌 비활성화로 "AdWidget is already in the Widget tree" 에러 근본 해결

### 2026-02-01: v27 광고 시스템 대폭 개편

**1. 페이지 전환 전면광고 추가**

| 파일 | 변경 |
|------|------|
| `fortune_category_list.dart` | 4개 운세 페이지 이동 시 `AdService.showInterstitialAd()` 호출 |
| `main_scaffold.dart` | AI 상담 탭 클릭 시 `AdService.showInterstitialAd()` 호출 |
| `menu_screen.dart` | 하단 네이티브 광고 #2 제거 (중복 노출 방지) |

**2. 토큰 소진 2버튼 UI 추가**

토큰 소진 시 2개 선택지:
- 🎬 영상 보고 대화 계속하기 (Rewarded Video, +20,000 토큰)
- 📋 광고 확인하고 대화 이어가기 (Native Ad, 클릭 시 +30,000 토큰)

---

## 7. 향후 TODO

- [ ] AdMob eCPM 모니터링: 실제 수익 확인 후 토큰/interval 조정
- [ ] Firebase A/B 테스트: interval 6 vs 10 비교
- [ ] IAP "광고 제거" 구현 (₩4,900)
- [ ] 프리미엄 구독 설계 (₩9,900/월)
