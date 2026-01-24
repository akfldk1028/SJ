# 메뉴 화면 (Menu Screen)

## 개요
앱의 메인 화면입니다. 오늘의 운세, 운세 카테고리 목록, 광고 등을 표시합니다.

## 주요 컴포넌트

### 1. Daily Fortune Provider
파일: `presentation/providers/daily_fortune_provider.dart`

오늘의 운세 데이터를 관리합니다.

#### 데이터 모델
```dart
class DailyFortuneData {
  final int overallScore;
  final String overallMessage;       // 긴 메시지
  final String overallMessageShort;  // 짧은 메시지 (오늘의 한마디)
  final Map<String, CategoryScore> categories;
  final LuckyInfo lucky;
  final IdiomInfo idiom;  // 오늘의 사자성어
  final String caution;
  final String affirmation;
}
```

#### DB 테이블
- 테이블: `ai_summaries`
- summary_type: `daily_fortune`
- target_date: 오늘 날짜

### 2. Fortune Summary Card
파일: `presentation/widgets/fortune_summary_card.dart`

오늘의 운세 요약 카드입니다.

#### 표시 우선순위
- 메시지: `overallMessageShort` 우선, 없으면 `overallMessage`
- 사자성어: `idiom.korean`, `idiom.chinese`, `idiom.meaning`

## 🚨 AI 프롬프트 주의사항

### 사자성어 (idiom) - 다양성 필수!
**절대 같은 사자성어를 반복하면 안 됨!**

잘못된 예:
```json
{
  "idiom": {
    "chinese": "磨斧爲針",
    "korean": "마부위침",  // 항상 마부위침만 나옴 ❌
    "meaning": "도끼를 갈아 바늘을 만든다"
  }
}
```

올바른 프롬프트:
```
### 6. 오늘의 사자성어 (idiom) - 매우 중요!
이 사람의 사주 특성과 오늘 날짜의 기운을 조합하여 **매번 다른 사자성어**를 선정하세요.
- **절대로 같은 사자성어를 반복하지 마세요**
- 사주의 특성에 맞는 사자성어 선택 (예: 수 기운이 강하면 유수부쟁선)
- 오늘 날짜의 기운에 맞는 사자성어 선택
```

## 캐싱 시스템
- **캐시 키**: `profile_id` + `summary_type` + `target_date`
- **같은 사주라도 profile_id가 다르면 새로 분석됨**
- **프롬프트 버전 변경 시 캐시 무효화됨** (`PromptVersions.dailyFortune`)

## 관련 파일
- `lib/AI/fortune/daily/daily_prompt.dart` - AI 프롬프트
- `lib/AI/fortune/daily/daily_queries.dart` - DB 쿼리
- `lib/AI/data/queries.dart` - aiQueries.getDailyFortune()

## 수정 이력
- v2.0: overallMessageShort 추가 (짧은 오늘의 한마디)
- v2.1 (2026-01-24): 사자성어 다양화 프롬프트 개선
