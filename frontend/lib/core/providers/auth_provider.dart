import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

part 'auth_provider.g.dart';

/// AuthService Provider
@riverpod
AuthService authService(ref) {
  return AuthService();
}

/// 현재 사용자 Provider
@riverpod
User? currentUser(ref) {
  return SupabaseService.auth?.currentUser;
}

/// 현재 사용자 ID Provider
@riverpod
String? currentUserId(ref) {
  return SupabaseService.auth?.currentUser?.id;
}

/// 익명 사용자 여부 Provider
@riverpod
bool isAnonymous(ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isAnonymous;
}

/// 로그인 여부 Provider
@riverpod
bool isLoggedIn(ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isLoggedIn;
}

/// 인증 상태 스트림 Provider
@riverpod
Stream<AuthState>? authStateChanges(ref) {
  return SupabaseService.auth?.onAuthStateChange;
}
