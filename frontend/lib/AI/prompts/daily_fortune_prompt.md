# 일운 분석 프롬프트 (Gemini 3.0 Flash)

## 개요

| 항목 | 값 |
|------|-----|
| **파일** | `daily_fortune_prompt.dart` |
| **모델** | Gemini 3.0 Flash (Google) |
| **토큰** | 2048 |
| **Temperature** | 0.8 |
| **캐시** | 24시간 |
| **비용** | ~$0.001/회 |

## 데이터 흐름

```
saju_analyses (DB) + ai_summaries (saju_base 참조)
      │
      ▼
AiQueries.convertToInputData()
      │
      ▼
SajuInputData + targetDate
      │
      ▼
DailyFortunePrompt.buildMessages()
      │
      ▼
ai-gemini Edge Function
      │
      ▼
Google Gemini 3.0 Flash API
      │
      ▼
ai_summaries (summary_type='daily_fortune')
```

---

## DB 데이터 예시

### saju_profiles

```json
{
  "display_name": "이지나",
  "birth_date": "1999-07-27",
  "birth_time_minutes": 900,
  "gender": "female",
  "is_lunar": false
}
```

### saju_analyses

```json
{
  "year_gan": "기(己)",
  "year_ji": "묘(卯)",
  "month_gan": "신(辛)",
  "month_ji": "미(未)",
  "day_gan": "경(庚)",
  "day_ji": "진(辰)",
  "hour_gan": "계(癸)",
  "hour_ji": "미(未)",

  "oheng_distribution": {
    "금(金)": 2,
    "목(木)": 1,
    "수(水)": 1,
    "토(土)": 4,
    "화(火)": 0
  },

  "yongsin": {
    "yongsin": "수(水)",
    "heesin": "금(金)",
    "gisin": "토(土)",
    "gusin": "목(木)"
  },

  "day_strength": {
    "level": "태강(太强)",
    "score": 75,
    "isStrong": true
  },

  "gyeokguk": {
    "name": "정인격(正印格)",
    "reason": "월지 정기(기)가 정인"
  },

  "twelve_unsung": [
    {"pillar": "년주", "unsung": "태(胎)"},
    {"pillar": "월주", "unsung": "관대(冠帶)"},
    {"pillar": "일주", "unsung": "양(養)"},
    {"pillar": "시주", "unsung": "관대(冠帶)"}
  ],

  "twelve_sinsal": [
    {"pillar": "년지", "sinsal": "장성(將星)", "fortuneType": "길"},
    {"pillar": "월지", "sinsal": "화개(華蓋)", "fortuneType": "길흉혼합"},
    {"pillar": "일지", "sinsal": "반안(攀鞍)", "fortuneType": "길"},
    {"pillar": "시지", "sinsal": "화개(華蓋)", "fortuneType": "길흉혼합"}
  ],

  "hapchung": {
    "jiji_samhaps": [
      {"pillars": ["년", "월"], "jijis": ["묘", "미"], "result_oheng": "목"},
      {"pillars": ["년", "시"], "jijis": ["묘", "미"], "result_oheng": "목"}
    ],
    "jiji_haes": [
      {"pillar1": "년", "pillar2": "일", "ji1": "묘", "ji2": "진"}
    ]
  },

  "daeun": {
    "startAge": 4,
    "isForward": true,
    "list": [
      {"order": 3, "pillar": "갑(甲)술(戌)", "startAge": 24, "endAge": 33}
    ]
  }
}
```

---

## 풀 프롬프트 (실제 Gemini 3.0 Flash 전달)

### System Prompt

```
당신은 친근하고 긍정적인 사주 상담사입니다. 오늘의 운세를 재미있고 실용적으로 안내해주세요.

## 원칙
1. 긍정적이고 희망적인 톤 유지
2. 구체적이고 실천 가능한 조언
3. 간결하고 핵심적인 내용
4. 일상에 적용할 수 있는 팁

## 응답 형식
JSON 형식으로 구조화된 일운을 반환하세요.
```

### User Prompt

```
## 대상 정보
- 이름: 이지나
- 생년월일: 1999년 7월 27일
- 성별: 여성
- 일간: 경

## 사주 팔자

| 구분 | 년주 | 월주 | 일주 | 시주 |
|------|------|------|------|------|
| 천간 | 기 | 신 | 경 | 계 |
| 지지 | 묘 | 미 | 진 | 미 |

## 오행 분포
- 목(木): 1
- 화(火): 0
- 토(土): 4
- 금(金): 2
- 수(水): 1

## 용신 정보
용신: 수(水), 희신: 금(金), 기신: 토(土), 구신: 목(木)

## 신강/신약
태강(太强) (점수: 75, 요인: 득령, 득시, 득세)

## 격국
정인격(正印格) (일반격) - 월지 정기(기)가 정인

## 12운성
년주: 태(胎), 월주: 관대(冠帶), 일주: 양(養), 시주: 관대(冠帶)

## 신살
년지: 장성(將星)(길), 월지: 화개(華蓋)(길흉혼합), 일지: 반안(攀鞍)(길), 시지: 화개(華蓋)(길흉혼합)

## 길성
길성 정보 없음

## 합충형파해
지지 삼합: 년-월 묘미 반합 (목), 년-시 묘미 반합 (목) | 지지 해: 년-일 묘진 해

## 대운
현재 대운: 갑술 (24세 ~ 33세)

## 오늘 날짜
2024년 12월 30일 (월요일)

## 평생사주 분석 참고
성격: 강한 인성과 상관의 조화로 학문과 창작에 뛰어난 재능
적합 분야: 연구직, 교육, 예술, IT
주의 건강: 폐, 대장, 피부

---

위 사주 정보를 종합하여 오늘 2024년 12월 30일의 운세를 JSON 형식으로 알려주세요.

반드시 아래 스키마를 따라주세요:

{
  "date": "2024년 12월 30일",
  "overall_score": 75,
  "overall_message": "오늘의 한마디 메시지",
  "categories": {
    "work": {
      "score": 80,
      "message": "업무/학업 관련 운세",
      "tip": "실천 팁"
    },
    "love": {
      "score": 70,
      "message": "연애/인간관계 운세",
      "tip": "실천 팁"
    },
    "wealth": {
      "score": 65,
      "message": "재물/금전 운세",
      "tip": "실천 팁"
    },
    "health": {
      "score": 85,
      "message": "건강 운세",
      "tip": "실천 팁"
    }
  },
  "lucky": {
    "color": "오늘의 행운 색",
    "number": 7,
    "time": "오후 2-4시",
    "direction": "동쪽"
  },
  "caution": "오늘 주의할 점 한 문장",
  "affirmation": "오늘의 긍정 확언"
}

점수는 0-100 사이로 설정해주세요.
```

---

## 예상 응답 스키마

```json
{
  "date": "2024년 12월 30일",
  "overall_score": 78,
  "overall_message": "한 해의 마무리를 정리하기 좋은 날입니다. 차분하게 계획을 세워보세요.",
  "categories": {
    "work": {
      "score": 82,
      "message": "월요일 시작이지만 집중력이 좋습니다. 밀린 업무 처리에 유리한 날.",
      "tip": "오전에 중요한 일을 먼저 처리하세요."
    },
    "love": {
      "score": 70,
      "message": "화개살의 영향으로 혼자만의 시간이 필요할 수 있습니다.",
      "tip": "무리한 약속보다 소중한 사람과 조용한 시간을 보내세요."
    },
    "wealth": {
      "score": 68,
      "message": "큰 지출보다 소소한 절약이 필요한 날입니다.",
      "tip": "충동구매를 피하고 리스트를 작성해서 쇼핑하세요."
    },
    "health": {
      "score": 85,
      "message": "전반적인 컨디션이 양호합니다. 운동하기 좋은 날.",
      "tip": "폐와 호흡기 건강을 위해 가벼운 유산소 운동을 추천합니다."
    }
  },
  "lucky": {
    "color": "검정색",
    "number": 6,
    "time": "오전 10-12시",
    "direction": "북쪽"
  },
  "caution": "성급한 결정은 피하고 한 번 더 생각해보세요.",
  "affirmation": "나는 오늘 하루를 의미있게 마무리할 수 있습니다."
}
```

---

## saju_base_prompt vs daily_fortune_prompt 비교

| 구분 | saju_base | daily_fortune |
|------|-----------|---------------|
| **모델** | GPT-5.2 | Gemini 3.0 Flash |
| **목적** | 평생 사주 심층 분석 | 오늘의 운세 |
| **톤** | 전문적, 심층적 | 친근, 긍정적 |
| **캐시** | 무기한 | 24시간 |
| **추가 입력** | 없음 | targetDate, saju_base_analysis |
| **출력 구조** | 성격/직업/재물/건강/대운 | 점수/카테고리/행운/주의사항 |

---

## 관련 코드

### DailyFortunePrompt.buildUserPrompt() (daily_fortune_prompt.dart:138)

```dart
@override
String buildUserPrompt(Map<String, dynamic> input) {
  final data = SajuInputData.fromJson(input);
  final dateStr = '${targetDate.year}년 ${targetDate.month}월 ${targetDate.day}일';
  final weekday = _getWeekday(targetDate.weekday);

  // GPT 평생사주 분석 결과가 있으면 참조
  final sajuBaseAnalysis = input['saju_base_analysis'] as Map<String, dynamic>?;

  return '''
## 대상 정보
- 이름: ${data.profileName}
- 생년월일: ${data.birthDate.year}년 ${data.birthDate.month}월 ${data.birthDate.day}일
...
## 오늘 날짜
$dateStr ($weekday)

${sajuBaseAnalysis != null ? '## 평생사주 분석 참고\n...' : ''}
''';
}
```

### 헬퍼 메서드

```dart
// 요일 변환
String _getWeekday(int weekday) {
  const days = ['월', '화', '수', '목', '금', '토', '일'];
  return '${days[weekday - 1]}요일';
}

// 용신 포맷
String _formatYongsin(Map<String, dynamic>? yongsin) {
  if (yongsin == null) return '용신 정보 없음';
  final parts = <String>[];
  if (yongsin['yongsin'] != null) parts.add('용신: ${yongsin['yongsin']}');
  if (yongsin['huisin'] != null) parts.add('희신: ${yongsin['huisin']}');
  ...
  return parts.join(', ');
}

// 대운 포맷 (현재 대운만)
String _formatDaeun(Map<String, dynamic>? daeun) {
  if (daeun == null) return '대운 정보 없음';
  final current = daeun['current'] as Map<String, dynamic>?;
  if (current == null) return '현재 대운 정보 없음';
  final gan = current['gan'] as String? ?? '';
  final ji = current['ji'] as String? ?? '';
  return '현재 대운: $gan$ji (${current['start_age']}세 ~ ${current['end_age']}세)';
}
```
