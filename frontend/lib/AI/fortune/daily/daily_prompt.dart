/// # 일운 프롬프트 (v2.0 - FortuneInputData 기반)
///
/// ## 개요
/// 매일 갱신되는 오늘의 운세 분석 프롬프트
/// Gemini 3.0 Flash 모델 사용 (빠르고 저렴)
///
/// ## v2.0 변경사항
/// - PromptTemplate 상속에서 독립 클래스로 변경
/// - FortuneInputData 직접 사용 (기존 SajuInputData 대신)
/// - fortune/ 폴더 패턴 통일
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/daily/daily_prompt.dart`
///
/// ## 모델
/// Gemini 3.0 Flash ($0.50 input, $3.00 output per 1M tokens)

import '../../core/ai_constants.dart';
import '../common/fortune_input_data.dart';

/// 일운 프롬프트 템플릿
class DailyPrompt {
  /// 입력 데이터 (saju_analyses 기반)
  final FortuneInputData inputData;

  /// 운세를 분석할 대상 날짜
  final DateTime targetDate;

  DailyPrompt({
    required this.inputData,
    required this.targetDate,
  });

  /// 분석 유형
  String get summaryType => SummaryType.dailyFortune;

  /// 모델명 (Gemini 3.0 Flash)
  String get modelName => GoogleModels.dailyFortune;

  /// 최대 토큰 수
  int get maxTokens => TokenLimits.dailyFortuneMaxTokens;

  /// Temperature (약간 창의적)
  double get temperature => 0.8;

  /// 캐시 만료
  Duration? get cacheExpiry => CacheExpiry.dailyFortune;

  /// 요일 문자열
  String get _weekdayString {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return '${days[targetDate.weekday - 1]}요일';
  }

  /// 날짜 문자열 (예: "2026년 1월 21일")
  String get _dateString {
    return '${targetDate.year}년 ${targetDate.month}월 ${targetDate.day}일';
  }

  /// 시스템 프롬프트
  String get systemPrompt => '''
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
- 최대한 다양하고 사자성어 해석까지 

## 톤앤매너
- 점쟁이 말투 금지 (띵동~ 같은 표현 X)
- 무조건 긍정도, 무조건 부정도 아닌 균형 잡힌 조언
- 힘든 날도 희망을 잃지 않도록 따뜻하게
- 좋은 날은 과하지 않게 담담하게

## 응답 형식
JSON 형식으로 반환하되, 각 message는 2-3문장으로 자연스럽게 이어지도록 작성하세요.
''';

  /// 사용자 프롬프트 생성
  String buildUserPrompt() {
    return '''
## 대상 정보
- 이름: ${inputData.profileName}
- 생년월일: ${inputData.birthDate}
${inputData.birthTime != null ? '- 태어난 시간: ${inputData.birthTime}' : ''}
- 성별: ${inputData.genderKorean}
- 일간: ${inputData.dayGan ?? '-'} (${inputData.dayGanDescription ?? '-'})

## 사주 팔자
${inputData.sajuPaljaTable}

## 오행 분포
- 일간 오행: ${inputData.dayGanElementFull ?? '-'}

## 용신 정보
${inputData.yongsinInfo}

## 신강/신약
${inputData.dayStrengthInfo}

## 신살
${inputData.sinsalInfo}

## 합충형파해
${inputData.hapchungInfo}

## 오늘 날짜
$_dateString ($_weekdayString)

---

위 사주 정보를 종합하여 오늘 $_dateString의 운세를 JSON 형식으로 알려주세요.

반드시 아래 스키마를 따라주세요. **예시처럼 책을 읽듯 풍부하고 자연스럽게!**

```json
{
  "date": "$_dateString",
  "overall_score": 75,
  "overall_message": "오늘은 마치 아침 안개가 서서히 걷히듯, 처음엔 흐릿하던 것들이 시간이 지나며 선명해지는 하루가 될 거예요. ${inputData.dayGan ?? '?'} 일간인 당신은 ... (5-7문장)",
  "overall_message_short": "${inputData.dayGan ?? '?'} 일간과 사자성어 정보를 통합해 하루 운세 설명... (2-3문장)",
  "categories": {
    "work": {
      "score": 80,
      "message": "아침에 뿌린 씨앗이 오후에 싹을 틔우는 날이에요. ... (5-7문장)",
      "tip": "오전 10시에 가장 어려운 일을 먼저 시작하세요"
    },
    "love": {
      "score": 70,
      "message": "사랑도 물처럼 흐르는 게 자연스러워요. ... (5-7문장)",
      "tip": "상대방 말 끝까지 듣고, 내 감정도 솔직히 표현해보세요"
    },
    "wealth": {
      "score": 65,
      "message": "돈은 물과 같아서 막으면 넘치고, 흘려보내면 다시 돌아와요. ... (5-7문장)",
      "tip": "오늘 지갑을 열기 전 '이게 정말 필요한가?' 10초만 생각해보세요"
    },
    "health": {
      "score": 85,
      "message": "몸은 마음의 집이에요. ... (5-7문장)",
      "tip": "점심 후 10분 산책, 저녁엔 따뜻한 차 한 잔 어떠세요?"
    }
  },
  "lucky": {
    "color": "행운색 (용신 기반 설명)",
    "number": 7,
    "time": "오전 10-12시",
    "direction": "북쪽"
  },
  "idiom": {
    "chinese": "磨斧爲針",
    "korean": "마부위침",
    "meaning": "도끼를 갈아 바늘을 만든다",
    "message": "오늘에 딱 맞는 의미 풀이 (2-3문장)"
  },
  "caution": "오늘은 성급한 판단이 가장 위험해요. ... (2문장)",
  "affirmation": "${inputData.dayGan ?? '?'} 일간과 사자성어 정보를 통합해 하루 운세 설명 객관적으로 (2-3문장)"
}
```

점수는 0-100 사이로 설정하세요. **각 message는 예시처럼 5-7문장으로 풍부하게, 책을 읽듯 줄줄 읽히게!**
''';
  }
}
