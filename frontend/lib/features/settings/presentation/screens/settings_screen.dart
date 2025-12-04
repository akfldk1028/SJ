import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';

/// 설정 화면
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final currentThemeType = ref.watch(appThemeNotifierProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        title: Text(
          AppStrings.settingsTitle,
          style: TextStyle(color: theme.textPrimary),
        ),
        iconTheme: IconThemeData(color: theme.textPrimary),
      ),
      body: ListView(
        children: [
          // 테마 설정 섹션
          _buildSectionHeader(context, '화면 설정'),
          _buildThemeSelector(context, ref, currentThemeType),
          const SizedBox(height: 16),

          // 계정 설정 섹션
          _buildSectionHeader(context, '계정 설정'),
          _buildSettingsTile(
            context,
            icon: Icons.person,
            title: AppStrings.settingsProfile,
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.notifications,
            title: AppStrings.settingsNotification,
            onTap: () {},
          ),

          const SizedBox(height: 16),

          // 정보 섹션
          _buildSectionHeader(context, '정보'),
          _buildSettingsTile(
            context,
            icon: Icons.description,
            title: AppStrings.settingsTerms,
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip,
            title: AppStrings.settingsPrivacy,
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.info,
            title: AppStrings.settingsDisclaimer,
            onTap: () {},
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = context.appTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    WidgetRef ref,
    AppThemeType currentThemeType,
  ) {
    final theme = context.appTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(
                  Icons.palette_rounded,
                  color: theme.primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  '테마 선택',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppThemeType.values.map((themeType) {
                final isSelected = themeType == currentThemeType;
                return _buildThemeOption(
                  context,
                  ref,
                  themeType,
                  isSelected,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    AppThemeType themeType,
    bool isSelected,
  ) {
    final theme = context.appTheme;
    final previewColor = AppTheme.getPreviewColor(themeType);
    final themeName = AppTheme.getThemeName(themeType);
    final themeIcon = AppTheme.getThemeIcon(themeType);

    return GestureDetector(
      onTap: () {
        ref.read(appThemeNotifierProvider.notifier).setTheme(themeType);
      },
      child: Container(
        width: 95,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? previewColor.withOpacity(0.15)
              : theme.isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.05),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: previewColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                themeIcon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              themeName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? previewColor : theme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(
                Icons.check_circle_rounded,
                color: previewColor,
                size: 16,
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
    final theme = context.appTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.textSecondary),
        title: Text(
          title,
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.textMuted,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
