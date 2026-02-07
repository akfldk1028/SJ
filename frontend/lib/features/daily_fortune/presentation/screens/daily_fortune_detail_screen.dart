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

/// 카테고리별 색상
class _FortuneColors {
  static const wealth = Color(0xFFF59E0B);
  static const love = Color(0xFFEC4899);
  static const work = Color(0xFF3B82F6);
  static const health = Color(0xFF10B981);
  static const accent = Color(0xFF6B48FF);
  static const accentLight = Color(0xFF8B5CF6);
  static const highlight = Color(0xFFFFB800);
}

/// 카테고리 항목 타입
typedef _CategoryDef = ({String key, String nameKey, IconData icon, Color color});

/// 행운 항목 타입
typedef _LuckyDef = ({String label, String value, IconData icon});

/// 오늘의 운세 상세 화면
class DailyFortuneDetailScreen extends ConsumerWidget {
  const DailyFortuneDetailScreen({super.key});

  static const _categories = <_CategoryDef>[
    (key: 'wealth', nameKey: 'daily_fortune.money', icon: Icons.account_balance_wallet_rounded, color: _FortuneColors.wealth),
    (key: 'love', nameKey: 'daily_fortune.love', icon: Icons.favorite_rounded, color: _FortuneColors.love),
    (key: 'work', nameKey: 'daily_fortune.work', icon: Icons.work_rounded, color: _FortuneColors.work),
    (key: 'health', nameKey: 'daily_fortune.health', icon: Icons.monitor_heart_rounded, color: _FortuneColors.health),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final fortuneAsync = ref.watch(dailyFortuneProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'daily_fortune.title'.tr(),
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: MysticBackground(
        child: SafeArea(
          child: fortuneAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) {
              if (kDebugMode) {
                print('[DailyFortuneDetail] 에러: $error\n$stack');
              }
              return _buildAnalyzingState(theme);
            },
            data: (fortune) {
              if (fortune == null) return _buildAnalyzingState(theme);
              return _buildContent(context, theme, fortune);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingState(AppThemeExtension theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          Text(
            'daily_fortune.analyzingTitle'.tr(),
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'daily_fortune.pleaseWait'.tr(),
            style: TextStyle(color: theme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppThemeExtension theme, DailyFortuneData fortune) {
    final horizontalPadding = context.horizontalPadding;
    final isSmall = context.isSmallMobile;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isSmall ? 16 : 20),
      children: [
        _buildOverallScoreCard(theme, fortune),
        const SizedBox(height: 24),
        _buildCategorySection(context, theme, fortune),
        const SizedBox(height: 24),
        _buildLuckySection(theme, fortune),
        const SizedBox(height: 24),
        _buildAdviceCard(theme, fortune),
        const SizedBox(height: 24),
        _buildConsultButton(context, theme),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── 종합 점수 카드 ──

  Widget _buildOverallScoreCard(AppThemeExtension theme, DailyFortuneData fortune) {
    final scoreColor = _getScoreColor(fortune.overallScore);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withValues(alpha: 0.15),
            theme.cardColor,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scoreColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildDateGreetingRow(theme, scoreColor),
            const SizedBox(height: 24),
            _buildScoreRow(theme, fortune, scoreColor),
            const SizedBox(height: 20),
            _buildMiniStatsRow(theme, fortune),
          ],
        ),
      ),
    );
  }

  Widget _buildDateGreetingRow(AppThemeExtension theme, Color scoreColor) {
    final now = DateTime.now();
    final weekdayKeys = [
      'daily_fortune.weekdayMon',
      'daily_fortune.weekdayTue',
      'daily_fortune.weekdayWed',
      'daily_fortune.weekdayThu',
      'daily_fortune.weekdayFri',
      'daily_fortune.weekdaySat',
      'daily_fortune.weekdaySun',
    ];
    final weekdayStr = weekdayKeys[now.weekday - 1].tr();
    final dateStr = 'daily_fortune.dateFormat'.tr(namedArgs: {
      'month': '${now.month}',
      'day': '${now.day}',
      'weekday': weekdayStr,
    });

    final (greeting, greetingIcon) = switch (now.hour) {
      >= 5 && < 12 => ('daily_fortune.greetingMorning'.tr(), Icons.wb_sunny_rounded),
      >= 12 && < 18 => ('daily_fortune.greetingAfternoon'.tr(), Icons.wb_sunny_outlined),
      >= 18 && < 22 => ('daily_fortune.greetingEvening'.tr(), Icons.nightlight_round),
      _ => ('daily_fortune.greetingNight'.tr(), Icons.bedtime_rounded),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_rounded, size: 12, color: theme.textMuted),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Icon(greetingIcon, size: 16, color: scoreColor),
            const SizedBox(width: 6),
            Text(
              greeting,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreRow(AppThemeExtension theme, DailyFortuneData fortune, Color scoreColor) {
    final score = fortune.overallScore;

    return Column(
      children: [
        // 등급 뱃지
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: scoreColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getGradeIcon(score), color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(
                _getScoreGrade(score),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 점수 원
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scoreColor.withValues(alpha: 0.2),
                scoreColor.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(color: scoreColor.withValues(alpha: 0.5), width: 3),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                    height: 1,
                  ),
                ),
                Text(
                  'daily_fortune.scorePoint'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: scoreColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 메시지 (전체 너비 — 좁은 Row 대신 아래로 길게)
        Text(
          FortuneTextFormatter.formatParagraph(fortune.overallMessage),
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: theme.textPrimary,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.left,
        ),
      ],
    );
  }

  Widget _buildMiniStatsRow(AppThemeExtension theme, DailyFortuneData fortune) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final cat in _categories)
            _buildMiniStat(theme, cat.nameKey.tr().substring(0, 2), fortune.getCategoryScore(cat.key), cat.color),
        ],
      ),
    );
  }

  Widget _buildMiniStat(AppThemeExtension theme, String label, int score, Color color) {
    return Column(
      children: [
        Text(
          '$score',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: theme.textMuted)),
      ],
    );
  }

  // ── 카테고리별 운세 ──

  Widget _buildCategorySection(BuildContext context, AppThemeExtension theme, DailyFortuneData fortune) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'daily_fortune.categoryFortune'.tr(),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: theme.textPrimary),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 12) / 2;
            final scale = (constraints.maxWidth / 400).clamp(0.8, 1.5);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final cat in _categories)
                  _buildCategoryCard(context, theme, fortune, cat, cardWidth, scale),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    AppThemeExtension theme,
    DailyFortuneData fortune,
    _CategoryDef cat,
    double cardWidth,
    double scale,
  ) {
    final score = fortune.getCategoryScore(cat.key);
    final message = fortune.getCategoryMessage(cat.key);
    final padding = (16 * scale).clamp(14.0, 22.0);

    // 온점 기준 첫 문장만 추출
    final firstSentence = message.split('.').first.trim();

    return GestureDetector(
      onTap: () => context.push('/fortune/daily/category?key=${cat.key}'),
      child: SizedBox(
        width: cardWidth,
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cat.color.withValues(alpha: 0.15),
                cat.color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cat.color.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카테고리명 + 점수
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(cat.icon, color: cat.color, size: (18 * scale).clamp(16.0, 24.0)),
                      SizedBox(width: 6 * scale),
                      Text(
                        cat.nameKey.tr(),
                        style: TextStyle(
                          fontSize: (13 * scale).clamp(11.0, 16.0),
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'daily_fortune.scoreWithValue'.tr(namedArgs: {'score': '$score'}),
                    style: TextStyle(
                      fontSize: (14 * scale).clamp(12.0, 18.0),
                      fontWeight: FontWeight.w700,
                      color: cat.color,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10 * scale),
              // 첫 문장 크게
              Text(
                firstSentence,
                style: TextStyle(
                  fontSize: (17 * scale).clamp(15.0, 22.0),
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 8 * scale),
              // 탭 유도
              Row(
                children: [
                  Text(
                    'daily_fortune.viewDetail'.tr(),
                    style: TextStyle(
                      fontSize: (11 * scale).clamp(10.0, 13.0),
                      color: theme.textMuted,
                    ),
                  ),
                  SizedBox(width: 2 * scale),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: (14 * scale).clamp(12.0, 18.0),
                    color: theme.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 오늘의 행운 ──

  Widget _buildLuckySection(AppThemeExtension theme, DailyFortuneData fortune) {
    final lucky = fortune.lucky;
    final items = <_LuckyDef>[
      (label: 'daily_fortune.luckyTime'.tr(), value: lucky.time, icon: Icons.schedule_rounded),
      (label: 'daily_fortune.luckyColor'.tr(), value: lucky.color, icon: Icons.palette_rounded),
      (label: 'daily_fortune.luckyNumber'.tr(), value: '${lucky.number}', icon: Icons.tag_rounded),
      (label: 'daily_fortune.luckyDirection'.tr(), value: lucky.direction, icon: Icons.explore_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'daily_fortune.todayLucky'.tr(),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: theme.textPrimary),
          ),
        ),
        for (int i = 0; i < items.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildLuckyCard(theme, items[i])),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < items.length
                      ? _buildLuckyCard(theme, items[i + 1])
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLuckyCard(AppThemeExtension theme, _LuckyDef item) {
    final color = theme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(item.label, style: TextStyle(fontSize: 11, color: theme.textMuted)),
          const SizedBox(height: 2),
          Text(
            item.value,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  // ── 오늘의 조언 ──

  Widget _buildAdviceCard(AppThemeExtension theme, DailyFortuneData fortune) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.textMuted.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'daily_fortune.todayAdvice'.tr(),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: theme.textPrimary),
          ),
          const SizedBox(height: 16),
          _buildAdviceRow(
            theme,
            label: 'daily_fortune.cautionLabel'.tr(),
            text: FortuneTextFormatter.formatParagraph(fortune.caution),
            textColor: theme.textPrimary,
          ),
          const SizedBox(height: 12),
          _buildAdviceRow(
            theme,
            label: 'daily_fortune.todayAffirmation'.tr(),
            text: FortuneTextFormatter.formatParagraph(fortune.affirmation),
            textColor: theme.textSecondary,
            italic: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceRow(
    AppThemeExtension theme, {
    required String label,
    required String text,
    required Color textColor,
    bool italic = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: textColor,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ── AI 상담 버튼 ──

  Widget _buildConsultButton(BuildContext context, AppThemeExtension theme) {
    return GestureDetector(
      onTap: () => context.go('/saju/chat?type=dailyFortune'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_FortuneColors.accent, _FortuneColors.accentLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _FortuneColors.accent.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'daily_fortune.askAiMore'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 유틸리티 ──

  IconData _getGradeIcon(int score) => switch (score) {
    >= 90 => Icons.emoji_events_rounded,
    >= 80 => Icons.thumb_up_rounded,
    >= 70 => Icons.sentiment_satisfied_rounded,
    >= 60 => Icons.sentiment_neutral_rounded,
    _ => Icons.warning_amber_rounded,
  };

  String _getScoreGrade(int score) => switch (score) {
    >= 90 => 'daily_fortune.gradeBestDay'.tr(),
    >= 80 => 'daily_fortune.gradeGoodDay'.tr(),
    >= 70 => 'daily_fortune.gradeOkDay'.tr(),
    >= 60 => 'daily_fortune.gradeNormalDay'.tr(),
    _ => 'daily_fortune.gradeCarefulDay'.tr(),
  };

  Color _getScoreColor(int score) => switch (score) {
    >= 85 => _FortuneColors.highlight,
    >= 70 => _FortuneColors.accent,
    >= 60 => _FortuneColors.work,
    _ => _FortuneColors.health,
  };
}
