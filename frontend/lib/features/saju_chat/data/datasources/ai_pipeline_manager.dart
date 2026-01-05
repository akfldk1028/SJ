import 'dart:async';
import 'dart:convert';

import 'openai_edge_datasource.dart';
import 'gemini_edge_datasource.dart';

/// AI 파이프라인 매니저
///
/// 듀얼 AI 아키텍처:
/// 1. GPT 5.2 Thinking → 사주 분석 (정확한 추론)
/// 2. Gemini 3.0 Pro → 대화 생성 (재미있는 응답)
///
/// 위젯 트리 최적화:
/// - 각 AI 모듈은 독립적으로 동작
/// - 스트리밍 응답으로 실시간 UX 제공
/// - 분석 결과 캐싱으로 중복 호출 방지
///
/// 2025-12-30: Edge Function 전환 - API 키 보안 강화
/// - OpenAIDatasource → OpenAIEdgeDatasource
/// - GeminiRestDatasource → GeminiEdgeDatasource
class AIPipelineManager {
  final OpenAIEdgeDatasource _gptDatasource;
  final GeminiEdgeDatasource _geminiDatasource;

  /// 분석 결과 캐시 (세션별)
  final Map<String, Map<String, dynamic>> _analysisCache = {};

  AIPipelineManager({
    OpenAIEdgeDatasource? gptDatasource,
    GeminiEdgeDatasource? geminiDatasource,
  })  : _gptDatasource = gptDatasource ?? OpenAIEdgeDatasource(),
        _geminiDatasource = geminiDatasource ?? GeminiEdgeDatasource();

  /// 초기화
  void initialize() {
    _gptDatasource.initialize();
    _geminiDatasource.initialize();
    print('[AIPipeline] Initialized - GPT: ${_gptDatasource.isInitialized}, Gemini: ${_geminiDatasource.isInitialized}');
  }

  /// GPT 사용 가능 여부
  bool get isGPTAvailable => _gptDatasource.isInitialized;

  /// Gemini 사용 가능 여부
  bool get isGeminiAvailable => _geminiDatasource.isInitialized;

  /// 듀얼 AI 파이프라인 응답 스트림
  ///
  /// 1단계: GPT 5.2 Thinking으로 사주 분석
  /// 2단계: 분석 결과를 Gemini에 전달하여 재미있는 대화 생성
  ///
  /// [userMessage] 사용자 질문
  /// [birthInfo] 생년월일시 정보
  /// [chartData] 만세력 계산 결과
  /// [systemPrompt] Gemini용 시스템 프롬프트
  /// [sessionId] 세션 ID (캐시용)
  Stream<PipelineResponse> processMessage({
    required String userMessage,
    required Map<String, dynamic> birthInfo,
    required Map<String, dynamic> chartData,
    required String systemPrompt,
    String? sessionId,
  }) async* {
    // Phase 1: GPT 분석 (캐시 확인)
    yield PipelineResponse(
      phase: PipelinePhase.analyzing,
      content: '🔍 사주를 분석하고 있습니다...',
    );

    Map<String, dynamic> analysis;

    // 캐시된 분석 결과가 있으면 사용
    final cacheKey = sessionId ?? 'default';
    if (_analysisCache.containsKey(cacheKey) &&
        !_isAnalysisRequired(userMessage)) {
      analysis = _analysisCache[cacheKey]!;
      print('[AIPipeline] Using cached analysis');
    } else {
      // GPT 5.2 Thinking으로 새 분석
      if (isGPTAvailable) {
        yield PipelineResponse(
          phase: PipelinePhase.analyzing,
          content: '🧠 GPT 5.2 Thinking이 심층 분석 중...',
        );

        analysis = await _gptDatasource.analyzeSaju(
          birthInfo: birthInfo,
          chartData: chartData,
          question: userMessage,
        );
      } else {
        // GPT 사용 불가시 Mock 분석
        analysis = _getFallbackAnalysis(userMessage);
      }

      // 캐시 저장
      _analysisCache[cacheKey] = analysis;
    }

    // Phase 2: Gemini로 대화 생성
    yield PipelineResponse(
      phase: PipelinePhase.generating,
      content: '✨ 답변을 생성하고 있습니다...',
      analysisData: analysis,
    );

    // Gemini에 분석 결과와 함께 대화 요청
    final geminiPrompt = _buildGeminiPrompt(
      userMessage: userMessage,
      analysis: analysis,
      systemPrompt: systemPrompt,
    );

    // Gemini 스트리밍 응답
    final geminiStream = _geminiDatasource.sendMessageStream(geminiPrompt);

    await for (final content in geminiStream) {
      yield PipelineResponse(
        phase: PipelinePhase.streaming,
        content: content,
        analysisData: analysis,
      );
    }

    // 완료
    yield PipelineResponse(
      phase: PipelinePhase.completed,
      content: '', // 마지막 스트리밍 content가 최종 응답
      analysisData: analysis,
    );
  }

  /// Gemini 단독 모드 (분석 없이 대화만)
  Stream<String> geminiOnlyStream({
    required String userMessage,
    required String systemPrompt,
  }) {
    _geminiDatasource.startNewSession(systemPrompt);
    return _geminiDatasource.sendMessageStream(userMessage);
  }

  /// 분석이 필요한 질문인지 판단
  bool _isAnalysisRequired(String message) {
    final keywords = [
      '운세', '오늘', '이번주', '이번달', '올해',
      '사주', '분석', '팔자', '명식',
      '궁합', '상성',
      '재물', '연애', '취업', '건강', '결혼',
      '대운', '세운', '월운',
    ];

    final lowerMessage = message.toLowerCase();
    return keywords.any((k) => lowerMessage.contains(k));
  }

  /// Gemini용 프롬프트 생성 (GPT 분석 결과 포함)
  String _buildGeminiPrompt({
    required String userMessage,
    required Map<String, dynamic> analysis,
    required String systemPrompt,
  }) {
    final analysisJson = jsonEncode(analysis);

    return '''$systemPrompt

## 전문가 분석 결과 (참고용)
$analysisJson

## 사용자 질문
$userMessage

위 분석 결과를 바탕으로, 친근하고 재미있게 대화해주세요.
- 딱딱한 분석 용어보다는 쉬운 말로
- 적절한 이모지 사용
- 긍정적이고 희망적인 톤
- 구체적인 조언 포함

## AI 시대 해석 가이드 (참고용 - 전통 의미와 함께 설명)
설명할 때 전통 의미 먼저, 현대 적용은 "요즘 시대에는~" 형태로 덧붙이기
- 식상: 전통(자녀/표현력) → 요즘(콘텐츠창작/SNS/유튜브)
- 역마살: 전통(먼여행/이사) → 요즘(디지털노마드/해외근무/출장)
- 도화살: 전통(이성매력) → 요즘(인플루언서/대중인기/연예계)
- 인성: 전통(학문/자격증) → 요즘(AI활용능력/온라인학습/코딩)
- 재성: 전통(재물/토지) → 요즘(디지털자산/투자/N잡/부업)
※ 이 해석은 참고용이며, 해석자마다 다를 수 있음을 언급해도 좋음''';
  }

  /// Fallback 분석 (GPT 사용 불가시)
  Map<String, dynamic> _getFallbackAnalysis(String question) {
    return {
      'analysis': {
        'summary': '기본 분석 결과입니다.',
        'fortune': {
          'overall': '보통',
          'advice': '더 정확한 분석을 위해 OpenAI API 키를 설정해주세요.',
        },
      },
      'is_fallback': true,
    };
  }

  /// 세션 캐시 초기화
  void clearCache([String? sessionId]) {
    if (sessionId != null) {
      _analysisCache.remove(sessionId);
    } else {
      _analysisCache.clear();
    }
  }

  /// 새 세션 시작
  void startNewSession(String systemPrompt) {
    _geminiDatasource.startNewSession(systemPrompt);
  }

  /// 리소스 정리
  void dispose() {
    _gptDatasource.dispose();
    _geminiDatasource.dispose();
    _analysisCache.clear();
  }
}

/// 파이프라인 응답 단계
enum PipelinePhase {
  /// GPT 분석 중
  analyzing,

  /// Gemini 응답 생성 중
  generating,

  /// 스트리밍 중
  streaming,

  /// 완료
  completed,
}

/// 파이프라인 응답
class PipelineResponse {
  final PipelinePhase phase;
  final String content;
  final Map<String, dynamic>? analysisData;

  const PipelineResponse({
    required this.phase,
    required this.content,
    this.analysisData,
  });

  bool get isAnalyzing => phase == PipelinePhase.analyzing;
  bool get isGenerating => phase == PipelinePhase.generating;
  bool get isStreaming => phase == PipelinePhase.streaming;
  bool get isCompleted => phase == PipelinePhase.completed;
}
