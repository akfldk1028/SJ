import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../../../menu/presentation/providers/daily_fortune_provider.dart';

/// 카테고리별 운세 상세 페이지 (재물운, 애정운, 직장운, 건강운)
class CategoryFortuneDetailScreen extends ConsumerWidget {
  final String categoryKey;

  const CategoryFortuneDetailScreen({super.key, required this.categoryKey});

  static const _categoryInfo = {
    'wealth': {
      'name': '재물운',
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFFF59E0B),
    },
    'love': {
      'name': '애정운',
      'icon': Icons.favorite_rounded,
      'color': Color(0xFFEC4899),
    },
    'work': {
      'name': '직장운',
      'icon': Icons.work_rounded,
      'color': Color(0xFF3B82F6),
    },
    'health': {
      'name': '건강운',
      'icon': Icons.monitor_heart_rounded,
      'color': Color(0xFF10B981),
    },
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final fortuneAsync = ref.watch(dailyFortuneProvider);
    final info = _categoryInfo[categoryKey];

    if (info == null) {
      return Scaffold(
        body: Center(child: Text('알 수 없는 카테고리', style: TextStyle(color: theme.textPrimary))),
      );
    }

    final name = info['name'] as String;
    final icon = info['icon'] as IconData;
    final color = info['color'] as Color;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: MysticBackground(
        child: SafeArea(
          child: fortuneAsync.when(
            data: (fortune) {
              if (fortune == null) {
                return Center(
                  child: Text('운세 데이터가 없습니다', style: TextStyle(color: theme.textMuted)),
                );
              }
              return _buildContent(context, theme, fortune, color, icon, name);
            },
            loading: () => Center(
              child: CircularProgressIndicator(color: color),
            ),
            error: (e, _) => Center(
              child: Text('오류: $e', style: TextStyle(color: theme.textMuted)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppThemeExtension theme,
    DailyFortuneData fortune,
    Color color,
    IconData icon,
    String name,
  ) {
    final score = fortune.getCategoryScore(categoryKey);
    final message = fortune.getCategoryMessage(categoryKey);
    final tip = fortune.getCategoryTip(categoryKey);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 점수 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.2),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                // 점수
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(
                      ' / 100',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: theme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 점수 바
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getGradeText(score),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 상세 메시지
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '오늘의 $name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textSecondary,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          // 팁 섹션
          if (tip.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, color: color, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '오늘의 팁',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tip,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getGradeText(int score) {
    if (score >= 90) return '매우 좋음';
    if (score >= 80) return '좋음';
    if (score >= 70) return '보통 이상';
    if (score >= 60) return '보통';
    if (score >= 50) return '다소 주의';
    return '주의 필요';
  }
}
