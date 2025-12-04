import 'package:flutter/material.dart';

/// 면책 배너 위젯
///
/// 위젯 트리 최적화:
/// - const 생성자 사용
/// - Theme 호출 최소화 (한 번만 호출)
class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '사주 상담은 참고용이며, 중요한 결정은 전문가와 상담하세요.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
