import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

/// 만톡 앱 루트 위젯
class MantokApp extends ConsumerWidget {
  const MantokApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final currentTheme = ref.watch(currentThemeDataProvider);
    final themeExt = ref.watch(currentThemeExtensionProvider);

    return ShadApp(
      debugShowCheckedModeBanner: false,
      materialThemeBuilder: (context, theme) {
        return ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: themeExt.primaryColor,
            brightness: themeExt.isDark ? Brightness.dark : Brightness.light,
          ),
          useMaterial3: true,
        );
      },
      home: MaterialApp.router(
        title: '만톡',
        debugShowCheckedModeBanner: false,
        theme: currentTheme,
        routerConfig: router,
      ),
    );
  }
}
