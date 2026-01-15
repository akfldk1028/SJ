import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../AI/services/saju_analysis_service.dart' as ai_saju;
import '../../../../AI/services/compatibility_analysis_service.dart';
import '../../../../core/services/prompt_loader.dart';
import '../../../../core/services/ai_summary_service.dart';
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
import 'chat_session_provider.dart';
import 'conversational_ad_provider.dart';
import 'persona_provider.dart';

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
          print('   📋 sajuOrigin: ${cachedSummary.sajuOrigin != null ? '있음' : '없음'}');
        }

        // 2. sajuOrigin이 없으면 GPT-5.2 트리거 (동기 실행)
        if (cachedSummary.sajuOrigin == null) {
          if (kDebugMode) {
            print('   🔄 sajuOrigin 없음 - GPT-5.2 분석 시작...');
          }

          final user = Supabase.instance.client.auth.currentUser;
          if (user != null) {
            final sajuService = ai_saju.SajuAnalysisService();
            final result = await sajuService.analyzeOnProfileSave(
              userId: user.id,
              profileId: profileId,
              runInBackground: false, // 완료 대기
            );

            if (result.sajuBase?.success == true) {
              if (kDebugMode) {
                print('   ✅ GPT-5.2 분석 완료 - DB에서 다시 조회');
              }
              // DB에서 다시 조회하여 sajuOrigin 포함된 데이터 반환
              final updatedSummary =
                  await AiSummaryService.getCachedSummary(profileId);
              if (updatedSummary != null) {
                _cachedAiSummary = updatedSummary;
                return updatedSummary;
              }
            } else {
              if (kDebugMode) {
                print('   ⚠️ GPT-5.2 분석 실패: ${result.sajuBase?.error}');
              }
            }
          } else {
            if (kDebugMode) {
              print('   ⚠️ 로그인 필요 - GPT-5.2 스킵');
            }
          }
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
          print('   📋 sajuOrigin: ${result.summary!.sajuOrigin != null ? '있음' : '없음'}');
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

  /// 시스템 프롬프트 빌드
  ///
  /// v3.4: SystemPromptBuilder 클래스로 분리 (모듈화)
  /// v3.5 (Phase 44): 궁합 채팅을 위한 상대방 프로필/사주 지원
  /// - system_prompt_builder.dart 참조
  String _buildFullSystemPrompt({
    required String basePrompt,
    AiSummary? aiSummary,
    SajuAnalysis? sajuAnalysis,
    SajuProfile? profile,
    AiPersona? persona,
    bool isFirstMessage = true,
    SajuProfile? targetProfile,
    SajuAnalysis? targetSajuAnalysis,
    Map<String, dynamic>? compatibilityAnalysis,
  }) {
    final builder = SystemPromptBuilder();
    return builder.build(
      basePrompt: basePrompt,
      aiSummary: aiSummary,
      sajuAnalysis: sajuAnalysis,
      profile: profile,
      persona: persona,
      isFirstMessage: isFirstMessage,
      targetProfile: targetProfile,
      targetSajuAnalysis: targetSajuAnalysis,
      compatibilityAnalysis: compatibilityAnalysis,
    );
  }

  /// 메시지 전송
  /// [targetProfileId]: 궁합 채팅 시 상대방 프로필 ID (선택)
  Future<void> sendMessage(String content, ChatType chatType, {String? targetProfileId}) async {
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
    final selectedPersona = ref.read(personaNotifierProvider);
    if (kDebugMode) {
      print('');
      print('╔══════════════════════════════════════════════════════════════╗');
      print('║  🚀 [1] CHAT SEND START                                      ║');
      print('╚══════════════════════════════════════════════════════════════╝');
      print('   📌 페르소나: ${selectedPersona.displayName} (${selectedPersona.name})');
      print('   📌 세션: $sessionId');
      if (targetProfileId != null) {
        print('   📌 상대방 프로필: $targetProfileId');
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
    AiSummary? aiSummary = _cachedAiSummary; // 캐시 있으면 즉시 사용
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

    /* ═══════════════════════════════════════════════════════════════════════════
    // v3.1 이전 동기 코드 (주석처리) - Edge Function 블로킹으로 첫 메시지 느림
    AiSummary? aiSummary;
    if (state.messages.isEmpty) {
      if (kDebugMode) {
        print('');
        print('┌──────────────────────────────────────────────────────────────┐');
        print('│  📦 [2] AI SUMMARY                                           │');
        print('└──────────────────────────────────────────────────────────────┘');
        print('   🔄 첫 메시지 - AI Summary 확인/생성...');
      }
      aiSummary = await _ensureAiSummary(profileId);  // ← 동기 호출 (느림!)
    } else {
      aiSummary = _cachedAiSummary;
      if (kDebugMode) {
        print('   ✅ 캐시된 AI Summary 사용');
      }
    }
    ═══════════════════════════════════════════════════════════════════════════ */

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
      final currentPersona = ref.read(personaNotifierProvider);

      // AI Summary (sajuOrigin 포함) + 페르소나를 시스템 프롬프트에 추가
      // v2.0: AIContext 제거, AiSummary.sajuOrigin으로 통합
      // v2.1: 첫 메시지에만 sajuOrigin 전체 포함 (토큰 최적화)
      final isFirstMessage = state.messages.where((m) => m.role == 'assistant').isEmpty;

      // v3.1: 로컬 SajuAnalysis 가져오기 (Edge Function sajuOrigin null 문제 해결)
      final sajuAnalysis = isFirstMessage
          ? await ref.read(currentSajuAnalysisProvider.future)
          : null;

      // v3.3: 프로필 정보 가져오기 (Supabase에서 조회됨)
      final activeProfile = isFirstMessage
          ? await ref.read(activeProfileProvider.future)
          : null;

      // v3.4 (Phase 44): 상대방 프로필/사주 조회 (궁합 채팅)
      SajuProfile? targetProfile;
      SajuAnalysis? targetSajuAnalysis;
      if (isFirstMessage && targetProfileId != null) {
        if (kDebugMode) {
          print('   🎯 궁합 모드: 상대방 프로필 조회 시작...');
        }
        final profileRepo = SajuProfileRepository();
        final analysisRepo = SajuAnalysisRepository();
        targetProfile = await profileRepo.getById(targetProfileId);
        if (targetProfile != null) {
          targetSajuAnalysis = await analysisRepo.getByProfileId(targetProfileId);

          // v3.5: 상대방 사주 분석이 없으면 GPT-5.2로 자동 생성
          if (targetSajuAnalysis == null) {
            if (kDebugMode) {
              print('   ⚠️ 상대방 사주 분석 없음 → GPT-5.2 자동 분석 시작');
            }
            try {
              // 현재 사용자 ID 가져오기 (RLS 필요)
              final userId = Supabase.instance.client.auth.currentUser?.id;
              if (userId != null) {
                // runInBackground: false → 분석 완료까지 대기
                final aiAnalysisService = ai_saju.SajuAnalysisService();
                final result = await aiAnalysisService.ensureSajuBaseAnalysis(
                  userId: userId,
                  profileId: targetProfileId,
                  runInBackground: false,  // 채팅 시작 전 완료 필요
                );

                if (result.success) {
                  // 분석 완료 후 다시 조회
                  targetSajuAnalysis = await analysisRepo.getByProfileId(targetProfileId);
                  if (kDebugMode) {
                    print('   ✅ 상대방 사주 분석 자동 생성 완료');
                  }
                } else {
                  if (kDebugMode) {
                    print('   ❌ 상대방 사주 분석 생성 실패: ${result.error}');
                  }
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('   ❌ 상대방 사주 분석 생성 중 오류: $e');
              }
            }
          }

          if (kDebugMode) {
            print('   ✅ 상대방 프로필: ${targetProfile.displayName}');
            print('   ✅ 상대방 사주: ${targetSajuAnalysis != null ? '있음' : '없음'}');
          }
        } else {
          if (kDebugMode) {
            print('   ⚠️ 상대방 프로필 조회 실패');
          }
        }
      }

      // v3.6: Gemini 궁합 분석 실행 (첫 메시지 + 궁합 모드)
      Map<String, dynamic>? compatibilityAnalysis;
      if (isFirstMessage && targetProfileId != null && targetProfile != null && profileId != null) {
        if (kDebugMode) {
          print('');
          print('   🎯 Gemini 궁합 분석 시작...');
        }
        try {
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId != null) {
            // profile_relations에서 관계 유형 조회
            final relationResult = await Supabase.instance.client
                .from('profile_relations')
                .select('relation_type')
                .eq('from_profile_id', profileId)
                .eq('to_profile_id', targetProfileId)
                .maybeSingle();

            final relationType = relationResult?['relation_type'] as String? ?? 'other';

            final compatibilityService = CompatibilityAnalysisService();
            final result = await compatibilityService.analyzeCompatibility(
              userId: userId,
              fromProfileId: profileId,
              toProfileId: targetProfileId,
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
      }

      final systemPrompt = _buildFullSystemPrompt(
        basePrompt: basePrompt,
        aiSummary: aiSummary,
        sajuAnalysis: sajuAnalysis,  // v3.1: 로컬 사주 데이터
        profile: activeProfile,  // v3.3: 프로필 정보 (생년월일, 성별)
        persona: currentPersona,
        isFirstMessage: isFirstMessage,
        targetProfile: targetProfile,  // v3.4: 궁합 상대방 프로필
        targetSajuAnalysis: targetSajuAnalysis,  // v3.4: 궁합 상대방 사주
        compatibilityAnalysis: compatibilityAnalysis,  // v3.6: Gemini 궁합 분석 결과
      );
      /////////////////////////////////////////////////////////////////수정1순우ㅟ
      // [4] 시스템 프롬프트 구성
      if (kDebugMode) {
        print('');
        print('[4] SYSTEM PROMPT BUILD (v3.5 Phase 44)');
        print('   현재 날짜: ${DateTime.now().year}년 ${DateTime.now().month}월 ${DateTime.now().day}일');
        print('   페르소나: ${currentPersona.displayName}');
        print('   isFirstMessage: $isFirstMessage');
        if (activeProfile != null) {
          print('   [나] 프로필: ${activeProfile.displayName} (${activeProfile.gender.displayName})');
          print('   [나] 생년월일: ${activeProfile.birthDateFormatted}');
        } else {
          print('   [나] 프로필 없음');
        }
        if (targetProfile != null) {
          print('   [상대방] 프로필: ${targetProfile.displayName} (${targetProfile.gender.displayName})');
          print('   [상대방] 생년월일: ${targetProfile.birthDateFormatted}');
          // v3.7 (Phase 47): target_calculated_saju 확인
          final sajuAnalysisData = compatibilityAnalysis?['saju_analysis'] as Map<String, dynamic>?;
          final hasTargetCalculatedSaju = sajuAnalysisData?['target_calculated_saju'] != null;
          if (targetSajuAnalysis != null) {
            print('   [상대방] 사주: 있음 (saju_analyses)');
          } else if (hasTargetCalculatedSaju) {
            print('   [상대방] 사주: 있음 (Gemini 계산)');
          } else {
            print('   [상대방] 사주: 없음');
          }
          print('   [궁합분석] ${compatibilityAnalysis != null ? '${compatibilityAnalysis['overall_score']}점' : '없음'}');
        } else if (targetProfileId != null) {
          print('   [상대방] 프로필 조회 실패 (targetProfileId: $targetProfileId)');
        }
        if (aiSummary != null) {
          print('   AI Summary 포함');
          if (isFirstMessage && aiSummary.sajuOrigin != null) {
            print('   sajuOrigin: 전체 포함 (합충형파해, 십성, 신살 등)');
          } else {
            print('   sajuOrigin: 생략 (대화 히스토리 참조)');
          }
        } else {
          print('   AI Summary 없음');
        }
        print('   프롬프트 길이: ${systemPrompt.length} chars');
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
        persona: currentPersona,
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

}
