import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 서비스
///
/// 앱 전역에서 Supabase 클라이언트에 접근하기 위한 서비스 클래스
/// main.dart에서 초기화 후 사용
class SupabaseService {
  static SupabaseClient? _client;

  /// Supabase 초기화
  ///
  /// main.dart에서 앱 시작 시 호출
  /// .env 파일에서 SUPABASE_URL, SUPABASE_ANON_KEY 로드
  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    // 개발 환경에서 placeholder 값 체크
    if (url == null ||
        url.isEmpty ||
        url == 'https://your-project.sql.co') {
      _logWarning('SUPABASE_URL not configured. Using offline mode.');
      return;
    }

    if (anonKey == null || anonKey.isEmpty || anonKey == 'your-anon-key') {
      _logWarning('SUPABASE_ANON_KEY not configured. Using offline mode.');
      return;
    }

    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: false, // 프로덕션에서는 false
      );
      _client = Supabase.instance.client;
      _logInfo('Supabase initialized successfully');
    } catch (e) {
      _logWarning('Failed to initialize Supabase: $e. Using offline mode.');
    }
  }

  /// Supabase 클라이언트
  ///
  /// null이면 오프라인 모드
  static SupabaseClient? get client => _client;

  /// GoTrueClient (인증 클라이언트)
  ///
  /// null이면 오프라인 모드
  static GoTrueClient? get auth => _client?.auth;

  /// Supabase 연결 여부
  static bool get isConnected => _client != null;

  /// Supabase URL (Edge Function 호출용)
  static String? get supabaseUrl => dotenv.env['SUPABASE_URL'];

  /// Supabase Anon Key (Edge Function Authorization용)
  static String? get anonKey => dotenv.env['SUPABASE_ANON_KEY'];

  /// 현재 인증된 사용자
  static User? get currentUser => _client?.auth.currentUser;

  /// 로그인 여부
  static bool get isLoggedIn => currentUser != null;

  /// 익명 사용자 여부
  static bool get isAnonymous => currentUser?.isAnonymous ?? false;

  /// 익명 로그인
  ///
  /// 로그인되지 않은 경우 익명 사용자로 자동 로그인
  /// 이미 로그인된 경우 아무 작업 안함
  static Future<User?> ensureAuthenticated() async {
    if (_client == null) {
      _logWarning('Supabase not initialized. Cannot authenticate.');
      return null;
    }

    // 이미 로그인된 경우
    if (currentUser != null) {
      _logInfo('User already authenticated: ${currentUser!.id}');
      return currentUser;
    }

    // 익명 로그인 시도
    try {
      final response = await _client!.auth.signInAnonymously();
      _logInfo('Anonymous sign-in successful: ${response.user?.id}');
      return response.user;
    } catch (e) {
      _logWarning('Anonymous sign-in failed: $e');
      return null;
    }
  }

  /// 현재 사용자 ID (없으면 null)
  static String? get currentUserId => currentUser?.id;

  /// saju_analyses 테이블 쿼리 빌더
  static SupabaseQueryBuilder? get sajuAnalysesTable {
    return _client?.from('saju_analyses');
  }

  /// saju_profiles 테이블 쿼리 빌더
  static SupabaseQueryBuilder? get sajuProfilesTable {
    return _client?.from('saju_profiles');
  }

  /// chat_sessions 테이블 쿼리 빌더
  static SupabaseQueryBuilder? get chatSessionsTable {
    return _client?.from('chat_sessions');
  }

  /// chat_messages 테이블 쿼리 빌더
  static SupabaseQueryBuilder? get chatMessagesTable {
    return _client?.from('chat_messages');
  }

  // 간단한 로깅 (실제로는 logger 패키지 사용 권장)
  static void _logInfo(String message) {
    // ignore: avoid_print
    print('[Supabase] $message');
  }

  static void _logWarning(String message) {
    // ignore: avoid_print
    print('[Supabase] WARNING: $message');
  }
}
