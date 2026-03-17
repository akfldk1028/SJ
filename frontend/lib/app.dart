import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'AI/fortune/common/korea_date_utils.dart';
import 'router/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'features/menu/presentation/providers/daily_fortune_provider.dart';
import 'purchase/providers/purchase_provider.dart';

/// 사담 앱 루트 위젯
class MantokApp extends ConsumerStatefulWidget {
  const MantokApp({super.key});

  @override
  ConsumerState<MantokApp> createState() => _MantokAppState();
}

class _MantokAppState extends ConsumerState<MantokApp> with WidgetsBindingObserver {
  bool _routerListenerAdded = false;
  /// 마지막으로 확인한 한국 날짜 (앱 resume 시 날짜 변경 감지용)
  DateTime _lastKnownDate = KoreaDateUtils.today;

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
      // 앱 재진입 시 구매 상태 갱신
      ref.read(purchaseNotifierProvider.notifier).refresh();
      // 날짜 변경 감지 → 일운 자동 갱신
      _checkDateChange();
    }
  }

  /// 한국 날짜가 바뀌었으면 dailyFortune 갱신
  void _checkDateChange() {
    final currentDate = KoreaDateUtils.today;
    if (currentDate != _lastKnownDate) {
      print('[MantokApp] 📅 날짜 변경 감지: $_lastKnownDate → $currentDate');
      _lastKnownDate = currentDate;
      ref.invalidate(dailyFortuneProvider);
      ref.invalidate(dailyFortuneDatesProvider);
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
      title: 'common.appName'.tr(),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: shadThemeData,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      materialThemeBuilder: (context, theme) {
        return currentTheme;
      },
    );
  }
}
