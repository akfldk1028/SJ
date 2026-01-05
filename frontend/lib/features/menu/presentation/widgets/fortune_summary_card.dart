import 'package:flutter/material.dart';
import '../../data/mock/mock_fortune_data.dart';
import '../../../../core/theme/app_theme.dart';

/// Fortune summary card - 다크/라이트 테마 지원
class FortuneSummaryCard extends StatelessWidget {
  const FortuneSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final score = MockFortuneData.todayScore;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          // 라이트 테마: 플랫 배경, 다크 테마: 그라데이션
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
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.isDark
                ? theme.primaryColor.withOpacity(0.2)
                : theme.primaryColor.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: theme.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // 골드 그라데이션 오버레이 (다크 테마에서만)
            if (theme.isDark)
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        theme.primaryColor.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            // 메인 콘텐츠
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '오늘의 총운',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textMuted,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '대길(大吉)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: theme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        '🌕',
                        style: TextStyle(fontSize: 40),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Score - 다크: 그라데이션, 라이트: 단색
                  theme.isDark
                      ? ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.primaryColor,
                              theme.accentColor ?? theme.primaryColor,
                              theme.primaryColor,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            '$score',
                            style: const TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        )
                      : Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w700,
                            color: theme.primaryColor,
                            height: 1,
                          ),
                        ),
                  Text(
                    '종합 운세 점수',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textMuted,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stars rating (5단계 별)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final filledStars = (score / 20).ceil();
                      final isFilled = index < filledStars;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 28,
                          color: isFilled ? theme.primaryColor : theme.textMuted.withOpacity(0.3),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
