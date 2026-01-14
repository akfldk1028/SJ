import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'router/app_router.dart';
import 'core/theme/theme_provider.dart';

/// 사담 앱 루트 위젯
class MantokApp extends ConsumerWidget {
  const MantokApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final currentTheme = ref.watch(currentThemeDataProvider);
    final themeExt = ref.watch(currentThemeExtensionProvider);

    // shadcn_ui 테마 데이터 생성
    final shadThemeData = themeExt.isDark
        ? ShadThemeData(
            brightness: Brightness.dark,
            colorScheme: ShadColorScheme.fromName(
              'slate',
              brightness: Brightness.dark,
            ).copyWith(
              background: themeExt.backgroundColor,
              foreground: themeExt.textPrimary,
              card: themeExt.cardColor,
              cardForeground: themeExt.textPrimary,
              primary: themeExt.primaryColor,
              primaryForeground: Colors.black,
              muted: themeExt.cardColor,
              mutedForeground: themeExt.textMuted,
              border: themeExt.textMuted.withOpacity(0.2),
              input: themeExt.textMuted.withOpacity(0.2),
            ),
          )
        : ShadThemeData(
            brightness: Brightness.light,
            colorScheme: ShadColorScheme.fromName(
              'slate',
              brightness: Brightness.light,
            ).copyWith(
              background: themeExt.backgroundColor,
              foreground: themeExt.textPrimary,
              card: themeExt.cardColor,
              cardForeground: themeExt.textPrimary,
              primary: themeExt.primaryColor,
              primaryForeground: Colors.white,
              muted: themeExt.cardColor,
              mutedForeground: themeExt.textMuted,
              border: themeExt.textMuted.withOpacity(0.2),
              input: themeExt.textMuted.withOpacity(0.2),
            ),
          );

    return ShadApp.router(
      title: '사담',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: shadThemeData,
      materialThemeBuilder: (context, theme) {
        return currentTheme;
      },
    );
  }
}
