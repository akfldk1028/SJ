import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'router/app_router.dart';

/// 만톡 앱 루트 위젯
class MantokApp extends ConsumerWidget {
  const MantokApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return ShadApp.router(
      title: '만톡',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadSlateColorScheme.light(),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(),
      ),
      routerConfig: router,
    );
  }
}
