/// # 일운 프롬프트 (Gemini 2.0 Flash용)
///
/// ## 개요
/// 매일 갱신되는 오늘의 운세 분석 프롬프트입니다.
/// Gemini 2.0 Flash 모델을 사용하여 빠르고 저렴한 분석을 제공합니다.
///
/// ## 파일 위치
/// `frontend/lib/AI/prompts/daily_fortune_prompt.dart`
///
/// ## 실행 시점
/// 1. 프로필 저장 시 (평생 사주와 함께 병렬 실행)
/// 2. 매일 자정 (스케줄러 또는 수동 갱신)
/// 3. 사용자가 오늘의 운세 조회 시 (캐시 없으면)
///
/// ## 분석 내용
/// - 오늘의 종합 점수 (0-100)
/// - 업무/학업 운세
/// - 연애/인간관계 운세
/// - 재물/금전 운세
/// - 건강 운세
/// - 행운 요소 (색, 숫자, 시간, 방향)
/// - 주의사항 및 긍정 확언
///
/// ## 입력 데이터
/// SajuInputData의 간소화 버전 사용:
/// - 이름, 일간, 오행 분포
/// - 용신 정보
/// - 오늘 날짜
///
/// ## 출력 형식 (JSON)
/// ```json
/// {
///   "date": "2024년 12월 26일",
///   "overall_score": 75,
///   "overall_message": "오늘의 한마디",
///   "categories": {
///     "work": {"score": 80, "message": "...", "tip": "..."},
///     "love": {"score": 70, "message": "...", "tip": "..."},
///     "wealth": {"score": 65, "message": "...", "tip": "..."},
///     "health": {"score": 85, "message": "...", "tip": "..."}
///   },
///   "lucky": {"color": "...", "number": 7, "time": "...", "direction": "..."},
///   "caution": "주의할 점",
///   "affirmation": "긍정 확언"
/// }
/// ```
///
/// ## 호출 흐름
/// ```
/// profile_provider.dart
///   → _triggerAiAnalysis()
///     → SajuAnalysisService.analyzeOnProfileSave()
///       → _runDailyFortuneAnalysis()
///         → DailyFortunePrompt.buildMessages()
///           → AiApiService.callGemini()
///             → Edge Function (ai-gemini)
///               → Google Gemini API
/// ```
///
/// ## 캐시 정책
/// - 만료 기간: 24시간
/// - 동일 날짜 + profile_id는 캐시 반환
/// - 자정 이후 자동 만료 → 새로운 분석 실행
///
/// ## 비용 참고 (2024-12 기준)
/// - Gemini 2.0 Flash: 입력 $0.10/1M, 출력 $0.40/1M
/// - 평균 분석 1회: 약 $0.001 미만 (매우 저렴)

import '../core/ai_constants.dart';
import 'prompt_template.dart';

/// 일운 프롬프트
///
/// ## 사용 예시
/// ```dart
/// final prompt = DailyFortunePrompt(targetDate: DateTime.now());
/// final messages = prompt.buildMessages(sajuInputData.toJson());
///
/// final response = await aiApiService.callGemini(
///   messages: messages,
///   model: prompt.modelName,          // gemini-2.0-flash
///   maxTokens: prompt.maxTokens,      // 2048
///   temperature: prompt.temperature,  // 0.8 (약간 창의적)
/// );
/// ```
///
/// ## 생성자 파라미터
/// - `targetDate`: 운세를 분석할 대상 날짜 (기본: 오늘)
///
/// ## GPT-4o vs Gemini 선택 이유
/// - **속도**: Gemini가 훨씬 빠름 (일운은 자주 조회)
/// - **비용**: Gemini가 약 25배 저렴
/// - **정확도**: 일운은 간단하므로 Gemini로 충분
///
/// ## 프롬프트 특징
/// - 친근하고 긍정적인 톤
/// - 구체적이고 실천 가능한 조언
/// - 카테고리별 점수 (0-100)
class DailyFortunePrompt extends PromptTemplate {
  /// 운세를 분석할 대상 날짜
  final DateTime targetDate;

  /// 일운 프롬프트 생성
  ///
  /// [targetDate] 분석 대상 날짜 (기본: 오늘)
  DailyFortunePrompt({required this.targetDate});

  @override
  String get summaryType => SummaryType.dailyFortune;

  @override
  String get modelName => GoogleModels.dailyFortune;  // Gemini 3.0 Flash

  @override
  int get maxTokens => TokenLimits.dailyFortuneMaxTokens;

  @override
  double get temperature => 0.8;

  @override
  Duration? get cacheExpiry => CacheExpiry.dailyFortune;

  @override
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
- 힘든 날: 고진감래(苦盡甘來), 전화위복(轉禍爲福), 마부위침(磨斧爲針)
- 좋은 날: 일취월장(日就月將), 금상첨화(錦上添花), 순풍만범(順風滿帆)
- 주의가 필요한 날: 화사첨족(畫蛇添足), 욕속부달(欲速不達), 과유불급(過猶不及)

## 톤앤매너
- 점쟁이 말투 금지 (띵동~ 같은 표현 X)
- 무조건 긍정도, 무조건 부정도 아닌 균형 잡힌 조언
- 힘든 날도 희망을 잃지 않도록 따뜻하게
- 좋은 날은 과하지 않게 담담하게

## 응답 형식
JSON 형식으로 반환하되, 각 message는 2-3문장으로 자연스럽게 이어지도록 작성하세요.
''';

  @override
  String buildUserPrompt([Map<String, dynamic>? input]) {
    final data = SajuInputData.fromJson(input!);
    final dateStr = '${targetDate.year}년 ${targetDate.month}월 ${targetDate.day}일';
    final weekday = _getWeekday(targetDate.weekday);

    // GPT 평생사주 분석 결과가 있으면 참조
    final sajuBaseAnalysis = input!['saju_base_analysis'] as Map<String, dynamic>?;

    return '''
## 대상 정보
- 이름: ${data.profileName}
- 생년월일: ${data.birthDate.year}년 ${data.birthDate.month}월 ${data.birthDate.day}일
- 성별: ${data.gender}
- 일간: ${data.dayMaster}

## 사주 팔자
${data.sajuString}

## 오행 분포
${data.ohengString}

## 용신 정보
${_formatYongsin(data.yongsin)}

## 신강/신약
${_formatDayStrength(data.dayStrength)}

## 격국
${_formatGyeokguk(data.gyeokguk)}

## 12운성
${_formatTwelveUnsung(data.twelveUnsung)}

## 신살
${_formatSinsal(data.sinsal)}

## 길성
${_formatGilseong(data.gilseong)}

## 합충형파해
${_formatHapchung(data.hapchung)}

## 대운
${_formatDaeun(data.daeun)}

## 오늘 날짜
$dateStr ($weekday)

${sajuBaseAnalysis != null ? '''
## 평생사주 분석 참고
${_formatSajuBaseAnalysis(sajuBaseAnalysis)}
''' : ''}

---

위 사주 정보를 종합하여 오늘 $dateStr의 운세를 JSON 형식으로 알려주세요.

반드시 아래 스키마를 따라주세요. **예시처럼 책을 읽듯 풍부하고 자연스럽게!**

```json
{
  "date": "$dateStr",
  "overall_score": 75,
  "overall_message": "오늘은 마치 아침 안개가 서서히 걷히듯, 처음엔 흐릿하던 것들이 시간이 지나며 선명해지는 하루가 될 거예요. 경금(庚金) 일간인 당신은 쇠가 불에 담금질되듯 어려움 속에서 더 단단해지는 분이에요. 오늘 하루, 작은 시련이 있더라도 그건 당신을 더 빛나게 하는 과정이니 걱정 마세요. 저녁 무렵이면 '아, 오늘 하루 잘 버텼다'는 뿌듯함이 찾아올 거예요.",
  "categories": {
    "work": {
      "score": 80,
      "message": "아침에 뿌린 씨앗이 오후에 싹을 틔우는 날이에요. 당신의 일간이 경금이라 화(火) 기운이 강한 오늘은 직장에서 압박감을 느낄 수 있어요. 상사나 동료의 요구가 평소보다 많을 수 있습니다. 하지만 옛말에 '쇠도 두들겨야 명검이 된다'고 했듯이, 오늘의 압박이 내일의 실력이 됩니다. 오전에는 밀린 업무를 정리하고, 오후에는 새로운 아이디어를 제안해보세요. 예상치 못한 곳에서 인정받는 기회가 생길 수 있어요. 특히 오후 2-4시 사이에 좋은 소식이 있을 수 있으니 기대해도 좋아요.",
      "tip": "오전 10시에 가장 어려운 일을 먼저 시작하세요"
    },
    "love": {
      "score": 70,
      "message": "사랑도 물처럼 흐르는 게 자연스러워요. 오늘은 관계에서 작은 파도가 일 수 있어요. 상대방의 말이 마음에 걸리거나, 표현이 서툴러 오해가 생길 수 있습니다. 하지만 '말 한마디에 천 냥 빚을 갚는다'는 옛말처럼, 진심 어린 한마디가 모든 오해를 풀어줄 거예요. 솔로인 분들은 오늘 새로운 인연을 만나기보다 기존 인연을 돌아보는 시간을 가져보세요. 연락이 뜸했던 친구에게 먼저 안부를 전하면 뜻밖의 인연으로 이어질 수 있어요.",
      "tip": "상대방 말 끝까지 듣고, 내 감정도 솔직히 표현해보세요"
    },
    "wealth": {
      "score": 65,
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

점수는 0-100 사이로 설정하세요. **각 message는 예시처럼 5-7문장으로 풍부하게, 책을 읽듯 줄줄 읽히게!**
''';
  }

  String _getWeekday(int weekday) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return '${days[weekday - 1]}요일';
  }

  String _formatYongsin(Map<String, dynamic>? yongsin) {
    if (yongsin == null) return '용신 정보 없음';

    final parts = <String>[];
    if (yongsin['yongsin'] != null) parts.add('용신: ${yongsin['yongsin']}');
    if (yongsin['huisin'] != null) parts.add('희신: ${yongsin['huisin']}');
    if (yongsin['gisin'] != null) parts.add('기신: ${yongsin['gisin']}');
    if (yongsin['gusin'] != null) parts.add('구신: ${yongsin['gusin']}');

    return parts.join(', ');
  }

  String _formatDayStrength(Map<String, dynamic>? dayStrength) {
    if (dayStrength == null) return '신강/신약 정보 없음';

    final isSingang = dayStrength['is_singang'] as bool? ?? false;
    final score = dayStrength['score'] as num? ?? 0;
    final factors = dayStrength['factors'] as Map<String, dynamic>? ?? {};

    final factorParts = <String>[];
    if (factors['deukryeong'] == true) factorParts.add('득령');
    if (factors['deukji'] == true) factorParts.add('득지');
    if (factors['deuksi'] == true) factorParts.add('득시');
    if (factors['deukse'] == true) factorParts.add('득세');

    return '${isSingang ? "신강" : "신약"} (점수: $score, 요인: ${factorParts.isEmpty ? "없음" : factorParts.join(", ")})';
  }

  String _formatGyeokguk(Map<String, dynamic>? gyeokguk) {
    if (gyeokguk == null) return '격국 정보 없음';

    final name = gyeokguk['name'] as String? ?? '';
    final category = gyeokguk['category'] as String? ?? '';
    final description = gyeokguk['description'] as String? ?? '';

    if (name.isEmpty) return '격국 정보 없음';
    return '$name ($category) - $description';
  }

  String _formatTwelveUnsung(List<dynamic>? twelveUnsung) {
    if (twelveUnsung == null || twelveUnsung.isEmpty) return '12운성 정보 없음';

    final parts = <String>[];
    for (final item in twelveUnsung) {
      if (item is Map<String, dynamic>) {
        final pillar = item['pillar'] as String? ?? '';
        final name = item['name'] as String? ?? item['unsung'] as String? ?? '';
        if (name.isNotEmpty) {
          parts.add('$pillar: $name');
        }
      }
    }

    return parts.isEmpty ? '12운성 정보 없음' : parts.join(', ');
  }

  String _formatSinsal(List<Map<String, dynamic>>? sinsal) {
    if (sinsal == null || sinsal.isEmpty) return '신살 정보 없음';

    final parts = <String>[];
    for (final item in sinsal) {
      final pillar = item['pillar'] as String? ?? '';
      final name = item['sinsal'] as String? ?? item['name'] as String? ?? '';
      final fortuneType = item['fortuneType'] as String? ?? '';
      if (name.isNotEmpty) {
        parts.add('$pillar: $name${fortuneType.isNotEmpty ? "($fortuneType)" : ""}');
      }
    }

    return parts.isEmpty ? '신살 정보 없음' : parts.join(', ');
  }

  String _formatGilseong(List<Map<String, dynamic>>? gilseong) {
    if (gilseong == null || gilseong.isEmpty) return '길성 정보 없음';

    final parts = <String>[];
    for (final item in gilseong) {
      final pillar = item['pillar'] as String? ?? '';
      final name = item['name'] as String? ?? item['gilseong'] as String? ?? '';
      if (name.isNotEmpty) {
        parts.add('$pillar: $name');
      }
    }

    return parts.isEmpty ? '길성 정보 없음' : parts.join(', ');
  }

  String _formatHapchung(Map<String, dynamic>? hapchung) {
    if (hapchung == null || hapchung.isEmpty) return '합충형파해 정보 없음';

    final parts = <String>[];

    // 천간 관계
    if (hapchung['cheongan'] is Map) {
      final cheongan = hapchung['cheongan'] as Map<String, dynamic>;
      cheongan.forEach((type, relations) {
        if (relations is List && relations.isNotEmpty) {
          parts.add('천간 $type: ${relations.join(", ")}');
        }
      });
    }

    // 지지 관계
    if (hapchung['jiji'] is Map) {
      final jiji = hapchung['jiji'] as Map<String, dynamic>;
      jiji.forEach((type, relations) {
        if (relations is List && relations.isNotEmpty) {
          parts.add('지지 $type: ${relations.join(", ")}');
        }
      });
    }

    return parts.isEmpty ? '합충형파해 없음' : parts.join(' | ');
  }

  String _formatDaeun(Map<String, dynamic>? daeun) {
    if (daeun == null) return '대운 정보 없음';

    final current = daeun['current'] as Map<String, dynamic>?;
    if (current == null) return '현재 대운 정보 없음';

    final gan = current['gan'] as String? ?? '';
    final ji = current['ji'] as String? ?? '';
    final startAge = current['start_age'] as num? ?? 0;
    final endAge = current['end_age'] as num? ?? 0;

    return '현재 대운: $gan$ji ($startAge세 ~ $endAge세)';
  }

  String _formatSajuBaseAnalysis(Map<String, dynamic> analysis) {
    final parts = <String>[];

    // 핵심 요약만 추출
    if (analysis['personality'] != null) {
      final personality = analysis['personality'];
      if (personality is Map && personality['summary'] != null) {
        parts.add('성격: ${personality['summary']}');
      }
    }

    if (analysis['career'] != null) {
      final career = analysis['career'];
      if (career is Map && career['suitable_fields'] != null) {
        parts.add('적합 분야: ${career['suitable_fields']}');
      }
    }

    if (analysis['health'] != null) {
      final health = analysis['health'];
      if (health is Map && health['weak_organs'] != null) {
        parts.add('주의 건강: ${health['weak_organs']}');
      }
    }

    return parts.isEmpty ? '평생사주 분석 참고' : parts.join('\n');
  }
}
