# 2026 신년운세 (New Year Fortune) Feature

## 개요
2026년 병오(丙午)년 신년운세를 표시하는 화면. AI가 생성한 운세 데이터를 Supabase에서 가져와 표시.

## DB 테이블
- 테이블: `ai_summaries`
- summary_type: `yearly_fortune_2026`
- target_year: `2026`

---

## DB → UI 데이터 확인 Step-by-Step

### Step 1: DB에서 실제 데이터 조회
```sql
SELECT
  summary_type,
  jsonb_pretty(content->'overview') as overview
FROM ai_summaries
WHERE summary_type = 'yearly_fortune_2026'
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
| `yearEnergyConclusion` | `overview.yearEnergyConclusion` | "2026년 총평" HighlightBox |

### Step 3: 전체 content 구조 확인
```sql
SELECT jsonb_object_keys(content) FROM ai_summaries
WHERE summary_type = 'yearly_fortune_2026' LIMIT 1;
```

예상 키:
- `year`, `yearGanji`
- `mySajuIntro` (나의 사주 소개)
- `overview` (총운)
- `achievements` (성취)
- `challenges` (도전)
- `categories` (분야별 운세)
- `lessons` (교훈)
- `to2027` (2027년으로)
- `closing` (마무리 메시지)

### Step 4: Provider 모델 확인
파일: `presentation/providers/new_year_fortune_provider.dart`

주요 클래스:
- `NewYearFortuneData` - 최상위 데이터 모델
- `OverviewSection` - 총운 섹션 (DB overview와 매핑)
- `MySajuIntroSection` - 나의 사주 소개
- `AchievementsSection`, `ChallengesSection`, `LessonsSection`, `To2027Section`

### Step 5: Screen UI 확인
파일: `presentation/screens/new_year_fortune_screen.dart`

`_buildContent()` 메서드에서 각 섹션이 어떻게 표시되는지 확인

---

## 문제 해결 체크리스트

1. **UI에 데이터가 안 보임**
   - [ ] DB 쿼리로 실제 데이터 존재 확인
   - [ ] Provider `fromJson`에서 해당 필드 파싱하는지 확인
   - [ ] Screen에서 해당 필드 표시하는지 확인

2. **새 필드 추가 시**
   - [ ] DB에 필드 추가 (AI 프롬프트 수정)
   - [ ] Provider 모델 클래스에 필드 추가
   - [ ] `fromJson`에서 파싱 로직 추가
   - [ ] Screen에서 UI 위젯 추가
   - [ ] 더미 데이터에도 필드 추가 (오프라인 테스트용)

---

## 파일 구조
```
new_year_fortune/
├── presentation/
│   ├── screens/
│   │   └── new_year_fortune_screen.dart  # 메인 화면
│   └── providers/
│       ├── new_year_fortune_provider.dart     # 데이터 Provider
│       └── new_year_fortune_provider.g.dart   # 생성된 코드
└── README.md
```

## UI 흐름 (위에서 아래로 스크롤)
1. **제목** - 2026년 신년운세 + 연간지
2. **연도 정보** - 병오년 설명 (납음, 12운성, 신살)
3. **개인 분석** - 일간 분석, 신살 분석, 합충 분석, 용신 분석
4. **총운** - 키워드, 점수, 요약, 핵심 포인트
5. **분기별 운세** - Q1~Q4 각 분기 운세
6. **분야별 운세** - 6개 카테고리 칩 (광고 시청 후 잠금해제)
7. **행운 정보** - 행운색, 숫자, 방향, 아이템
8. **마무리 메시지** - 연간 메시지 + 최종 조언
9. **AI 상담 버튼**

## 분야별 운세 (카테고리 칩) - 핵심 기능
- **위치**: 분기별 운세 다음에 표시
- **컴포넌트**: `FortuneCategoryChipSection` (shared widget)
- **카테고리**: career, wealth, love, health, study, business (6개)
- **잠금/해제**: Hive 로컬 저장소 (`unlocked_fortune_categories`)
- **광고 연동**: 잠긴 칩 클릭 → 리워드 광고 → 잠금 해제 → 내용 표시

## 데이터 소스
- **테이블**: `ai_summaries`
- **쿼리**: `Yearly2026Queries.getCached(profileId)`
- **content 필드**: JSON 형태로 저장
```json
{
  "year": 2026,
  "yearGanji": "병오(丙午)",
  "mySajuIntro": {...},
  "overview": {
    "score": 76,
    "keyword": "불의 단련",
    "opening": "...",
    "ilganAnalysis": "...",
    "sinsalAnalysis": "...",
    "hapchungAnalysis": "...",
    "yongshinAnalysis": "...",
    "yearEnergyConclusion": "..."
  },
  "achievements": {...},
  "challenges": {...},
  "categories": {...},
  "lessons": {...},
  "to2027": {...},
  "closing": {...}
}
```

## 관련 파일
- `shared/widgets/fortune_category_chip_section.dart` - 카테고리 칩 공통 위젯
- `AI/fortune/yearly_2026/yearly_2026_queries.dart` - Supabase 쿼리
- `AI/fortune/yearly_2026/yearly_2026_prompt.dart` - AI 프롬프트
- `AI/fortune/yearly_2026/yearly_2026_analyzer.dart` - AI 분석 로직

## 수정 이력
- 2026-01-24: OverviewSection에 DB 필드 추가 (ilganAnalysis, sinsalAnalysis, hapchungAnalysis, yongshinAnalysis, yearEnergyConclusion)
- 2026-01-20: 카테고리 순서 변경, 기본 카테고리 추가
