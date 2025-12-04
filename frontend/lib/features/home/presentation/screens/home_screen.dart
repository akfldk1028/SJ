import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../router/routes.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../widgets/daily_fortune_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myProfileAsync = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 운세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: 알림 화면
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Daily Fortune Card
            myProfileAsync.when(
              data: (profile) => DailyFortuneCard(
                profileName: profile?.displayName,
                onTap: () {
                  if (profile != null) {
                    context.push(Routes.sajuChart);
                  } else {
                    context.push(Routes.profileEdit);
                  }
                },
              ),
              loading: () => const DailyFortuneCard(),
              error: (_, __) => const DailyFortuneCard(),
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              '빠른 메뉴',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.person_outline,
                    label: '내 프로필',
                    onTap: () => context.push(Routes.profileEdit),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.auto_graph,
                    label: '만세력',
                    onTap: () => context.push(Routes.sajuChart),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.chat_bubble_outline,
                    label: 'AI 상담',
                    onTap: () => context.go(Routes.sajuChat),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.people_outline,
                    label: '인연 관리',
                    onTap: () => context.go(Routes.relationshipList),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tips Section
            Text(
              '오늘의 팁',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildTipCard(
              context,
              emoji: '💡',
              title: '진태양시 보정이란?',
              description: '실제 태양의 위치를 기준으로 출생시간을 보정하여 더 정확한 사주를 계산합니다.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(
    BuildContext context, {
    required String emoji,
    required String title,
    required String description,
  }) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.p.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.muted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: ShadCard(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
