import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../profile/presentation/providers/profile_provider.dart';

/// 메인 홈 화면 (Shadcn UI)
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileList = ref.watch(profileListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(32),

              // 헤더
              _buildHeader(context, theme),
              const Gap(48),

              // 메인 메뉴 카드들
              Expanded(
                child: Column(
                  children: [
                    // 새 상담 시작
                    _MenuCard(
                      icon: RadixIcons.plus,
                      title: '새 상담 시작',
                      subtitle: '사주 정보를 입력하고 AI 상담을 시작하세요',
                      onTap: () => context.go('/profile/new'),
                    ),
                    const Gap(16),

                    // 이전 상담 보기
                    profileList.when(
                      data: (profiles) => _MenuCard(
                        icon: RadixIcons.clock,
                        title: '이전 상담',
                        subtitle: profiles.isEmpty
                            ? '저장된 프로필이 없습니다'
                            : '${profiles.length}개의 프로필이 저장되어 있습니다',
                        onTap: profiles.isEmpty
                            ? null
                            : () => context.go('/profiles'),
                        secondary: true,
                      ),
                      loading: () => _MenuCard(
                        icon: RadixIcons.clock,
                        title: '이전 상담',
                        subtitle: '로딩 중...',
                        onTap: null,
                        secondary: true,
                      ),
                      error: (_, __) => _MenuCard(
                        icon: RadixIcons.clock,
                        title: '이전 상담',
                        subtitle: '프로필을 불러올 수 없습니다',
                        onTap: null,
                        secondary: true,
                      ),
                    ),
                  ],
                ),
              ),

              // 하단 정보
              Center(
                child: Text(
                  '만톡 v0.1.0',
                  style: theme.typography.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ),
              const Gap(16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                RadixIcons.star,
                color: Colors.white,
                size: 28,
              ),
            ),
            const Gap(16),
            Text(
              '만톡',
              style: theme.typography.h2.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Gap(8),
        Text(
          'AI와 함께하는 사주 상담',
          style: theme.typography.lead.copyWith(
            color: theme.colorScheme.mutedForeground,
          ),
        ),
      ],
    );
  }
}

/// 메뉴 카드 위젯
class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.secondary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Card(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: secondary
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: secondary
                        ? theme.colorScheme.secondaryForeground
                        : theme.colorScheme.primaryForeground,
                    size: 28,
                  ),
                ),
                const Gap(16),
                Text(
                  title,
                  style: theme.typography.h4.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(4),
                Text(
                  subtitle,
                  style: theme.typography.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
                const Spacer(),
                if (onTap != null)
                  Row(
                    children: [
                      Text(
                        '시작하기',
                        style: theme.typography.small.copyWith(
                          color: secondary
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(4),
                      Icon(
                        RadixIcons.arrowRight,
                        color: secondary
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.primary,
                        size: 16,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
