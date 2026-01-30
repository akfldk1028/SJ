import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'router/app_router.dart';
import 'core/theme/theme_provider.dart';

/// 사담 앱 루트 위젯
class MantokApp extends ConsumerStatefulWidget {
  const MantokApp({super.key});

  @override
  ConsumerState<MantokApp> createState() => _MantokAppState();
}

class _MantokAppState extends ConsumerState<MantokApp> with WidgetsBindingObserver {
  bool _routerListenerAdded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 초기 상태바 스타일 적용
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applySystemUiStyle();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applySystemUiStyle();
    }
  }

  void _applySystemUiStyle() {
    // Manual 모드: 상태바만 표시, 하단 네비게이션 바 숨김
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final currentTheme = ref.watch(currentThemeDataProvider);
    final themeExt = ref.watch(currentThemeExtensionProvider);

    // 라우터 리스너 추가 (한 번만)
    if (!_routerListenerAdded) {
      _routerListenerAdded = true;
      router.routerDelegate.addListener(() {
        // 라우트 변경 시 상태바 스타일 재적용
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _applySystemUiStyle();
        });
      });
    }

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
