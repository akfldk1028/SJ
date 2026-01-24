# 월별 운세 (Monthly Fortune)

## 개요
현재 월의 운세를 표시하는 화면입니다. v4.0부터 12개월 통합 구조로 변경되었습니다.

## DB 테이블
- 테이블: `ai_summaries`
- summary_type: `monthly_fortune`
- target_month: 현재 월 (예: 1, 2, ... 12)
- target_year: 현재 년도

## DB → UI 데이터 확인 Step-by-Step

### Step 1: DB에서 실제 데이터 조회
```sql
SELECT
  summary_type,
  target_month,
  jsonb_pretty(content->'current'->'overview') as current_overview,
  jsonb_pretty(content->'months') as months_summary
FROM ai_summaries
WHERE summary_type = 'monthly_fortune'
LIMIT 1;
```

### Step 2: Overview 섹션 필드 확인
DB `content.current.overview` 또는 `content.overview`에 있는 필드:
| DB 필드 | Provider 필드 | UI 표시 위치 |
|---------|---------------|-------------|
| `score` | `overview.score` | 상단 점수 게이지 |
| `keyword` | `overview.keyword` | 헤더 키워드 |
| `opening` 또는 `reading` | `overview.opening` | 총운 본문 |
| `monthEnergy` | `overview.monthEnergy` | "이달의 기운" HighlightBox |
| `hapchungEffect` | `overview.hapchungEffect` | "합충 영향" HighlightBox |
| `conclusion` | `overview.conclusion` | "결론" HighlightBox |

### Step 3: v4.0 구조 - 현재 월 vs 12개월 요약
```
content: {
  year: 2026,
  currentMonth: 1,
  current: {           // 현재 월 상세 데이터
    monthGanji: "경인(庚寅)",
    overview: {...},
    categories: {...},
    lucky: {...}
  },
  months: {            // 12개월 요약
    month1: { keyword, score, reading },
    month2: { keyword, score, reading },
    ...
    month12: { keyword, score, reading }
  },
  closingMessage: "..."
}
```

### Step 4: 전체 content 구조 확인
```sql
SELECT jsonb_object_keys(content) FROM ai_summaries
WHERE summary_type = 'monthly_fortune' LIMIT 1;
```

예상 키:
- `year`, `currentMonth`, `monthGanji`
- `current` (현재 월 상세)
- `months` (12개월 요약)
- `closingMessage`

### Step 5: Provider 모델 확인
파일: `presentation/providers/monthly_fortune_provider.dart`

주요 클래스:
- `MonthlyFortuneData` - 최상위 데이터 모델
- `OverviewSection` - 총운 섹션
- `CategorySection` - 분야별 운세
- `LuckySection` - 행운 정보 (colors, numbers, foods, tip)
- `MonthSummary` - 12개월 요약 (v4.0)

### Step 6: Screen UI 확인
파일: `presentation/screens/monthly_fortune_screen.dart`

주요 섹션:
- 헤더 (월, 월간지, 점수)
- 총운 (opening, monthEnergy, hapchungEffect, conclusion)
- 분야별 운세 (categories)
- 행운 정보 (lucky colors, numbers, foods)
- 12개월 미리보기 (months)

## 문제 해결 체크리스트

1. **UI에 데이터가 안 보임**
   - [ ] DB 쿼리로 실제 데이터 존재 확인
   - [ ] `current` 섹션 안에 데이터가 있는지 확인 (v4.0 구조)
   - [ ] Provider `fromJson`에서 해당 필드 파싱하는지 확인
   - [ ] Screen에서 해당 필드 표시하는지 확인

2. **v4.0 구조 주의사항**
   - `current` 섹션: 현재 월 상세 데이터
   - `months` 섹션: 12개월 요약 (keyword, score, reading)
   - fromJson에서 `json['current']` 우선, 없으면 `json` 직접 사용

3. **새 필드 추가 시**
   - [ ] DB에 필드 추가 (AI 프롬프트 수정)
   - [ ] Provider 모델 클래스에 필드 추가
   - [ ] `fromJson`에서 파싱 로직 추가
   - [ ] Screen에서 UI 위젯 추가

## 관련 파일
- `lib/AI/fortune/monthly/monthly_queries.dart` - DB 쿼리
- `lib/AI/fortune/monthly/monthly_analyzer.dart` - AI 분석 로직

## 수정 이력
- v4.0: 12개월 통합 구조로 변경
