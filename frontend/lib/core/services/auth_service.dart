import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// 인증 서비스 - Anonymous Sign-In 기반
///
/// 프로덕션 레벨 세션 관리:
/// - 앱 시작 시 기존 세션 확인 → 있으면 재사용
/// - 세션 없을 때만 새 익명 사용자 생성
/// - 세션 만료 시 자동 갱신 (supabase_flutter 기본 동작)
class AuthService {
  final GoTrueClient? _auth;

  AuthService() : _auth = SupabaseService.auth;

  /// Supabase 연결 여부
  bool get isConnected => _auth != null;

  // ============================================================
  // 상태 조회
  // ============================================================

  /// 현재 사용자
  User? get currentUser => _auth?.currentUser;

  /// 현재 사용자 ID
  String? get currentUserId => _auth?.currentUser?.id;

  /// 현재 세션
  Session? get currentSession => _auth?.currentSession;

  /// 로그인 여부
  bool get isLoggedIn => _auth?.currentSession != null;

  /// 익명 사용자 여부
  bool get isAnonymous {
    final user = _auth?.currentUser;
    if (user == null) return true;

    // Supabase User 객체의 isAnonymous 속성 사용
    return user.isAnonymous ?? true;
  }

  /// 영구 사용자 여부 (익명이 아닌 사용자)
  bool get isPermanentUser => !isAnonymous;

  // ============================================================
  // 인증 초기화
  // ============================================================

  /// 앱 시작 시 호출 - 세션 없으면 익명 로그인
  ///
  /// 프로덕션 동작:
  /// 1. localStorage에서 기존 세션 확인 (supabase_flutter가 자동 복원)
  /// 2. 세션 있으면 → 기존 사용자 유지 (새 user 생성 안 함)
  /// 3. 세션 없으면 → 새 익명 사용자 생성
  Future<User?> initializeAuth() async {
    if (_auth == null) {
      if (kDebugMode) {
        print('[AuthService] Supabase not initialized. Using offline mode.');
      }
      return null;
    }

    final session = _auth.currentSession;

    if (session != null) {
      // 기존 세션 존재 → 재사용
      if (kDebugMode) {
        print('[AuthService] 기존 세션 재사용: ${session.user.id}');
        print('[AuthService] 익명 여부: ${session.user.isAnonymous}');
        print('[AuthService] 세션 만료: ${session.expiresAt != null ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000) : "없음"}');
      }
      return _auth.currentUser;
    }

    // 세션 없음 → 새 익명 사용자 생성
    if (kDebugMode) {
      print('[AuthService] 저장된 세션 없음 → 새 익명 사용자 생성');
    }
    return await signInAnonymously();
  }

  /// 익명 로그인
  ///
  /// 새 익명 사용자를 생성하고 세션을 localStorage에 자동 저장
  Future<User?> signInAnonymously() async {
    if (_auth == null) {
      if (kDebugMode) {
        print('[AuthService] Supabase not initialized. Cannot sign in.');
      }
      return null;
    }

    try {
      final response = await _auth.signInAnonymously();
      if (kDebugMode) {
        print('[AuthService] 새 익명 사용자 생성됨: ${response.user?.id}');
      }
      return response.user;
    } catch (e) {
      if (kDebugMode) {
        print('[AuthService] 익명 로그인 실패: $e');
      }
      rethrow;
    }
  }

  // ============================================================
  // 익명 → 영구 계정 전환
  // ============================================================

  /// 이메일로 영구 계정 전환 (Step 1: 이메일 연결)
  /// 인증 메일이 발송됩니다.
  Future<void> linkEmail(String email) async {
    if (_auth == null) throw Exception('Supabase not initialized');
    await _auth.updateUser(
      UserAttributes(email: email),
    );
  }

  /// 이메일 인증 완료 후 비밀번호 설정 (Step 2)
  Future<void> setPassword(String password) async {
    if (_auth == null) throw Exception('Supabase not initialized');
    await _auth.updateUser(
      UserAttributes(password: password),
    );
  }

  /// 이메일 + 비밀번호로 한 번에 전환 (이메일 인증 필요)
  Future<void> convertToEmailUser({
    required String email,
    required String password,
  }) async {
    // 1. 이메일 연결 (인증 메일 발송)
    await linkEmail(email);
    // 2. 비밀번호 설정은 이메일 인증 후 별도 호출 필요
  }

  /// OAuth로 영구 계정 전환 (Google, Apple, Kakao 등)
  Future<void> linkOAuth(OAuthProvider provider) async {
    if (_auth == null) throw Exception('Supabase not initialized');
    await _auth.linkIdentity(provider);
  }

  /// Google 계정으로 전환
  Future<void> convertToGoogle() => linkOAuth(OAuthProvider.google);

  /// Apple 계정으로 전환
  Future<void> convertToApple() => linkOAuth(OAuthProvider.apple);

  /// Kakao 계정으로 전환
  Future<void> convertToKakao() => linkOAuth(OAuthProvider.kakao);

  // ============================================================
  // 일반 로그인 (영구 사용자용)
  // ============================================================

  /// 이메일/비밀번호 로그인
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_auth == null) throw Exception('Supabase not initialized');
    return await _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// OAuth 로그인
  Future<void> signInWithOAuth(OAuthProvider provider) async {
    if (_auth == null) throw Exception('Supabase not initialized');
    await _auth.signInWithOAuth(provider);
  }

  // ============================================================
  // 로그아웃
  // ============================================================

  /// 로그아웃
  Future<void> signOut() async {
    if (_auth == null) return;
    await _auth.signOut();
  }

  /// 로그아웃 후 익명 로그인 (데이터 초기화 효과)
  Future<User?> signOutAndSignInAnonymously() async {
    await signOut();
    return await signInAnonymously();
  }

  // ============================================================
  // 인증 상태 스트림
  // ============================================================

  /// 인증 상태 변경 스트림
  Stream<AuthState>? get onAuthStateChange => _auth?.onAuthStateChange;
}
