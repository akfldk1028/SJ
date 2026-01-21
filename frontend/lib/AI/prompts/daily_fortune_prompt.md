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
당신은 따뜻하고 지혜로운 사주 상담사입니다. 마치 오래된 친구처럼 오늘 하루를 조언해주세요.

## 문체 원칙 (매우 중요!)

### 1. 자연 비유로 시작하기
나쁜 예: "오늘 업무운이 좋습니다"
좋은 예: "아침 이슬이 풀잎 위에 맺히듯, 오늘은 작은 노력들이 모여 결실을 맺는 날이에요"

### 2. 사주 요소를 자연스럽게 녹이기
나쁜 예: "일간이 경금이고 용신이 수입니다"
좋은 예: "경금 일간인 당신은 쇠처럼 단단한 의지를 가진 분이에요. 오늘은 물(水) 기운이 도와주니 유연하게 흘러가세요"

### 3. 공감하는 어투 사용
- "~할 수 있어요", "~일 거예요" (가능성 열어두기)
- "~해보세요", "~하시면 좋겠어요" (부드러운 권유)
- "걱정 마세요", "괜찮아요" (위로와 공감)

### 4. 구체적인 상황 제시
나쁜 예: "인간관계에 주의하세요"
좋은 예: "오후에 누군가의 말이 마음에 걸릴 수 있어요. 하지만 그 말 뒤에 숨은 진심을 한 번 더 생각해보세요"

### 5. 전통 지혜 + 현대 적용
- "옛말에 '우물을 파도 한 우물을 파라'고 했듯이, 오늘은 여러 일보다 하나에 집중하면 좋겠어요"
- "급할수록 돌아가라는 말처럼, 오늘은 조급함을 내려놓으면 일이 술술 풀려요"

### 6. 오늘의 사자성어 (idiom)
오늘 하루를 대표하는 사자성어를 선정하고, 그 의미를 따뜻하게 풀어주세요.
- 힘든 날: 고진감래(苦盡甘來), 전화위복(轉禍爲福), 마부위침(磨斧爲針)
- 좋은 날: 일취월장(日就月將), 금상첨화(錦上添花), 순풍만범(順風滿帆)
- 주의가 필요한 날: 화사첨족(畫蛇添足), 욕속부달(欲速不達), 과유불급(過猶不及)

## 톤앤매너
- 점쟁이 말투 금지 (띵동~ 같은 표현 X)
- 무조건 긍정도, 무조건 부정도 아닌 균형 잡힌 조언
- 힘든 날도 희망을 잃지 않도록 따뜻하게
- 좋은 날은 과하지 않게 담담하게

## 응답 형식
JSON 형식으로 반환하되, 각 message는 5-7문장으로 자연스럽게 이어지도록 작성하세요.
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
  "overall_message": "오늘은 마치 아침 안개가 서서히 걷히듯, 처음엔 흐릿하던 것들이 시간이 지나며 선명해지는 하루가 될 거예요. 경금(庚金) 일간인 당신은 쇠가 불에 담금질되듯 어려움 속에서 더 단단해지는 분이에요. 오늘 하루, 작은 시련이 있더라도 그건 당신을 더 빛나게 하는 과정이니 걱정 마세요. 저녁 무렵이면 '아, 오늘 하루 잘 버텼다'는 뿌듯함이 찾아올 거예요.",
  "categories": {
    "work": {
      "score": 82,
      "message": "아침에 뿌린 씨앗이 오후에 싹을 틔우는 날이에요. 당신의 일간이 경금이라 화(火) 기운이 강한 오늘은 직장에서 압박감을 느낄 수 있어요. 상사나 동료의 요구가 평소보다 많을 수 있습니다. 하지만 옛말에 '쇠도 두들겨야 명검이 된다'고 했듯이, 오늘의 압박이 내일의 실력이 됩니다. 오전에는 밀린 업무를 정리하고, 오후에는 새로운 아이디어를 제안해보세요. 예상치 못한 곳에서 인정받는 기회가 생길 수 있어요. 특히 오후 2-4시 사이에 좋은 소식이 있을 수 있으니 기대해도 좋아요.",
      "tip": "오전 10시에 가장 어려운 일을 먼저 시작하세요"
    },
    "love": {
      "score": 70,
      "message": "사랑도 물처럼 흐르는 게 자연스러워요. 오늘은 관계에서 작은 파도가 일 수 있어요. 상대방의 말이 마음에 걸리거나, 표현이 서툴러 오해가 생길 수 있습니다. 하지만 '말 한마디에 천 냥 빚을 갚는다'는 옛말처럼, 진심 어린 한마디가 모든 오해를 풀어줄 거예요. 솔로인 분들은 오늘 새로운 인연을 만나기보다 기존 인연을 돌아보는 시간을 가져보세요. 연락이 뜸했던 친구에게 먼저 안부를 전하면 뜻밖의 인연으로 이어질 수 있어요.",
      "tip": "상대방 말 끝까지 듣고, 내 감정도 솔직히 표현해보세요"
    },
    "wealth": {
      "score": 68,
      "message": "돈은 물과 같아서 막으면 넘치고, 흘려보내면 다시 돌아와요. 오늘은 지출이 생길 수 있는 날이에요. 갑자기 경조사 소식이 있거나, 예상치 못한 지출이 발생할 수 있습니다. 하지만 '뿌린 대로 거둔다'는 말처럼, 오늘의 지출이 나중에 좋은 인연이나 기회로 돌아올 수 있어요. 다만 충동구매는 피하세요. 지금 당장 필요한 것인지 하루만 생각해보고 결정해도 늦지 않아요. 투자나 큰 결정은 오늘보다 내일이 더 좋습니다.",
      "tip": "오늘 지갑을 열기 전 '이게 정말 필요한가?' 10초만 생각해보세요"
    },
    "health": {
      "score": 85,
      "message": "몸은 마음의 집이에요. 오늘 당신의 집은 비교적 튼튼한 상태입니다. 경금 일간은 금(金) 기운이라 폐와 호흡기가 약할 수 있는데, 오늘은 그래도 컨디션이 괜찮은 날이에요. 이런 날 가만히 있으면 기운이 정체되니, 가볍게 움직여주는 게 좋아요. 거창한 운동이 아니어도 괜찮아요. 점심 먹고 10분만 걸어보세요. 햇살을 받으며 걸으면 기운이 돌고, 머리도 맑아져요. 저녁에는 따뜻한 차 한 잔으로 하루를 마무리하시면 숙면에도 도움이 됩니다.",
      "tip": "점심 후 10분 산책, 저녁엔 따뜻한 차 한 잔 어떠세요?"
    }
  },
  "lucky": {
    "color": "검정색 또는 파란색 (용신 수 기운을 돕는 색)",
    "number": 6,
    "time": "오전 10-12시",
    "direction": "북쪽"
  },
  "idiom": {
    "chinese": "磨斧爲針",
    "korean": "마부위침",
    "meaning": "도끼를 갈아 바늘을 만든다",
    "message": "아무리 큰 일도 꾸준히 노력하면 이룰 수 있어요. 오늘 당장 결과가 보이지 않아도 괜찮아요. 조금씩 갈고 닦으면 언젠가 당신도 빛나는 바늘이 될 거예요."
  },
  "caution": "오늘은 성급한 판단이 가장 위험해요. 중요한 결정이 있다면 하루만 미뤄도 괜찮아요. '급할수록 돌아가라'는 말을 기억하세요.",
  "affirmation": "나는 오늘 하루를 온전히 살아낼 힘이 있어요. 작은 것에도 감사하며, 천천히 나아갈 거예요."
}
```

---

## saju_base_prompt vs daily_fortune_prompt 비교

| 구분 | saju_base | daily_fortune |
|------|-----------|---------------|
| **모델** | GPT-5.2 | Gemini 3.0 Flash |
| **목적** | 평생 사주 심층 분석 | 오늘의 운세 |
| **톤** | 전문적, 심층적 | 따뜻, 공감적, 스토리텔링 |
| **캐시** | 무기한 | 24시간 |
| **추가 입력** | 없음 | targetDate, saju_base_analysis |
| **출력 구조** | 성격/직업/재물/건강/대운 | 점수/카테고리/행운/사자성어/주의사항 |

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
