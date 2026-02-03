import 'package:dio/dio.dart';
import '../../../core/ai_config.dart';
import '../../../core/ai_simple_logger.dart';
import '../../../core/base_provider.dart';

/// OpenAI DALL-E 이미지 생성 Provider
class DalleProvider extends BaseImageProvider {
  static final DalleProvider _instance = DalleProvider._();
  factory DalleProvider() => _instance;
  DalleProvider._();

  late final Dio _dio;
  bool _isInitialized = false;
  final String _model = AIConfig.dalleDefault;

  @override
  String get name => 'DALL-E';

  @override
  bool get isInitialized => _isInitialized;

  @override
  void initialize() {
    final config = AIConfig.instance;
    if (!config.hasDalle) {
      AILogger.error(name, 'API key not configured');
      return;
    }

    _dio = Dio(BaseOptions(
      baseUrl: AIConfig.openaiBaseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.openaiApiKey}',
      },
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
      throw Exception('DALL-E not initialized');
    }

    try {
      AILogger.request(name, '/images/generations');

      final response = await _dio.post('/images/generations', data: {
        'model': _model,
        'prompt': prompt,
        'n': 1,
        'size': size.toDalleSize(),
        'style': style == ImageStyle.vivid ? 'vivid' : 'natural',
        'response_format': 'url',
      });

      final data = response.data['data'][0];
      AILogger.response(name);

      return ImageResult(
        url: data['url'],
        revisedPrompt: data['revised_prompt'],
        model: _model,
      );
    } on DioException catch (e) {
      AILogger.error(name, e.response?.data ?? e.message);
      rethrow;
    }
  }

  @override
  Future<ImageResult> editImage({
    required String imageUrl,
    required String prompt,
    String? mask,
  }) async {
    // DALL-E 3는 edit 미지원, DALL-E 2 사용 필요
    throw UnimplementedError('DALL-E 3 does not support image editing');
  }

  @override
  void dispose() {
    _isInitialized = false;
  }
}
