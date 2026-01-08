import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../../../../router/routes.dart';

/// 설정 화면 - shadcn_ui 기반
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shadTheme = ShadTheme.of(context);
    final appTheme = context.appTheme;
    final currentThemeType = ref.watch(appThemeNotifierProvider);

    return Scaffold(
      backgroundColor: appTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('설정', style: TextStyle(color: appTheme.textPrimary)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: appTheme.textPrimary),
          onPressed: () => context.go('/menu'),
        ),
      ),
      body: MysticBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // 테마 설정 섹션
              _buildSectionHeader(context, '화면 설정'),
              const SizedBox(height: 8),
              _buildThemeSelector(context, ref, currentThemeType),
              const SizedBox(height: 24),

              // 계정 설정 섹션
              _buildSectionHeader(context, '계정 설정'),
              const SizedBox(height: 8),
              ShadCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildSettingsTile(
                      context,
                      icon: LucideIcons.user,
                      title: AppStrings.settingsProfile,
                      onTap: () => context.push(Routes.settingsProfile),
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      context,
                      icon: LucideIcons.bell,
                      title: AppStrings.settingsNotification,
                      onTap: () => context.push(Routes.settingsNotification),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 정보 섹션
              _buildSectionHeader(context, '정보'),
              const SizedBox(height: 8),
              ShadCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildSettingsTile(
                      context,
                      icon: LucideIcons.fileText,
                      title: AppStrings.settingsTerms,
                      onTap: () => context.push(Routes.settingsTerms),
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      context,
                      icon: LucideIcons.shield,
                      title: AppStrings.settingsPrivacy,
                      onTap: () => context.push(Routes.settingsPrivacy),
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      context,
                      icon: LucideIcons.info,
                      title: AppStrings.settingsDisclaimer,
                      onTap: () => context.push(Routes.settingsDisclaimer),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 개발자 도구 섹션
              _buildSectionHeader(context, '개발자 도구'),
              const SizedBox(height: 8),
              ShadCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildSettingsTile(
                      context,
                      icon: LucideIcons.play,
                      title: '온보딩 다시 보기',
                      onTap: () => context.go(Routes.onboarding),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final appTheme = context.appTheme;
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: appTheme.textMuted,
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    WidgetRef ref,
    AppThemeType currentThemeType,
  ) {
    return ShadCard(
      title: Row(
        children: [
          Icon(LucideIcons.palette, size: 18),
          const SizedBox(width: 8),
          const Text('테마 선택'),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: AppThemeType.values.map((themeType) {
          final isSelected = themeType == currentThemeType;
          return _buildThemeOption(context, ref, themeType, isSelected);
        }).toList(),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    AppThemeType themeType,
    bool isSelected,
  ) {
    final appTheme = context.appTheme;
    final previewColor = AppTheme.getPreviewColor(themeType);
    final themeName = AppTheme.getThemeName(themeType);
    final themeIcon = AppTheme.getThemeIcon(themeType);

    return GestureDetector(
      onTap: () {
        ref.read(appThemeNotifierProvider.notifier).setTheme(themeType);
      },
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? previewColor.withOpacity(0.15)
              : appTheme.cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? previewColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: previewColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                themeIcon,
                color: appTheme.isDark ? Colors.black : Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              themeName,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? previewColor : appTheme.textMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              Icon(
                Icons.check_circle,
                color: previewColor,
                size: 12,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final appTheme = context.appTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: appTheme.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  color: appTheme.textPrimary,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: appTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
