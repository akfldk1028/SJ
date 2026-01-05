import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Fortune category horizontal scroll list - 와이어프레임 스타일
class FortuneCategoryList extends StatelessWidget {
  const FortuneCategoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    // 4개 박스가 화면에 맞게 배치되도록 계산 (padding 40 + gap 36)
    final boxWidth = (screenWidth - 40 - 36) / 4;

    final categories = [
      {'icon': '💰', 'name': '재물운', 'score': 92},
      {'icon': '💕', 'name': '애정운', 'score': 78},
      {'icon': '💼', 'name': '직장운', 'score': 85},
      {'icon': '🏥', 'name': '건강운', 'score': 70},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: categories.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < categories.length - 1 ? 12 : 0),
              height: 110,
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
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(theme.isDark ? 0.1 : 0.12),
                ),
                boxShadow: theme.isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    cat['icon'] as String,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat['name'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cat['score']}점',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
