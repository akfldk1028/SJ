import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/services/supabase_service.dart';
import 'core/services/auth_service.dart';
import 'features/profile/data/datasources/profile_local_datasource.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
// import 'test_edge_function.dart'; // 테스트 완료 후 주석 처리

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경변수 로드
  await dotenv.load(fileName: '.env');

  // Hive 초기화
  await Hive.initFlutter();

  // Hive 박스 열기 (앱 시작 전에 모두 열어야 함)
  await Hive.openBox<Map<dynamic, dynamic>>('saju_profiles');  // 프로필 (가장 중요!)
  await Hive.openBox('chat_sessions');
  await Hive.openBox('chat_messages');

  // Supabase 초기화 (세션 자동 복원)
  await SupabaseService.initialize();

  // 인증 초기화 (기존 세션 있으면 재사용, 없으면 익명 로그인)
  final authService = AuthService();
  await authService.initializeAuth();

  // 클라우드 동기화 (앱 시작 시 Cloud → Local)
  await _syncProfilesFromCloud();

  // Edge Function 테스트 (필요시 주석 해제)
  // if (kDebugMode) {
  //   await testEdgeFunction();
  // }

  runApp(
    const ProviderScope(
      child: MantokApp(),
    ),
  );
}

/// 앱 시작 시 클라우드에서 프로필 동기화
Future<void> _syncProfilesFromCloud() async {
  try {
    final datasource = ProfileLocalDatasource();
    final repository = ProfileRepositoryImpl(datasource);
    await repository.syncFromCloud();
    if (kDebugMode) {
      print('[Main] 프로필 동기화 완료');
    }
  } catch (e) {
    if (kDebugMode) {
      print('[Main] 프로필 동기화 실패 (앱은 계속 실행): $e');
    }
  }
}
