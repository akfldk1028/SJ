import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 클라이언트 싱글톤 서비스
///
/// 프로덕션 레벨 세션 관리:
/// - localStorage에 세션 자동 저장 (supabase_flutter 기본 동작)
/// - 앱 재시작 시 기존 세션 자동 복원
/// - 세션 만료 시 자동 갱신
class SupabaseService {
  static SupabaseClient? _client;

  /// Supabase 초기화
  ///
  /// authFlowType: pkce (Proof Key for Code Exchange) - 보안 강화
  /// persistSession: true - 세션을 localStorage에 저장
  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || anonKey == null) {
      throw Exception(
        'SUPABASE_URL 또는 SUPABASE_ANON_KEY가 .env 파일에 없습니다.',
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: kDebugMode, // 디버그 모드에서만 로그 출력
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce, // 보안 강화된 OAuth 흐름
      ),
    );

    _client = Supabase.instance.client;

    if (kDebugMode) {
      final session = _client?.auth.currentSession;
      if (session != null) {
        print('[SupabaseService] 기존 세션 복원됨: ${session.user.id}');
        print('[SupabaseService] 익명 사용자: ${session.user.isAnonymous}');
      } else {
        print('[SupabaseService] 저장된 세션 없음 - 새 세션 필요');
      }
    }
  }

  /// Supabase 클라이언트 접근
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase가 초기화되지 않았습니다. initialize()를 먼저 호출하세요.');
    }
    return _client!;
  }

  /// Auth 클라이언트 접근
  static GoTrueClient get auth => client.auth;
}
