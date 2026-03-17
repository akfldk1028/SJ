import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../../../../shared/utils/text_formatter.dart';
import '../../../menu/presentation/providers/daily_fortune_provider.dart';

/// 카테고리 정보 레코드
typedef _CategoryInfo = ({String nameKey, IconData icon, Color color});

/// 카테고리별 운세 상세 페이지 (재물운, 애정운, 직장운, 건강운)
class CategoryFortuneDetailScreen extends ConsumerWidget {
  final String categoryKey;

  const CategoryFortuneDetailScreen({super.key, required this.categoryKey});

  // ── 카테고리 정보 (Dart 3 Record) ──

  static const _categoryMap = <String, _CategoryInfo>{
    'wealth': (nameKey: 'daily_fortune.money', icon: Icons.account_balance_wallet_rounded, color: Color(0xFFF59E0B)),
    'love': (nameKey: 'daily_fortune.love', icon: Icons.favorite_rounded, color: Color(0xFFEC4899)),
    'work': (nameKey: 'daily_fortune.work', icon: Icons.work_rounded, color: Color(0xFF3B82F6)),
    'health': (nameKey: 'daily_fortune.health', icon: Icons.monitor_heart_rounded, color: Color(0xFF10B981)),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final fortuneAsync = ref.watch(dailyFortuneProvider);
    final info = _categoryMap[categoryKey];

    if (info == null) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        body: Center(
          child: Text('daily_fortune.unknownCategory'.tr(), style: TextStyle(color: theme.textPrimary)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          info.nameKey.tr(),
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
                  child: Text('daily_fortune.noFortuneData'.tr(), style: TextStyle(color: theme.textMuted)),
                );
              }

              final score = fortune.getCategoryScore(categoryKey);
              final message = fortune.getCategoryMessage(categoryKey);
              final tip = fortune.getCategoryTip(categoryKey);

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: context.horizontalPadding,
                  vertical: context.scaledPadding(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScoreCard(theme, info, score),
                    SizedBox(height: context.scaledPadding(24)),
                    _buildMessageCard(theme, info, message),
                    if (tip.isNotEmpty) ...[
                      SizedBox(height: context.scaledPadding(16)),
                      _buildTipCard(theme, info.color, tip),
                    ],
                    SizedBox(height: context.scaledPadding(32)),
                  ],
                ),
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(color: info.color),
            ),
            error: (e, _) {
              if (kDebugMode) print('[CategoryFortuneDetail] 오류: $e');
              return Center(
                child: Text(
                  'daily_fortune.cannotLoadFortune'.tr(),
                  style: TextStyle(color: theme.textMuted),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── 점수 카드 ──

  Widget _buildScoreCard(AppThemeExtension theme, _CategoryInfo info, int score) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            info.color.withValues(alpha: 0.15),
            info.color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: info.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // 아이콘
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(info.icon, color: info.color, size: 28),
          ),
          const SizedBox(height: 12),
          // 카테고리명
          Text(
            info.nameKey.tr(),
            style: TextStyle(
              fontSize: 18,
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
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: info.color,
                ),
              ),
              Text(
                'daily_fortune.outOf100'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 진행바
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: info.color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(info.color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          // 등급
          Text(
            _gradeText(score),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: info.color,
            ),
          ),
        ],
      ),
    );
  }

  // ── 상세 메시지 카드 ──

  Widget _buildMessageCard(AppThemeExtension theme, _CategoryInfo info, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 제목 (아이콘 제거 → 텍스트만)
          Text(
            'daily_fortune.todayCategoryFortune'.tr(namedArgs: {'name': info.nameKey.tr()}),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // 본문 (아래로 길게 읽히도록)
          Text(
            FortuneTextFormatter.formatParagraph(message),
            style: TextStyle(
              fontSize: 15,
              color: theme.textSecondary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  // ── 팁 카드 ──

  Widget _buildTipCard(AppThemeExtension theme, Color color, String tip) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 제목 (아이콘 제거 → 텍스트만)
          Text(
            'daily_fortune.todayTip'.tr(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          // 본문
          Text(
            FortuneTextFormatter.formatParagraph(tip),
            style: TextStyle(
              fontSize: 14,
              color: theme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── 등급 텍스트 (Dart 3 switch expression) ──

  String _gradeText(int score) => switch (score) {
    >= 90 => 'daily_fortune.gradeVeryGood'.tr(),
    >= 80 => 'daily_fortune.gradeGoodSimple'.tr(),
    >= 70 => 'daily_fortune.gradeAboveAverage'.tr(),
    >= 60 => 'daily_fortune.gradeAverage'.tr(),
    >= 50 => 'daily_fortune.gradeSomeCaution'.tr(),
    _ => 'daily_fortune.gradeCautionNeeded'.tr(),
  };
}
