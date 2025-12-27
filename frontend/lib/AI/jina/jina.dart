/// Jina 전용 모듈
/// 담당: Jina
/// 역할: Gemini 3.0으로 재미있는 대화 생성 + Nanabanan 이미지
///
/// 폴더 구조:
/// - chat/     : 대화 생성 로직
/// - personas/ : 페르소나 시스템
/// - context/  : 맥락 관리
/// - image/    : Nanabanan 이미지 생성
/// - providers/: Jina 전용 Provider

// ═══════════════════════════════════════════════════════════════
// Chat - 대화 생성
// ═══════════════════════════════════════════════════════════════
export 'chat/response_generator.dart';
export 'chat/tone_adjuster.dart';
export 'chat/emoji_injector.dart';

// ═══════════════════════════════════════════════════════════════
// Personas - 페르소나
// ═══════════════════════════════════════════════════════════════
export 'personas/persona_base.dart';
export 'personas/persona_registry.dart';
export 'personas/persona_selector.dart';
export 'personas/cute_friend.dart';
export 'personas/friendly_sister.dart';
export 'personas/wise_scholar.dart';

// ═══════════════════════════════════════════════════════════════
// Context - 맥락 관리
// ═══════════════════════════════════════════════════════════════
export 'context/chat_history_manager.dart';
export 'context/context_builder.dart';

// ═══════════════════════════════════════════════════════════════
// Image - Nanabanan
// ═══════════════════════════════════════════════════════════════
export 'image/nanabanan_provider.dart';
export 'image/saju_illustration_prompt.dart';

// ═══════════════════════════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════════════════════════
export 'providers/jina_chat_provider.dart';
