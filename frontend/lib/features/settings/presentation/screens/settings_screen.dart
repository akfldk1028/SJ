import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../../../../purchase/providers/purchase_provider.dart';
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // 테마 설정 섹션
              _buildSectionHeader(context, '화면 설정'),
              const SizedBox(height: 8),
              _buildThemeSelector(context, ref, currentThemeType),
              const SizedBox(height: 24),

              // TODO: 배포 시 계정 설정 섹션 제거 (프로필관리, 알림설정)
              // // 계정 설정 섹션
              // _buildSectionHeader(context, '계정 설정'),
              // const SizedBox(height: 8),
              // ShadCard(
              //   padding: EdgeInsets.zero,
              //   child: Column(
              //     children: [
              //       _buildSettingsTile(
              //         context,
              //         icon: LucideIcons.user,
              //         title: AppStrings.settingsProfile,
              //         onTap: () => context.push(Routes.settingsProfile),
              //       ),
              //       const Divider(height: 1),
              //       _buildSettingsTile(
              //         context,
              //         icon: LucideIcons.bell,
              //         title: AppStrings.settingsNotification,
              //         onTap: () => context.push(Routes.settingsNotification),
              //       ),
              //     ],
              //   ),
              // ),

              // 구독 관리 섹션
              _buildSectionHeader(context, '구독 관리'),
              const SizedBox(height: 8),
              _buildPremiumTile(context, ref),
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
              const SizedBox(height: 32),

              // TODO: 배포 시 개발자 도구 섹션 제거
              // // 개발자 도구 섹션
              // _buildSectionHeader(context, '개발자 도구'),
              // const SizedBox(height: 8),
              // ShadCard(
              //   padding: EdgeInsets.zero,
              //   child: Column(
              //     children: [
              //       _buildSettingsTile(
              //         context,
              //         icon: LucideIcons.play,
              //         title: '온보딩 다시 보기',
              //         onTap: () => context.go(Routes.onboarding),
              //       ),
              //       const Divider(height: 1),
              //       _buildSettingsTile(
              //         context,
              //         icon: LucideIcons.palette,
              //         title: '앱 아이콘 생성기',
              //         onTap: () => context.push(Routes.iconGenerator),
              //       ),
              //     ],
              //   ),
              // ),
                  ],
                ),
              ),
            );
          },
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
        children: [
          // 활성화된 테마만 표시
          AppThemeType.streetLamp,
          AppThemeType.streetLampLight,
          AppThemeType.orientalLight, // 레드 라이트
          AppThemeType.darkPurple,
          // 비활성화된 테마 (주석처리)
          // AppThemeType.orientalDark,
          // AppThemeType.defaultLight,
          // AppThemeType.orientalRed,
          // AppThemeType.natureGreen,
          // AppThemeType.nightSky,
          // AppThemeType.sakuraPink,
        ].map((themeType) {
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
    final themeExtension = AppTheme.getExtension(themeType);

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
                color: themeExtension.isDark
                    ? themeExtension.cardColor
                    : themeExtension.backgroundColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: previewColor.withOpacity(0.6),
                  width: 1.5,
                ),
              ),
              child: Icon(
                themeIcon,
                color: previewColor,
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

  Widget _buildPremiumTile(BuildContext context, WidgetRef ref) {
    final appTheme = context.appTheme;
    ref.watch(purchaseNotifierProvider); // 상태 변경 감지용
    final isPremium = ref.read(purchaseNotifierProvider.notifier).isPremium;

    return ShadCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push(Routes.settingsPremium),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(LucideIcons.sparkles, size: 20, color: isPremium ? Colors.amber : appTheme.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '프리미엄 이용권',
                  style: TextStyle(
                    fontSize: 15,
                    color: appTheme.textPrimary,
                  ),
                ),
              ),
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '이용중',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber,
                    ),
                  ),
                )
              else
                Text(
                  '구매하기',
                  style: TextStyle(
                    fontSize: 13,
                    color: appTheme.textMuted,
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: appTheme.textMuted,
              ),
            ],
          ),
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
