import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Daily advice card - 와이어프레임 스타일 (오늘의 조언)
class DailyAdviceSection extends StatelessWidget {
  const DailyAdviceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: theme.isDark ? null : theme.cardColor,
          gradient: theme.isDark
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1A24),
                    const Color(0xFF14141C),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.primaryColor.withOpacity(theme.isDark ? 0.15 : 0.12),
          ),
          boxShadow: theme.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 20,
              right: 20,
              child: Text(
                '🪷',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '"오늘은 새로운 시작에 좋은 날입니다.\n중요한 결정을 내리기에 적합하며,\n대인관계에서 좋은 소식이 있을 수 있습니다."',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: theme.textSecondary,
                  height: 1.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
