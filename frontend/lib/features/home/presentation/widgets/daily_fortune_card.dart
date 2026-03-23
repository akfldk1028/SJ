import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/constants/app_colors.dart';

/// 오늘의 운세 카드 위젯
class DailyFortuneCard extends StatelessWidget {
  const DailyFortuneCard({
    super.key,
    this.profileName,
    this.fortuneMessage,
    this.luckyColor,
    this.luckyNumber,
    this.onTap,
  });

  final String? profileName;
  final String? fortuneMessage;
  final String? luckyColor;
  final int? luckyNumber;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final today = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: ShadCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🔮', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      'menu.todayFortune'.tr(),
                      style: theme.textTheme.h4,
                    ),
                  ],
                ),
                Text(
                  today,
                  style: theme.textTheme.muted,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Profile greeting
            if (profileName != null) ...[
              Text(
                'menu.greeting'.tr(namedArgs: {'name': profileName!}),
                style: theme.textTheme.p.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Fortune message
            Text(
              fortuneMessage ?? _getDefaultFortuneMessage(),
              textAlign: TextAlign.justify,
              style: theme.textTheme.p.copyWith(
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),

            // Lucky items
            Row(
              children: [
                _buildLuckyItem(
                  context,
                  icon: Icons.palette_outlined,
                  label: 'menu.luckyColorShort'.tr(),
                  value: luckyColor ?? '파랑',
                ),
                const SizedBox(width: 24),
                _buildLuckyItem(
                  context,
                  icon: Icons.tag,
                  label: 'menu.luckyNumberShort'.tr(),
                  value: '${luckyNumber ?? 7}',
                ),
              ],
            ),

            // CTA
            if (onTap != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'menu.viewMore'.tr(),
                    style: theme.textTheme.small.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLuckyItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = ShadTheme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.secondary,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.muted.copyWith(fontSize: 11),
            ),
            Text(
              value,
              style: theme.textTheme.p.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getDefaultFortuneMessage() {
    // 간단한 기본 메시지들 (실제로는 사주 기반 생성)
    final messages = [
      '오늘은 새로운 인연을 만나기 좋은 날입니다. 동쪽에서 귀인이 나타날 수 있으니 주변을 잘 살펴보세요.',
      '오늘의 기운이 상승하고 있습니다. 미뤄왔던 일을 시작하기에 좋은 날입니다.',
      '차분하게 내면을 돌아보는 시간을 가지세요. 깊은 통찰이 행운을 가져올 것입니다.',
    ];
    return messages[DateTime.now().day % messages.length];
  }
}
