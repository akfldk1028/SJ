import 'package:flutter/foundation.dart';

/// AI 로깅 유틸리티
class AILogger {
  static bool enabled = kDebugMode;

  static void log(String provider, String message) {
    if (!enabled) return;
    print('[$provider] $message');
  }

  static void request(String provider, String endpoint) {
    log(provider, '→ Request: $endpoint');
  }

  static void response(String provider, {int? tokens, Duration? duration}) {
    final parts = <String>['← Response'];
    if (tokens != null) parts.add('$tokens tokens');
    if (duration != null) parts.add('${duration.inMilliseconds}ms');
    log(provider, parts.join(' | '));
  }

  static void error(String provider, dynamic error) {
    log(provider, '✗ Error: $error');
  }

  static void pipeline(String phase, String message) {
    print('[Pipeline:$phase] $message');
  }
}
