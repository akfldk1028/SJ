/// 파이프라인 응답 단계
enum PipelinePhase {
  /// 분석 중
  analyzing,

  /// 응답 생성 중
  generating,

  /// 이미지 생성 중
  imaging,

  /// 스트리밍 중
  streaming,

  /// 완료
  completed,

  /// 에러
  error,
}

/// 파이프라인 응답
class PipelineResponse {
  final PipelinePhase phase;
  final String content;
  final Map<String, dynamic>? analysisData;
  final String? imageUrl;
  final String? error;

  const PipelineResponse({
    required this.phase,
    required this.content,
    this.analysisData,
    this.imageUrl,
    this.error,
  });

  bool get isAnalyzing => phase == PipelinePhase.analyzing;
  bool get isGenerating => phase == PipelinePhase.generating;
  bool get isImaging => phase == PipelinePhase.imaging;
  bool get isStreaming => phase == PipelinePhase.streaming;
  bool get isCompleted => phase == PipelinePhase.completed;
  bool get isError => phase == PipelinePhase.error;

  factory PipelineResponse.analyzing(String message) => PipelineResponse(
        phase: PipelinePhase.analyzing,
        content: message,
      );

  factory PipelineResponse.generating(String message,
          [Map<String, dynamic>? analysis]) =>
      PipelineResponse(
        phase: PipelinePhase.generating,
        content: message,
        analysisData: analysis,
      );

  factory PipelineResponse.streaming(String content,
          [Map<String, dynamic>? analysis]) =>
      PipelineResponse(
        phase: PipelinePhase.streaming,
        content: content,
        analysisData: analysis,
      );

  factory PipelineResponse.completed({
    required String content,
    Map<String, dynamic>? analysis,
    String? imageUrl,
  }) =>
      PipelineResponse(
        phase: PipelinePhase.completed,
        content: content,
        analysisData: analysis,
        imageUrl: imageUrl,
      );

  factory PipelineResponse.error(String error) => PipelineResponse(
        phase: PipelinePhase.error,
        content: '',
        error: error,
      );
}

/// 파이프라인 결과 (최종)
class PipelineResult {
  final Map<String, dynamic> analysis;
  final String response;
  final String? imageUrl;
  final bool success;
  final String? error;
  final Duration duration;

  const PipelineResult({
    required this.analysis,
    required this.response,
    this.imageUrl,
    required this.success,
    this.error,
    required this.duration,
  });
}
