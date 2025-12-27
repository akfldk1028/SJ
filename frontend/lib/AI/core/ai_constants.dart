/// # AI 모듈 상수 정의
///
/// ## 개요
/// AI 분석에 사용되는 모든 상수를 중앙 관리합니다.
/// - 모델명 및 버전
/// - 토큰 가격 (비용 추적용)
/// - 분석 유형 (DB summary_type 매핑)
/// - 캐시 정책
/// - 토큰 제한
///
/// ## 파일 위치
/// `frontend/lib/AI/core/ai_constants.dart`
///
/// ## 관련 파일
/// - `ai_api_service.dart`: 비용 계산에 가격 정보 사용
/// - `prompt_template.dart`: 모델명, 토큰 제한 참조
/// - `mutations.dart`: SummaryType, ModelProvider 사용
///
/// ## 사용 예시
/// ```dart
/// import 'package:your_app/AI/core/ai_constants.dart';
///
/// // 모델 선택
/// final model = OpenAIModels.gpt4o;
///
/// // 분석 유형
/// final type = SummaryType.dailyFortune;
///
/// // 비용 계산
/// final cost = OpenAIPricing.calculateCost(
///   model: model,
///   promptTokens: 1000,
///   completionTokens: 500,
/// );
/// ```
///
/// ## 가격 업데이트 주기
/// - 분기별로 OpenAI/Google 공식 가격 페이지 확인
/// - https://openai.com/pricing
/// - https://ai.google.dev/pricing

// ═══════════════════════════════════════════════════════════════════════════
// OpenAI 모델 정보
// ═══════════════════════════════════════════════════════════════════════════

/// OpenAI 모델 식별자
///
/// ## 모델 선택 가이드
/// - `gpt52`: GPT-5.2 추론 특화 (2025.12 출시) → 사주 분석용
/// - `gpt52Pro`: GPT-5.2 Pro 최고 품질 → 복잡한 분석용
/// - `gpt4o`: 레거시 → 호환성 유지용
///
/// ## 참고
/// - 모델 ID는 OpenAI API에서 사용하는 정확한 값
/// - 버전이 바뀌면 여기만 수정하면 됨
abstract class OpenAIModels {
  /// GPT-5.2 (2025년 12월 출시)
  /// - Thinking - 추론 특화
  /// - 사주 분석에 최적화
  /// - 복잡한 논리 추론 능력 강화
  static const String gpt52 = 'gpt-5.2';

  /// GPT-5.2 Chat (빠른 응답)
  /// - Instant - 빠른 응답
  /// - 대화형 질의에 적합
  static const String gpt52Chat = 'gpt-5.2-chat-latest';

  /// GPT-5.2 Pro (최고 품질)
  /// - Pro - 가장 정확한 분석
  /// - 비용 높음
  static const String gpt52Pro = 'gpt-5.2-pro';

  /// GPT-4o (레거시)
  /// - 이전 버전 호환용
  /// - Chat Completions API
  static const String gpt4o = 'gpt-4o';

  /// GPT-4o Mini (레거시)
  /// - 빠른 응답 속도
  /// - 저렴한 비용
  static const String gpt4oMini = 'gpt-4o-mini';

  /// 사주 분석용 기본 모델
  /// - GPT-5.2: 추론 능력 강화로 사주 분석에 최적
  /// - 프로필당 1회만 실행되므로 비용 부담 적음
  static const String sajuAnalysis = gpt52;
}

// ═══════════════════════════════════════════════════════════════════════════
// Google (Gemini) 모델 정보
// ═══════════════════════════════════════════════════════════════════════════

/// Google Gemini 모델 식별자
///
/// ## 모델 선택 가이드
/// - `gemini20Flash`: 빠름, 저렴 → 일운/대화용
/// - `gemini15Pro`: 더 정확 → 복잡한 분석용
///
/// ## 참고
/// - Gemini API 엔드포인트에서 사용하는 정확한 모델 ID
abstract class GoogleModels {
  /// Gemini 2.0 Flash (실험적)
  /// - 가장 빠른 응답
  /// - 저렴한 비용
  /// - 일운 분석에 최적
  static const String gemini20Flash = 'gemini-2.0-flash';

  /// Gemini 1.5 Pro
  /// - 더 긴 컨텍스트
  /// - 복잡한 추론
  static const String gemini15Pro = 'gemini-1.5-pro';

  /// 대화/일운용 기본 모델
  /// - 속도 우선, 비용 효율적
  static const String chat = gemini20Flash;
}

// ═══════════════════════════════════════════════════════════════════════════
// 토큰 가격 (USD per 1M tokens)
// ═══════════════════════════════════════════════════════════════════════════

/// OpenAI 토큰 가격 (2025-12 기준)
///
/// ## 가격 출처
/// https://openai.com/pricing
///
/// ## 비용 계산 공식
/// ```
/// 입력 비용 = (prompt_tokens - cached_tokens) × input_price / 1,000,000
/// 캐시 비용 = cached_tokens × cached_price / 1,000,000
/// 출력 비용 = completion_tokens × output_price / 1,000,000
/// 총 비용 = 입력 비용 + 캐시 비용 + 출력 비용
/// ```
abstract class OpenAIPricing {
  // ─────────────────────────────────────────────────────────────────────────
  // GPT-5.2 가격 (per 1M tokens) - 2025-12-11 출시
  // ─────────────────────────────────────────────────────────────────────────
  static const double gpt52Input = 1.75;
  static const double gpt52Output = 14.00;
  static const double gpt52Cached = 0.175; // 90% 할인

  // ─────────────────────────────────────────────────────────────────────────
  // GPT-4o 가격 (per 1M tokens) - 레거시
  // ─────────────────────────────────────────────────────────────────────────
  static const double gpt4oInput = 2.50;
  static const double gpt4oOutput = 10.00;
  static const double gpt4oCached = 1.25; // 50% 할인

  // ─────────────────────────────────────────────────────────────────────────
  // GPT-4o-mini 가격 (per 1M tokens) - 레거시
  // ─────────────────────────────────────────────────────────────────────────
  static const double gpt4oMiniInput = 0.15;
  static const double gpt4oMiniOutput = 0.60;
  static const double gpt4oMiniCached = 0.075;

  /// 모델별 가격 조회
  ///
  /// [model] OpenAI 모델 ID (예: 'gpt-5.2')
  /// 반환: {input, output, cached} 가격 맵 또는 null
  static Map<String, double>? getModelPricing(String model) {
    switch (model) {
      case 'gpt-5.2':
      case 'gpt-5.2-chat-latest':
      case 'gpt-5.2-pro':
        return {'input': gpt52Input, 'output': gpt52Output, 'cached': gpt52Cached};
      case 'gpt-4o':
        return {'input': gpt4oInput, 'output': gpt4oOutput, 'cached': gpt4oCached};
      case 'gpt-4o-mini':
        return {'input': gpt4oMiniInput, 'output': gpt4oMiniOutput, 'cached': gpt4oMiniCached};
      default:
        return null;
    }
  }

  /// 비용 계산
  ///
  /// [model] 모델 ID
  /// [promptTokens] 입력 토큰 수
  /// [completionTokens] 출력 토큰 수
  /// [cachedTokens] 캐시된 토큰 수 (기본 0)
  static double calculateCost({
    required String model,
    required int promptTokens,
    required int completionTokens,
    int cachedTokens = 0,
  }) {
    final pricing = getModelPricing(model);
    if (pricing == null) return 0.0;

    final inputCost = (promptTokens - cachedTokens) * pricing['input']! / 1000000;
    final cachedCost = cachedTokens * pricing['cached']! / 1000000;
    final outputCost = completionTokens * pricing['output']! / 1000000;

    return inputCost + cachedCost + outputCost;
  }
}

/// Google Gemini 토큰 가격 (2024-12 기준)
///
/// ## 가격 출처
/// https://ai.google.dev/pricing
///
/// ## 참고
/// - Gemini는 캐시 할인이 다르게 적용됨
/// - 현재는 캐시 미적용
abstract class GeminiPricing {
  // ─────────────────────────────────────────────────────────────────────────
  // Gemini 2.0 Flash 가격 (per 1M tokens)
  // ─────────────────────────────────────────────────────────────────────────
  static const double gemini20FlashInput = 0.10;
  static const double gemini20FlashOutput = 0.40;

  // ─────────────────────────────────────────────────────────────────────────
  // Gemini 1.5 Pro 가격 (per 1M tokens)
  // ─────────────────────────────────────────────────────────────────────────
  static const double gemini15ProInput = 1.25;
  static const double gemini15ProOutput = 5.00;

  /// 모델별 가격 조회
  static Map<String, double>? getModelPricing(String model) {
    if (model.contains('gemini-2.0-flash')) {
      return {'input': gemini20FlashInput, 'output': gemini20FlashOutput};
    }
    if (model.contains('gemini-1.5-pro')) {
      return {'input': gemini15ProInput, 'output': gemini15ProOutput};
    }
    return null;
  }

  /// 비용 계산
  static double calculateCost({
    required String model,
    required int promptTokens,
    required int completionTokens,
  }) {
    final pricing = getModelPricing(model);
    if (pricing == null) return 0.0;

    final inputCost = promptTokens * pricing['input']! / 1000000;
    final outputCost = completionTokens * pricing['output']! / 1000000;

    return inputCost + outputCost;
  }
}

// 레거시 호환용 (deprecated)
@Deprecated('Use OpenAIPricing or GeminiPricing instead')
abstract class TokenPricing {
  static const double gpt4oInput = OpenAIPricing.gpt4oInput;
  static const double gpt4oOutput = OpenAIPricing.gpt4oOutput;
  static const double gpt4oCachedInput = OpenAIPricing.gpt4oCached;
  static const double gpt4oMiniInput = OpenAIPricing.gpt4oMiniInput;
  static const double gpt4oMiniOutput = OpenAIPricing.gpt4oMiniOutput;
  static const double gemini20FlashInput = GeminiPricing.gemini20FlashInput;
  static const double gemini20FlashOutput = GeminiPricing.gemini20FlashOutput;
}

// ═══════════════════════════════════════════════════════════════════════════
// 분석 유형 (Summary Type)
// ═══════════════════════════════════════════════════════════════════════════

/// AI 분석 유형
///
/// ## DB 매핑
/// `ai_summaries.summary_type` 컬럼의 ENUM 값과 1:1 매핑
///
/// ## 유형별 특성
/// | 유형 | 모델 | 캐시 | 트리거 |
/// |------|------|------|--------|
/// | saju_base | GPT-4o | 무기한 | 프로필 저장 |
/// | daily_fortune | Gemini | 24시간 | 프로필 저장, 매일 자정 |
/// | monthly_fortune | GPT-4o | 7일 | 매월 1일 |
/// | yearly_fortune | GPT-4o | 30일 | 매년 1월 1일 |
/// | question_answer | Gemini | 없음 | 사용자 질문 |
/// | compatibility | GPT-4o | 무기한 | 궁합 요청 |
abstract class SummaryType {
  /// 기본 사주 분석 (평생 운세)
  /// - 프로필 저장 시 1회 실행
  /// - 성격, 적성, 재물운, 건강 등 종합 분석
  static const String sajuBase = 'saju_base';

  /// 일운 (오늘의 운세)
  /// - 매일 자정에 갱신 가능
  /// - 프로필 저장 시에도 실행
  static const String dailyFortune = 'daily_fortune';

  /// 월운
  /// - 매월 갱신
  static const String monthlyFortune = 'monthly_fortune';

  /// 년운
  /// - 매년 갱신
  static const String yearlyFortune = 'yearly_fortune';

  /// 질문 응답
  /// - 사용자 자유 질문에 대한 답변
  /// - 캐시하지 않음
  static const String questionAnswer = 'question_answer';

  /// 궁합 분석
  /// - 두 프로필 간 궁합
  static const String compatibility = 'compatibility';
}

// ═══════════════════════════════════════════════════════════════════════════
// 캐시 만료 정책
// ═══════════════════════════════════════════════════════════════════════════

/// 분석 결과 캐시 만료 시간
///
/// ## 캐시 동작
/// - `null`: 무기한 캐시 (수동 갱신만 가능)
/// - `Duration`: 해당 시간 후 자동 만료
///
/// ## DB 연동
/// - `ai_summaries.expires_at` 컬럼에 저장
/// - 쿼리 시 만료 여부 체크
abstract class CacheExpiry {
  /// 기본 사주 분석: 무기한
  /// - 생년월일이 바뀌지 않으므로 갱신 불필요
  /// - 프로필 수정 시에만 재생성
  static Duration? get sajuBase => null;

  /// 일운: 24시간
  /// - 매일 자정 기준으로 갱신
  static const Duration dailyFortune = Duration(hours: 24);

  /// 월운: 7일
  /// - 월 초에 생성, 일주일간 유효
  static const Duration monthlyFortune = Duration(days: 7);

  /// 년운: 30일
  /// - 년 초에 생성, 한 달간 유효
  static const Duration yearlyFortune = Duration(days: 30);

  /// 질문 응답: 캐시 안함
  /// - 매번 새로운 답변 생성
  static Duration? get questionAnswer => null;

  /// 궁합: 무기한
  /// - 두 프로필이 바뀌지 않는 한 유효
  static Duration? get compatibility => null;
}

// ═══════════════════════════════════════════════════════════════════════════
// 토큰 제한
// ═══════════════════════════════════════════════════════════════════════════

/// 응답 최대 토큰 수
///
/// ## 설정 가이드
/// - 너무 작으면 응답이 잘림
/// - 너무 크면 비용 증가 + 응답 시간 증가
/// - JSON 응답의 예상 크기 기반으로 설정
abstract class TokenLimits {
  /// 기본 사주 분석: 4096 토큰
  /// - 상세한 JSON 응답 필요
  /// - 성격, 직업, 재물, 건강 등 다양한 필드
  static const int sajuBaseMaxTokens = 4096;

  /// 일운: 2048 토큰
  /// - 간결한 오늘의 운세
  static const int dailyFortuneMaxTokens = 2048;

  /// 월운: 2048 토큰
  static const int monthlyFortuneMaxTokens = 2048;

  /// 년운: 3072 토큰
  /// - 더 상세한 연간 전망
  static const int yearlyFortuneMaxTokens = 3072;

  /// 질문 응답: 1024 토큰
  /// - 간결한 답변
  static const int questionAnswerMaxTokens = 1024;

  /// 궁합: 3072 토큰
  static const int compatibilityMaxTokens = 3072;
}

// ═══════════════════════════════════════════════════════════════════════════
// 모델 제공자
// ═══════════════════════════════════════════════════════════════════════════

/// AI 제공자 식별자
///
/// ## DB 매핑
/// `ai_summaries.model_provider` 컬럼 값
abstract class ModelProvider {
  static const String openai = 'openai';
  static const String google = 'google';
  static const String anthropic = 'anthropic';
}
