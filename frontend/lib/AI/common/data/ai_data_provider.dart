import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../features/profile/data/queries.dart';
import '../../../features/profile/data/models/saju_profile_model.dart';
import '../../../features/saju_chart/data/queries.dart';
import '../../../features/saju_chart/data/models/saju_analysis_db_model.dart';
import '../../../features/saju_chat/data/queries.dart';
import '../../../features/saju_chat/data/models/chat_message_model.dart';
import '../../../core/services/supabase_service.dart';
import 'ai_context.dart';

part 'ai_data_provider.g.dart';

/// AI 컨텍스트 Provider
///
/// AI 팀원 (JH_AI, Jina)이 사용하는 데이터 접근 포인트
///
/// 사용법:
/// ```dart
/// // 자동 watch (async)
/// final context = await ref.watch(aiContextProvider.future);
///
/// // 일회성 read
/// final context = await ref.read(aiContextProvider.future);
///
/// // 새로고침
/// ref.invalidate(aiContextProvider);
/// ```
@riverpod
class AiContext extends _$AiContext {
  @override
  Future<AIContext?> build() async {
    // 현재 활성 프로필 ID 가져오기
    final profileId = _getActiveProfileId();
    if (profileId == null) return null;

    return _loadContext(profileId);
  }

  /// 특정 프로필로 컨텍스트 로드
  Future<AIContext?> loadForProfile(String profileId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadContext(profileId));
    return state.valueOrNull;
  }

  /// 컨텍스트 새로고침
  Future<AIContext?> refresh() async {
    final profileId = _getActiveProfileId();
    if (profileId == null) return null;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadContext(profileId));
    return state.valueOrNull;
  }

  /// 대화 세션 설정
  Future<void> setSession(String sessionId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // 최근 메시지 로드
    final messagesResult = await chatMessageQueries.getForAiContext(
      sessionId,
      limit: 10,
    );

    state = AsyncData(current.copyWith(
      currentSessionId: sessionId,
      recentMessages: messagesResult.data,
    ));
  }

  // ============================================================================
  // Private Methods
  // ============================================================================

  String? _getActiveProfileId() {
    // TODO: 실제로는 Hive나 Provider에서 활성 프로필 ID를 가져옴
    // 임시로 Supabase currentUserId 기반으로 처리
    return SupabaseService.currentUserId;
  }

  Future<AIContext?> _loadContext(String profileId) async {
    // 1. 프로필 조회
    final profileResult = await profileQueries.getById(profileId);
    if (profileResult.isFailure || profileResult.data == null) {
      return null;
    }

    // 2. 사주 분석 조회
    final analysisResult = await sajuAnalysisQueries.getByProfileId(profileId);
    if (analysisResult.isFailure || analysisResult.data == null) {
      return null;
    }

    return AIContext(
      profile: profileResult.data!,
      analysis: analysisResult.data!,
    );
  }
}

/// 프로필 + 분석 데이터만 조회 (빠른 로딩)
@riverpod
Future<AIContext?> aiContextBasic(AiContextBasicRef ref, String profileId) async {
  // 프로필 조회
  final profileResult = await profileQueries.getById(profileId);
  if (profileResult.isFailure || profileResult.data == null) {
    return null;
  }

  // 기본 사주 정보만 조회
  final analysisResult = await sajuAnalysisQueries.getBasicByProfileId(profileId);
  if (analysisResult.isFailure || analysisResult.data == null) {
    return null;
  }

  return AIContext(
    profile: profileResult.data!,
    analysis: analysisResult.data!,
  );
}

/// AI 컨텍스트 + 최근 대화 포함
@riverpod
Future<AIContext?> aiContextWithChat(
  AiContextWithChatRef ref,
  String profileId,
  String sessionId,
) async {
  // 기본 컨텍스트 로드
  final basicContext = await ref.watch(aiContextBasicProvider(profileId).future);
  if (basicContext == null) return null;

  // 최근 메시지 로드
  final messagesResult = await chatMessageQueries.getForAiContext(
    sessionId,
    limit: 10,
  );

  return basicContext.copyWith(
    currentSessionId: sessionId,
    recentMessages: messagesResult.data,
  );
}

// ============================================================================
// 개별 데이터 Provider (세분화 접근용)
// ============================================================================

/// 프로필 데이터만 조회
@riverpod
Future<SajuProfileModel?> aiProfile(AiProfileRef ref, String profileId) async {
  final result = await profileQueries.getById(profileId);
  return result.data;
}

/// 사주 분석 데이터만 조회
@riverpod
Future<SajuAnalysisDbModel?> aiAnalysis(AiAnalysisRef ref, String profileId) async {
  final result = await sajuAnalysisQueries.getByProfileId(profileId);
  return result.data;
}

/// 오행 분포만 조회
@riverpod
Future<Map<String, dynamic>?> aiOheng(AiOhengRef ref, String profileId) async {
  final result = await sajuAnalysisQueries.getOhengDistribution(profileId);
  return result.data;
}

/// 용신 정보만 조회
@riverpod
Future<Map<String, dynamic>?> aiYongsin(AiYongsinRef ref, String profileId) async {
  final result = await sajuAnalysisQueries.getYongsin(profileId);
  return result.data;
}

/// 대운 정보만 조회
@riverpod
Future<Map<String, dynamic>?> aiDaeun(AiDaeunRef ref, String profileId) async {
  final result = await sajuAnalysisQueries.getDaeun(profileId);
  return result.data;
}

/// 최근 대화 메시지 조회
@riverpod
Future<List<ChatMessageModel>> aiRecentMessages(
  AiRecentMessagesRef ref,
  String sessionId, {
  int limit = 10,
}) async {
  final result = await chatMessageQueries.getForAiContext(sessionId, limit: limit);
  return result.data ?? [];
}
