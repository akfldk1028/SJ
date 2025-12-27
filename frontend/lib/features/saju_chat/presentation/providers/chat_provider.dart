import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/prompt_loader.dart';
import '../../../../core/services/ai_summary_service.dart';
import '../../../../core/utils/suggested_questions_parser.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../saju_chart/presentation/providers/saju_chart_provider.dart';
import '../../data/datasources/gemini_rest_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/services/chat_realtime_service.dart';
import '../../data/services/conversation_window_manager.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/models/chat_type.dart';
import 'chat_session_provider.dart';

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

  @override
  ChatState build(String sessionId) {
    // 세션별로 새로운 ChatRepository 생성 (Gemini 히스토리 분리)
    _repository = ChatRepositoryImpl(
      datasource: GeminiRestDatasource(),
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
      // 자신이 보낸 메시지가 아닌 경우에만 추가 (중복 방지)
      final exists = state.messages.any((m) => m.id == message.id);
      if (!exists) {
        state = state.copyWith(
          messages: [...state.messages, message],
          totalMessageCount: state.totalMessageCount + 1,
        );

        if (kDebugMode) {
          print('[ChatNotifier] Realtime 메시지 추가: ${message.role.name}');
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
          print('[ChatNotifier] Realtime 메시지 삭제: $messageId');
        }
      }
    });

    // Supabase Realtime 채널 구독
    realtimeService.subscribeToSession(sessionId);

    if (kDebugMode) {
      print('[ChatNotifier] Realtime 구독 시작: $sessionId');
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
        print('[ChatNotifier] 메시지 삭제 완료: $messageId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ChatNotifier] 메시지 삭제 실패: $e');
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
        print('[ChatNotifier] AI Summary 스킵: profileId 없음');
      }
      return null;
    }

    try {
      // 1. 먼저 DB에서 캐시된 요약 확인
      final cachedSummary = await AiSummaryService.getCachedSummary(profileId);
      if (cachedSummary != null) {
        if (kDebugMode) {
          print('[ChatNotifier] AI Summary 캐시에서 로드: $profileId');
        }
        _cachedAiSummary = cachedSummary;
        return cachedSummary;
      }

      // 2. 캐시 없으면 새로 생성
      if (kDebugMode) {
        print('[ChatNotifier] AI Summary 새로 생성 시작: $profileId');
      }

      // 활성 프로필 정보 가져오기
      final activeProfile = await ref.read(activeProfileProvider.future);
      if (activeProfile == null || activeProfile.id != profileId) {
        if (kDebugMode) {
          print('[ChatNotifier] AI Summary 스킵: 프로필 불일치');
        }
        return null;
      }

      // 사주 분석 결과 가져오기
      final sajuAnalysis = await ref.read(currentSajuAnalysisProvider.future);
      if (sajuAnalysis == null) {
        if (kDebugMode) {
          print('[ChatNotifier] AI Summary 스킵: 사주 분석 없음');
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
          print('[ChatNotifier] AI Summary 생성 완료 (cached: ${result.cached})');
        }
        return result.summary;
      } else {
        if (kDebugMode) {
          print('[ChatNotifier] AI Summary 생성 실패: ${result.error}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ChatNotifier] AI Summary 오류: $e');
      }
      return null;
    }
  }

  /// AI Summary를 시스템 프롬프트에 추가
  String _appendAiSummaryToPrompt(String basePrompt, AiSummary? aiSummary) {
    if (aiSummary == null) return basePrompt;

    final summaryContext = '''

## 사용자 사주 분석 요약 (AI 생성)

### 성격
- **핵심**: ${aiSummary.personality.core}
- **특성**: ${aiSummary.personality.traits.join(', ')}

### 강점
${aiSummary.strengths.map((s) => '- $s').join('\n')}

### 약점
${aiSummary.weaknesses.map((w) => '- $w').join('\n')}

### 진로 적성
- **적합 분야**: ${aiSummary.career.aptitude.join(', ')}
- **조언**: ${aiSummary.career.advice}

### 대인관계
- **스타일**: ${aiSummary.relationships.style}
- **팁**: ${aiSummary.relationships.tips}

### 개운법
- **행운의 색상**: ${aiSummary.fortuneTips.colors.join(', ')}
- **행운의 방향**: ${aiSummary.fortuneTips.directions.join(', ')}
- **추천 활동**: ${aiSummary.fortuneTips.activities.join(', ')}

---
위 사주 분석 요약을 참고하여 사용자에게 맞춤형 상담을 제공하세요.
''';

    return basePrompt + summaryContext;
  }

  /// 메시지 전송
  Future<void> sendMessage(String content, ChatType chatType) async {
    if (content.trim().isEmpty) return;

    print('[ChatNotifier] sendMessage 호출: sessionId=$sessionId, content=${content.substring(0, content.length > 20 ? 20 : content.length)}...');

    final currentSessionId = sessionId;
    final sessionRepository = ref.read(chatSessionRepositoryProvider);

    // 현재 세션의 profileId 가져오기
    final currentSession = await sessionRepository.getSession(currentSessionId);
    final profileId = currentSession?.profileId;

    // 첫 메시지인 경우 AI Summary 확인/생성
    AiSummary? aiSummary;
    if (state.messages.isEmpty) {
      if (kDebugMode) {
        print('[ChatNotifier] 첫 메시지 - AI Summary 확인/생성');
      }
      aiSummary = await _ensureAiSummary(profileId);
    } else {
      // 이미 메시지가 있으면 캐시된 요약 사용
      aiSummary = _cachedAiSummary;
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

    print('[ChatNotifier] 사용자 메시지 추가됨: messages.length=${state.messages.length}');

    // 사용자 메시지 저장
    try {
      await sessionRepository.saveMessage(userMessage);
    } catch (e) {
      // 저장 실패해도 계속 진행
    }

    try {
      // MD 파일에서 시스템 프롬프트 로드
      final basePrompt = await _loadSystemPrompt(chatType);

      // AI Summary를 시스템 프롬프트에 추가
      final systemPrompt = _appendAiSummaryToPrompt(basePrompt, aiSummary);

      if (kDebugMode && aiSummary != null) {
        print('[ChatNotifier] AI Summary가 시스템 프롬프트에 추가됨');
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

      if (kDebugMode) {
        if (tokensUsed != null) {
          print('[ChatNotifier] 토큰 사용량: $tokensUsed');
        }
        print('[ChatNotifier] $tokenUsage');
        if (windowResult?.wasTrimmed == true) {
          print('[ChatNotifier] ⚠️ 컨텍스트 트리밍 발생: ${windowResult!.removedCount}개 메시지 제거');
        }
      }

      // AI 응답에서 후속 질문 파싱
      final parseResult = SuggestedQuestionsParser.parse(fullContent);
      final cleanedContent = parseResult.cleanedContent;
      final suggestedQuestions = parseResult.suggestedQuestions;

      if (kDebugMode && suggestedQuestions != null) {
        print('[ChatNotifier] 후속 질문 추출: $suggestedQuestions');
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

      // AI 메시지 저장 (tokensUsed 포함)
      await sessionRepository.saveMessage(aiMessage);

      // 세션 메타데이터 업데이트
      await _updateSessionMetadata(currentSessionId, content);
    } catch (e) {
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
