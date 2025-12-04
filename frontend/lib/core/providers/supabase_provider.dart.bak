import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_provider.g.dart';

/// Supabase Client Provider
/// keepAlive: true - 앱 생명주기 동안 유지
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(SupabaseClientRef ref) {
  return Supabase.instance.client;
}

/// Supabase Auth Provider
@Riverpod(keepAlive: true)
GoTrueClient supabaseAuth(SupabaseAuthRef ref) {
  return ref.watch(supabaseClientProvider).auth;
}

/// Auth State Stream Provider
@riverpod
Stream<AuthState> authState(AuthStateRef ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
}

/// Current User Provider
/// 
/// 
@riverpod
User? currentUser(CurrentUserRef ref) {
  // auth 상태 변경 감지
  ref.watch(authStateProvider);
  return ref.watch(supabaseClientProvider).auth.currentUser;
}

/// Is Logged In Provider
@riverpod
bool isLoggedIn(IsLoggedInRef ref) {
  return ref.watch(currentUserProvider) != null;
}
