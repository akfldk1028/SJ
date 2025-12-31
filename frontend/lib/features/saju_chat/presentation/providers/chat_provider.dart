import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../AI/services/saju_analysis_service.dart';
import '../../../../core/services/prompt_loader.dart';
import '../../../../core/services/ai_summary_service.dart';
import '../../../../core/utils/suggested_questions_parser.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../saju_chart/presentation/providers/saju_chart_provider.dart';
import '../../data/datasources/gemini_edge_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../data/services/chat_realtime_service.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/models/ai_persona.dart';
import '../../domain/models/chat_type.dart';
import 'chat_session_provider.dart';
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
            final sajuService = SajuAnalysisService();
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

  /// 시스템 프롬프트에 AI Summary + 페르소나 추가
  ///
  /// 템플릿 순서:
  /// 1. 페르소나 지시문 (말투/성격)
  /// 2. 기본 프롬프트 (MD 파일에서 로드)
  /// 3. 사주 원본 데이터 (sajuOrigin: 합충형파해, 십성, 신살 등)
  /// 4. AI Summary (GPT-5.2 분석 결과)
  ///
  /// v2.0: AIContext 제거, AiSummary.sajuOrigin으로 통합
  /// - Gemini가 합충형파해 같은 복잡한 정보를 까먹지 않도록
  /// - 모든 원본 사주 데이터가 sajuOrigin에 포함됨
  ///
  /// v2.1: 토큰 최적화
  /// - isFirstMessage=true: sajuOrigin 전체 포함 (첫 메시지)
  /// - isFirstMessage=false: sajuOrigin 생략 (대화 히스토리에 이미 있음)
  String _buildFullSystemPrompt({
    required String basePrompt,
    AiSummary? aiSummary,
    AiPersona? persona,
    bool isFirstMessage = true,
  }) {
    final buffer = StringBuffer();

    // 0. 페르소나 지시문 추가 (가장 먼저)
    if (persona != null) {
      buffer.writeln('## 캐릭터 설정');
      buffer.writeln();
      buffer.writeln(persona.systemPromptInstruction);
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }

    // 기본 프롬프트 추가
    buffer.writeln(basePrompt);

    // AI Summary가 있을 때만 추가 정보 포함
    if (aiSummary != null) {
      // 1. 원본 사주 데이터 추가 (sajuOrigin에서)
      // - 합충형파해, 십성, 신살 등 복잡한 정보 포함
      // - Gemini가 까먹지 않도록 시스템 프롬프트에 포함
      // - v2.1: 첫 메시지에만 전체 포함 (토큰 최적화)
      if (isFirstMessage && aiSummary.sajuOrigin != null) {
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
        buffer.writeln('## 사주 원본 데이터 (GPT-5.2 분석용)');
        buffer.writeln();
        _addSajuOriginToPrompt(buffer, aiSummary.sajuOrigin!);
      } else if (!isFirstMessage) {
        // 이후 메시지에서는 간략 참조만
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
        buffer.writeln('## 사주 정보');
        buffer.writeln('(이전 대화에서 제공된 상세 사주 정보를 참조하세요)');
      }

      // 2. AI 분석 결과 추가
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln('## AI 분석 요약 (GPT-5.2)');
      buffer.writeln();

      // 한 문장 요약
      if (aiSummary.summary != null) {
        buffer.writeln('### 요약');
        buffer.writeln(aiSummary.summary);
        buffer.writeln();
      }

      buffer.writeln('### 성격');
      buffer.writeln('- **핵심**: ${aiSummary.personality.core}');
      buffer.writeln('- **특성**: ${aiSummary.personality.traits.join(', ')}');
      buffer.writeln();
      buffer.writeln('### 강점');
      buffer.writeln(aiSummary.strengths.map((s) => '- $s').join('\n'));
      buffer.writeln();
      buffer.writeln('### 약점');
      buffer.writeln(aiSummary.weaknesses.map((w) => '- $w').join('\n'));
      buffer.writeln();

      // 재물운
      if (aiSummary.wealth != null) {
        buffer.writeln('### 재물운');
        if (aiSummary.wealth!.overallTendency != null) {
          buffer.writeln('- **성향**: ${aiSummary.wealth!.overallTendency}');
        }
        if (aiSummary.wealth!.advice != null) {
          buffer.writeln('- **조언**: ${aiSummary.wealth!.advice}');
        }
        buffer.writeln();
      }

      // 연애운
      if (aiSummary.love != null) {
        buffer.writeln('### 연애운');
        if (aiSummary.love!.attractionStyle != null) {
          buffer.writeln('- **매력 스타일**: ${aiSummary.love!.attractionStyle}');
        }
        if (aiSummary.love!.advice != null) {
          buffer.writeln('- **조언**: ${aiSummary.love!.advice}');
        }
        buffer.writeln();
      }

      // 결혼운
      if (aiSummary.marriage != null) {
        buffer.writeln('### 결혼운');
        if (aiSummary.marriage!.marriageTiming != null) {
          buffer.writeln('- **시기**: ${aiSummary.marriage!.marriageTiming}');
        }
        if (aiSummary.marriage!.advice != null) {
          buffer.writeln('- **조언**: ${aiSummary.marriage!.advice}');
        }
        buffer.writeln();
      }

      buffer.writeln('### 진로/직장운');
      buffer.writeln('- **적합 분야**: ${aiSummary.career.aptitude.join(', ')}');
      buffer.writeln('- **조언**: ${aiSummary.career.advice}');
      buffer.writeln();

      // 사업운
      if (aiSummary.business != null) {
        buffer.writeln('### 사업운');
        if (aiSummary.business!.entrepreneurshipAptitude != null) {
          buffer.writeln('- **적성**: ${aiSummary.business!.entrepreneurshipAptitude}');
        }
        if (aiSummary.business!.advice != null) {
          buffer.writeln('- **조언**: ${aiSummary.business!.advice}');
        }
        buffer.writeln();
      }

      // 건강운
      if (aiSummary.health != null) {
        buffer.writeln('### 건강운');
        if (aiSummary.health!.vulnerableOrgans.isNotEmpty) {
          buffer.writeln('- **취약 장기**: ${aiSummary.health!.vulnerableOrgans.join(', ')}');
        }
        if (aiSummary.health!.lifestyleAdvice.isNotEmpty) {
          buffer.writeln('- **생활 조언**: ${aiSummary.health!.lifestyleAdvice.join(', ')}');
        }
        buffer.writeln();
      }

      buffer.writeln('### 대인관계');
      buffer.writeln('- **스타일**: ${aiSummary.relationships.style}');
      buffer.writeln('- **팁**: ${aiSummary.relationships.tips}');
      buffer.writeln();

      // 행운 요소 (luckyElements 우선, 없으면 fortuneTips)
      if (aiSummary.luckyElements != null) {
        buffer.writeln('### 행운 요소');
        buffer.writeln('- **행운의 색상**: ${aiSummary.luckyElements!.colors.join(', ')}');
        buffer.writeln('- **행운의 방향**: ${aiSummary.luckyElements!.directions.join(', ')}');
        if (aiSummary.luckyElements!.numbers.isNotEmpty) {
          buffer.writeln('- **행운의 숫자**: ${aiSummary.luckyElements!.numbers.join(', ')}');
        }
      } else {
        buffer.writeln('### 개운법');
        buffer.writeln('- **행운의 색상**: ${aiSummary.fortuneTips.colors.join(', ')}');
        buffer.writeln('- **행운의 방향**: ${aiSummary.fortuneTips.directions.join(', ')}');
        buffer.writeln('- **추천 활동**: ${aiSummary.fortuneTips.activities.join(', ')}');
      }

      // 종합 조언
      if (aiSummary.overallAdvice != null) {
        buffer.writeln();
        buffer.writeln('### 종합 조언');
        buffer.writeln(aiSummary.overallAdvice);
      }
    }

    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('위 사용자 정보를 참고하여 맞춤형 상담을 제공하세요.');
    buffer.writeln('사용자가 생년월일을 다시 물어볼 필요 없이, 이미 알고 있는 정보를 활용하세요.');
    buffer.writeln('합충형파해, 십성, 신살 정보를 적극 활용하여 깊이 있는 상담을 제공하세요.');

    return buffer.toString();
  }

  /// sajuOrigin 데이터를 프롬프트에 추가하는 헬퍼 메서드
  ///
  /// sajuOrigin 구조:
  /// - saju: 사주팔자 (년월일시)
  /// - oheng: 오행 분포
  /// - yongsin: 용신 정보
  /// - sipsin: 십성 배치
  /// - singang: 신강/신약
  /// - gyeokguk: 격국
  /// - hapchung: 합충형파해
  /// - sinsal: 신살
  /// - gilseong: 길성
  /// - twelve_unsung: 12운성
  /// - daeun: 대운
  void _addSajuOriginToPrompt(StringBuffer buffer, Map<String, dynamic> sajuOrigin) {
    // 기본 사주 정보
    final saju = sajuOrigin['saju'] as Map<String, dynamic>?;
    if (saju != null) {
      buffer.writeln('### 사주팔자');
      buffer.writeln('| 구분 | 년주 | 월주 | 일주 | 시주 |');
      buffer.writeln('|------|------|------|------|------|');
      final yearGan = saju['year']?['gan'] ?? '?';
      final yearJi = saju['year']?['ji'] ?? '?';
      final monthGan = saju['month']?['gan'] ?? '?';
      final monthJi = saju['month']?['ji'] ?? '?';
      final dayGan = saju['day']?['gan'] ?? '?';
      final dayJi = saju['day']?['ji'] ?? '?';
      final hourGan = saju['hour']?['gan'] ?? '?';
      final hourJi = saju['hour']?['ji'] ?? '?';
      buffer.writeln('| 천간 | $yearGan | $monthGan | $dayGan | $hourGan |');
      buffer.writeln('| 지지 | $yearJi | $monthJi | $dayJi | $hourJi |');
      buffer.writeln();
    }

    // 오행 분포
    final oheng = sajuOrigin['oheng'] as Map<String, dynamic>?;
    if (oheng != null) {
      buffer.writeln('### 오행 분포');
      buffer.writeln('- 목(木): ${oheng['wood'] ?? 0}');
      buffer.writeln('- 화(火): ${oheng['fire'] ?? 0}');
      buffer.writeln('- 토(土): ${oheng['earth'] ?? 0}');
      buffer.writeln('- 금(金): ${oheng['metal'] ?? 0}');
      buffer.writeln('- 수(水): ${oheng['water'] ?? 0}');
      buffer.writeln();
    }

    // 용신
    final yongsin = sajuOrigin['yongsin'] as Map<String, dynamic>?;
    if (yongsin != null) {
      buffer.writeln('### 용신');
      buffer.writeln('- 용신: ${yongsin['yongsin'] ?? '미정'}');
      buffer.writeln('- 희신: ${yongsin['huisin'] ?? '미정'}');
      buffer.writeln('- 기신: ${yongsin['gisin'] ?? '미정'}');
      buffer.writeln('- 구신: ${yongsin['gusin'] ?? '미정'}');
      buffer.writeln();
    }

    // 신강/신약
    final singang = sajuOrigin['singang'] as Map<String, dynamic>?;
    if (singang != null) {
      final isSingang = singang['is_singang'] == true;
      buffer.writeln('### 신강/신약');
      buffer.writeln('- ${isSingang ? '신강' : '신약'} (점수: ${singang['score'] ?? 50})');
      buffer.writeln();
    }

    // 격국
    final gyeokguk = sajuOrigin['gyeokguk'] as Map<String, dynamic>?;
    if (gyeokguk != null) {
      buffer.writeln('### 격국');
      buffer.writeln('- ${gyeokguk['name'] ?? '미정'}');
      if (gyeokguk['reason'] != null) {
        buffer.writeln('- 사유: ${gyeokguk['reason']}');
      }
      buffer.writeln();
    }

    // 십성 (중요!)
    final sipsin = sajuOrigin['sipsin'] as Map<String, dynamic>?;
    if (sipsin != null) {
      buffer.writeln('### 십성 배치');
      buffer.writeln('- 년간: ${sipsin['yearGan'] ?? '?'}');
      buffer.writeln('- 월간: ${sipsin['monthGan'] ?? '?'}');
      buffer.writeln('- 시간: ${sipsin['hourGan'] ?? '?'}');
      buffer.writeln('- 년지: ${sipsin['yearJi'] ?? '?'}');
      buffer.writeln('- 월지: ${sipsin['monthJi'] ?? '?'}');
      buffer.writeln('- 일지: ${sipsin['dayJi'] ?? '?'}');
      buffer.writeln('- 시지: ${sipsin['hourJi'] ?? '?'}');
      buffer.writeln();
    }

    // 합충형파해 (핵심!)
    final hapchung = sajuOrigin['hapchung'] as Map<String, dynamic>?;
    if (hapchung != null) {
      buffer.writeln('### 합충형파해');
      // 천간합
      if (hapchung['chungan_haps'] != null) {
        final haps = hapchung['chungan_haps'] as List?;
        if (haps != null && haps.isNotEmpty) {
          buffer.writeln('**천간합**:');
          for (final h in haps) {
            buffer.writeln('- ${h['description'] ?? h}');
          }
        }
      }
      // 지지육합
      if (hapchung['jiji_yukhaps'] != null) {
        final haps = hapchung['jiji_yukhaps'] as List?;
        if (haps != null && haps.isNotEmpty) {
          buffer.writeln('**지지육합**:');
          for (final h in haps) {
            buffer.writeln('- ${h['description'] ?? h}');
          }
        }
      }
      // 지지삼합
      if (hapchung['jiji_samhaps'] != null) {
        final haps = hapchung['jiji_samhaps'] as List?;
        if (haps != null && haps.isNotEmpty) {
          buffer.writeln('**지지삼합**:');
          for (final h in haps) {
            buffer.writeln('- ${h['description'] ?? h}');
          }
        }
      }
      // 충
      if (hapchung['chungs'] != null) {
        final items = hapchung['chungs'] as List?;
        if (items != null && items.isNotEmpty) {
          buffer.writeln('**충**:');
          for (final item in items) {
            buffer.writeln('- ${item['description'] ?? item}');
          }
        }
      }
      // 형
      if (hapchung['hyungs'] != null) {
        final items = hapchung['hyungs'] as List?;
        if (items != null && items.isNotEmpty) {
          buffer.writeln('**형**:');
          for (final item in items) {
            buffer.writeln('- ${item['description'] ?? item}');
          }
        }
      }
      // 파
      if (hapchung['pas'] != null) {
        final items = hapchung['pas'] as List?;
        if (items != null && items.isNotEmpty) {
          buffer.writeln('**파**:');
          for (final item in items) {
            buffer.writeln('- ${item['description'] ?? item}');
          }
        }
      }
      // 해
      if (hapchung['haes'] != null) {
        final items = hapchung['haes'] as List?;
        if (items != null && items.isNotEmpty) {
          buffer.writeln('**해**:');
          for (final item in items) {
            buffer.writeln('- ${item['description'] ?? item}');
          }
        }
      }
      buffer.writeln();
    }

    // 신살
    final sinsal = sajuOrigin['sinsal'] as List?;
    if (sinsal != null && sinsal.isNotEmpty) {
      buffer.writeln('### 신살');
      for (final s in sinsal) {
        final name = s['name'] ?? s['sinsal'] ?? '?';
        final type = s['type'] ?? s['fortuneType'] ?? '';
        final pillar = s['pillar'] ?? '';
        buffer.writeln('- $pillar: $name ($type)');
      }
      buffer.writeln();
    }

    // 길성
    final gilseong = sajuOrigin['gilseong'] as List?;
    if (gilseong != null && gilseong.isNotEmpty) {
      buffer.writeln('### 길성');
      for (final g in gilseong) {
        final name = g['name'] ?? g;
        buffer.writeln('- $name');
      }
      buffer.writeln();
    }

    // 12운성
    final twelveUnsung = sajuOrigin['twelve_unsung'] as List?;
    if (twelveUnsung != null && twelveUnsung.isNotEmpty) {
      buffer.writeln('### 12운성');
      for (final u in twelveUnsung) {
        final pillar = u['pillar'] ?? '?';
        final unsung = u['unsung'] ?? '?';
        buffer.writeln('- $pillar: $unsung');
      }
      buffer.writeln();
    }

    // 대운
    final daeun = sajuOrigin['daeun'] as Map<String, dynamic>?;
    if (daeun != null) {
      buffer.writeln('### 대운');
      final current = daeun['current'] as Map<String, dynamic>?;
      if (current != null) {
        final pillar = current['pillar'] ?? '${current['gan'] ?? ''}${current['ji'] ?? ''}';
        final startAge = current['start_age'] ?? current['startAge'] ?? '?';
        final endAge = current['end_age'] ?? current['endAge'] ?? '?';
        buffer.writeln('- 현재: $pillar ($startAge세 ~ $endAge세)');
      }
      buffer.writeln();
    }
  }

  /// 메시지 전송
  Future<void> sendMessage(String content, ChatType chatType) async {
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
    }

    final currentSessionId = sessionId;
    final sessionRepository = ref.read(chatSessionRepositoryProvider);

    // 현재 세션의 profileId 가져오기
    final currentSession = await sessionRepository.getSession(currentSessionId);
    final profileId = currentSession?.profileId;

    // [2] AI Summary 준비
    AiSummary? aiSummary;
    if (state.messages.isEmpty) {
      if (kDebugMode) {
        print('');
        print('┌──────────────────────────────────────────────────────────────┐');
        print('│  📦 [2] AI SUMMARY                                           │');
        print('└──────────────────────────────────────────────────────────────┘');
        print('   🔄 첫 메시지 - AI Summary 확인/생성...');
      }
      aiSummary = await _ensureAiSummary(profileId);
    } else {
      // 이미 메시지가 있으면 캐시된 요약 사용
      aiSummary = _cachedAiSummary;
      if (kDebugMode) {
        print('   ✅ 캐시된 AI Summary 사용');
      }
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
      final currentPersona = ref.read(personaNotifierProvider);

      // AI Summary (sajuOrigin 포함) + 페르소나를 시스템 프롬프트에 추가
      // v2.0: AIContext 제거, AiSummary.sajuOrigin으로 통합
      // v2.1: 첫 메시지에만 sajuOrigin 전체 포함 (토큰 최적화)
      final isFirstMessage = state.messages.where((m) => m.role == 'assistant').isEmpty;
      final systemPrompt = _buildFullSystemPrompt(
        basePrompt: basePrompt,
        aiSummary: aiSummary,
        persona: currentPersona,
        isFirstMessage: isFirstMessage,
      );

      // [4] 시스템 프롬프트 구성
      if (kDebugMode) {
        print('');
        print('┌──────────────────────────────────────────────────────────────┐');
        print('│  ⚙️ [4] SYSTEM PROMPT BUILD                                  │');
        print('└──────────────────────────────────────────────────────────────┘');
        print('   👤 페르소나: ${currentPersona.displayName}');
        print('   🔢 isFirstMessage: $isFirstMessage');
        if (aiSummary != null) {
          print('   ✅ AI Summary 포함');
          if (isFirstMessage && aiSummary.sajuOrigin != null) {
            print('   📋 sajuOrigin: ✅ 전체 포함 (합충형파해, 십성, 신살 등)');
          } else {
            print('   📋 sajuOrigin: ⏭️ 생략 (대화 히스토리 참조)');
          }
        } else {
          print('   ❌ AI Summary 없음');
        }
        print('   📏 프롬프트 길이: ${systemPrompt.length} chars');
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
