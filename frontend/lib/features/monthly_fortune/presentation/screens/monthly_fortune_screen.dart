import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/fortune_shimmer_loading.dart';
import '../../../../shared/widgets/fortune_monthly_chip_section.dart';
import '../../../../shared/widgets/fortune_title_header.dart';
import '../../../../shared/widgets/fortune_section_card.dart';
import '../../../../shared/widgets/fortune_score_gauge.dart';
import '../../../../AI/fortune/fortune_coordinator.dart';
import '../../../../AI/fortune/common/fortune_input_data.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
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
          '이번 달 운세',
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
        error: (error, stack) => _buildError(context, theme),
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
              '월별 운세를 불러오지 못했습니다',
              style: TextStyle(color: theme.textSecondary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(monthlyFortuneProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('다시 시도'),
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
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '월별 운세를 분석하고 있습니다...',
            style: TextStyle(color: theme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '잠시만 기다려주세요',
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
          title: '${fortune.year}년 ${fortune.month}월',
          subtitle: fortune.monthGanji,
          keyword: fortune.overview.keyword.isNotEmpty ? fortune.overview.keyword : null,
          score: fortune.overview.score > 0 ? fortune.overview.score : null,
          style: HeaderStyle.hero,
        ),
        const SizedBox(height: 28),

        // 월간 총운
        FortuneSectionCard(
          title: '월간 총운',
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
                  label: '이달의 기운',
                  content: fortune.overview.monthEnergy,
                  type: HighlightType.info,
                  icon: Icons.bolt,
                ),
              ],
              if (fortune.overview.hapchungEffect.isNotEmpty) ...[
                const SizedBox(height: 12),
                FortuneHighlightBox(
                  label: '합충 영향',
                  content: fortune.overview.hapchungEffect,
                  type: HighlightType.warning,
                ),
              ],
              if (fortune.overview.conclusion.isNotEmpty) ...[
                const SizedBox(height: 16),
                FortuneHighlightBox(
                  label: '결론',
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
          const FortuneSectionTitle(
            title: '이번 달 분야별 운세',
            icon: Icons.grid_view,
          ),
          const SizedBox(height: 12),
          _buildCategoryGrid(theme, fortune.categories),
          const SizedBox(height: 24),
        ],

        // 월별 운세 (12개월 칩)
        const FortuneSectionTitle(
          title: '연간 월별 운세',
          subtitle: '탭하여 다른 월 운세를 확인하세요',
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
          title: '이달의 행운',
          icon: Icons.star,
          style: CardStyle.gradient,
          child: _buildLuckyGrid(theme, fortune.lucky),
        ),
        const SizedBox(height: 24),

        // 마무리 메시지
        if (fortune.closingMessage.isNotEmpty) ...[
          FortuneSectionCard(
            title: '이달의 메시지',
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

  /// 분야별 운세 그리드
  Widget _buildCategoryGrid(AppThemeExtension theme, Map<String, CategorySection> categories) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: categories.entries.map((entry) {
        final cat = entry.value;
        final categoryName = _getCategoryName(entry.key);
        final icon = _getCategoryIcon(entry.key);
        return _buildCategoryCard(theme, categoryName, cat.score, cat.reading, icon);
      }).toList(),
    );
  }

  Widget _buildCategoryCard(AppThemeExtension theme, String title, int score, String reading, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.textMuted.withValues(alpha: 0.15)),
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
            ],
          ),
          const Spacer(),
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
      ),
    );
  }

  /// 행운 정보 그리드
  Widget _buildLuckyGrid(AppThemeExtension theme, LuckySection lucky) {
    final items = <Map<String, dynamic>>[];

    if (lucky.colors.isNotEmpty) {
      items.add({'icon': Icons.palette, 'label': '행운의 색상', 'value': lucky.colors.join(', ')});
    }
    if (lucky.numbers.isNotEmpty) {
      items.add({'icon': Icons.pin, 'label': '행운의 숫자', 'value': lucky.numbers.join(', ')});
    }
    if (lucky.foods.isNotEmpty) {
      items.add({'icon': Icons.restaurant, 'label': '행운의 음식', 'value': lucky.foods.join(', ')});
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
        label: const Text(
          'AI에게 월운 상담받기',
          style: TextStyle(
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
    const names = {
      'career': '직업운',
      'business': '사업운',
      'wealth': '재물운',
      'love': '애정운',
      'marriage': '결혼운',
      'study': '학업운',
      'health': '건강운',
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

  /// 12개월 데이터 생성
  Map<String, MonthData> _generate12MonthsData(MonthlyFortuneData fortune) {
    final currentMonth = fortune.month;
    final months = <String, MonthData>{};

    for (int i = 1; i <= 12; i++) {
      final monthKey = 'month$i';

      if (i == currentMonth) {
        months[monthKey] = MonthData(
          keyword: fortune.overview.keyword,
          score: fortune.overview.score,
          reading: fortune.overview.opening.isNotEmpty
              ? fortune.overview.opening
              : fortune.overview.conclusion,
          tip: fortune.lucky.tip,
        );
      } else {
        final monthSummary = fortune.months[monthKey];
        if (monthSummary != null && monthSummary.keyword.isNotEmpty) {
          months[monthKey] = MonthData(
            keyword: monthSummary.keyword,
            score: monthSummary.score,
            reading: monthSummary.reading,
            tip: '',
          );
        } else {
          months[monthKey] = MonthData(
            keyword: '운세 준비중',
            score: 0,
            reading: '$i월 운세 분석이 아직 준비되지 않았습니다.',
            tip: '',
          );
        }
      }
    }

    return months;
  }

  /// 특정 월의 상세 운세 API 호출
  Future<MonthData?> _fetchDetailedMonthFortune(int year, int monthNumber) async {
    debugPrint('[MonthlyFortune] API call: $year년 $monthNumber월');

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      final activeProfile = await ref.read(activeProfileProvider.future);
      if (activeProfile == null) return null;

      final result = await fortuneCoordinator.analyzeMonthly(
        userId: user.id,
        profileId: activeProfile.id,
        inputData: await _getFortuneInputData(activeProfile.id),
        year: year,
        month: monthNumber,
        forceRefresh: true,
      );

      if (!result.success || result.content == null) return null;

      final fortuneData = MonthlyFortuneData.fromJson(result.content!);

      final categories = <String, CategoryData>{};
      for (final entry in fortuneData.categories.entries) {
        categories[entry.key] = CategoryData(
          title: _getCategoryName(entry.key),
          score: entry.value.score,
          reading: entry.value.reading,
        );
      }

      return MonthData(
        keyword: fortuneData.overview.keyword,
        score: fortuneData.overview.score,
        reading: fortuneData.overview.opening.isNotEmpty
            ? fortuneData.overview.opening
            : fortuneData.overview.conclusion,
        tip: fortuneData.lucky.tip,
        categories: categories,
      );
    } catch (e) {
      debugPrint('[MonthlyFortune] API error: $e');
      return null;
    }
  }

  /// FortuneInputData 가져오기
  Future<FortuneInputData> _getFortuneInputData(String profileId) async {
    final supabase = Supabase.instance.client;

    final sajuAnalysesResponse = await supabase
        .from('saju_analyses')
        .select()
        .eq('profile_id', profileId)
        .maybeSingle();

    if (sajuAnalysesResponse == null) {
      throw Exception('saju_analyses가 없습니다.');
    }

    final profileResponse = await supabase
        .from('saju_profiles')
        .select('display_name, birth_date, birth_time_minutes, gender')
        .eq('id', profileId)
        .maybeSingle();

    if (profileResponse == null) {
      throw Exception('프로필을 찾을 수 없습니다.');
    }

    final profileName = profileResponse['display_name'] as String? ?? '';
    final birthDate = profileResponse['birth_date'] as String? ?? '';
    final birthTimeMinutes = profileResponse['birth_time_minutes'] as int?;
    final gender = profileResponse['gender'] as String? ?? 'M';

    String? birthTime;
    if (birthTimeMinutes != null) {
      final hours = birthTimeMinutes ~/ 60;
      final minutes = birthTimeMinutes % 60;
      birthTime = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }

    return FortuneInputData.fromSajuAnalyses(
      profileName: profileName,
      birthDate: birthDate,
      birthTime: birthTime,
      gender: gender,
      sajuAnalyses: sajuAnalysesResponse,
    );
  }
}
