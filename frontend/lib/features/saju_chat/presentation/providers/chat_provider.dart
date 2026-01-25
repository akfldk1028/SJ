import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../AI/services/saju_analysis_service.dart' as ai_saju;
import '../../../../AI/services/compatibility_analysis_service.dart';
// Phase 50 다중 궁합 제거됨 - 궁합은 항상 2명만
// import '../../../../AI/services/multi_compatibility_analysis_service.dart';
import '../../../../core/services/prompt_loader.dart';
import '../../../../core/services/ai_summary_service.dart';
import '../../../../core/services/intent_classifier_service.dart';
import '../../../../core/utils/suggested_questions_parser.dart';
import '../../../profile/domain/entities/saju_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../saju_chart/domain/entities/saju_analysis.dart';
import '../../../saju_chart/presentation/providers/saju_chart_provider.dart';
import '../../../../core/repositories/saju_profile_repository.dart';
import '../../../../core/repositories/saju_analysis_repository.dart';
import '../../data/datasources/gemini_edge_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/services/chat_realtime_service.dart';
import '../../data/models/conversational_ad_model.dart' show AdTriggerResult;
import '../../data/services/system_prompt_builder.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/models/ai_persona.dart';
import '../../domain/models/chat_type.dart';
import '../../domain/models/chat_persona.dart';
import '../providers/chat_persona_provider.dart';
import 'chat_session_provider.dart';
import 'conversational_ad_provider.dart';

part 'chat_provider.g.dart';

/// 채팅 상태
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isLoadingMore; // 이전 메시지 로딩 중
  final bool hasMoreMessages; // 더 로드할 메시지 있음
  final int totalMessageCount; // 전체 메시지 수
  final String? streamingContent;
  final String? error;

  /// 토큰 사용량 정보
  final TokenUsageInfo? tokenUsage;

  /// 메시지 트리밍 발생 여부 (토큰 제한으로 오래된 메시지 제거됨)
  final bool wasContextTrimmed;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
    this.totalMessageCount = 0,
    this.streamingContent,
    this.error,
    this.tokenUsage,
    this.wasContextTrimmed = false,
  });

  /// 토큰 사용량이 80% 이상인지 확인
  bool get isNearTokenLimit => tokenUsage?.isNearLimit ?? false;

  /// GPT-5.2 상세 분석 실행 중 여부
  /// v3.0: aiSummary 주석처리로 현재 미사용 (항상 false)
  bool get isDeepAnalysisRunning => false;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMoreMessages,
    int? totalMessageCount,
    String? streamingContent,
    String? error,
    TokenUsageInfo? tokenUsage,
    bool? wasContextTrimmed,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      totalMessageCount: totalMessageCount ?? this.totalMessageCount,
      streamingContent: streamingContent,
      error: error,
      tokenUsage: tokenUsage ?? this.tokenUsage,
      wasContextTrimmed: wasContextTrimmed ?? this.wasContextTrimmed,
    );
  }
}

/// Pagination 상수
const int kMessagesPerPage = 30;

/// 채팅 상태 관리 Provider (세션 인식)
///
/// 각 세션별로 독립된 ChatRepository 인스턴스를 가짐
/// → Gemini AI 히스토리가 세션별로 분리됨
@riverpod
class ChatNotifier extends _$ChatNotifier {
  final _uuid = const Uuid();

  /// 세션별 독립된 ChatRepository 인스턴스
  late final ChatRepositoryImpl _repository;

  /// Realtime 구독
  StreamSubscription<ChatMessage>? _realtimeSubscription;
  StreamSubscription<String>? _deleteSubscription;

  /// 메시지 처리 중 플래그 (Realtime 중복 방지)
  bool _isProcessingMessage = false;

  /// 메시지 전송 중 플래그 (더블클릭 방지)
  bool _isSendingMessage = false;

  @override
  ChatState build(String sessionId) {
    // 세션별로 새로운 ChatRepository 생성 (Gemini 히스토리 분리)
    // 2025-12-30: Edge Function 전환 - API 키 보안 강화
    _repository = ChatRepositoryImpl(
      datasource: GeminiEdgeDatasource(),
    );

    // Provider dispose 시 정리
    ref.onDispose(() {
      _repository.resetSession();
      _unsubscribeRealtime();
    });

    // 세션이 변경되면 메시지 로드 + Realtime 구독
    Future.microtask(() {
      loadSessionMessages(sessionId);
      _subscribeRealtime(sessionId);
    });

    return const ChatState();
  }

  /// Realtime 구독 설정
  void _subscribeRealtime(String sessionId) {
    final realtimeService = ChatRealtimeService.instance;

    // 새 메시지 수신 구독
    _realtimeSubscription = realtimeService.onNewMessage.listen((message) {
      // 메시지 처리 중이면 Realtime에서 온 메시지 무시 (중복 방지)
      if (_isProcessingMessage) {
        if (kDebugMode) {
          print('   🔇 [Realtime] 메시지 무시 (처리 중)');
        }
        return;
      }

      // 이미 존재하는 메시지인 경우 추가하지 않음
      final exists = state.messages.any((m) => m.id == message.id);
      if (!exists) {
        state = state.copyWith(
          messages: [...state.messages, message],
          totalMessageCount: state.totalMessageCount + 1,
        );

        if (kDebugMode) {
          print('   📡 [Realtime] 메시지 추가: ${message.role.name}');
        }
      }
    });

    // 메시지 삭제 구독
    _deleteSubscription = realtimeService.onMessageDeleted.listen((messageId) {
      final exists = state.messages.any((m) => m.id == messageId);
      if (exists) {
        state = state.copyWith(
          messages: state.messages.where((m) => m.id != messageId).toList(),
          totalMessageCount: state.totalMessageCount - 1,
        );

        if (kDebugMode) {
          print('   🗑️ [Realtime] 메시지 삭제: $messageId');
        }
      }
    });

    // Supabase Realtime 채널 구독
    realtimeService.subscribeToSession(sessionId);

    if (kDebugMode) {
      print('   📡 [Realtime] 구독 시작: $sessionId');
    }
  }

  /// Realtime 구독 해제
  void _unsubscribeRealtime() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    _deleteSubscription?.cancel();
    _deleteSubscription = null;
  }

  /// 세션의 메시지 로드 (Pagination 적용)
  /// 최신 메시지 [kMessagesPerPage]개만 먼저 로드
  Future<void> loadSessionMessages(String sessionId) async {
    // 이미 메시지가 있거나 로딩 중이면 스킵
    if (state.messages.isNotEmpty || state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final sessionRepository = ref.read(chatSessionRepositoryProvider);

      // 전체 메시지 수 조회
      final totalCount = await sessionRepository.getSessionMessageCount(sessionId);

      // 최신 메시지 로드 (Pagination)
      final messages = await sessionRepository.getSessionMessages(
        sessionId,
        limit: kMessagesPerPage,
        offset: 0,
      );

      // 로드 중에 메시지가 추가되었으면 덮어쓰지 않음
      if (state.messages.isEmpty) {
        state = state.copyWith(
          messages: messages,
          isLoading: false,
          hasMoreMessages: messages.length < totalCount,
          totalMessageCount: totalCount,
        );

        // ═══════════════════════════════════════════════════════════════════
        // 기존 세션 복원: 메시지가 있으면 시스템 프롬프트 + 대화 히스토리 재설정
        // 앱 백그라운드 → 포그라운드 복귀 시 AI가 페르소나/사주 정보 + 대화 맥락 기억
        // ═══════════════════════════════════════════════════════════════════
        if (messages.isNotEmpty) {
          // v7.1: 사주 정보 포함한 완전한 시스템 프롬프트 생성
          final fullSystemPrompt = await _buildRestoreSystemPrompt();
          _repository.restoreExistingSession(fullSystemPrompt, messages: messages);
          if (kDebugMode) {
            print('[ChatProvider] 기존 세션 복원 완료 (${messages.length}개 메시지, 사주 정보 포함)');
          }
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '메시지 로드 중 오류가 발생했습니다.',
      );
    }
  }

  /// 이전 메시지 더 로드 (무한 스크롤)
  Future<void> loadMoreMessages() async {
    // 이미 로딩 중이거나 더 로드할 메시지가 없으면 스킵
    if (state.isLoadingMore || !state.hasMoreMessages) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final sessionRepository = ref.read(chatSessionRepositoryProvider);

      // 현재 로드된 메시지 수를 offset으로 사용
      final offset = state.messages.length;

      final olderMessages = await sessionRepository.getSessionMessages(
        sessionId,
        limit: kMessagesPerPage,
        offset: offset,
      );

      if (olderMessages.isNotEmpty) {
        // 이전 메시지를 앞에 추가
        state = state.copyWith(
          messages: [...olderMessages, ...state.messages],
          isLoadingMore: false,
          hasMoreMessages: state.messages.length + olderMessages.length < state.totalMessageCount,
        );
      } else {
        state = state.copyWith(
          isLoadingMore: false,
          hasMoreMessages: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: '이전 메시지 로드 중 오류가 발생했습니다.',
      );
    }
  }

  /// 개별 메시지 삭제
  Future<void> deleteMessage(String messageId) async {
    try {
      final sessionRepository = ref.read(chatSessionRepositoryProvider);
      await sessionRepository.deleteMessage(messageId);

      // 로컬 상태에서 제거
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != messageId).toList(),
        totalMessageCount: state.totalMessageCount - 1,
      );

      if (kDebugMode) {
        print('   🗑️ [Chat] 메시지 삭제 완료: $messageId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('   ❌ [Chat] 메시지 삭제 실패: $e');
      }
    }
  }

  /// 세션 초기화 (새 세션으로 전환)
  void clearSession() {
    _cachedAiSummary = null; // AI Summary 캐시 초기화
    state = const ChatState();
  }

  /// ChatPersona → AiPersona 매핑 (광고 텍스트용)
  AiPersona _mapToAiPersona(ChatPersona persona) {
    switch (persona) {
      case ChatPersona.basePerson:
        return AiPersona.professional;
      case ChatPersona.babyMonk:
        return AiPersona.babyMonk;
      case ChatPersona.scenarioWriter:
        return AiPersona.scenarioWriter;
      case ChatPersona.saOngJiMa:
        return AiPersona.saOngJiMa;
      case ChatPersona.sewerSaju:
        return AiPersona.sewerSaju;
    }
  }

  /// ChatType → 프롬프트 파일명 매핑
  String _getPromptFileName(ChatType chatType) {
    switch (chatType) {
      case ChatType.dailyFortune:
        return 'daily_fortune';
      case ChatType.sajuAnalysis:
        return 'saju_analysis';
      case ChatType.compatibility:
        return 'compatibility';
      default:
        return 'general';
    }
  }

  /// 시스템 프롬프트 로드 (MD 파일에서)
  Future<String> _loadSystemPrompt(ChatType chatType) async {
    final fileName = _getPromptFileName(chatType);
    return PromptLoader.load(fileName);
  }

  /// AI Summary 캐시 (세션별로 한 번만 로드)
  AiSummary? _cachedAiSummary;

  /// AI Summary 확인 및 생성 (첫 메시지 시)
  ///
  /// 1. 캐시에 있으면 반환
  /// 2. DB에서 기존 요약 조회
  /// 3. 없으면 Edge Function 호출하여 새로 생성
  Future<AiSummary?> _ensureAiSummary(String? profileId) async {
    // 캐시에 있으면 반환
    if (_cachedAiSummary != null) {
      return _cachedAiSummary;
    }

    // profileId 없으면 스킵
    if (profileId == null || profileId.isEmpty) {
      if (kDebugMode) {
        print('   ⚠️ profileId 없음 - 스킵');
      }
      return null;
    }

    try {
      // 1. 먼저 DB에서 캐시된 요약 확인
      final cachedSummary = await AiSummaryService.getCachedSummary(profileId);
      if (cachedSummary != null) {
        if (kDebugMode) {
          print('   ✅ DB 캐시에서 로드: $profileId');
        }

        _cachedAiSummary = cachedSummary;
        return cachedSummary;
      }

      // 2. 캐시 없으면 새로 생성
      if (kDebugMode) {
        print('   🔄 새로 생성 시작: $profileId');
      }

      // 활성 프로필 정보 가져오기
      final activeProfile = await ref.read(activeProfileProvider.future);
      if (activeProfile == null || activeProfile.id != profileId) {
        if (kDebugMode) {
          print('   ⚠️ 프로필 불일치 - 스킵');
        }
        return null;
      }

      // 사주 분석 결과 가져오기
      final sajuAnalysis = await ref.read(currentSajuAnalysisProvider.future);
      if (sajuAnalysis == null) {
        if (kDebugMode) {
          print('   ⚠️ 사주 분석 없음 - 스킵');
        }
        return null;
      }

      // 생년월일 문자열 생성
      final birthDate = activeProfile.birthDate;
      final birthTimeStr = activeProfile.birthTimeUnknown
          ? ''
          : ' ${(activeProfile.birthTimeMinutes ?? 0) ~/ 60}:${((activeProfile.birthTimeMinutes ?? 0) % 60).toString().padLeft(2, '0')}';
      final birthDateStr =
          '${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}$birthTimeStr';

      // Edge Function 호출
      final result = await AiSummaryService.generateSummary(
        profileId: profileId,
        profileName: activeProfile.displayName,
        birthDate: birthDateStr,
        sajuAnalysis: sajuAnalysis,
      );

      if (result.isSuccess && result.summary != null) {
        _cachedAiSummary = result.summary;
        if (kDebugMode) {
          print('   ✅ 생성 완료 (cached: ${result.cached})');
        }
        return result.summary;
      } else {
        if (kDebugMode) {
          print('   ❌ 생성 실패: ${result.error}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('   💥 오류: $e');
      }
      return null;
    }
  }

  /// 세션 복원용 시스템 프롬프트 빌드
  ///
  /// v7.1: 앱 백그라운드 → 포그라운드 복귀 시 사주 정보 포함
  /// - 프로필 + 사주 분석 + AI Summary 로드하여 완전한 프롬프트 생성
  /// - 궁합 모드는 미지원 (일반 채팅만)
  Future<String> _buildRestoreSystemPrompt() async {
    try {
      // 1. 페르소나 프롬프트 (기본)
      final personaPrompt = ref.read(finalSystemPromptProvider);

      // 2. 프로필 로드
      final activeProfile = await ref.read(activeProfileProvider.future);
      if (activeProfile == null) {
        if (kDebugMode) {
          print('[ChatProvider] 세션 복원: 프로필 없음 - 페르소나 프롬프트만 사용');
        }
        return personaPrompt;
      }

      // 3. 사주 분석 로드
      final sajuAnalysis = await ref.read(currentSajuAnalysisProvider.future);

      // 4. AI Summary (캐시된 것만 사용 - 새로 생성하지 않음!)
      // 세션 복원 시 Edge Function 호출하면 비용 발생하므로 캐시만 확인
      final aiSummary = _cachedAiSummary;

      // 5. 완전한 시스템 프롬프트 생성
      final fullPrompt = _buildFullSystemPrompt(
        basePrompt: personaPrompt,
        aiSummary: aiSummary,
        sajuAnalysis: sajuAnalysis,
        profile: activeProfile,
        personaPrompt: personaPrompt,
        isFirstMessage: true,  // 복원 후 첫 메시지로 취급
      );

      if (kDebugMode) {
        print('[ChatProvider] 세션 복원: 사주 정보 포함 프롬프트 생성 완료');
        print('   프로필: ${activeProfile.displayName}');
        print('   사주: ${sajuAnalysis != null ? "있음" : "없음"}');
        print('   AI Summary: ${aiSummary != null ? "있음" : "없음"}');
      }

      return fullPrompt;
    } catch (e) {
      if (kDebugMode) {
        print('[ChatProvider] 세션 복원 프롬프트 오류: $e - 페르소나 프롬프트만 사용');
      }
      return ref.read(finalSystemPromptProvider);
    }
  }

  /// 시스템 프롬프트 빌드
  ///
  /// v3.4: SystemPromptBuilder 클래스로 분리 (모듈화)
  /// v3.5 (Phase 44): 궁합 채팅을 위한 상대방 프로필/사주 지원
  /// v7.0: Intent Classification 추가 (토큰 최적화)
  /// - system_prompt_builder.dart 참조
  String _buildFullSystemPrompt({
    required String basePrompt,
    AiSummary? aiSummary,
    IntentClassificationResult? intentClassification,  // v7.0
    SajuAnalysis? sajuAnalysis,
    SajuProfile? profile,
    String? personaPrompt,
    bool isFirstMessage = true,
    SajuProfile? targetProfile,
    SajuAnalysis? targetSajuAnalysis,
    Map<String, dynamic>? compatibilityAnalysis,
    bool isThirdPartyCompatibility = false,  // v6.0 (Phase 57): 나 제외 모드
  }) {
    final builder = SystemPromptBuilder();
    return builder.build(
      basePrompt: basePrompt,
      aiSummary: aiSummary,
      intentClassification: intentClassification,  // v7.0
      sajuAnalysis: sajuAnalysis,
      profile: profile,
      personaPrompt: personaPrompt,
      isFirstMessage: isFirstMessage,
      targetProfile: targetProfile,
      targetSajuAnalysis: targetSajuAnalysis,
      compatibilityAnalysis: compatibilityAnalysis,
      isThirdPartyCompatibility: isThirdPartyCompatibility,  // v6.0
    );
  }

  /// 메시지 전송
  ///
  /// ## v6.0 리팩토링 (Phase 57): 궁합 로직 단순화
  /// - [compatibilityParticipantIds]: 궁합 채팅 시 2명의 프로필 ID [person1, person2]
  ///   - "나 포함/제외" 구분 없이 단순히 선택된 2명의 ID
  ///   - null이면 일반 채팅 (owner의 사주 사용)
  ///
  /// ## 기존 파라미터 (하위 호환)
  /// - [targetProfileId]: 단일 궁합 시 상대방 ID (compatibilityParticipantIds 없을 때 fallback)
  /// - [multiParticipantIds]: deprecated → compatibilityParticipantIds 사용
  /// - [includesOwner]: deprecated → 더 이상 사용하지 않음
  Future<void> sendMessage(
    String content,
    ChatType chatType, {
    String? targetProfileId,
    List<String>? multiParticipantIds,
    bool includesOwner = true, // deprecated, 하위 호환용
    List<String>? compatibilityParticipantIds,
  }) async {
    if (content.trim().isEmpty) return;

    // 더블클릭/중복 호출 방지
    if (_isSendingMessage) {
      if (kDebugMode) {
        print('⚠️ [CHAT] 중복 호출 차단');
      }
      return;
    }
    _isSendingMessage = true;

    // Realtime 중복 방지 플래그 설정
    _isProcessingMessage = true;

    // [1] 채팅 시작
    final selectedChatPersona = ref.read(chatPersonaNotifierProvider);

    // ═══════════════════════════════════════════════════════════════════════════
    // v6.0 (Phase 57): 궁합 로직 단순화
    // - 궁합 = 그냥 2명의 profileId
    // - "나 포함/제외" 구분 제거 → 선택된 2명 그대로 사용
    // ═══════════════════════════════════════════════════════════════════════════

    // 궁합 참가자 결정 (우선순위: compatibilityParticipantIds > multiParticipantIds)
    final effectiveParticipantIds = compatibilityParticipantIds ?? multiParticipantIds;

    // 궁합 모드: 2명의 참가자가 있는 경우
    final isCompatibilityMode = effectiveParticipantIds != null && effectiveParticipantIds.length >= 2;

    // 궁합 모드에서 참가자 ID 추출
    String? person1Id;  // 첫 번째 사람 (기존 activeProfile 역할)
    String? person2Id;  // 두 번째 사람 (기존 targetProfile 역할)

    if (isCompatibilityMode) {
      person1Id = effectiveParticipantIds[0];
      person2Id = effectiveParticipantIds[1];
      if (kDebugMode) {
        print('   ✅ 궁합 모드 활성화: person1Id=$person1Id, person2Id=$person2Id');
      }
    } else if (targetProfileId != null) {
      // 하위 호환: 단일 targetProfileId만 있는 경우 → owner + target 방식
      person2Id = targetProfileId;
      if (kDebugMode) {
        print('   ⚠️ 하위 호환 모드: targetProfileId=$targetProfileId');
      }
    } else {
      if (kDebugMode) {
        print('   📝 일반 채팅 모드 (궁합 아님)');
        print('      effectiveParticipantIds: $effectiveParticipantIds');
        print('      compatibilityParticipantIds: $compatibilityParticipantIds');
        print('      multiParticipantIds: $multiParticipantIds');
      }
    }

    if (kDebugMode) {
      print('');
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║  🚀 [1] CHAT SEND START (v6.0 리팩토링)                      ║');
      print('╚══════════════════════════════════════════════════════════════╝');
      print('   📌 페르소나: ${selectedChatPersona.displayName}');
      print('   📌 세션: $sessionId');
      if (isCompatibilityMode) {
        print('   📌 궁합 모드: person1=$person1Id, person2=$person2Id');
      } else if (person2Id != null) {
        print('   📌 단일 궁합 모드 (하위 호환): target=$person2Id');
      } else {
        print('   📌 일반 채팅 모드');
      }
    }

    final currentSessionId = sessionId;
    final sessionRepository = ref.read(chatSessionRepositoryProvider);

    // 현재 세션의 profileId 가져오기
    final currentSession = await sessionRepository.getSession(currentSessionId);
    final profileId = currentSession?.profileId;

    // ═══════════════════════════════════════════════════════════════════════════
    // [2] AI Summary 준비 (v3.2: 비동기 - 블로킹 제거)
    // - v3.1에서 로컬 SajuAnalysis 사용하므로 aiSummary는 캐시용
    // - Edge Function 호출을 백그라운드로 변경하여 첫 메시지 속도 개선
    // ═══════════════════════════════════════════════════════════════════════════
    final aiSummary = _cachedAiSummary; // 캐시 있으면 즉시 사용
    if (state.messages.isEmpty && _cachedAiSummary == null && profileId != null) {
      if (kDebugMode) {
        print('');
        print('┌──────────────────────────────────────────────────────────────┐');
        print('│  📦 [2] AI SUMMARY (비동기)                                  │');
        print('└──────────────────────────────────────────────────────────────┘');
        print('   🔄 백그라운드 캐시 생성 시작 (블로킹 없음)...');
      }
      // v3.2: 비동기 (fire-and-forget) - await 제거로 블로킹 방지
      _ensureAiSummary(profileId).then((summary) {
        _cachedAiSummary = summary;
        if (kDebugMode) {
          print('   ✅ [비동기] AI Summary 캐시 완료');
        }
      });
    } else if (_cachedAiSummary != null && kDebugMode) {
      print('   ✅ 캐시된 AI Summary 사용');
    }

    // 사용자 메시지 추가 (sessionId 포함)
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      sessionId: currentSessionId,
      content: content,
      role: MessageRole.user,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    // [3] 메시지 추가
    if (kDebugMode) {
      print('');
      print('┌──────────────────────────────────────────────────────────────┐');
      print('│  💬 [3] MESSAGE ADDED                                        │');
      print('└──────────────────────────────────────────────────────────────┘');
      print('   📝 내용: ${content.length > 30 ? '${content.substring(0, 30)}...' : content}');
      print('   📊 전체 메시지 수: ${state.messages.length}');
    }

    // 사용자 메시지 저장
    try {
      await sessionRepository.saveMessage(userMessage);
    } catch (e) {
      // 저장 실패해도 계속 진행
    }

    try {
      // MD 파일에서 시스템 프롬프트 로드
      final basePrompt = await _loadSystemPrompt(chatType);

      // 현재 페르소나 가져오기
      final currentPersonaPrompt = ref.read(finalSystemPromptProvider);

      // ═══════════════════════════════════════════════════════════════════════════
      // v7.0: Intent Classification (토큰 최적화)
      // - 첫 메시지 포함, 항상 분류 실행 (aiSummary 없어도 분류는 수행)
      // - aiSummary가 없으면 분류 결과는 사용하되 필터링은 적용 안 함
      // ═══════════════════════════════════════════════════════════════════════════
      final isFirstMessageInSession = state.messages.where((m) => m.role == MessageRole.assistant).isEmpty;

      if (kDebugMode) {
        print('');
        print('┌──────────────────────────────────────────────────────────────┐');
        print('│  🎯 INTENT CLASSIFICATION (v7.0)                             │');
        print('└──────────────────────────────────────────────────────────────┘');
        if (isFirstMessageInSession) {
          print('   📌 첫 메시지 - Intent Classification 실행');
        }
        if (aiSummary == null) {
          print('   ⚠️ aiSummary 없음 (분류는 실행하되 필터링은 적용 안 함)');
        }
      }

      // 최근 대화 3턴 추출 (컨텍스트)
      final recentMessages = state.messages
          .skip(state.messages.length > 6 ? state.messages.length - 6 : 0)
          .map((m) => '${m.role.name}: ${m.content}')
          .toList();

      // userId 가져오기 (Intent Classification에서 Quota 관리용)
      final userId = Supabase.instance.client.auth.currentUser?.id;

      // 항상 Intent Classification 실행 (aiSummary 유무와 관계없이)
      final intentClassification = await IntentClassifierService.classifyIntent(
        userMessage: content,
        chatHistory: recentMessages,
        userId: userId,
      );

      if (kDebugMode) {
        print('   📌 분류 결과: ${intentClassification.categories.map((c) => c.korean).join(", ")}');
        print('   💡 이유: ${intentClassification.reason}');
        if (intentClassification.categories.contains(SummaryCategory.general)) {
          print('   ⚠️ 전체 정보 포함 (GENERAL)');
        } else if (aiSummary != null) {
          final filtered = FilteredAiSummary(
            original: aiSummary,
            classification: intentClassification,
          );
          print('   💰 토큰 절약 예상: ~${filtered.estimatedTokenSavings}%');
        } else {
          print('   💡 aiSummary 없음 - 필터링은 적용 안 됨 (전체 포함)');
        }
      }

      // ═══════════════════════════════════════════════════════════════════════════
      // v6.0 (Phase 57): 프로필/사주 로드 로직 단순화
      // - 궁합 모드: person1, person2 둘 다 동일하게 처리
      // - 일반 채팅: owner의 프로필/사주 사용
      // ═══════════════════════════════════════════════════════════════════════════

      // 사주 로드 조건: 첫 메시지이거나, 궁합 모드일 때
      final shouldLoadSaju = isFirstMessageInSession || isCompatibilityMode || person2Id != null;

      SajuProfile? activeProfile;    // 첫 번째 사람 (궁합) 또는 owner (일반)
      SajuAnalysis? sajuAnalysis;    // 첫 번째 사람의 사주
      SajuProfile? targetProfile;    // 두 번째 사람 (궁합 시에만)
      SajuAnalysis? targetSajuAnalysis;  // 두 번째 사람의 사주

      final profileRepo = SajuProfileRepository();
      final analysisRepo = SajuAnalysisRepository();

      if (shouldLoadSaju) {
        if (kDebugMode) {
          print('   📍 사주 로드: isFirstMessage=$isFirstMessageInSession, isCompatibilityMode=$isCompatibilityMode');
        }

        if (isCompatibilityMode && person1Id != null) {
          // ═══════════════════════════════════════════════════════════════════
          // 궁합 모드: person1, person2 둘 다 프로필/사주 로드
          // ═══════════════════════════════════════════════════════════════════
          if (kDebugMode) {
            print('   🎯 궁합 모드: 두 사람 프로필/사주 조회...');
          }

          // Person 1 로드
          activeProfile = await profileRepo.getById(person1Id);
          if (activeProfile != null) {
            sajuAnalysis = await analysisRepo.getByProfileId(person1Id);

            // v6.0: 첫 번째 사람도 사주 자동생성
            if (sajuAnalysis == null && userId != null) {
              if (kDebugMode) {
                print('   ⚠️ Person1 사주 분석 없음 → GPT-5.2 자동 분석 시작');
              }
              try {
                final aiAnalysisService = ai_saju.SajuAnalysisService();
                final result = await aiAnalysisService.ensureSajuBaseAnalysis(
                  userId: userId,
                  profileId: person1Id,
                  runInBackground: false,
                );
                if (result.success) {
                  sajuAnalysis = await analysisRepo.getByProfileId(person1Id);
                  if (kDebugMode) {
                    print('   ✅ Person1 사주 분석 자동 생성 완료');
                  }
                }
              } catch (e) {
                if (kDebugMode) {
                  print('   ❌ Person1 사주 분석 생성 중 오류: $e');
                }
              }
            }

            if (kDebugMode) {
              print('   ✅ Person1 프로필: ${activeProfile.displayName}');
              print('   ✅ Person1 사주: ${sajuAnalysis != null ? '있음' : '없음'}');
            }
          }

          // Person 2 로드
          if (person2Id != null) {
            targetProfile = await profileRepo.getById(person2Id);
            if (targetProfile != null) {
              targetSajuAnalysis = await analysisRepo.getByProfileId(person2Id);

              // v6.0: 두 번째 사람도 사주 자동생성
              if (targetSajuAnalysis == null && userId != null) {
                if (kDebugMode) {
                  print('   ⚠️ Person2 사주 분석 없음 → GPT-5.2 자동 분석 시작');
                }
                try {
                  final aiAnalysisService = ai_saju.SajuAnalysisService();
                  final result = await aiAnalysisService.ensureSajuBaseAnalysis(
                    userId: userId,
                    profileId: person2Id,
                    runInBackground: false,
                  );
                  if (result.success) {
                    targetSajuAnalysis = await analysisRepo.getByProfileId(person2Id);
                    if (kDebugMode) {
                      print('   ✅ Person2 사주 분석 자동 생성 완료');
                    }
                  }
                } catch (e) {
                  if (kDebugMode) {
                    print('   ❌ Person2 사주 분석 생성 중 오류: $e');
                  }
                }
              }

              if (kDebugMode) {
                print('   ✅ Person2 프로필: ${targetProfile.displayName}');
                print('   ✅ Person2 사주: ${targetSajuAnalysis != null ? '있음' : '없음'}');
              }
            }
          }
        } else if (person2Id != null) {
          // ═══════════════════════════════════════════════════════════════════
          // 하위 호환: owner + target 방식 (단일 targetProfileId만 있는 경우)
          // ═══════════════════════════════════════════════════════════════════
          if (kDebugMode) {
            print('   🎯 하위 호환 모드: owner + target');
          }

          // Owner (나) 로드
          sajuAnalysis = await ref.read(currentSajuAnalysisProvider.future);
          activeProfile = await ref.read(activeProfileProvider.future);

          // Target 로드
          targetProfile = await profileRepo.getById(person2Id);
          if (targetProfile != null) {
            targetSajuAnalysis = await analysisRepo.getByProfileId(person2Id);

            if (targetSajuAnalysis == null && userId != null) {
              if (kDebugMode) {
                print('   ⚠️ 상대방 사주 분석 없음 → GPT-5.2 자동 분석 시작');
              }
              try {
                final aiAnalysisService = ai_saju.SajuAnalysisService();
                final result = await aiAnalysisService.ensureSajuBaseAnalysis(
                  userId: userId,
                  profileId: person2Id,
                  runInBackground: false,
                );
                if (result.success) {
                  targetSajuAnalysis = await analysisRepo.getByProfileId(person2Id);
                }
              } catch (e) {
                if (kDebugMode) {
                  print('   ❌ 상대방 사주 분석 생성 중 오류: $e');
                }
              }
            }
          }
        } else {
          // ═══════════════════════════════════════════════════════════════════
          // 일반 채팅: owner의 프로필/사주 사용
          // ═══════════════════════════════════════════════════════════════════
          sajuAnalysis = await ref.read(currentSajuAnalysisProvider.future);
          activeProfile = await ref.read(activeProfileProvider.future);
          if (kDebugMode) {
            print('   🎯 일반 채팅 모드: owner 프로필/사주 사용');
            print('   ✅ 프로필: ${activeProfile?.displayName}');
            print('   ✅ 사주: ${sajuAnalysis != null ? '있음' : '없음'}');
          }
        }
      }

      // ═══════════════════════════════════════════════════════════════════════════
      // 궁합 분석 실행 (v6.0: 단순화)
      // ═══════════════════════════════════════════════════════════════════════════
      Map<String, dynamic>? compatibilityAnalysis;

      // 궁합 분석 조건: 두 사람의 프로필이 모두 있어야 함
      final canDoCompatibility = shouldLoadSaju &&
          activeProfile != null &&
          targetProfile != null &&
          person1Id != null &&
          person2Id != null;

      if (canDoCompatibility) {
        if (kDebugMode) {
          print('');
          print('   🎯 Gemini 궁합 분석 시작...');
        }
        try {
          if (userId != null) {
            // profile_relations에서 관계 유형 조회 (양방향 검색)
            var relationResult = await Supabase.instance.client
                .from('profile_relations')
                .select('relation_type')
                .eq('from_profile_id', person1Id)
                .eq('to_profile_id', person2Id)
                .maybeSingle();

            // 못 찾으면 반대 방향도 검색
            relationResult ??= await Supabase.instance.client
                .from('profile_relations')
                .select('relation_type')
                .eq('from_profile_id', person2Id)
                .eq('to_profile_id', person1Id)
                .maybeSingle();

            final relationType = relationResult?['relation_type'] as String? ?? 'other';

            if (kDebugMode) {
              print('   📌 궁합 참가자: person1=$person1Id, person2=$person2Id');
            }

            final compatibilityService = CompatibilityAnalysisService();
            final result = await compatibilityService.analyzeCompatibility(
              userId: userId,
              fromProfileId: person1Id,
              toProfileId: person2Id,
              relationType: relationType,
            );

            if (result.success && result.data != null) {
              compatibilityAnalysis = result.data;
              if (kDebugMode) {
                print('   ✅ 궁합 분석 완료: ${result.data?['overall_score']}점');
              }
            } else {
              if (kDebugMode) {
                print('   ⚠️ 궁합 분석 실패: ${result.error}');
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('   ❌ 궁합 분석 중 오류: $e');
          }
        }

        // chat_mentions에 참가자 저장
        if (effectiveParticipantIds != null && effectiveParticipantIds.isNotEmpty) {
          await _saveChatMentions(currentSessionId, effectiveParticipantIds);
        }
      }

      // v5.2 (Phase 54): 연속 궁합 채팅에서도 사주 정보 포함
      // isFirstMessage → isFirstMessageInSession (기존 로깅용)
      // 궁합 모드에서는 항상 사주 정보 포함 (shouldLoadSaju)

      // v6.0 (Phase 57): "나 제외" 모드 판단
      // - 궁합 모드에서 person1이 로그인 사용자의 primary profile이 아니면 "나 제외"
      bool isThirdPartyCompatibility = false;
      if (isCompatibilityMode && person1Id != null) {
        final ownerProfile = await ref.read(activeProfileProvider.future);
        isThirdPartyCompatibility = ownerProfile?.id != person1Id;
        if (kDebugMode && isThirdPartyCompatibility) {
          print('   📌 나 제외 모드: 로그인사용자=${ownerProfile?.displayName}, person1=${activeProfile?.displayName}, person2=${targetProfile?.displayName}');
        }
      }

      final systemPrompt = _buildFullSystemPrompt(
        basePrompt: basePrompt,
        aiSummary: aiSummary,
        intentClassification: intentClassification,  // v7.0: Intent 분류 결과
        sajuAnalysis: sajuAnalysis,  // v3.1: 로컬 사주 데이터
        profile: activeProfile,  // v3.3: 프로필 정보 (생년월일, 성별)
        personaPrompt: currentPersonaPrompt,
        isFirstMessage: shouldLoadSaju,  // v5.2: 궁합 모드면 항상 사주 포함
        targetProfile: targetProfile,  // v3.4: 궁합 상대방 프로필
        targetSajuAnalysis: targetSajuAnalysis,  // v3.4: 궁합 상대방 사주
        compatibilityAnalysis: compatibilityAnalysis,  // v3.6: Gemini 궁합 분석 결과
        isThirdPartyCompatibility: isThirdPartyCompatibility,  // v6.0: 나 제외 모드
      );

      // [4] 시스템 프롬프트 구성
      if (kDebugMode) {
        print('');
        print('[4] SYSTEM PROMPT BUILD (v7.0 Intent Routing)');
        print('   현재 날짜: ${DateTime.now().year}년 ${DateTime.now().month}월 ${DateTime.now().day}일');
        print('   페르소나: ${selectedChatPersona.displayName}');
        print('   isFirstMessageInSession: $isFirstMessageInSession');
        print('   isCompatibilityMode: $isCompatibilityMode');
        print('   isThirdPartyCompatibility: $isThirdPartyCompatibility');  // v6.0
        print('   shouldLoadSaju: $shouldLoadSaju');
        
        // v7.0: Intent Classification 결과 표시
        if (intentClassification != null) {
          print('');
          print('   ╔══════════════════════════════════════════════════════╗');
          print('   ║  📋 AI SUMMARY 참조 정보 (Intent Routing)           ║');
          print('   ╚══════════════════════════════════════════════════════╝');
          final categories = intentClassification.categories;
          final isGeneral = categories.contains(SummaryCategory.general);
          
          if (aiSummary == null) {
            print('   ⚠️ aiSummary 없음 - 필터링 적용 안 됨 (전체 포함)');
            print('   💡 분류 결과: ${categories.map((c) => c.korean).join(", ")}');
            print('   💡 분류 이유: ${intentClassification.reason}');
          } else if (isGeneral) {
            print('   🔵 참조 범위: 전체 (GENERAL)');
            print('   📦 포함 섹션: 모든 카테고리');
            print('   💡 분류 이유: ${intentClassification.reason}');
          } else {
            print('   🎯 참조 범위: 선택적 필터링');
            print('   📦 포함 섹션:');
            print('      - saju_origin (기본 정보) ✅');
            print('      - wonGuk_analysis (원국 분석) ✅');
            for (final category in categories) {
              final icon = switch (category) {
                SummaryCategory.personality => '🧑',
                SummaryCategory.love => '💕',
                SummaryCategory.marriage => '💍',
                SummaryCategory.career => '💼',
                SummaryCategory.business => '🏢',
                SummaryCategory.wealth => '💰',
                SummaryCategory.health => '🏥',
                _ => '📌',
              };
              print('      - $icon ${category.korean} (${category.code}) ✅');
            }
            
            final filtered = FilteredAiSummary(
              original: aiSummary,
              classification: intentClassification,
            );
            print('   💾 토큰 절약: 약 ${filtered.estimatedTokenSavings}%');
            print('   💡 분류 이유: ${intentClassification.reason}');
          }
        } else if (aiSummary != null && isFirstMessageInSession) {
          print('');
          print('   ╔══════════════════════════════════════════════════════╗');
          print('   ║  📋 AI SUMMARY 참조 정보 (첫 메시지)                ║');
          print('   ╚══════════════════════════════════════════════════════╝');
          print('   🔵 참조 범위: 전체 (첫 메시지는 항상 전체 포함)');
          print('   📦 포함 섹션: 모든 카테고리');
          print('   💡 이유: 사용자 경험 최적화 (첫 인사/종합 소개)');
        }
        
        print('');
        if (activeProfile != null) {
          print('   [Person1] 프로필: ${activeProfile.displayName} (${activeProfile.gender.displayName})');
          print('   [Person1] 생년월일: ${activeProfile.birthDateFormatted}');
          print('   [Person1] 사주: ${sajuAnalysis != null ? '있음' : '없음'}');
        } else {
          print('   [Person1] 프로필 없음');
        }
        if (targetProfile != null) {
          print('   [Person2] 프로필: ${targetProfile.displayName} (${targetProfile.gender.displayName})');
          print('   [Person2] 생년월일: ${targetProfile.birthDateFormatted}');
          print('   [Person2] 사주: ${targetSajuAnalysis != null ? '있음' : '없음'}');
          print('   [궁합분석] ${compatibilityAnalysis != null ? '${compatibilityAnalysis['overall_score']}점' : '없음'}');
        } else if (person2Id != null) {
          print('   [Person2] 프로필 조회 실패 (person2Id: $person2Id)');
        }
        print('');
        print('   프롬프트 길이: ${systemPrompt.length} chars');

        // v6.0 Debug: 프롬프트에 Person2 정보 포함 여부 확인
        if (isCompatibilityMode && targetProfile != null) {
          final hasPerson2Name = systemPrompt.contains(targetProfile.displayName);
          final hasPerson2Birth = systemPrompt.contains(targetProfile.birthDateFormatted ?? '');
          final hasPerson2Saju = systemPrompt.contains('두 번째 사람') || systemPrompt.contains('상대방');
          print('   [DEBUG] 프롬프트 검증:');
          print('      - Person2 이름(${targetProfile.displayName}) 포함: $hasPerson2Name');
          print('      - Person2 생년월일 포함: $hasPerson2Birth');
          print('      - Person2 사주 섹션 포함: $hasPerson2Saju');

          // 프롬프트 첫 2000자 출력 (너무 길면 truncate)
          final previewLength = systemPrompt.length > 2000 ? 2000 : systemPrompt.length;
          print('   [DEBUG] 프롬프트 미리보기 (${previewLength}자):');
          print(systemPrompt.substring(0, previewLength));
          print('   [DEBUG] === 프롬프트 미리보기 끝 ===');
        }
      }

      // 스트리밍 응답 (세션별 독립된 repository 사용)
      final stream = _repository.sendMessageStream(
        userMessage: content,
        conversationHistory: state.messages,
        systemPrompt: systemPrompt,
      );

      String fullContent = '';
      await for (final chunk in stream) {
        fullContent = chunk;
        state = state.copyWith(
          streamingContent: fullContent,
        );
      }

      // 스트리밍 완료 후 토큰 사용량 및 윈도우잉 정보 조회
      final tokensUsed = _repository.getLastTokensUsed();
      final tokenUsage = _repository.getTokenUsageInfo();
      final windowResult = _repository.getLastWindowResult();

      // [5] AI 응답 완료
      if (kDebugMode) {
        print('');
        print('┌──────────────────────────────────────────────────────────────┐');
        print('│  ✨ [5] AI RESPONSE RECEIVED                                 │');
        print('└──────────────────────────────────────────────────────────────┘');
        print('   📝 응답 길이: ${fullContent.length} chars');
        print('   🔢 토큰 사용: ${tokensUsed ?? 'N/A'}');
        print('   📊 $tokenUsage');
        if (windowResult?.wasTrimmed == true) {
          print('   ⚠️ 컨텍스트 트리밍: ${windowResult!.removedCount}개 메시지 제거');
        }
      }

      // AI 응답에서 후속 질문 파싱
      final parseResult = SuggestedQuestionsParser.parse(fullContent);
      final cleanedContent = parseResult.cleanedContent;
      final suggestedQuestions = parseResult.suggestedQuestions;

      // [6] 후속 질문 추출
      if (kDebugMode) {
        print('');
        print('┌──────────────────────────────────────────────────────────────┐');
        print('│  💡 [6] SUGGESTED QUESTIONS                                  │');
        print('└──────────────────────────────────────────────────────────────┘');
        if (suggestedQuestions != null && suggestedQuestions.isNotEmpty) {
          for (int i = 0; i < suggestedQuestions.length; i++) {
            print('   ${i + 1}. ${suggestedQuestions[i]}');
          }
        } else {
          print('   (없음)');
        }
      }

      // 스트리밍 완료 후 메시지로 추가 (sessionId + tokensUsed + suggestedQuestions 포함)
      final aiMessage = ChatMessage(
        id: _uuid.v4(),
        sessionId: currentSessionId,
        content: cleanedContent, // 태그 제거된 정제된 응답
        role: MessageRole.assistant,
        createdAt: DateTime.now(),
        tokensUsed: tokensUsed,
        suggestedQuestions: suggestedQuestions,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
        streamingContent: null,
        tokenUsage: tokenUsage,
        wasContextTrimmed: windowResult?.wasTrimmed ?? false,
      );

      // [AD] 토큰 기반 광고 트리거 체크
      final adTrigger = ref.read(conversationalAdNotifierProvider.notifier).checkAndTrigger(
        tokenUsage: tokenUsage,
        messageCount: state.messages.length,
        persona: _mapToAiPersona(selectedChatPersona),
      );

      if (kDebugMode && adTrigger != AdTriggerResult.none) {
        print('');
        print('┌──────────────────────────────────────────────────────────────┐');
        print('│  📢 [AD] TOKEN-BASED AD TRIGGERED                            │');
        print('└──────────────────────────────────────────────────────────────┘');
        print('   🎯 Trigger: $adTrigger');
        print('   📊 Usage: ${(tokenUsage.usageRate * 100).toStringAsFixed(1)}%');
      }

      // AI 메시지 저장 (tokensUsed 포함)
      await sessionRepository.saveMessage(aiMessage);

      // 세션 메타데이터 업데이트
      await _updateSessionMetadata(currentSessionId, content);

      // [7] 완료
      if (kDebugMode) {
        print('');
        print('╔══════════════════════════════════════════════════════════════╗');
        print('║  ✅ [7] CHAT COMPLETE                                        ║');
        print('╚══════════════════════════════════════════════════════════════╝');
        print('');
      }

      // 플래그 해제
      _isProcessingMessage = false;
      _isSendingMessage = false;
    } catch (e) {
      // [ERROR]
      if (kDebugMode) {
        print('');
        print('╔══════════════════════════════════════════════════════════════╗');
        print('║  ❌ [ERROR] CHAT FAILED                                      ║');
        print('╚══════════════════════════════════════════════════════════════╝');
        print('   💥 $e');
        print('');
      }
      // 에러 시에도 플래그 해제
      _isProcessingMessage = false;
      _isSendingMessage = false;

      state = state.copyWith(
        isLoading: false,
        streamingContent: null,
        error: '메시지 전송 중 오류가 발생했습니다.',
      );
    }
  }

  /// chat_mentions 테이블에 다중 궁합 참가자 저장 (Phase 50)
  ///
  /// 다중 궁합 분석 시 참가자 프로필 ID를 저장하여
  /// 추후 세션에서 참가자 정보를 조회할 수 있도록 합니다.
  Future<void> _saveChatMentions(String sessionId, List<String> participantIds) async {
    try {
      if (kDebugMode) {
        print('   📝 chat_mentions 저장 시작 (${participantIds.length}명)...');
      }

      // 기존 멘션 삭제 (세션 재분석 시 중복 방지)
      await Supabase.instance.client
          .from('chat_mentions')
          .delete()
          .eq('session_id', sessionId);

      // 새 멘션 저장
      final mentionRows = participantIds.asMap().entries.map((entry) => {
        'session_id': sessionId,
        'target_profile_id': entry.value,
        'mention_order': entry.key,
      }).toList();

      await Supabase.instance.client
          .from('chat_mentions')
          .insert(mentionRows);

      if (kDebugMode) {
        print('   ✅ chat_mentions 저장 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('   ⚠️ chat_mentions 저장 실패: $e');
      }
      // 실패해도 분석은 계속 진행
    }
  }

  /// 세션 메타데이터 업데이트 (메시지 개수, 미리보기)
  Future<void> _updateSessionMetadata(
      String sessionId, String lastUserMessage) async {
    try {
      final sessionNotifier = ref.read(chatSessionNotifierProvider.notifier);
      final sessionRepository = ref.read(chatSessionRepositoryProvider);

      // 현재 세션 가져오기
      final currentSession = await sessionRepository.getSession(sessionId);
      if (currentSession == null) return;

      // 메시지 개수 카운트 (현재 state의 messages)
      final messageCount = state.messages.length;

      // 미리보기 텍스트 (사용자의 마지막 메시지, 최대 50자)
      final preview = lastUserMessage.length > 50
          ? '${lastUserMessage.substring(0, 50)}...'
          : lastUserMessage;

      // 세션 업데이트
      final updatedSession = currentSession.copyWith(
        messageCount: messageCount,
        lastMessagePreview: preview,
        updatedAt: DateTime.now(),
      );

      await sessionRepository.updateSession(updatedSession);

      // 세션 목록 새로고침
      await sessionNotifier.loadSessions();
    } catch (e) {
      // 메타데이터 업데이트 실패해도 무시
    }
  }

  /// 보너스 토큰 추가 (광고 시청 시)
  ///
  /// 광고를 보면 토큰 한도가 증가하여 이전 대화를 유지하면서 더 대화 가능
  /// [tokens]: 추가할 토큰 수
  void addBonusTokens(int tokens) {
    _repository.addBonusTokens(tokens);

    // 토큰 사용량 정보 업데이트
    final tokenUsage = _repository.getTokenUsageInfo();
    state = state.copyWith(
      tokenUsage: tokenUsage,
      wasContextTrimmed: false, // 토큰 충전으로 트리밍 해제
    );

    if (kDebugMode) {
      print('[ChatProvider] 보너스 토큰 추가: +$tokens');
      print('[ChatProvider] 새 토큰 상태: $tokenUsage');
    }
  }

}
