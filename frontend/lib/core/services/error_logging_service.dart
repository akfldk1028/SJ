import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 에러 로깅 서비스
///
/// chat_error_logs 테이블에 에러를 기록하여
/// 프로덕션 환경에서 에러 추적 가능하게 함.
class ErrorLoggingService {
  /// 에러를 Supabase chat_error_logs 테이블에 기록
  ///
  /// 에러 로깅 자체의 실패는 무시 (무한 루프 방지)
  static Future<void> logError({
    required String operation,
    required String errorMessage,
    String? errorType,
    String? errorCode,
    String? userMessage,
    String? sessionId,
    String? sourceFile,
    int? sourceLine,
    String? stackTrace,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('chat_error_logs').insert({
        'user_id': user.id,
        'session_id': sessionId,
        'error_type': errorType ?? _classifyError(errorMessage),
        'error_code': errorCode,
        'error_message': errorMessage.length > 2000
            ? errorMessage.substring(0, 2000)
            : errorMessage,
        'user_message': userMessage,
        'operation': operation,
        'source_file': sourceFile,
        'source_line': sourceLine,
        'stack_trace': stackTrace != null && stackTrace.length > 5000
            ? stackTrace.substring(0, 5000)
            : stackTrace,
        'device_info': {
          'platform': Platform.operatingSystem,
        },
        'extra_data': extraData,
      });

      if (kDebugMode) {
        print('[ErrorLoggingService] Error logged: $operation - ${errorType ?? _classifyError(errorMessage)}');
      }
    } catch (_) {
      // 에러 로깅 실패는 무시 (무한 루프 방지)
    }
  }

  /// 에러 메시지 기반 자동 분류
  static String _classifyError(String msg) {
    if (msg.contains('QUOTA_EXCEEDED')) return 'quota';
    if (msg.contains('AUTH_EXPIRED')) return 'auth';
    if (msg.contains('SSE') || msg.contains('네트워크')) return 'network';
    if (msg.contains('timeout') || msg.contains('Timeout')) return 'timeout';
    return 'unknown';
  }
}
