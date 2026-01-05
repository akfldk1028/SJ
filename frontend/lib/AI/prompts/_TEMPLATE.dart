/// ┌─────────────────────────────────────────────────────────────────────────────┐
/// │                        새 프롬프트 템플릿                                     │
/// │                                                                             │
/// │  사용법:                                                                     │
/// │  1. 이 파일을 복사해서 새 파일 생성 (예: yearly_fortune_prompt.dart)          │
/// │  2. 클래스명 변경 (예: _TemplatePrompt → YearlyFortunePrompt)                │
/// │  3. 모든 TODO 항목 채우기                                                    │
/// │  4. 필요시 ai_constants.dart에 SummaryType 상수 추가                         │
/// │                                                                             │
/// │  담당: JH_AI (분석용) / Jina (대화용)                                         │
/// └─────────────────────────────────────────────────────────────────────────────┘

import '../core/ai_constants.dart';
import 'prompt_template.dart';

/// TODO: 클래스명 변경하기!
/// 예: YearlyFortunePrompt, MonthlyFortunePrompt, CompatibilityPrompt
class _TemplatePrompt extends PromptTemplate {
  // ═══════════════════════════════════════════════════════════════════════════
  // 생성자 (필요한 파라미터 추가)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 예: 년운이면 targetYear, 궁합이면 partnerData 등
  // final DateTime targetDate;
  // _TemplatePrompt({required this.targetDate});

  // ═══════════════════════════════════════════════════════════════════════════
  // 필수 항목 (반드시 채우기!)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 분석 유형 (DB 저장용)
  ///
  /// ai_constants.dart의 SummaryType에 정의된 값 사용
  /// 새 유형이면 SummaryType에 추가 필요!
  ///
  /// 예시:
  /// - SummaryType.sajuBase (평생 사주)
  /// - SummaryType.dailyFortune (일운)
  /// - 'yearly_fortune' (새로 추가)
  @override
  String get summaryType => 'TODO_summary_type'; // TODO: 변경!

  /// 사용할 AI 모델
  ///
  /// OpenAI 모델 (분석용):
  /// - OpenAIModels.gpt52Thinking (추론 특화, 100-150초)
  /// - OpenAIModels.gpt52Instant (빠른 응답)
  /// - OpenAIModels.gpt4oMini (빠르고 저렴, 레거시)
  ///
  /// Google 모델 (대화/일운용):
  /// - GoogleModels.gemini30Flash (빠르고 저렴)
  /// - GoogleModels.gemini30Pro (고급 추론)
  @override
  String get modelName => OpenAIModels.gpt52Thinking; // TODO: 선택!

  /// 최대 응답 토큰 수
  ///
  /// 참고:
  /// - 짧은 응답: 500-1000
  /// - 보통 응답: 1500-2500
  /// - 긴 분석: 3000-5000
  @override
  int get maxTokens => 2000; // TODO: 조절!

  /// Temperature (창의성 수준)
  ///
  /// - 0.0: 결정적, 일관된 응답 (분석용)
  /// - 0.7: 적당한 창의성 (기본값)
  /// - 1.0: 창의적 (대화용)
  @override
  double get temperature => 0.7; // TODO: 선택!

  /// 캐시 만료 시간
  ///
  /// - null: 무기한 (평생 사주 등)
  /// - Duration(hours: 24): 24시간 (일운)
  /// - Duration(days: 30): 30일 (월운)
  /// - CacheExpiry 상수 사용 권장
  @override
  Duration? get cacheExpiry => null; // TODO: 설정!

  /// 시스템 프롬프트 (AI의 역할 정의)
  ///
  /// 포함할 내용:
  /// 1. AI의 역할/전문성
  /// 2. 응답 원칙
  /// 3. 응답 형식 (JSON 스키마 등)
  @override
  String get systemPrompt => '''
당신은 한국 전통 사주명리학 전문가입니다.

## 원칙
1. 정확하고 전문적인 분석 제공
2. 긍정적이고 희망적인 방향으로 해석
3. 실용적인 조언 포함

## 응답 형식
JSON 형식으로 구조화된 분석을 반환하세요.
'''; // TODO: 작성!

  /// 사용자 프롬프트 생성
  ///
  /// [input] SajuInputData.toJson() 결과
  /// 반환: 완성된 사용자 프롬프트
  @override
  String buildUserPrompt(Map<String, dynamic> input) {
    final data = SajuInputData.fromJson(input);

    return '''
## 대상 정보
- 이름: ${data.profileName}
- 생년월일: ${data.birthDate}
- 일간: ${data.dayMaster}
- 사주: ${data.sajuString}
- 오행: ${data.ohengString}

## 분석 요청
[분석 내용 설명]

## 응답 형식
```json
{
  "field1": "값1",
  "field2": "값2",
  "score": 75
}
```
'''; // TODO: 작성!
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 등록 체크리스트
// ═══════════════════════════════════════════════════════════════════════════════
//
// [ ] 1. 클래스명 변경 완료
// [ ] 2. summaryType 설정 (필요시 ai_constants.dart에 추가)
// [ ] 3. modelName 선택 (OpenAI or Google)
// [ ] 4. maxTokens, temperature, cacheExpiry 설정
// [ ] 5. systemPrompt 작성 완료
// [ ] 6. buildUserPrompt 작성 완료 (JSON 스키마 포함)
// [ ] 7. 사용하는 서비스에서 import
// [ ] 8. 테스트 완료
//
// ═══════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════════
// 참고: JSON 응답 스키마 예시
// ═══════════════════════════════════════════════════════════════════════════════
//
// 년운 예시:
// ```json
// {
//   "year": "2025",
//   "overall_score": 75,
//   "summary": "올해 전반적인 운세 요약",
//   "quarterly": {
//     "q1": {"score": 70, "focus": "1분기 집중할 점"},
//     "q2": {"score": 80, "focus": "2분기 집중할 점"},
//     "q3": {"score": 75, "focus": "3분기 집중할 점"},
//     "q4": {"score": 85, "focus": "4분기 집중할 점"}
//   },
//   "advice": "올해의 핵심 조언"
// }
// ```
//
// 궁합 예시:
// ```json
// {
//   "compatibility_score": 85,
//   "summary": "궁합 요약",
//   "strengths": ["장점1", "장점2"],
//   "challenges": ["주의점1", "주의점2"],
//   "advice": "관계 발전을 위한 조언"
// }
// ```
