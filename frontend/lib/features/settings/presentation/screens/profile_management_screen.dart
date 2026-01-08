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
        title: const Text('프로필 관리'),
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
              _buildSectionHeader(context, '계정 정보'),
              const SizedBox(height: 8),
              ShadCard(
                child: Column(
                  children: [
                    _buildInfoRow(context, '이메일', 'user@example.com'),
                    const Divider(height: 24),
                    _buildInfoRow(context, '가입일', '2024년 1월 1일'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 프로필 설정 카드
              _buildSectionHeader(context, '프로필 설정'),
              const SizedBox(height: 8),
              ShadCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildActionRow(
                      context,
                      icon: LucideIcons.user,
                      title: '닉네임 변경',
                      onTap: () => _showEditDialog(context, '닉네임'),
                    ),
                    const Divider(height: 1),
                    _buildActionRow(
                      context,
                      icon: LucideIcons.image,
                      title: '프로필 이미지 변경',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 계정 관리 카드
              _buildSectionHeader(context, '계정 관리'),
              const SizedBox(height: 8),
              ShadCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildActionRow(
                      context,
                      icon: LucideIcons.lock,
                      title: '비밀번호 변경',
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    _buildActionRow(
                      context,
                      icon: LucideIcons.logOut,
                      title: '로그아웃',
                      onTap: () => _showLogoutDialog(context),
                    ),
                    const Divider(height: 1),
                    _buildActionRow(
                      context,
                      icon: LucideIcons.trash2,
                      title: '계정 탈퇴',
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
        title: Text('$field 변경'),
        description: Text('새 $field을 입력해주세요'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ShadButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('저장'),
          ),
        ],
        child: ShadInput(
          controller: controller,
          placeholder: Text('새 $field'),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('로그아웃'),
        description: const Text('로그아웃 하시겠습니까?'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ShadButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showShadDialog(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('계정 탈퇴'),
        description: const Text('정말 탈퇴하시겠습니까?\n모든 데이터가 삭제되며 복구할 수 없습니다.'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.pop(context),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
  }
}
