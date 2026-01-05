import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';

/// 프로필 관리 화면
class ProfileManagementScreen extends ConsumerWidget {
  const ProfileManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: MysticBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, theme),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 계정 정보 카드
                    _buildInfoCard(
                      context,
                      theme,
                      title: '계정 정보',
                      children: [
                        _buildInfoRow(theme, '이메일', 'user@example.com'),
                        const Divider(height: 1),
                        _buildInfoRow(theme, '가입일', '2024년 1월 1일'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 프로필 설정 카드
                    _buildInfoCard(
                      context,
                      theme,
                      title: '프로필 설정',
                      children: [
                        _buildActionRow(
                          theme,
                          icon: Icons.person,
                          title: '닉네임 변경',
                          onTap: () => _showEditDialog(context, '닉네임'),
                        ),
                        const Divider(height: 1),
                        _buildActionRow(
                          theme,
                          icon: Icons.image,
                          title: '프로필 이미지 변경',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 계정 관리 카드
                    _buildInfoCard(
                      context,
                      theme,
                      title: '계정 관리',
                      children: [
                        _buildActionRow(
                          theme,
                          icon: Icons.lock,
                          title: '비밀번호 변경',
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        _buildActionRow(
                          theme,
                          icon: Icons.logout,
                          title: '로그아웃',
                          onTap: () => _showLogoutDialog(context),
                          isDestructive: false,
                        ),
                        const Divider(height: 1),
                        _buildActionRow(
                          theme,
                          icon: Icons.delete_forever,
                          title: '계정 탈퇴',
                          onTap: () => _showDeleteAccountDialog(context),
                          isDestructive: true,
                        ),
                      ],
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

  Widget _buildHeader(BuildContext context, AppThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.15),
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: theme.primaryColor,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          Text(
            '프로필 관리',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    AppThemeExtension theme, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(AppThemeExtension theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: theme.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    AppThemeExtension theme, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red[400] : theme.textPrimary;

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
                style: TextStyle(
                  fontSize: 15,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String field) {
    final theme = context.appTheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          '$field 변경',
          style: TextStyle(color: theme.textPrimary),
        ),
        content: TextField(
          decoration: InputDecoration(
            hintText: '새 $field을 입력하세요',
            hintStyle: TextStyle(color: theme.textMuted),
          ),
          style: TextStyle(color: theme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('저장', style: TextStyle(color: theme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = context.appTheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('로그아웃', style: TextStyle(color: theme.textPrimary)),
        content: Text(
          '로그아웃 하시겠습니까?',
          style: TextStyle(color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('로그아웃', style: TextStyle(color: theme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final theme = context.appTheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          '계정 탈퇴',
          style: TextStyle(color: Colors.red[400]),
        ),
        content: Text(
          '정말 탈퇴하시겠습니까?\n모든 데이터가 삭제되며 복구할 수 없습니다.',
          style: TextStyle(color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('탈퇴', style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );
  }
}
