/// AI Provider 추상 베이스 클래스
abstract class BaseAIProvider {
  /// 제공자 이름
  String get name;

  /// 초기화 여부
  bool get isInitialized;

  /// 초기화
  void initialize();

  /// 리소스 정리
  void dispose();
}

/// LLM (텍스트 생성) Provider
abstract class BaseLLMProvider extends BaseAIProvider {
  /// 단일 메시지 전송
  Future<String> sendMessage(String message);

  /// 구조화된 응답 (JSON)
  Future<Map<String, dynamic>> sendStructured({
    required String systemPrompt,
    required String userMessage,
  });

  /// 스트리밍 응답
  Stream<String> sendMessageStream(String message);
}

/// 이미지 생성 Provider
abstract class BaseImageProvider extends BaseAIProvider {
  /// 이미지 생성
  /// Returns: 이미지 URL 또는 base64
  Future<ImageResult> generateImage({
    required String prompt,
    ImageSize size = ImageSize.square,
    ImageStyle style = ImageStyle.natural,
  });

  /// 이미지 편집 (inpainting)
  Future<ImageResult> editImage({
    required String imageUrl,
    required String prompt,
    String? mask,
  });
}

/// 이미지 생성 결과
class ImageResult {
  final String url;
  final String? base64;
  final String? revisedPrompt;
  final String model;

  const ImageResult({
    required this.url,
    this.base64,
    this.revisedPrompt,
    required this.model,
  });
}

/// 이미지 크기
enum ImageSize {
  square,    // 1024x1024
  landscape, // 1792x1024
  portrait,  // 1024x1792
}

/// 이미지 스타일
enum ImageStyle {
  natural,   // 자연스러운
  vivid,     // 생생한
  artistic,  // 예술적
}

extension ImageSizeExtension on ImageSize {
  String toDalleSize() {
    switch (this) {
      case ImageSize.square:
        return '1024x1024';
      case ImageSize.landscape:
        return '1792x1024';
      case ImageSize.portrait:
        return '1024x1792';
    }
  }

  Map<String, int> toImagenSize() {
    switch (this) {
      case ImageSize.square:
        return {'width': 1024, 'height': 1024};
      case ImageSize.landscape:
        return {'width': 1536, 'height': 1024};
      case ImageSize.portrait:
        return {'width': 1024, 'height': 1536};
    }
  }
}
