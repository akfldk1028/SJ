import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경변수 로드
  await dotenv.load(fileName: '.env');

  // Hive 초기화
  await Hive.initFlutter();

  // Hive 박스 열기 (채팅 세션용)
  await Hive.openBox('chat_sessions');
  await Hive.openBox('chat_messages');
  await Hive.openBox('saju_analyses'); // 사주 분석 결과 캐시

  // Supabase 초기화 (오프라인 모드 지원)
  await SupabaseService.initialize();

  runApp(
    const ProviderScope(
      child: MantokApp(),
    ),
  );
}
