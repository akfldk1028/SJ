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
나쁜 예: "일간이 경금이므로 금 기운이..."
좋은 예: "당신의 단단한 경금(庚金) 기운이 오늘따라 유독 빛을 발하는데..."

### 3. 사자성어/고사성어 활용
각 카테고리 메시지에 자연스럽게 한 개 이상의 사자성어를 녹여주세요.

## 점수 규칙 (필수!)
- 카테고리별 점수는 **극적인 차이**가 있어야 합니다
- 4개 카테고리 중 최고점과 최저점의 **차이가 최소 30점 이상**이어야 합니다
- 점수 범위: 20~95 (너무 극단적이지 않게, 하지만 과감하게)
- 전부 60~80 사이로 모는 것은 **금지**합니다
- 예시: work=90, love=45, wealth=75, health=60 (차이 45점 ✅)
- 나쁜 예: work=75, love=70, wealth=68, health=72 (차이 7점 ❌)
- 사주 오행과 용신을 기반으로 논리적으로 점수를 산출하세요

## 메시지 길이
- overall_message: 150~200자 (충분히 풍성하게)
- overall_message_short: 60~80자 (사자성어 포함 한줄 요약)
- 카테고리 message: 120~180자 (구체적 조언 포함)
- tip: 한 문장 (실천 가능한 행동)

## 응답 형식
JSON 형식으로 구조화된 일운을 반환하세요.
''';

  @override
  String buildUserPrompt([Map<String, dynamic>? input]) {
    final data = SajuInputData.fromJson(input);
    final dateStr = '${targetDate.year}년 ${targetDate.month}월 ${targetDate.day}일';
    final weekday = _getWeekday(targetDate.weekday);

    return '''
## 대상 정보
- 이름: ${data.profileName}
- 일간: ${data.dayMaster}
- 오행 분포: ${data.ohengString}

## 오늘 날짜
$dateStr ($weekday)

## 용신 정보
${_formatYongsin(data.yongsin)}

---

오늘 $dateStr의 운세를 JSON 형식으로 알려주세요.

**점수 규칙 재확인**: 4개 카테고리 중 최고점과 최저점의 차이가 **최소 30점 이상**이어야 합니다. 모든 점수를 비슷하게 만들지 마세요.

반드시 아래 스키마를 따라주세요:

```json
{
  "date": "$dateStr",
  "overall_score": "(20~95 사이, 카테고리 평균 기반)",
  "overall_message": "(150~200자, 자연 비유와 사주 요소를 녹여 오늘 하루를 조언)",
  "overall_message_short": "(60~80자, 사자성어 포함 핵심 한줄 요약)",
  "categories": {
    "work": {
      "score": "(20~95 사이 정수)",
      "message": "(120~180자, 업무/학업 운세 - 자연 비유 활용)",
      "tip": "(실천 가능한 구체적 행동 한 문장)"
    },
    "love": {
      "score": "(20~95 사이 정수)",
      "message": "(120~180자, 연애/인간관계 운세)",
      "tip": "(실천 팁)"
    },
    "wealth": {
      "score": "(20~95 사이 정수)",
      "message": "(120~180자, 재물/금전 운세)",
      "tip": "(실천 팁)"
    },
    "health": {
      "score": "(20~95 사이 정수)",
      "message": "(120~180자, 건강 운세)",
      "tip": "(실천 팁)"
    }
  },
  "lucky": {
    "color": "오늘의 행운 색 (오행 기반)",
    "number": "(1~9 정수)",
    "time": "(구체적 시간대)",
    "direction": "(오행 기반 방향)"
  },
  "caution": "오늘 주의할 점 한 문장",
  "affirmation": "오늘의 긍정 확언 (사주 기반)"
}
```

중요: score 필드에는 **실제 정수**를 넣으세요. 문자열이 아닙니다.
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

    return parts.join(', ');
  }
}
