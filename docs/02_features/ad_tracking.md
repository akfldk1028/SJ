# 광고 추적 시스템 설계서

> **버전**: v1.0
> **작성일**: 2026-01-22
> **작성자**: Claude (DK 지시)

---

## 1. 개요

### 1.1 목표
사용자의 광고 시청 행동을 상세히 추적하여 수익 분석 및 최적화에 활용

### 1.2 추적 대상 광고 유형

| 광고 유형 | 설명 | 현재 구현 상태 |
|----------|------|---------------|
| **Banner** | 하단 배너 광고 | ✅ 구현됨 |
| **Interstitial** | 전면 광고 | ✅ 구현됨 |
| **Rewarded** | 보상형 광고 | ✅ 구현됨 |
| **Native** | 채팅 내 네이티브 광고 | ⏳ 미구현 |

### 1.3 추적 이벤트 유형

| 이벤트 | 설명 | Banner | Interstitial | Rewarded | Native |
|--------|------|:------:|:------------:|:--------:|:------:|
| **impression** | 광고 노출 | ✅ | - | - | ✅ |
| **show** | 전면 광고 표시 시작 | - | ✅ | ✅ | - |
| **complete** | 광고 시청 완료 (닫힘) | - | ✅ | ✅ | - |
| **click** | 광고 클릭 | ✅ | ✅ | ✅ | ✅ |
| **rewarded** | 보상 지급 완료 | - | - | ✅ | - |

---

## 2. 데이터베이스 스키마

### 2.1 `ad_events` 테이블 (상세 이벤트 로그)

개별 광고 이벤트를 상세히 기록하는 테이블

```sql
CREATE TABLE public.ad_events (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- 광고 정보
  ad_type       TEXT NOT NULL,     -- 'banner', 'interstitial', 'rewarded', 'native'
  event_type    TEXT NOT NULL,     -- 'impression', 'show', 'complete', 'click', 'rewarded'

  -- 보상 정보 (rewarded 이벤트만)
  reward_amount INTEGER,           -- 보상 토큰 수량
  reward_type   TEXT,              -- 보상 유형 (예: 'token', 'chat_bonus')

  -- 컨텍스트 정보
  screen        TEXT,              -- 발생 화면 (예: '/saju/chat', '/home')
  session_id    UUID,              -- 채팅 세션 ID (있을 경우)

  -- 타임스탬프
  created_at    TIMESTAMPTZ DEFAULT now(),

  -- 제약조건
  CONSTRAINT check_ad_type CHECK (ad_type IN ('banner', 'interstitial', 'rewarded', 'native')),
  CONSTRAINT check_event_type CHECK (event_type IN ('impression', 'show', 'complete', 'click', 'rewarded'))
);

-- 인덱스
CREATE INDEX idx_ad_events_user_id ON public.ad_events(user_id);
CREATE INDEX idx_ad_events_created_at ON public.ad_events(created_at);
CREATE INDEX idx_ad_events_ad_type ON public.ad_events(ad_type);
CREATE INDEX idx_ad_events_user_date ON public.ad_events(user_id, created_at::date);
```

### 2.2 `user_daily_token_usage` 테이블 확장 (일별 집계)

기존 테이블에 광고 추적 컬럼 추가

```sql
-- 배너 광고
ALTER TABLE public.user_daily_token_usage
ADD COLUMN banner_impressions INTEGER DEFAULT 0,
ADD COLUMN banner_clicks INTEGER DEFAULT 0;

-- 전면 광고
ALTER TABLE public.user_daily_token_usage
ADD COLUMN interstitial_shows INTEGER DEFAULT 0,
ADD COLUMN interstitial_completes INTEGER DEFAULT 0,
ADD COLUMN interstitial_clicks INTEGER DEFAULT 0;

-- 보상형 광고
ALTER TABLE public.user_daily_token_usage
ADD COLUMN rewarded_shows INTEGER DEFAULT 0,
ADD COLUMN rewarded_completes INTEGER DEFAULT 0,
ADD COLUMN rewarded_clicks INTEGER DEFAULT 0,
ADD COLUMN rewarded_tokens_earned INTEGER DEFAULT 0;

-- 네이티브 광고 (채팅 내)
ALTER TABLE public.user_daily_token_usage
ADD COLUMN native_impressions INTEGER DEFAULT 0,
ADD COLUMN native_clicks INTEGER DEFAULT 0;
```

### 2.3 필드 상세 설명

#### 배너 광고 (Banner)
| 필드 | 타입 | 설명 |
|------|------|------|
| `banner_impressions` | INTEGER | 배너 광고 노출 횟수 |
| `banner_clicks` | INTEGER | 배너 광고 클릭 횟수 |

#### 전면 광고 (Interstitial)
| 필드 | 타입 | 설명 |
|------|------|------|
| `interstitial_shows` | INTEGER | 전면 광고 표시 시작 횟수 |
| `interstitial_completes` | INTEGER | 전면 광고 완료 (닫힘) 횟수 |
| `interstitial_clicks` | INTEGER | 전면 광고 클릭 횟수 |

> **shows vs completes**: 사용자가 광고를 중간에 닫을 수 있으므로 구분 필요

#### 보상형 광고 (Rewarded)
| 필드 | 타입 | 설명 |
|------|------|------|
| `rewarded_shows` | INTEGER | 보상형 광고 표시 시작 횟수 |
| `rewarded_completes` | INTEGER | 보상형 광고 완료 (보상 지급) 횟수 |
| `rewarded_clicks` | INTEGER | 보상형 광고 클릭 횟수 |
| `rewarded_tokens_earned` | INTEGER | 보상으로 받은 총 토큰 수 |

#### 네이티브 광고 (Native)
| 필드 | 타입 | 설명 |
|------|------|------|
| `native_impressions` | INTEGER | 네이티브 광고 노출 횟수 |
| `native_clicks` | INTEGER | 네이티브 광고 클릭 횟수 |

---

## 3. 현재 광고 시스템 구조

### 3.1 파일 구조

```
frontend/lib/ad/
├── ad_config.dart          # AdMob 설정 및 Unit ID
├── ad_service.dart         # 광고 로딩/표시 서비스 (싱글톤)
├── ad_strategy.dart        # 광고 전략 설정 (빈도, 한도 등)
├── providers/
│   └── ad_provider.dart    # Riverpod 상태 관리
└── widgets/
    └── (광고 위젯들)
```

### 3.2 현재 콜백 매핑

| 광고 유형 | AdMob 콜백 | 추적 이벤트 |
|----------|-----------|------------|
| **Banner** | `onAdLoaded` | - |
| | `onAdImpression` | `impression` |
| | `onAdClicked` | `click` |
| | `onAdClosed` | - |
| **Interstitial** | `onAdLoaded` | - |
| | `onAdShowedFullScreenContent` | `show` |
| | `onAdDismissedFullScreenContent` | `complete` |
| | `onAdClicked` | `click` |
| **Rewarded** | `onAdLoaded` | - |
| | `onAdShowedFullScreenContent` | `show` |
| | `onAdDismissedFullScreenContent` | `complete` |
| | `onAdClicked` | `click` |
| | `onUserEarnedReward` | `rewarded` |

### 3.3 AdService 콜백 위치 (ad_service.dart)

```dart
// Banner - line 81~106
BannerAdListener(
  onAdImpression: (ad) { /* → banner impression */ },
  onAdClicked: (ad) { /* → banner click */ },
)

// Interstitial - line 136~161
FullScreenContentCallback(
  onAdShowedFullScreenContent: (ad) { /* → interstitial show */ },
  onAdDismissedFullScreenContent: (ad) { /* → interstitial complete */ },
  onAdClicked: (ad) { /* → interstitial click */ },
)

// Rewarded - line 212~239
FullScreenContentCallback(
  onAdShowedFullScreenContent: (ad) { /* → rewarded show */ },
  onAdDismissedFullScreenContent: (ad) { /* → rewarded complete */ },
  onAdClicked: (ad) { /* → rewarded click */ },
)
// line 263~267
onUserEarnedReward: (ad, reward) { /* → rewarded + rewarded_tokens_earned */ }
```

---

## 4. 구현 계획

### 4.1 Phase 1: 데이터베이스 마이그레이션

1. `ad_events` 테이블 생성
2. `user_daily_token_usage` 테이블 컬럼 추가
3. RLS 정책 설정
4. 인덱스 생성

### 4.2 Phase 2: Flutter 추적 서비스

1. `AdTrackingService` 생성 (Supabase 연동)
2. `ad_service.dart` 콜백에 추적 로직 추가
3. 일별 집계 업데이트 로직 구현

### 4.3 Phase 3: 테스트 및 검증

1. 각 광고 유형별 이벤트 추적 테스트
2. 일별 집계 정확성 검증
3. 성능 영향 분석

---

## 5. RLS 정책

```sql
-- ad_events RLS
ALTER TABLE public.ad_events ENABLE ROW LEVEL SECURITY;

-- 사용자는 자신의 광고 이벤트만 INSERT 가능
CREATE POLICY "Users can insert own ad events"
  ON public.ad_events
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 사용자는 자신의 광고 이벤트만 SELECT 가능
CREATE POLICY "Users can view own ad events"
  ON public.ad_events
  FOR SELECT
  USING (auth.uid() = user_id);

-- 삭제/수정 불가 (관리자만)
```

---

## 6. 분석 쿼리 예시

### 6.1 사용자별 일일 광고 요약

```sql
SELECT
  usage_date,
  banner_impressions,
  banner_clicks,
  CASE WHEN banner_impressions > 0
    THEN ROUND(banner_clicks::numeric / banner_impressions * 100, 2)
    ELSE 0
  END AS banner_ctr,
  interstitial_shows,
  interstitial_completes,
  rewarded_shows,
  rewarded_completes,
  rewarded_tokens_earned
FROM user_daily_token_usage
WHERE user_id = $1
ORDER BY usage_date DESC
LIMIT 30;
```

### 6.2 광고 유형별 전환율 분석

```sql
SELECT
  ad_type,
  COUNT(*) FILTER (WHERE event_type = 'show') AS shows,
  COUNT(*) FILTER (WHERE event_type = 'complete') AS completes,
  COUNT(*) FILTER (WHERE event_type = 'click') AS clicks,
  ROUND(
    COUNT(*) FILTER (WHERE event_type = 'complete')::numeric /
    NULLIF(COUNT(*) FILTER (WHERE event_type = 'show'), 0) * 100, 2
  ) AS completion_rate,
  ROUND(
    COUNT(*) FILTER (WHERE event_type = 'click')::numeric /
    NULLIF(COUNT(*) FILTER (WHERE event_type IN ('show', 'impression')), 0) * 100, 2
  ) AS click_rate
FROM ad_events
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY ad_type;
```

### 6.3 시간대별 광고 효율 분석

```sql
SELECT
  EXTRACT(HOUR FROM created_at) AS hour,
  ad_type,
  COUNT(*) AS total_events,
  COUNT(*) FILTER (WHERE event_type = 'click') AS clicks
FROM ad_events
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY EXTRACT(HOUR FROM created_at), ad_type
ORDER BY hour, ad_type;
```

---

## 7. 기존 필드 처리

### 7.1 기존 필드 유지 여부

| 기존 필드 | 처리 | 이유 |
|----------|------|------|
| `ads_watched` | **유지** (deprecated) | 기존 데이터 호환성 |
| `bonus_tokens_earned` | **유지** | AI 관련 보너스 토큰용 |

> 새 필드 사용 권장: `rewarded_completes` (광고 시청 횟수), `rewarded_tokens_earned` (광고 보상 토큰)

### 7.2 마이그레이션 전략

```sql
-- 기존 데이터 마이그레이션 (선택적)
UPDATE user_daily_token_usage
SET rewarded_completes = ads_watched
WHERE ads_watched > 0;
```

---

## 8. 관련 문서

- [광고 전략 설정](../../frontend/lib/ad/ad_strategy.dart) - 광고 빈도, 한도 설정
- [대화형 광고 설계서](../frontend/lib/features/saju_chat/docs/CONVERSATIONAL_AD_DESIGN.md) - 토큰 기반 광고 시스템
- [데이터 모델](./04_data_models.md) - 전체 DB 스키마

---

## 9. 체크리스트

### 데이터베이스
- [ ] `ad_events` 테이블 생성
- [ ] `user_daily_token_usage` 컬럼 추가
- [ ] RLS 정책 적용
- [ ] 인덱스 생성

### Flutter
- [ ] `AdTrackingService` 생성
- [ ] `AdService` 콜백 수정
- [ ] 일별 집계 업데이트 로직
- [ ] 에러 핸들링 및 재시도 로직

### 테스트
- [ ] 배너 광고 추적 테스트
- [ ] 전면 광고 추적 테스트
- [ ] 보상형 광고 추적 테스트
- [ ] 네이티브 광고 추적 테스트 (구현 후)
- [ ] 일별 집계 정확성 검증
