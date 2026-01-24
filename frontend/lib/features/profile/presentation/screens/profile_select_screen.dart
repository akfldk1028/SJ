import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../router/routes.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../../domain/entities/saju_profile.dart';
import '../providers/profile_provider.dart';

/// 프로필 선택 화면
///
/// 등록된 프로필 목록에서 활성 프로필을 선택
/// 위젯 트리 최적화:
/// - const 생성자 사용
/// - 100줄 이하 위젯으로 분리
class ProfileSelectScreen extends ConsumerWidget {
  const ProfileSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final profileListAsync = ref.watch(profileListProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: MysticBackground(
        child: SafeArea(
          child: Column(
            children: [
              _AppBar(theme: theme),
              Expanded(
                child: profileListAsync.when(
                  data: (profiles) => profiles.isEmpty
                      ? _EmptyState(theme: theme)
                      : _ProfileList(profiles: profiles, theme: theme),
                  loading: () => Center(
                    child: CircularProgressIndicator(color: theme.primaryColor),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      '프로필 로딩 실패: $e',
                      style: TextStyle(color: theme.textMuted),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.profileEdit),
        backgroundColor: theme.primaryColor,
        child: Icon(Icons.add, color: theme.textPrimary),
      ),
    );
  }
}

/// 앱바 위젯
class _AppBar extends StatelessWidget {
  final AppThemeExtension theme;

  const _AppBar({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_ios, color: theme.textMuted),
          ),
          Expanded(
            child: Text(
              '프로필 선택',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 빈 상태 위젯
class _EmptyState extends StatelessWidget {
  final AppThemeExtension theme;

  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_add_outlined,
            size: 64,
            color: theme.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            '등록된 프로필이 없습니다',
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+ 버튼을 눌러 프로필을 추가하세요',
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// 프로필 목록 위젯
class _ProfileList extends StatelessWidget {
  final List<SajuProfile> profiles;
  final AppThemeExtension theme;

  const _ProfileList({required this.profiles, required this.theme});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: profiles.length,
      itemBuilder: (context, index) => _ProfileCard(
        profile: profiles[index],
        isLast: index == profiles.length - 1,
        theme: theme,
      ),
    );
  }
}

/// 프로필 카드 위젯
class _ProfileCard extends ConsumerWidget {
  final SajuProfile profile;
  final bool isLast;
  final AppThemeExtension theme;

  const _ProfileCard({
    required this.profile,
    required this.isLast,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onSelect(context, ref),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: profile.isActive
                    ? theme.primaryColor
                    : theme.primaryColor.withValues(alpha: 0.15),
                width: profile.isActive ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                _ProfileAvatar(profile: profile, theme: theme),
                const SizedBox(width: 16),
                Expanded(child: _ProfileInfo(profile: profile, theme: theme)),
                // 수정 버튼 (연필 아이콘)
                IconButton(
                  onPressed: () => _onEdit(context),
                  icon: Icon(
                    Icons.edit_outlined,
                    color: theme.textMuted,
                    size: 20,
                  ),
                  tooltip: '프로필 수정',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                // 삭제 버튼 (휴지통 아이콘)
                IconButton(
                  onPressed: () => _onDelete(context, ref),
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red[400],
                    size: 20,
                  ),
                  tooltip: '프로필 삭제',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                if (profile.isActive)
                  Icon(
                    Icons.check_circle,
                    color: theme.primaryColor,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSelect(BuildContext context, WidgetRef ref) async {
    if (profile.isActive) {
      // 이미 활성화된 프로필이면 그냥 닫기
      context.pop();
      return;
    }

    // 활성 프로필 변경
    await ref.read(profileListProvider.notifier).setActiveProfile(profile.id);
    if (context.mounted) {
      context.pop();
    }
  }

  /// 프로필 수정 화면으로 이동
  void _onEdit(BuildContext context) {
    context.push('${Routes.profileEdit}?profileId=${profile.id}');
  }

  /// 프로필 삭제
  void _onDelete(BuildContext context, WidgetRef ref) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('프로필 삭제'),
        content: Text('${profile.displayName} 프로필을 삭제하시겠습니까?\n\n관련된 모든 데이터가 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              debugPrint('🗑️ [ProfileSelectScreen] 프로필 삭제 시작: ${profile.id}');

              try {
                await ref.read(profileListProvider.notifier).deleteProfile(profile.id);
                debugPrint('✅ [ProfileSelectScreen] 프로필 삭제 성공');

                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('${profile.displayName} 프로필이 삭제되었습니다')),
                );
              } catch (e) {
                debugPrint('❌ [ProfileSelectScreen] 프로필 삭제 실패: $e');
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('삭제 실패: $e'),
                    backgroundColor: Colors.red[400],
                  ),
                );
              }
            },
            child: Text(
              '삭제',
              style: TextStyle(color: Colors.red[400]),
            ),
          ),
        ],
      ),
    );
  }
}

/// 프로필 아바타 위젯
class _ProfileAvatar extends StatelessWidget {
  final SajuProfile profile;
  final AppThemeExtension theme;

  const _ProfileAvatar({required this.profile, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          profile.displayName.isNotEmpty ? profile.displayName[0] : '?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// 프로필 정보 위젯
class _ProfileInfo extends StatelessWidget {
  final SajuProfile profile;
  final AppThemeExtension theme;

  const _ProfileInfo({required this.profile, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              profile.displayName,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                profile.relationType.label,
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${profile.birthDateFormatted} (${profile.calendarTypeLabel})',
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 13,
          ),
        ),
        if (profile.birthTimeFormatted != null)
          Text(
            '${profile.birthTimeFormatted} 출생',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}
