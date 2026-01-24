# 2025 신년운세 (Yearly 2025 Fortune)

## 개요
2025년 을사(乙巳)년 신년운세 화면입니다. 회고 스타일로 표시됩니다.

## DB 테이블
- 테이블: `ai_summaries`
- summary_type: `yearly_fortune_2025`
- target_year: `2025`

## DB → UI 데이터 확인 Step-by-Step

### Step 1: DB에서 실제 데이터 조회
```sql
SELECT
  summary_type,
  jsonb_pretty(content->'overview') as overview
FROM ai_summaries
WHERE summary_type = 'yearly_fortune_2025'
LIMIT 1;
```

### Step 2: Overview 섹션 필드 확인
DB `content.overview`에 있는 필드:
| DB 필드 | Provider 필드 | UI 표시 위치 |
|---------|---------------|-------------|
| `score` | `overview.score` | 상단 점수 게이지 |
| `keyword` | `overview.keyword` | 헤더 키워드 |
| `opening` | `overview.opening` | 총운 본문 |
| `ilganAnalysis` | `overview.ilganAnalysis` | "일간 분석" HighlightBox |
| `sinsalAnalysis` | `overview.sinsalAnalysis` | "신살 분석" HighlightBox |
| `hapchungAnalysis` | `overview.hapchungAnalysis` | "합충 분석" HighlightBox |
| `yongshinAnalysis` | `overview.yongshinAnalysis` | "용신 분석" HighlightBox |
| `yearEnergyConclusion` | `overview.yearEnergyConclusion` | "2025년 총평" HighlightBox |

레거시 필드 (하위 호환):
| DB 필드 | Provider 필드 | 비고 |
|---------|---------------|------|
| `yearEnergy` | `overview.yearEnergy` | ilganAnalysis 없을 때 표시 |
| `hapchungEffect` | `overview.hapchungEffect` | hapchungAnalysis 없을 때 표시 |
| `conclusion` | `overview.conclusion` | yearEnergyConclusion 없을 때 표시 |

### Step 3: 전체 content 구조 확인
```sql
SELECT jsonb_object_keys(content) FROM ai_summaries
WHERE summary_type = 'yearly_fortune_2025' LIMIT 1;
```

예상 키:
- `year`, `yearGanji`
- `mySajuIntro` (나의 사주 소개)
- `overview` (총운)
- `achievements` (성취)
- `challenges` (도전)
- `categories` (분야별 운세)
- `timeline` (분기별 운세)
- `lessons` (교훈)
- `to2026` (2026년으로)
- `closing` (마무리 메시지)

### Step 4: Provider 모델 확인
파일: `presentation/providers/yearly_2025_fortune_provider.dart`

주요 클래스:
- `Yearly2025FortuneData` - 최상위 데이터 모델
- `OverviewSection` - 총운 섹션 (DB overview와 매핑)
  - 2026-01-24 업데이트: ilganAnalysis, sinsalAnalysis, yongshinAnalysis, yearEnergyConclusion 추가
- `MySajuIntroSection` - 나의 사주 소개
- `AchievementsSection`, `ChallengesSection`, `LessonsSection`, `To2026Section`
- `TimelineSection`, `QuarterSection` - 분기별 운세
- `CategorySection` - 분야별 운세

### Step 5: Screen UI 확인
파일: `presentation/screens/yearly_2025_fortune_screen.dart`

`_buildContent()` 메서드에서 각 섹션이 어떻게 표시되는지 확인

## 문제 해결 체크리스트

1. **UI에 데이터가 안 보임**
   - [ ] DB 쿼리로 실제 데이터 존재 확인
   - [ ] Provider `fromJson`에서 해당 필드 파싱하는지 확인
   - [ ] Screen에서 해당 필드 표시하는지 확인
   - [ ] 필드가 비어있지 않은지 확인 (`.isNotEmpty` 조건)

2. **새 필드 추가 시**
   - [ ] DB에 필드 추가 (AI 프롬프트 수정)
   - [ ] Provider 모델 클래스에 필드 추가
   - [ ] `fromJson`에서 파싱 로직 추가
   - [ ] Screen에서 UI 위젯 추가
   - [ ] 더미 데이터에도 필드 추가 (오프라인 테스트용)

3. **레거시 호환성**
   - DB 필드 우선, 없으면 레거시 필드 사용
   - 예: `hapchungAnalysis` 우선 → 없으면 `hapchungEffect` 사용

## 관련 파일
- `lib/AI/fortune/yearly_2025/yearly_2025_queries.dart` - DB 쿼리
- `lib/AI/fortune/yearly_2025/yearly_2025_analyzer.dart` - AI 분석 로직

## 수정 이력
- 2026-01-24: OverviewSection에 DB 필드 추가 (ilganAnalysis, sinsalAnalysis, hapchungAnalysis, yongshinAnalysis, yearEnergyConclusion)
