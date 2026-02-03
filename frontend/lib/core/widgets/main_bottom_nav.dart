import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../AI/services/saju_analysis_service.dart';
import '../services/error_logging_service.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../theme/app_theme.dart';

/// 메인 하단 네비게이션 바 - 공유 위젯
class MainBottomNav extends ConsumerWidget {
  final int currentIndex;

  const MainBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.isDark
                ? const Color.fromRGBO(0, 0, 0, 0.3)
                : const Color.fromRGBO(0, 0, 0, 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, ref, theme, Icons.auto_awesome_rounded, '운세', 0, '/menu'),
          _buildNavItem(context, ref, theme, Icons.people_outline_rounded, '인맥', 1, '/relationships'),
          _buildNavItem(context, ref, theme, Icons.forum_rounded, 'AI 상담', 2, '/saju/chat'),
          _buildNavItem(context, ref, theme, Icons.calendar_month_rounded, '캘린더', 3, '/calendar'),
          _buildNavItem(context, ref, theme, Icons.settings_outlined, '설정', 4, '/settings'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, WidgetRef ref, AppThemeExtension theme, IconData icon, String label, int index, String route) {
    final isActive = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isActive) {
            // v30: AI 상담 또는 운세 탭 → saju_base lazy trigger
            if (index == 0 || index == 2) {
              _triggerSajuBaseIfNeeded(ref);
            }
            context.go(route);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? theme.primaryColor : theme.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? theme.primaryColor : theme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// v30: saju_base lazy trigger (fire-and-forget)
  void _triggerSajuBaseIfNeeded(WidgetRef ref) {
    ref.read(activeProfileProvider.future).then((profile) {
      if (profile == null) return;
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      SajuAnalysisService().analyzeOnProfileSave(
        userId: user.id,
        profileId: profile.id,
        runInBackground: true,
      );
    }).catchError((e) {
      ErrorLoggingService.logError(
        operation: 'main_bottom_nav._triggerSajuBaseIfNeeded',
        errorMessage: e.toString(),
        errorType: 'saju_base_trigger',
        sourceFile: 'core/widgets/main_bottom_nav.dart',
      );
    });
  }
}
