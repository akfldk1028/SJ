/// 파일 로거 스텁 (비웹 플랫폼용)
///
/// 웹이 아닌 플랫폼에서는 아무 동작도 하지 않습니다.

/// 파일 로거 (스텁 - 비웹 플랫폼)
class FileLogger {
  static void init() {}
  static void log(String content) {}
  static void logAiApi({
    required String provider,
    required String model,
    required String type,
    required bool success,
    String? requestSummary,
    String? response,
    Map<String, dynamic>? tokens,
    double? costUsd,
    int? processingTimeMs,
    String? error,
  }) {}
  static void restoreFromLocalStorage() {}
  static void downloadLog() {}
  static String getLogContent() => '';
  static void clear() {}
  static void printAllLogs() {}
}
