import 'dart:convert';
import '../core/ai_cache.dart';
import '../core/ai_logger.dart';
import '../providers/openai/gpt_provider.dart';
import '../providers/google/gemini_provider.dart';
import '../providers/image/dalle_provider.dart';
import '../prompts/saju_prompts.dart';
import 'base_pipeline.dart';

/// 사주 분석 파이프라인
/// GPT 분석 → Gemini 대화 → (선택) 이미지 생성
class SajuPipeline {
  static final SajuPipeline _instance = SajuPipeline._();
  factory SajuPipeline() => _instance;
  SajuPipeline._();

  final GPTProvider _gpt = GPTProvider();
  final GeminiProvider _gemini = GeminiProvider();
  final DalleProvider _dalle = DalleProvider();
  final AICache _cache = AICache();

  bool _isInitialized = false;

  /// 초기화
  void initialize() {
    if (_isInitialized) return;

    AILogger.pipeline('Init', 'Starting SajuPipeline initialization...');
    _gpt.initialize();
    _gemini.initialize();
    _dalle.initialize();
    _isInitialized = true;

    AILogger.pipeline('Init', 'GPT: ${_gpt.isInitialized}');
    AILogger.pipeline('Init', 'Gemini: ${_gemini.isInitialized}');
    AILogger.pipeline('Init', 'DALL-E: ${_dalle.isInitialized}');
  }

  /// 상태 확인
  bool get isGptReady => _gpt.isInitialized;
  bool get isGeminiReady => _gemini.isInitialized;
  bool get isDalleReady => _dalle.isInitialized;

  /// 사주 분석 파이프라인 실행 (스트리밍)
  Stream<PipelineResponse> process({
    required String question,
    Map<String, dynamic>? birthInfo,
    Map<String, dynamic>? chartData,
    bool generateImage = false,
  }) async* {
    if (!_isInitialized) initialize();

    final stopwatch = Stopwatch()..start();
    AILogger.pipeline('Start', 'Question: $question');

    // ═══════════════════════════════════════════════════════════
    // Phase 1: GPT 분석
    // ═══════════════════════════════════════════════════════════
    yield PipelineResponse.analyzing('🔍 사주를 분석하고 있습니다...');

    Map<String, dynamic> analysis;

    // 캐시 확인
    final cacheKey = _cache.createKey('saju', question, birthInfo);
    final cached = _cache.get<Map<String, dynamic>>(cacheKey);

    if (cached != null) {
      AILogger.pipeline('Cache', 'Using cached analysis');
      analysis = cached;
    } else if (_gpt.isInitialized) {
      yield PipelineResponse.analyzing('🧠 GPT가 심층 분석 중...');

      analysis = await _gpt.sendStructured(
        systemPrompt: SajuPrompts.analysisSystem,
        userMessage: _buildAnalysisPrompt(question, birthInfo, chartData),
      );

      // 캐시 저장
      if (!analysis.containsKey('error')) {
        _cache.set(cacheKey, analysis);
      }
    } else {
      analysis = _getMockAnalysis(question);
    }

    AILogger.pipeline('GPT', 'Analysis complete');

    // ═══════════════════════════════════════════════════════════
    // Phase 2: Gemini 대화 생성
    // ═══════════════════════════════════════════════════════════
    yield PipelineResponse.generating('✨ 답변을 생성하고 있습니다...', analysis);

    if (_gemini.isInitialized) {
      final geminiPrompt = _buildChatPrompt(question, analysis);

      // 스트리밍 응답
      await for (final content in _gemini.sendMessageStream(geminiPrompt)) {
        yield PipelineResponse.streaming(content, analysis);
      }
    } else {
      yield PipelineResponse.streaming(_getMockChat(question), analysis);
    }

    // ═══════════════════════════════════════════════════════════
    // Phase 3: 이미지 생성 (선택)
    // ═══════════════════════════════════════════════════════════
    String? imageUrl;

    if (generateImage && _dalle.isInitialized) {
      yield PipelineResponse(
        phase: PipelinePhase.imaging,
        content: '🎨 사주 이미지를 생성하고 있습니다...',
        analysisData: analysis,
      );

      try {
        final dayGan = chartData?['dayPillar']?['gan'] ?? '갑';
        final oheng = analysis['analysis']?['yongsin']?['primary'] ?? '목';

        final imageResult = await _dalle.generateImage(
          prompt: SajuPrompts.sajuImagePrompt(
            dayGan: dayGan,
            oheng: oheng,
            mood: 'hopeful and mystical',
          ),
        );
        imageUrl = imageResult.url;
        AILogger.pipeline('DALL-E', 'Image generated');
      } catch (e) {
        AILogger.pipeline('DALL-E', 'Error: $e');
      }
    }

    stopwatch.stop();
    AILogger.pipeline('Complete', 'Duration: ${stopwatch.elapsed}');

    yield PipelineResponse.completed(
      content: '',
      analysis: analysis,
      imageUrl: imageUrl,
    );
  }

  /// 단순 분석 (스트리밍 없이)
  Future<PipelineResult> analyze({
    required String question,
    Map<String, dynamic>? birthInfo,
    Map<String, dynamic>? chartData,
    bool generateImage = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    String finalResponse = '';
    Map<String, dynamic> analysis = {};
    String? imageUrl;

    await for (final response in process(
      question: question,
      birthInfo: birthInfo,
      chartData: chartData,
      generateImage: generateImage,
    )) {
      if (response.isStreaming || response.isCompleted) {
        finalResponse = response.content;
      }
      if (response.analysisData != null) {
        analysis = response.analysisData!;
      }
      if (response.imageUrl != null) {
        imageUrl = response.imageUrl;
      }
    }

    stopwatch.stop();

    return PipelineResult(
      analysis: analysis,
      response: finalResponse,
      imageUrl: imageUrl,
      success: true,
      duration: stopwatch.elapsed,
    );
  }

  String _buildAnalysisPrompt(
    String question,
    Map<String, dynamic>? birthInfo,
    Map<String, dynamic>? chartData,
  ) {
    final buffer = StringBuffer();

    if (birthInfo != null) {
      buffer.writeln('## 생년월일시 정보');
      buffer.writeln(jsonEncode(birthInfo));
      buffer.writeln();
    }

    if (chartData != null) {
      buffer.writeln('## 만세력 데이터');
      buffer.writeln(jsonEncode(chartData));
      buffer.writeln();
    }

    buffer.writeln('## 질문');
    buffer.writeln(question);

    return buffer.toString();
  }

  String _buildChatPrompt(String question, Map<String, dynamic> analysis) {
    return '''${SajuPrompts.chatSystem}

## 전문가 분석 결과
${jsonEncode(analysis)}

## 사용자 질문
$question

위 분석을 바탕으로 친근하게 대화해주세요.''';
  }

  Map<String, dynamic> _getMockAnalysis(String question) {
    return {
      'analysis': {
        'summary': '(Mock) GPT API 연결이 필요합니다.',
        'fortune': {'overall': '보통'},
        'advice': ['API 키를 확인해주세요'],
      },
      'is_mock': true,
    };
  }

  String _getMockChat(String question) {
    return '''안녕하세요! 🌟

Gemini API 연결이 필요합니다.
API 키를 확인해주세요!''';
  }

  /// 캐시 초기화
  void clearCache() => _cache.clear();
}
