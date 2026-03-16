# 글로벌 출시 TODO — 시간대별 토큰 충전 & 광고 수익화

## 핵심 문제: 시간대(Timezone)

현재 모든 일일 리셋이 **KST(UTC+9) 하드코딩**되어 있음.
글로벌 유저는 자기 시간대 기준 자정에 토큰이 충전되어야 함.

### 영향받는 코드

| # | 위치 | 현재 | 글로벌 대응 |
|---|------|------|-----------|
| 1 | `ai-gemini/index.ts` → `getTodayKST()` | `Asia/Seoul` 고정 | 클라이언트에서 `timezone` 파라미터 전달 |
| 2 | Supabase RPC `add_ad_bonus_tokens` | `CURRENT_DATE` (UTC) | `p_usage_date` 파라미터 추가 또는 timezone 변환 |
| 3 | Supabase RPC `add_native_bonus_tokens` | `CURRENT_DATE` (UTC) | 동일 |
| 4 | DB 트리거 `trg_update_daily_chat_tokens` | 확인 필요 (UTC?) | timezone 반영 |
| 5 | `ad_tracking_service.dart` → `_incrementDailyCounter` | 확인 필요 | 클라이언트 timezone 기준 날짜 전달 |

---

## Phase 1: 시간대 기반 일일 리셋 (필수)

### 1-1. 클라이언트 → Edge Function timezone 전달
- [ ] `GeminiEdgeDatasource`에서 요청 시 `timezone` 필드 추가
  ```dart
  'timezone': DateTime.now().timeZoneOffset.inHours, // 또는 IANA timezone
  ```
- [ ] Edge Function `getTodayKST()` → `getTodayByTimezone(offsetHours)` 변경
  ```ts
  function getTodayByTimezone(offsetHours: number): string {
    const now = new Date();
    const local = new Date(now.getTime() + offsetHours * 60 * 60 * 1000);
    return local.toISOString().split('T')[0];
  }
  ```
- [ ] fallback: timezone 없으면 기존 KST 유지 (하위 호환)

### 1-2. Supabase RPC timezone 대응
- [ ] `add_ad_bonus_tokens`: `CURRENT_DATE` → 클라이언트 전달 날짜 사용
  ```sql
  -- 방법 A: 클라이언트가 usage_date 직접 전달
  CREATE OR REPLACE FUNCTION add_ad_bonus_tokens(
    p_user_id UUID, p_bonus_tokens INT, p_usage_date DATE DEFAULT CURRENT_DATE
  ) ...

  -- 방법 B: timezone offset 전달
  CREATE OR REPLACE FUNCTION add_ad_bonus_tokens(
    p_user_id UUID, p_bonus_tokens INT, p_tz_offset INT DEFAULT 9
  ) ...
  ```
- [ ] `add_native_bonus_tokens` 동일 변경
- [ ] `TokenRewardService.grantRewardedAdTokens()`에서 timezone 전달

### 1-3. DB 트리거 확인
- [ ] `trg_update_daily_chat_tokens` 트리거: 어떤 날짜 기준으로 `chatting_tokens` 업데이트하는지 확인
- [ ] UTC 기준이면 timezone 반영 필요

---

## Phase 2: 광고 글로벌 설정

### 2-1. 광고 ID 국가별 분리
- [ ] `ad_config.dart`에서 국가별 eCPM 차이 고려
  - Tier 1 (US, JP, KR, UK, DE): eCPM $10-15
  - Tier 2 (BR, MX, TH, PH): eCPM $3-5
  - Tier 3 (IN, ID, VN): eCPM $1-3
- [ ] 저 eCPM 국가에서 14,000 토큰 지급하면 적자 → 국가별 보상 차등화 검토

### 2-2. 토큰 보상 국가별 조정 (수익성 보장)
```
현재: depletedRewardTokensVideo = 14,000 (한국 기준)

국가별 권장:
- Tier 1 (KR/JP/US): 14,000 → 순이익 ~$0.005/회
- Tier 2 (BR/TH):     8,000 → 순이익 ~$0.002/회
- Tier 3 (IN/VN):     5,000 → 순이익 ~$0.001/회
```
- [ ] `AdStrategy`에 국가별 토큰량 매핑 추가
- [ ] 또는 서버에서 eCPM 실측 기반 동적 조절 (장기)

### 2-3. AdMob 밴 해제 후 프로덕션 전환
- [ ] `ad_config.dart`: `AdMode.test` → `AdMode.production`
- [ ] iOS 광고 Unit ID 설정 (현재 `YOUR_IOS_*` placeholder)
- [ ] AdMob 밴 해제 확인 (~2026-03-12 예상)

---

## Phase 3: 다국어 & 로컬라이제이션

### 3-1. 광고 관련 UI 텍스트
- [ ] `token_depleted_banner.dart` 한국어 → i18n 키로 변환
  - "토큰이 소진되었어요! 광고를 보면 대화를 계속할 수 있어요"
  - "▶ 계속하기" / "✨ 프리미엄"
  - "광고 준비 중이어서 소량 충전되었어요"
- [ ] `conversational_ad_widget.dart` 광고 라벨 "광고" → "Ad" (영어권)

### 3-2. 사주 콘텐츠 다국어
- [ ] 만세력 계산은 로케일 무관 (음력/양력 변환)
- [ ] AI 프롬프트 다국어 대응 (Gemini/GPT)
- [ ] 운세 카테고리 이름 번역

---

## Phase 4: 수익 모니터링

### 4-1. 국가별 수익성 대시보드
- [ ] Supabase에 국가 코드 저장 (user_daily_token_usage에 `country_code` 컬럼)
- [ ] eCPM 실측 vs API 비용 → 국가별 순이익 모니터링
- [ ] 적자 국가 감지 시 자동 토큰 보상 하향 (또는 알림)

### 4-2. 수익 공식
```
순이익 = (전면광고 eCPM / 1000) - (보상토큰 × $0.47 / 1,000,000)

예시 (14,000 토큰 기준):
- 한국 ($11.23 eCPM): $0.011 - $0.0066 = +$0.005 ✅
- 인도 ($2.00 eCPM):  $0.002 - $0.0066 = -$0.005 ❌ 적자!
- 미국 ($14.08 eCPM): $0.014 - $0.0066 = +$0.007 ✅
```

---

## 우선순위

| 순위 | 항목 | 난이도 | 영향도 |
|------|------|--------|--------|
| **P0** | Phase 1-1: Edge Function timezone | 중 | 글로벌 필수 |
| **P0** | Phase 1-2: RPC timezone | 중 | 글로벌 필수 |
| **P1** | Phase 2-2: 국가별 토큰 차등화 | 중 | 적자 방지 |
| **P1** | Phase 2-3: AdMob 프로덕션 전환 | 하 | 수익 시작 |
| **P1** | Phase 3-1: 광고 UI 다국어 | 중 | UX |
| **P2** | Phase 4-1: 수익 모니터링 | 중 | 운영 |
| **P2** | Phase 1-3: DB 트리거 timezone | 중 | 정확성 |

---

## 현재 수익 구조 요약 (2026-03-08 기준)

```
일일 무료 쿼타: 20,000 tokens (대화 ~3-4회)
전면광고 보상:  14,000 tokens (대화 ~2-3회 추가)
광고 실패 시:    5,000 tokens (fallback)

수익 (한국 Android):
  전면광고 eCPM $11.23 → 1회 $0.011 수익
  API 비용: 14K tokens × $0.47/1M = $0.0066
  순이익: $0.005/회 (~6원)

Gemini 3 Flash Preview 가격:
  Input:  $0.50/1M tokens
  Output: $3.00/1M tokens
  실측 혼합: $0.47/1M tokens
```
