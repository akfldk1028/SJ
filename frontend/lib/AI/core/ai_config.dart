/// AI 서비스 설정
class AIConfig {
  static AIConfig? _instance;
  static AIConfig get instance => _instance ??= AIConfig._();
  AIConfig._();

  // ═══════════════════════════════════════════════════════════
  // API Keys (빌드 시 --dart-define-from-file=.env 로 주입)
  // SECURITY: .env를 assets에 절대 포함 금지. 컴파일 타임 상수로만 박기.
  // ═══════════════════════════════════════════════════════════
  String get openaiApiKey => const String.fromEnvironment('OPENAI_API_KEY');
  String get geminiApiKey => const String.fromEnvironment('GEMINI_API_KEY');
  String get claudeApiKey => const String.fromEnvironment('CLAUDE_API_KEY');
  String get dalleApiKey => openaiApiKey; // DALL-E uses OpenAI key
  String get imagenApiKey => geminiApiKey; // Imagen uses Google key

  // ═══════════════════════════════════════════════════════════
  // Model Names
  // ═══════════════════════════════════════════════════════════

  // OpenAI Models (GPT-5.2 - 2025.12.11 출시)
  // Responses API 사용: /v1/responses
  static const String gptDefault = 'gpt-5.2-thinking'; // Thinking - 추론 특화 (100-150초)
  static const String gptInstant = 'gpt-5.2-instant'; // Instant - 빠른 응답
  static const String gptPro = 'gpt-5.2-pro'; // Pro - 최고 품질
  static const String gptLegacy = 'gpt-4o'; // 이전 버전 (Chat Completions API)

  // Google Models (v37: 2026-04-04 비용 절감 전환)
  static const String geminiDefault = 'gemini-2.5-flash-lite'; // Gemini 2.5 Flash Lite (비용 최적)
  static const String geminiPro = 'gemini-3-pro-preview'; // Gemini 3 Pro
  static const String geminiLegacy = 'gemini-2.0-flash'; // 이전 버전 (호환용)

  // Anthropic Models
  static const String claudeDefault = 'claude-3-5-sonnet-20241022';
  static const String claudeHaiku = 'claude-3-haiku-20240307';

  // Image Models
  static const String dalleDefault = 'dall-e-3';
  static const String imagenDefault = 'imagen-3.0-generate-001';

  // ═══════════════════════════════════════════════════════════
  // API Endpoints
  // ═══════════════════════════════════════════════════════════
  static const String openaiBaseUrl = 'https://api.openai.com/v1';
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String claudeBaseUrl = 'https://api.anthropic.com/v1';

  // ═══════════════════════════════════════════════════════════
  // Validation
  // ═══════════════════════════════════════════════════════════
  bool get hasOpenAI => openaiApiKey.isNotEmpty && !openaiApiKey.contains('YOUR_');
  bool get hasGemini => geminiApiKey.isNotEmpty && !geminiApiKey.contains('YOUR_');
  bool get hasClaude => claudeApiKey.isNotEmpty && !claudeApiKey.contains('YOUR_');
  bool get hasDalle => hasOpenAI;
  bool get hasImagen => hasGemini;

  Map<String, bool> get availableProviders => {
    'openai': hasOpenAI,
    'gemini': hasGemini,
    'claude': hasClaude,
    'dalle': hasDalle,
    'imagen': hasImagen,
  };

  void printStatus() {
    print('[AIConfig] Available Providers:');
    availableProviders.forEach((name, available) {
      print('  $name: ${available ? "✅" : "❌"}');
    });
  }
}
