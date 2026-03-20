import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/illustrations/illustrations.dart';
import '../../../../shared/widgets/fortune_shimmer_loading.dart';
import '../../../../shared/widgets/fortune_monthly_chip_section.dart';
import '../../../../shared/widgets/fortune_title_header.dart';
import '../../../../shared/widgets/fortune_section_card.dart';
import '../../../../shared/widgets/fortune_score_gauge.dart';
import '../providers/monthly_fortune_provider.dart';

/// 월별 운세 상세 화면 - 개선된 UI/UX
class MonthlyFortuneScreen extends ConsumerStatefulWidget {
  const MonthlyFortuneScreen({super.key});

  @override
  ConsumerState<MonthlyFortuneScreen> createState() => _MonthlyFortuneScreenState();
}

class _MonthlyFortuneScreenState extends ConsumerState<MonthlyFortuneScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final fortuneAsync = ref.watch(monthlyFortuneProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'monthly_fortune.appBarTitle'.tr(),
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.textSecondary, size: 22),
            onPressed: () => ref.read(monthlyFortuneProvider.notifier).refresh(),
          ),
        ],
      ),
      body: fortuneAsync.when(
        loading: () => const FortuneShimmerLoading(),
        error: (error, stack) {
          print('[MonthlyFortuneScreen] ❌ 에러: $error');
          print('[MonthlyFortuneScreen] ❌ 스택: $stack');
          return _buildError(context, theme);
        },
        data: (fortune) {
          if (fortune == null) {
            return _buildAnalyzing(theme);
          }
          return _buildContent(context, theme, fortune);
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, AppThemeExtension theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.textMuted),
            const SizedBox(height: 16),
            Text(
              'monthly_fortune.errorLoadMonthly'.tr(),
              style: TextStyle(color: theme.textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(monthlyFortuneProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text('monthly_fortune.retry'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzing(AppThemeExtension theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 100,
            height: 100,
            child: AnimatedYinYangIllustration(
              size: 100,
              showGlow: true,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'monthly_fortune.analyzingMonthly'.tr(),
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'monthly_fortune.pleaseWait'.tr(),
            style: TextStyle(color: theme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppThemeExtension theme, MonthlyFortuneData fortune) {
    // 반응형 패딩 적용
    final horizontalPadding = context.horizontalPadding;
    final isSmall = context.isSmallMobile;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isSmall ? 12 : 16),
      children: [
        // 히어로 헤더
        FortuneTitleHeader(
          title: 'monthly_fortune.yearMonth'.tr(namedArgs: {'year': '${fortune.year}', 'month': '${fortune.month}'}),
          subtitle: fortune.monthGanji,
          keyword: fortune.overview.keyword.isNotEmpty ? fortune.overview.keyword : null,
          score: fortune.overview.score > 0 ? fortune.overview.score : null,
          style: HeaderStyle.hero,
        ),
        const SizedBox(height: 28),

        // 월간 총운
        FortuneSectionCard(
          title: 'monthly_fortune.monthlyOverall'.tr(),
          icon: Icons.calendar_month,
          style: CardStyle.elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (fortune.overview.opening.isNotEmpty)
                Text(
                  fortune.overview.opening,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textSecondary,
                    height: 1.8,
                  ),
                ),
              if (fortune.overview.monthEnergy.isNotEmpty) ...[
                const SizedBox(height: 16),
                FortuneHighlightBox(
                  label: 'monthly_fortune.monthEnergy'.tr(),
                  content: fortune.overview.monthEnergy,
                  type: HighlightType.info,
                  icon: Icons.bolt,
                ),
              ],
              if (fortune.overview.hapchungEffect.isNotEmpty) ...[
                const SizedBox(height: 12),
                FortuneHighlightBox(
                  label: 'monthly_fortune.hapchungEffect'.tr(),
                  content: fortune.overview.hapchungEffect,
                  type: HighlightType.warning,
                ),
              ],
              if (fortune.overview.conclusion.isNotEmpty) ...[
                const SizedBox(height: 16),
                FortuneHighlightBox(
                  label: 'monthly_fortune.conclusion'.tr(),
                  content: fortune.overview.conclusion,
                  type: HighlightType.primary,
                  icon: Icons.check_circle_outline,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 분야별 운세 (카드 그리드)
        if (fortune.categories.isNotEmpty) ...[
          FortuneSectionTitle(
            title: 'monthly_fortune.categoryFortuneTitle'.tr(),
            icon: Icons.grid_view,
          ),
          const SizedBox(height: 12),
          _buildCategoryGrid(theme, fortune.categories),
          const SizedBox(height: 24),
        ],

        // 월별 운세 (12개월 칩)
        FortuneSectionTitle(
          title: 'monthly_fortune.yearlyMonthlyFortune'.tr(),
          subtitle: 'monthly_fortune.yearlyMonthlySubtitle'.tr(),
          icon: Icons.date_range,
        ),
        const SizedBox(height: 12),
        FortuneMonthlyChipSection(
          fortuneType: 'monthly_fortune',
          title: '',
          months: _generate12MonthsData(fortune),
          currentMonth: fortune.month,
          onMonthUnlocked: (monthNumber) => _fetchDetailedMonthFortune(fortune.year, monthNumber),
        ),
        const SizedBox(height: 24),

        // 행운 정보
        FortuneSectionCard(
          title: 'monthly_fortune.monthlyLucky'.tr(),
          icon: Icons.star,
          style: CardStyle.gradient,
          child: _buildLuckyGrid(theme, fortune.lucky),
        ),
        const SizedBox(height: 24),

        // 마무리 메시지
        if (fortune.closingMessage.isNotEmpty) ...[
          FortuneSectionCard(
            title: 'monthly_fortune.monthlyMessage'.tr(),
            icon: Icons.message,
            style: CardStyle.outlined,
            content: fortune.closingMessage,
          ),
          const SizedBox(height: 24),
        ],

        // AI 상담 버튼
        _buildConsultButton(context, theme),
        const SizedBox(height: 40),
      ],
    );
  }

  /// 펼쳐진 카테고리 키
  String? _expandedCategoryKey;

  /// 분야별 운세 리스트 (탭하여 펼치기)
  Widget _buildCategoryGrid(AppThemeExtension theme, Map<String, CategorySection> categories) {
    return Column(
      children: categories.entries.map((entry) {
        final cat = entry.value;
        final categoryName = _getCategoryName(entry.key);
        final icon = _getCategoryIcon(entry.key);
        final isExpanded = _expandedCategoryKey == entry.key;
        return _buildCategoryCard(theme, entry.key, categoryName, cat.score, cat.reading, icon, isExpanded);
      }).toList(),
    );
  }

  Widget _buildCategoryCard(AppThemeExtension theme, String key, String title, int score, String reading, IconData icon, bool isExpanded) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedCategoryKey = isExpanded ? null : key;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isExpanded
              ? theme.primaryColor.withValues(alpha: 0.06)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpanded
                ? theme.primaryColor.withValues(alpha: 0.4)
                : theme.textMuted.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: theme.isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                ),
                if (score > 0)
                  FortuneScoreGauge(
                    score: score,
                    size: 32,
                    style: GaugeStyle.compact,
                    showLabel: false,
                  ),
                const SizedBox(width: 4),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: theme.textSecondary,
                ),
              ],
            ),
            if (!isExpanded) ...[
              const SizedBox(height: 8),
              Text(
                reading,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (isExpanded) ...[
              const SizedBox(height: 12),
              Text(
                reading,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textSecondary,
                  height: 1.7,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 행운 정보 그리드
  Widget _buildLuckyGrid(AppThemeExtension theme, LuckySection lucky) {
    final items = <Map<String, dynamic>>[];

    if (lucky.colors.isNotEmpty) {
      items.add({'icon': Icons.palette, 'label': 'monthly_fortune.luckyColors'.tr(), 'value': lucky.colors.join(', ')});
    }
    if (lucky.numbers.isNotEmpty) {
      items.add({'icon': Icons.pin, 'label': 'monthly_fortune.luckyNumbers'.tr(), 'value': lucky.numbers.join(', ')});
    }
    if (lucky.foods.isNotEmpty) {
      items.add({'icon': Icons.restaurant, 'label': 'monthly_fortune.luckyFoods'.tr(), 'value': lucky.foods.join(', ')});
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) => _buildLuckyChip(
            theme,
            item['icon'] as IconData,
            item['label'] as String,
            item['value'] as String,
          )).toList(),
        ),
        if (lucky.tip.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.textMuted.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates, size: 18, color: theme.primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lucky.tip,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLuckyChip(AppThemeExtension theme, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textMuted.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.primaryColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textMuted,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsultButton(BuildContext context, AppThemeExtension theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.accentColor ?? theme.primaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => context.go('/saju/chat?type=monthlyFortune'),
        icon: const Icon(Icons.chat_bubble_outline, size: 20),
        label: Text(
          'monthly_fortune.consultAiMonthly'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  String _getCategoryName(String key) {
    final names = {
      'career': 'monthly_fortune.career'.tr(),
      'business': 'monthly_fortune.business'.tr(),
      'wealth': 'monthly_fortune.wealth'.tr(),
      'love': 'monthly_fortune.loveCategory'.tr(),
      'marriage': 'monthly_fortune.marriage'.tr(),
      'study': 'monthly_fortune.study'.tr(),
      'health': 'monthly_fortune.healthCategory'.tr(),
    };
    return names[key] ?? key;
  }

  IconData _getCategoryIcon(String key) {
    const icons = {
      'career': Icons.work_outline,
      'business': Icons.business_center_outlined,
      'wealth': Icons.account_balance_wallet_outlined,
      'love': Icons.favorite_outline,
      'marriage': Icons.people_outline,
      'study': Icons.school_outlined,
      'health': Icons.health_and_safety_outlined,
    };
    return icons[key] ?? Icons.category;
  }

  /// 12개월 데이터 생성 (v5.0: highlights, lucky 포함)
  Map<String, MonthData> _generate12MonthsData(MonthlyFortuneData fortune) {
    final currentMonth = fortune.month;
    final months = <String, MonthData>{};

    debugPrint('[MonthlyScreen] 🔍 _generate12MonthsData 시작 (v5.0)');
    debugPrint('[MonthlyScreen] currentMonth=$currentMonth, fortune.months.length=${fortune.months.length}');
    debugPrint('[MonthlyScreen] fortune.months.keys=${fortune.months.keys.toList()}');

    for (int i = 1; i <= 12; i++) {
      final monthKey = 'month$i';

      if (i == currentMonth) {
        // 현재 월은 overview 데이터 사용
        debugPrint('[MonthlyScreen] $monthKey: 현재월 - overview.keyword=${fortune.overview.keyword}');
        months[monthKey] = MonthData(
          keyword: fortune.overview.keyword,
          score: fortune.overview.score,
          reading: fortune.overview.opening.isNotEmpty
              ? fortune.overview.opening
              : fortune.overview.conclusion,
          tip: fortune.lucky.tip,
        );
      } else {
        // 다른 월은 months 데이터 사용 (v5.0: highlights, idiom 포함)
        final monthSummary = fortune.months[monthKey];
        final hasHighlights = monthSummary?.highlights != null;
        final hasIdiom = monthSummary?.idiom != null;
        debugPrint('[MonthlyScreen] $monthKey: monthSummary=${monthSummary != null ? "있음(keyword=${monthSummary.keyword}, highlights=$hasHighlights, idiom=$hasIdiom)" : "없음"}');

        if (monthSummary != null && monthSummary.keyword.isNotEmpty) {
          // v5.3: highlights 변환 (7개 카테고리)
          Map<String, MonthHighlightData>? highlights;
          if (monthSummary.highlights != null) {
            highlights = {};
            final h = monthSummary.highlights!;
            for (final entry in {
              'career': h.career,
              'business': h.business,
              'wealth': h.wealth,
              'love': h.love,
              'marriage': h.marriage,
              'health': h.health,
              'study': h.study,
            }.entries) {
              if (entry.value != null) {
                highlights[entry.key] = MonthHighlightData(
                  score: entry.value!.score,
                  summary: entry.value!.summary,
                );
              }
            }
          }

          // v5.0: idiom 변환 (사자성어)
          MonthIdiomData? idiom;
          if (monthSummary.idiom != null) {
            idiom = MonthIdiomData(
              phrase: monthSummary.idiom!.phrase,
              meaning: monthSummary.idiom!.meaning,
            );
          }

          // v5.3: lucky 변환
          MonthLuckyData? luckyData;
          if (monthSummary.lucky != null) {
            luckyData = MonthLuckyData(
              color: monthSummary.lucky!.color,
              number: monthSummary.lucky!.number,
            );
          }

          months[monthKey] = MonthData(
            keyword: monthSummary.keyword,
            score: monthSummary.score,
            reading: monthSummary.reading,
            tip: monthSummary.tip,
            highlights: highlights,
            idiom: idiom,
            lucky: luckyData,
          );
        } else {
          months[monthKey] = MonthData(
            keyword: 'monthly_fortune.fortuneNotReady'.tr(),
            score: 0,
            reading: 'monthly_fortune.monthFortuneNotReady'.tr(namedArgs: {'month': '$i'}),
            tip: '',
          );
        }
      }
    }

    debugPrint('[MonthlyScreen] ✅ 생성된 months: ${months.entries.map((e) => "${e.key}:${e.value.keyword}(highlights=${e.value.hasHighlights},idiom=${e.value.hasIdiom})").join(", ")}');
    return months;
  }

  /// 특정 월의 상세 운세 반환 (이미 로드된 데이터 사용)
  ///
  /// v5.1: API 호출 제거 - 12개월 데이터가 이미 DB에 있으므로
  /// fortune.months에서 직접 반환
  Future<MonthData?> _fetchDetailedMonthFortune(int year, int monthNumber) async {
    debugPrint('[MonthlyFortune] 월 데이터 조회: $year년 $monthNumber월');

    try {
      // 현재 로드된 fortune 데이터에서 가져오기
      final fortune = ref.read(monthlyFortuneProvider).value;
      if (fortune == null) {
        debugPrint('[MonthlyFortune] fortune 데이터 없음');
        return null;
      }

      final monthKey = 'month$monthNumber';
      final monthSummary = fortune.months[monthKey];

      if (monthSummary == null) {
        debugPrint('[MonthlyFortune] $monthKey 데이터 없음');
        return null;
      }

      debugPrint('[MonthlyFortune] ✅ $monthKey 데이터 반환: keyword=${monthSummary.keyword}');

      // v5.3: highlights 변환 (7개 카테고리 - _generate12MonthsData와 동일)
      Map<String, MonthHighlightData>? highlights;
      if (monthSummary.highlights != null) {
        highlights = {};
        final h = monthSummary.highlights!;
        for (final entry in {
          'career': h.career,
          'business': h.business,
          'wealth': h.wealth,
          'love': h.love,
          'marriage': h.marriage,
          'health': h.health,
          'study': h.study,
        }.entries) {
          if (entry.value != null) {
            highlights[entry.key] = MonthHighlightData(
              score: entry.value!.score,
              summary: entry.value!.summary,
            );
          }
        }
      }

      // v5.0: idiom 변환
      MonthIdiomData? idiom;
      if (monthSummary.idiom != null) {
        idiom = MonthIdiomData(
          phrase: monthSummary.idiom!.phrase,
          meaning: monthSummary.idiom!.meaning,
        );
      }

      // v5.3: lucky 변환
      MonthLuckyData? luckyData;
      if (monthSummary.lucky != null) {
        luckyData = MonthLuckyData(
          color: monthSummary.lucky!.color,
          number: monthSummary.lucky!.number,
        );
      }

      return MonthData(
        keyword: monthSummary.keyword,
        score: monthSummary.score,
        reading: monthSummary.reading,
        tip: monthSummary.tip,
        highlights: highlights,
        idiom: idiom,
        lucky: luckyData,
      );
    } catch (e) {
      debugPrint('[MonthlyFortune] 데이터 조회 오류: $e');
      return null;
    }
  }
}
