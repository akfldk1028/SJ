import 'package:dio/dio.dart';
import '../../core/ai_config.dart';
import '../../core/ai_logger.dart';
import '../../core/base_provider.dart';

/// Google Imagen 이미지 생성 Provider
class ImagenProvider extends BaseImageProvider {
  static final ImagenProvider _instance = ImagenProvider._();
  factory ImagenProvider() => _instance;
  ImagenProvider._();

  late final Dio _dio;
  bool _isInitialized = false;
  final String _model = AIConfig.imagenDefault;

  @override
  String get name => 'Imagen';

  @override
  bool get isInitialized => _isInitialized;

  @override
  void initialize() {
    final config = AIConfig.instance;
    if (!config.hasImagen) {
      AILogger.error(name, 'API key not configured');
      return;
    }

    _dio = Dio(BaseOptions(
      baseUrl: AIConfig.geminiBaseUrl,
      headers: {'Content-Type': 'application/json'},
      queryParameters: {'key': config.geminiApiKey},
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
    ));

    _isInitialized = true;
    AILogger.log(name, 'Initialized with $_model');
  }

  @override
  Future<ImageResult> generateImage({
    required String prompt,
    ImageSize size = ImageSize.square,
    ImageStyle style = ImageStyle.natural,
  }) async {
    if (!_isInitialized) {
      throw Exception('Imagen not initialized');
    }

    try {
      AILogger.request(name, '/models/$_model:predict');

      final response = await _dio.post(
        '/models/$_model:predict',
        data: {
          'instances': [
            {'prompt': prompt}
          ],
          'parameters': {
            'sampleCount': 1,
            'aspectRatio': _getAspectRatio(size),
            'personGeneration': 'allow_adult',
          },
        },
      );

      final predictions = response.data['predictions'] as List;
      if (predictions.isEmpty) {
        throw Exception('No image generated');
      }

      final base64Image = predictions[0]['bytesBase64Encoded'];
      AILogger.response(name);

      return ImageResult(
        url: 'data:image/png;base64,$base64Image',
        base64: base64Image,
        model: _model,
      );
    } on DioException catch (e) {
      AILogger.error(name, e.response?.data ?? e.message);
      rethrow;
    }
  }

  String _getAspectRatio(ImageSize size) {
    switch (size) {
      case ImageSize.square:
        return '1:1';
      case ImageSize.landscape:
        return '16:9';
      case ImageSize.portrait:
        return '9:16';
    }
  }

  @override
  Future<ImageResult> editImage({
    required String imageUrl,
    required String prompt,
    String? mask,
  }) async {
    // Imagen 3는 편집 지원
    throw UnimplementedError('Imagen edit not implemented yet');
  }

  @override
  void dispose() {
    _isInitialized = false;
  }
}
