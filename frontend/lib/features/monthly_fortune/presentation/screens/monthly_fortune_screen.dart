import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/illustrations/illustrations.dart';
import '../../../../shared/widgets/fortune_shimmer_loading.dart';
import '../../../../shared/widgets/fortune_monthly_chip_section.dart';
import '../../../../AI/fortune/fortune_coordinator.dart';
import '../../../../AI/fortune/common/fortune_input_data.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/monthly_fortune_provider.dart';

/// 월별 운세 상세 화면 - 책처럼 읽기 쉬운 레이아웃
/// v5.0: 광고 해금 시 해당 월 상세 운세 API 호출 지원
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '월별 운세를 불러오지 못했습니다',
            style: TextStyle(color: theme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => ref.read(monthlyFortuneProvider.notifier).refresh(),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzing(AppThemeExtension theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: AnimatedYinYangIllustration(
              size: 100,
              showGlow: true,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '🔮 AI가 월별 운세를 분석하고 있어요',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '잠시만 기다려주세요...',
            style: TextStyle(color: theme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppThemeExtension theme, MonthlyFortuneData fortune) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        // 제목
        _buildTitle(theme, fortune),
        const SizedBox(height: 32),

        // 월간 총운
        _buildSection(
          theme,
          title: '월간 총운',
          children: [
            if (fortune.overview.keyword.isNotEmpty)
              _buildKeyword(theme, fortune.overview.keyword, fortune.overview.score),
            if (fortune.overview.opening.isNotEmpty)
              _buildParagraph(theme, fortune.overview.opening),
            if (fortune.overview.monthEnergy.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSubSection(theme, '이달의 기운', fortune.overview.monthEnergy),
            ],
            if (fortune.overview.hapchungEffect.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSubSection(theme, '합충 영향', fortune.overview.hapchungEffect),
            ],
            if (fortune.overview.conclusion.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSubSection(theme, '결론', fortune.overview.conclusion),
            ],
          ],
        ),
        const SizedBox(height: 32),

        // 분야별 운세 (바로 표시)
        if (fortune.categories.isNotEmpty) ...[
          _buildSection(
            theme,
            title: '이번 달 분야별 운세',
            children: [
              ...fortune.categories.entries.map((entry) {
                final cat = entry.value;
                final categoryName = _getCategoryName(entry.key);
                return _buildCategoryCard(theme, categoryName, cat.score, cat.reading);
              }),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // 월별 운세 (광고 잠금) - 12개월 모두 표시
        // 현재 달은 위에 이미 내용이 보이므로 잠금 해제
        // v5.0: 광고 해금 시 해당 월 상세 운세 API 호출
        FortuneMonthlyChipSection(
          fortuneType: 'monthly_fortune',
          title: '${fortune.year}년 월별 운세',
          months: _generate12MonthsData(fortune),
          currentMonth: fortune.month,
          onMonthUnlocked: (monthNumber) => _fetchDetailedMonthFortune(fortune.year, monthNumber),
        ),
        const SizedBox(height: 32),

        // 행운 정보
        _buildSection(
          theme,
          title: '이달의 행운',
          children: [
            if (fortune.lucky.colors.isNotEmpty)
              _buildLuckyItem(theme, '행운의 색상', fortune.lucky.colors.join(', ')),
            if (fortune.lucky.numbers.isNotEmpty)
              _buildLuckyItem(theme, '행운의 숫자', fortune.lucky.numbers.join(', ')),
            if (fortune.lucky.foods.isNotEmpty)
              _buildLuckyItem(theme, '행운의 음식', fortune.lucky.foods.join(', ')),
            if (fortune.lucky.tip.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildParagraph(theme, fortune.lucky.tip),
            ],
          ],
        ),
        const SizedBox(height: 32),

        // 마무리 메시지
        if (fortune.closingMessage.isNotEmpty) ...[
          _buildSection(
            theme,
            title: '이달의 메시지',
            children: [
              _buildParagraph(theme, fortune.closingMessage),
            ],
          ),
          const SizedBox(height: 32),
        ],

        // AI 상담 버튼
        _buildConsultButton(context, theme),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTitle(AppThemeExtension theme, MonthlyFortuneData fortune) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${fortune.year}년 ${fortune.month}월',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        if (fortune.monthGanji.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            fortune.monthGanji,
            style: TextStyle(
              fontSize: 16,
              color: theme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSection(AppThemeExtension theme, {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildSubSection(AppThemeExtension theme, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: TextStyle(
            fontSize: 15,
            color: theme.textSecondary,
            height: 1.8,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyword(AppThemeExtension theme, String keyword, int score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        '키워드: $keyword  |  총점: $score점',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildParagraph(AppThemeExtension theme, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        color: theme.textSecondary,
        height: 1.8,
      ),
    );
  }

  Widget _buildLuckyItem(AppThemeExtension theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 15,
          color: theme.textSecondary,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildCategoryCard(AppThemeExtension theme, String title, int score, String reading) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textMuted.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              if (score > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(score).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$score점',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _getScoreColor(score),
                    ),
                  ),
                ),
            ],
          ),
          if (reading.isNotEmpty) ...[
            const SizedBox(height: 10),
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
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Widget _buildConsultButton(BuildContext context, AppThemeExtension theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.go('/saju/chat?type=monthlyFortune'),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.textPrimary,
          foregroundColor: theme.backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'AI에게 월운 상담받기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _getCategoryName(String key) {
    // v6.2: 7개 카테고리 전체 지원
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

  /// 12개월 데이터 생성 (v4.0: AI 응답의 months 데이터 사용)
  /// - 현재 월: 상세 데이터 (overview + categories)
  /// - 나머지 11개월: AI 응답의 요약 데이터
  Map<String, MonthData> _generate12MonthsData(MonthlyFortuneData fortune) {
    final currentMonth = fortune.month;
    final months = <String, MonthData>{};

    // 디버그: AI 응답의 months 데이터 확인
    debugPrint('[MonthlyFortune] fortune.months 개수: ${fortune.months.length}');
    debugPrint('[MonthlyFortune] fortune.months keys: ${fortune.months.keys.toList()}');
    for (final entry in fortune.months.entries) {
      debugPrint('[MonthlyFortune] ${entry.key}: keyword=${entry.value.keyword}, score=${entry.value.score}, reading=${entry.value.reading.length}자');
    }

    for (int i = 1; i <= 12; i++) {
      final monthKey = 'month$i';

      if (i == currentMonth) {
        // 현재 월은 상세 데이터 사용
        months[monthKey] = MonthData(
          keyword: fortune.overview.keyword,
          score: fortune.overview.score,
          reading: fortune.overview.opening.isNotEmpty
              ? fortune.overview.opening
              : fortune.overview.conclusion,
          tip: fortune.lucky.tip,
        );
      } else {
        // v4.0: AI 응답의 months 데이터 사용
        final monthSummary = fortune.months[monthKey];
        if (monthSummary != null && monthSummary.keyword.isNotEmpty) {
          months[monthKey] = MonthData(
            keyword: monthSummary.keyword,
            score: monthSummary.score,
            reading: monthSummary.reading,
            tip: '',
          );
        } else {
          // 데이터가 없으면 기본 메시지 (하위 호환)
          months[monthKey] = MonthData(
            keyword: '운세 준비중',
            score: 0,
            reading: '$i월 운세 분석이 아직 준비되지 않았습니다. 새로고침 버튼을 눌러 운세를 다시 불러와주세요.',
            tip: '',
          );
        }
      }
    }

    return months;
  }

  /// v5.0: 특정 월의 상세 운세 API 호출
  ///
  /// 광고 해금 후 호출되어 7개 카테고리 상세 데이터를 가져옴
  /// - year: 대상 연도
  /// - monthNumber: 대상 월 (1-12)
  /// 반환: MonthData (categories 포함)
  Future<MonthData?> _fetchDetailedMonthFortune(int year, int monthNumber) async {
    debugPrint('[MonthlyFortune] 🚀 상세 운세 API 호출: $year년 $monthNumber월');

    try {
      // 1. 현재 사용자 확인
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('[MonthlyFortune] ❌ 사용자 인증 필요');
        return null;
      }

      // 2. 활성 프로필 가져오기
      final activeProfile = await ref.read(activeProfileProvider.future);
      if (activeProfile == null) {
        debugPrint('[MonthlyFortune] ❌ 활성 프로필 없음');
        return null;
      }

      // 3. FortuneCoordinator로 특정 월 운세 분석 호출
      debugPrint('[MonthlyFortune] 📡 API 호출 시작: userId=${user.id}, profileId=${activeProfile.id}');
      final result = await fortuneCoordinator.analyzeMonthly(
        userId: user.id,
        profileId: activeProfile.id,
        inputData: await _getFortuneInputData(activeProfile.id),
        year: year,
        month: monthNumber,
        forceRefresh: true, // 항상 새로 분석
      );

      if (!result.success || result.content == null) {
        debugPrint('[MonthlyFortune] ❌ API 호출 실패: ${result.errorMessage}');
        return null;
      }

      // 4. API 응답을 MonthData로 변환
      debugPrint('[MonthlyFortune] ✅ API 응답 수신, 파싱 시작');
      final content = result.content!;
      final fortuneData = MonthlyFortuneData.fromJson(content);

      // 5. 카테고리 데이터 구성
      final categories = <String, CategoryData>{};
      for (final entry in fortuneData.categories.entries) {
        categories[entry.key] = CategoryData(
          title: _getCategoryName(entry.key),
          score: entry.value.score,
          reading: entry.value.reading,
        );
      }

      debugPrint('[MonthlyFortune] ✅ 상세 운세 로드 완료: ${categories.length}개 카테고리');

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
      debugPrint('[MonthlyFortune] ❌ 상세 운세 로드 실패: $e');
      return null;
    }
  }

  /// FortuneInputData 가져오기 (saju_analyses 기반)
  Future<FortuneInputData> _getFortuneInputData(String profileId) async {
    final supabase = Supabase.instance.client;

    // saju_analyses 조회
    final sajuAnalysesResponse = await supabase
        .from('saju_analyses')
        .select()
        .eq('profile_id', profileId)
        .maybeSingle();

    if (sajuAnalysesResponse == null) {
      throw Exception('saju_analyses가 없습니다.');
    }

    // 프로필 정보 조회
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

    // birth_time_minutes → HH:mm 변환
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
