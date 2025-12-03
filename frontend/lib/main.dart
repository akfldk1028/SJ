import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';

/// 앱 진입점
/// - 환경변수 로드 (.env)
/// - Supabase 초기화
/// - ProviderScope로 Riverpod 상태 관리 래핑
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경변수 로드
  await dotenv.load(fileName: '.env');

  // Supabase 초기화
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(
    const ProviderScope(
      child: MantokApp(),
    ),
  );
}

/// 만톡 앱 루트 위젯
class MantokApp extends ConsumerWidget {
  const MantokApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return ShadcnApp.router(
      title: '만톡',
      debugShowCheckedModeBanner: false,

      // Shadcn 테마 설정
      theme: ThemeData(
        colorScheme: ColorSchemes.darkDefaultColor,
        radius: 0.5,
        scaling: 1.0,
      ),

      // 라우터 설정
      routerConfig: router,
    );
  }
}
