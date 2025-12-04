import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../domain/entities/saju_profile.dart';
import '../providers/profile_provider.dart';

/// 프로필 목록 화면 (Shadcn UI)
class ProfileListScreen extends ConsumerWidget {
  const ProfileListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profileListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      headers: [
        AppBar(
          leading: [
            IconButton.ghost(
              icon: const Icon(RadixIcons.arrowLeft),
              onPressed: () => context.go('/home'),
            ),
          ],
          title: const Text('내 프로필'),
          trailing: [
            IconButton.ghost(
              icon: const Icon(RadixIcons.plus),
              onPressed: () => context.push('/profile/new'),
            ),
          ],
        ),
      ],
      child: profilesAsync.when(
        data: (profiles) => profiles.isEmpty
            ? _buildEmptyState(context, theme)
            : _buildProfileList(context, ref, theme, profiles),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, ref, theme, error),
      ),
    );
  }

  /// 프로필이 없을 때 빈 상태
  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              RadixIcons.person,
              size: 40,
              color: theme.colorScheme.secondaryForeground,
            ),
          ),
          const Gap(24),
          Text(
            '등록된 프로필이 없습니다',
            style: theme.typography.h4.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(8),
          Text(
            '새 프로필을 추가해보세요',
            style: theme.typography.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
          const Gap(24),
          PrimaryButton(
            onPressed: () => context.push('/profile/new'),
            leading: const Icon(RadixIcons.plus, size: 16),
            child: const Text('프로필 추가'),
          ),
        ],
      ),
    );
  }

  /// 프로필 목록
  Widget _buildProfileList(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<SajuProfile> profiles,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: profiles.length,
      itemBuilder: (context, index) {
        final profile = profiles[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ProfileCard(
            profile: profile,
            onTap: () => context.push('/chat/${profile.id}'),
            onEdit: () => context.push('/profile/${profile.id}/edit'),
            onDelete: () => _confirmDelete(context, ref, theme, profile),
            onSetActive: () => _setActiveProfile(ref, profile.id),
          ),
        );
      },
    );
  }

  /// 에러 상태
  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Object error,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.destructive.scaleAlpha(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              RadixIcons.crossCircled,
              size: 40,
              color: theme.colorScheme.destructive,
            ),
          ),
          const Gap(24),
          Text(
            '프로필을 불러오지 못했습니다',
            style: theme.typography.h4.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(8),
          Text(
            error.toString(),
            style: theme.typography.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          PrimaryButton(
            onPressed: () => ref.invalidate(profileListProvider),
            leading: const Icon(RadixIcons.reload, size: 16),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  /// 삭제 확인 다이얼로그
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    SajuProfile profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프로필 삭제'),
        content: Text('${profile.displayName} 프로필을 삭제하시겠습니까?'),
        actions: [
          OutlineButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          DestructiveButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(profileListProvider.notifier).deleteProfile(profile.id);
    }
  }

  /// 활성 프로필 설정
  Future<void> _setActiveProfile(WidgetRef ref, String profileId) async {
    await ref.read(profileListProvider.notifier).setActiveProfile(profileId);
  }
}

/// 프로필 카드 위젯
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onSetActive,
  });

  final SajuProfile profile;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 프로필 아바타
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: profile.isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    profile.displayName.isNotEmpty
                        ? profile.displayName[0]
                        : '?',
                    style: theme.typography.h3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: profile.isActive
                          ? theme.colorScheme.primaryForeground
                          : theme.colorScheme.secondaryForeground,
                    ),
                  ),
                ),
              ),
              const Gap(16),

              // 프로필 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          profile.displayName,
                          style: theme.typography.large.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (profile.isActive) ...[
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '활성',
                              style: theme.typography.xSmall.copyWith(
                                color: theme.colorScheme.primaryForeground,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Gap(4),
                    Text(
                      _buildSubtitle(),
                      style: theme.typography.small.copyWith(
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),

              // 액션 버튼들
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!profile.isActive)
                    IconButton.ghost(
                      icon: const Icon(RadixIcons.checkCircled, size: 18),
                      onPressed: onSetActive,
                    ),
                  IconButton.ghost(
                    icon: const Icon(RadixIcons.pencil1, size: 18),
                    onPressed: onEdit,
                  ),
                  IconButton.ghost(
                    icon: Icon(
                      RadixIcons.trash,
                      size: 18,
                      color: theme.colorScheme.destructive,
                    ),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];

    // 성별
    parts.add(profile.gender.displayName);

    // 생년월일
    final date = profile.birthDate;
    parts.add('${date.year}.${date.month}.${date.day}');

    // 음양력
    if (profile.isLunar) {
      parts.add('(음력)');
    }

    return parts.join(' · ');
  }
}
