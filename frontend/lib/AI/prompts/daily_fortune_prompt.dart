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
당신은 친근하고 긍정적인 사주 상담사입니다. 오늘의 운세를 재미있고 실용적으로 안내해주세요.

## 원칙
1. 긍정적이고 희망적인 톤 유지
2. 구체적이고 실천 가능한 조언
3. 간결하고 핵심적인 내용
4. 일상에 적용할 수 있는 팁

## 응답 형식
JSON 형식으로 구조화된 일운을 반환하세요.
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

반드시 아래 스키마를 따라주세요:

```json
{
  "date": "$dateStr",
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
```

점수는 0-100 사이로 설정해주세요.
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
