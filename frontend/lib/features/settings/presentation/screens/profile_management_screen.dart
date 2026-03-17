import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// 프로필 관리 화면 - shadcn_ui 기반
class ProfileManagementScreen extends ConsumerWidget {
  const ProfileManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('settings.profile'.tr()),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 계정 정보 카드
              _buildSectionHeader(context, 'settings.accountInfo'.tr()),
              const SizedBox(height: 8),
              ShadCard(
                child: Column(
                  children: [
                    _buildInfoRow(context, 'settings.email'.tr(), 'user@example.com'),
                    const Divider(height: 24),
                    _buildInfoRow(context, 'settings.joinDate'.tr(), '2024년 1월 1일'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 프로필 설정 카드
              _buildSectionHeader(context, 'settings.profileSettings'.tr()),
              const SizedBox(height: 8),
              ShadCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildActionRow(
                      context,
                      icon: LucideIcons.user,
                      title: 'settings.changeNickname'.tr(),
                      onTap: () => _showEditDialog(context, 'settings.nickname'.tr()),
                    ),
                    const Divider(height: 1),
                    _buildActionRow(
                      context,
                      icon: LucideIcons.image,
                      title: 'settings.changeProfileImage'.tr(),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 계정 관리 카드
              _buildSectionHeader(context, 'settings.accountManagement'.tr()),
              const SizedBox(height: 8),
              ShadCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildActionRow(
                      context,
                      icon: LucideIcons.lock,
                      title: 'settings.changePassword'.tr(),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    _buildActionRow(
                      context,
                      icon: LucideIcons.logOut,
                      title: 'settings.logout'.tr(),
                      onTap: () => _showLogoutDialog(context),
                    ),
                    const Divider(height: 1),
                    _buildActionRow(
                      context,
                      icon: LucideIcons.trash2,
                      title: 'settings.deleteAccount'.tr(),
                      onTap: () => _showDeleteAccountDialog(context),
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = ShadTheme.of(context);
    return Text(
      title,
      style: theme.textTheme.small.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.mutedForeground,
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = ShadTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.p.copyWith(
            color: theme.colorScheme.mutedForeground,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.p.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = ShadTheme.of(context);
    final color = isDestructive
        ? theme.colorScheme.destructive
        : theme.colorScheme.foreground;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.p.copyWith(color: color),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: theme.colorScheme.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String field) {
    final controller = TextEditingController();

    showShadDialog(
      context: context,
      builder: (context) => ShadDialog(
        title: Text('settings.changeField'.tr(namedArgs: {'field': field})),
        description: Text('settings.enterNewField'.tr(namedArgs: {'field': field})),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context),
            child: Text('common.buttonCancel'.tr()),
          ),
          ShadButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.save'.tr()),
          ),
        ],
        child: ShadInput(
          controller: controller,
          placeholder: Text('settings.newField'.tr(namedArgs: {'field': field})),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: Text('settings.logout'.tr()),
        description: Text('settings.logoutConfirm'.tr()),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context),
            child: Text('common.buttonCancel'.tr()),
          ),
          ShadButton(
            onPressed: () => Navigator.pop(context),
            child: Text('settings.logout'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: Text('settings.deleteAccount'.tr()),
        description: Text('settings.deleteAccountConfirm'.tr()),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context),
            child: Text('common.buttonCancel'.tr()),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.pop(context),
            child: Text('settings.withdraw'.tr()),
          ),
        ],
      ),
    );
  }
}
