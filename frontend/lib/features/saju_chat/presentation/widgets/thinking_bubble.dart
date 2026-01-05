import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'typing_indicator.dart';

/// AI가 생각 중일 때 표시하는 버블
///
/// 스트리밍 시작 전 로딩 상태를 시각적으로 표현
class ThinkingBubble extends StatelessWidget {
  const ThinkingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI 아바타
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: appTheme.isDark
                    ? [const Color(0xFF4A6572), const Color(0xFF344955)]
                    : [const Color(0xFF78909C), const Color(0xFF607D8B)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: appTheme.isDark
                    ? [const Color(0xFF2A3540), const Color(0xFF1E2830)] // 틸 다크
                    : [const Color(0xFFF5F5F5), const Color(0xFFEBEBEB)], // 쿨 그레이
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: appTheme.isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '생각 중',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: appTheme.isDark
                        ? const Color(0xFFE8E8E8)
                        : const Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(width: 8),
                const TypingIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
