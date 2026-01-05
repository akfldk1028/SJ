import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

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
    final appTheme = context.appTheme;

    // 다크/라이트 테마에 맞는 색상
    final backgroundColor = appTheme.isDark
        ? const Color(0xFF1E2830) // 틸 다크 배경
        : const Color(0xFFF5F5F5); // 라이트 그레이 배경
    final textColor = appTheme.isDark
        ? const Color(0xFFB0BEC5) // 밝은 회색
        : const Color(0xFF607D8B); // 블루 그레이
    final borderColor = appTheme.isDark
        ? const Color(0xFF344955)
        : const Color(0xFFE0E0E0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '사주 상담은 참고용이며, 중요한 결정은 전문가와 상담하세요.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
