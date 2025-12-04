import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../router/routes.dart';
import '../widgets/legal_notice_dialog.dart';

/// 설정 화면
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSection(
            context,
            title: '계정',
            children: [
              _SettingsTile(
                icon: Icons.person_outline,
                title: AppStrings.settingsProfile,
                onTap: () => context.push(Routes.profileEdit),
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: AppStrings.settingsNotification,
                trailing: ShadSwitch(
                  value: true,
                  onChanged: (value) {
                    // TODO: 알림 설정 토글
                  },
                ),
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: '정보',
            children: [
              _SettingsTile(
                icon: Icons.description_outlined,
                title: AppStrings.settingsTerms,
                onTap: () => LegalNoticeDialog.show(context, LegalNoticeType.terms),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: AppStrings.settingsPrivacy,
                onTap: () => LegalNoticeDialog.show(context, LegalNoticeType.privacy),
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                title: AppStrings.settingsDisclaimer,
                onTap: () => LegalNoticeDialog.show(context, LegalNoticeType.disclaimer),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            title: '앱 정보',
            children: [
              _SettingsTile(
                icon: Icons.code,
                title: '버전',
                trailing: Text(
                  '1.0.0',
                  style: theme.textTheme.muted,
                ),
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppStrings.disclaimer,
              style: theme.textTheme.muted.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ShadCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: theme.colorScheme.foreground,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.p,
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.mutedForeground,
              ),
          ],
        ),
      ),
    );
  }
}
