import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/ai_pipeline_manager.dart';
import '../datasources/gemini_edge_datasource.dart';
import '../services/conversation_window_manager.dart';

export '../datasources/gemini_edge_datasource.dart' show GeminiResponse;
export '../services/conversation_window_manager.dart' show TokenUsageInfo, WindowedConversation;

/// ChatRepository 구현체
///
/// 듀얼 AI 파이프라인:
/// - GPT 5.2 Thinking: 사주 분석 (정확한 추론)
/// - Gemini 3.0: 대화 생성 (재미있는 응답)
///
/// Pipeline 모드가 비활성화되면 Gemini 단독 모드로 동작
///
/// 2025-12-30: Edge Function 전환 - API 키 보안 강화
/// - GeminiRestDatasource → GeminiEdgeDatasource
/// - API 키가 Supabase Secrets에만 저장됨
class ChatRepositoryImpl implements ChatRepository {
  final GeminiEdgeDatasource _datasource;
  final AIPipelineManager? _pipeline;
  final _uuid = const Uuid();
  bool _isSessionStarted = false;

  /// 파이프라인 모드 활성화 여부
  final bool usePipeline;

  /// 사용자 프로필 정보 (사주 분석용)
  Map<String, dynamic>? birthInfo;
  Map<String, dynamic>? chartData;

  ChatRepositoryImpl({
    GeminiEdgeDatasource? datasource,
    AIPipelineManager? pipeline,
    this.usePipeline = true,
  })  : _datasource = datasource ?? GeminiEdgeDatasource(),
        _pipeline = pipeline ?? (usePipeline ? AIPipelineManager() : null);

  /// 프로필 정보 설정 (사주 분석용)
  void setProfileInfo({
    required Map<String, dynamic> birthInfo,
    required Map<String, dynamic> chartData,
  }) {
    this.birthInfo = birthInfo;
    this.chartData = chartData;
  }

  @override
  Future<ChatMessage> sendMessage({
    required String userMessage,
    required List<ChatMessage> conversationHistory,
    required String systemPrompt,
  }) async {
    _ensureInitialized(systemPrompt);

    try {
      final response = await _datasource.sendMessage(userMessage);

      return ChatMessage(
        id: _uuid.v4(),
        sessionId: '',
        content: response,
        role: MessageRole.assistant,
        createdAt: DateTime.now(),
        status: MessageStatus.sent,
      );
    } catch (e) {
      return ChatMessage(
        id: _uuid.v4(),
        sessionId: '',
        content: '죄송합니다. 응답을 받는 중 오류가 발생했습니다.',
        role: MessageRole.assistant,
        createdAt: DateTime.now(),
        status: MessageStatus.error,
      );
    }
  }

  @override
  Stream<String> sendMessageStream({
    required String userMessage,
    required List<ChatMessage> conversationHistory,
    required String systemPrompt,
  }) {
    _ensureInitialized(systemPrompt);

    // 파이프라인 모드 (GPT 분석 → Gemini 대화)
    if (usePipeline && _pipeline != null && _hasSajuContext) {
      return _pipelineStream(
        userMessage: userMessage,
        systemPrompt: systemPrompt,
      );
    }

    // Gemini 단독 모드
    return _datasource.sendMessageStream(userMessage);
  }

  /// 파이프라인 스트림 (GPT → Gemini)
  Stream<String> _pipelineStream({
    required String userMessage,
    required String systemPrompt,
  }) async* {
    final pipeline = _pipeline!;

    String lastContent = '';

    await for (final response in pipeline.processMessage(
      userMessage: userMessage,
      birthInfo: birthInfo ?? {},
      chartData: chartData ?? {},
      systemPrompt: systemPrompt,
    )) {
      // 분석 중 상태 메시지
      if (response.isAnalyzing || response.isGenerating) {
        yield response.content;
      }
      // 스트리밍 응답
      else if (response.isStreaming) {
        lastContent = response.content;
        yield lastContent;
      }
    }
  }

  /// 사주 컨텍스트 존재 여부
  bool get _hasSajuContext =>
      birthInfo != null &&
      birthInfo!.isNotEmpty &&
      chartData != null &&
      chartData!.isNotEmpty;

  /// 초기화 확인
  void _ensureInitialized(String systemPrompt) {
    if (!_isSessionStarted) {
      _datasource.initialize();
      _datasource.startNewSession(systemPrompt);

      if (usePipeline && _pipeline != null) {
        _pipeline.initialize();
        _pipeline.startNewSession(systemPrompt);
      }

      _isSessionStarted = true;
    }
  }

  /// 세션 리셋 (새 대화 시작 시 호출)
  void resetSession() {
    _isSessionStarted = false;
    _datasource.dispose();
    _pipeline?.dispose();
  }

  /// 분석 캐시 초기화
  void clearAnalysisCache([String? sessionId]) {
    _pipeline?.clearCache(sessionId);
  }

  /// 마지막 스트리밍 응답의 토큰 사용량 조회
  ///
  /// sendMessageStream 완료 후 호출하면 토큰 사용량을 반환
  /// 스트리밍 중이거나 아직 응답이 없으면 null 반환
  GeminiResponse? getLastStreamingResponse() {
    return _datasource.lastStreamingResponse;
  }

  /// 마지막 응답의 토큰 사용량만 조회 (편의 메서드)
  int? getLastTokensUsed() {
    return _datasource.lastStreamingResponse?.tokensUsed;
  }

  /// 현재 토큰 사용량 정보 조회
  ///
  /// 토큰 제한에 가까워지면 UI에서 경고 표시 가능
  TokenUsageInfo getTokenUsageInfo() {
    return _datasource.getTokenUsageInfo();
  }

  /// 마지막 윈도우잉 결과 조회
  ///
  /// 메시지가 트리밍되었는지 확인 가능
  WindowedConversation? getLastWindowResult() {
    return _datasource.lastWindowResult;
  }
}
