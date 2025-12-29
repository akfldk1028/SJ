// AI 모듈
// GPT + Gemini + DALL-E + Imagen 통합 AI 시스템
//
// 폴더 구조:
// - common/  : 공통 코드 (core, providers, pipelines, prompts)
// - jh/      : JH 전용 개발 영역
// - jina/    : Jina 전용 개발 영역

// ═══════════════════════════════════════════════════════════════
// Common - Core
// ═══════════════════════════════════════════════════════════════
export 'common/core/ai_config.dart';
export 'common/core/ai_cache.dart';
export 'common/core/ai_logger.dart';
export 'common/core/base_provider.dart';

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
export 'prompts/prompt_template.dart';
export 'prompts/saju_base_prompt.dart';
export 'prompts/daily_fortune_prompt.dart';
export 'data/queries.dart';
export 'data/mutations.dart';
export 'services/ai_api_service.dart';
export 'services/saju_analysis_service.dart';
