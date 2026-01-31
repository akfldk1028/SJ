// AI 모듈
// GPT + Gemini + DALL-E + Imagen 통합 AI 시스템
//
// 폴더 구조:
// - core/    : 설정, 로거, 캐시, 상수
// - common/  : 공통 코드 (providers, pipelines, prompts)
// - fortune/ : 운세 프롬프트 통합 (lifetime, daily, monthly, yearly)
// - jh/      : JH 전용 개발 영역
// - jina/    : Jina 전용 개발 영역

// ═══════════════════════════════════════════════════════════════
// Core - 설정, 로거, 캐시
// ═══════════════════════════════════════════════════════════════
export 'core/ai_config.dart';
export 'core/ai_cache.dart';
export 'core/ai_simple_logger.dart';
export 'core/base_provider.dart';

// ═══════════════════════════════════════════════════════════════
// Common - LLM Providers
// ═══════════════════════════════════════════════════════════════
export 'common/providers/openai/gpt_provider.dart';
export 'common/providers/google/gemini_provider.dart';
// export 'common/providers/anthropic/claude_provider.dart'; // 나중에 추가

// ═══════════════════════════════════════════════════════════════
// Common - Image Providers
// ═══════════════════════════════════════════════════════════════
export 'common/providers/image/dalle_provider.dart';
export 'common/providers/image/imagen_provider.dart';

// ═══════════════════════════════════════════════════════════════
// Common - Pipelines
// ═══════════════════════════════════════════════════════════════
export 'common/pipelines/base_pipeline.dart';
export 'common/pipelines/saju_pipeline.dart';

// ═══════════════════════════════════════════════════════════════
// Common - Prompts
// ═══════════════════════════════════════════════════════════════
export 'common/prompts/saju_prompts.dart';

// ═══════════════════════════════════════════════════════════════
// JH - GPT-5.2 정확한 사주 분석 (담당: JH_AI)
// ═══════════════════════════════════════════════════════════════
export 'jh/jh.dart';

// ═══════════════════════════════════════════════════════════════
// Jina - Gemini 3.0 재미있는 대화 (담당: Jina)
// ═══════════════════════════════════════════════════════════════
export 'jina/jina.dart';

// ═══════════════════════════════════════════════════════════════
// AI Analysis - 프로필 저장 시 백그라운드 분석
// ═══════════════════════════════════════════════════════════════
export 'core/ai_constants.dart';
export 'fortune/common/prompt_template.dart';
export 'fortune/lifetime/lifetime_prompt.dart';
// daily_fortune_prompt.dart → fortune/daily/daily_prompt.dart로 이동됨 (v7.0)
export 'data/queries.dart';
export 'data/mutations.dart';
export 'services/ai_api_service.dart';
export 'services/saju_analysis_service.dart';

// ═══════════════════════════════════════════════════════════════
// Fortune Module (v7.0) - 운세 분석 통합 모듈
// ═══════════════════════════════════════════════════════════════
export 'fortune/fortune_coordinator.dart';
export 'fortune/common/fortune_input_data.dart';
export 'fortune/common/fortune_state.dart';
export 'fortune/common/korea_date_utils.dart';
export 'fortune/daily/daily_service.dart';
export 'fortune/daily/daily_prompt.dart';
export 'fortune/monthly/monthly_service.dart';
export 'fortune/yearly_2025/yearly_2025_service.dart';
export 'fortune/yearly_2026/yearly_2026_service.dart';

// ═══════════════════════════════════════════════════════════════
// Compatibility Analysis - 궁합 분석 서비스
// ═══════════════════════════════════════════════════════════════
export 'services/compatibility_calculator.dart';
export 'services/compatibility_analysis_service.dart';

