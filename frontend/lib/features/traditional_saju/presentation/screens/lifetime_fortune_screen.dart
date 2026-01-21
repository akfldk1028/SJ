import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/fortune_shimmer_loading.dart';
import '../../../../shared/widgets/fortune_category_chip_section.dart';
import '../../../../ad/ad_service.dart';
import '../providers/lifetime_fortune_provider.dart';

/// 평생운세 상세 화면 - 책처럼 읽기 쉬운 레이아웃
class LifetimeFortuneScreen extends ConsumerStatefulWidget {
  const LifetimeFortuneScreen({super.key});

  @override
  ConsumerState<LifetimeFortuneScreen> createState() => _LifetimeFortuneScreenState();
}

class _LifetimeFortuneScreenState extends ConsumerState<LifetimeFortuneScreen> {
  /// 세션 기반 잠금해제 상태 (앱 재시작 시 초기화)
  final Set<String> _unlockedCycles = {};
  bool _isLoadingAd = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final fortuneAsync = ref.watch(lifetimeFortuneProvider);

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
          '평생운세',
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
            onPressed: () => ref.read(lifetimeFortuneProvider.notifier).refresh(),
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
            '평생운세를 불러오지 못했습니다',
            style: TextStyle(color: theme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => ref.read(lifetimeFortuneProvider.notifier).refresh(),
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
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '평생운세를 분석하고 있습니다...',
            style: TextStyle(color: theme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'GPT-5.2 분석은 1-2분 정도 소요됩니다',
            style: TextStyle(color: theme.textSecondary.withValues(alpha: 0.7), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppThemeExtension theme, LifetimeFortuneData fortune) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        // 제목
        _buildTitle(theme),
        const SizedBox(height: 32),

        // v7.0: 나의 사주 소개
        if (fortune.mySajuIntro != null && fortune.mySajuIntro!.reading.isNotEmpty) ...[
          _buildMySajuIntroSection(theme, fortune.mySajuIntro!),
          const SizedBox(height: 32),
        ],

        // 요약
        if (fortune.summary.isNotEmpty) ...[
          _buildSection(
            theme,
            title: '나의 사주 요약',
            children: [
              _buildParagraph(theme, fortune.summary),
            ],
          ),
          const SizedBox(height: 32),
        ],

        // 성격 분석
        if (_hasPersonality(fortune.personality)) ...[
          _buildSection(
            theme,
            title: '타고난 성격',
            children: [
              if (fortune.personality.description.isNotEmpty)
                _buildParagraph(theme, fortune.personality.description),
              if (fortune.personality.coreTraits.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '핵심 특성:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...fortune.personality.coreTraits.map((t) => _buildListItem(theme, t)),
              ],
              if (fortune.personality.strengths.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '강점:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...fortune.personality.strengths.map((s) => _buildListItem(theme, s)),
              ],
              if (fortune.personality.weaknesses.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '주의할 점:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...fortune.personality.weaknesses.map((w) => _buildListItem(theme, w)),
              ],
            ],
          ),
          const SizedBox(height: 32),
        ],

        // 분야별 운세 (칩 형태로 표시, 광고 보고 펼치기)
        if (fortune.categories.isNotEmpty) ...[
          FortuneCategoryChipSection(
            fortuneType: 'lifetime',
            title: '평생 분야별 운세',
            categories: fortune.categories.map((key, cat) => MapEntry(
              key,
              CategoryData(
                title: cat.title,
                score: cat.score,
                reading: cat.reading,
              ),
            )),
          ),
          const SizedBox(height: 8),
        ],

        // 인생 주기
        if (_hasLifeCycles(fortune.lifeCycles)) ...[
          _buildSection(
            theme,
            title: '인생 주기별 전망',
            children: [
              // 청년기 (항상 열림)
              if (fortune.lifeCycles.youth.isNotEmpty) ...[
                _buildSubSection(theme, '청년기 (20-35세)', fortune.lifeCycles.youth),
                const SizedBox(height: 12),
              ],
              // 중년기 (광고 필요)
              if (fortune.lifeCycles.middleAge.isNotEmpty) ...[
                _buildLifeCycleCard(
                  theme,
                  cycleKey: 'middleAge',
                  title: '중년기',
                  ageRange: '35-55세',
                  content: fortune.lifeCycles.middleAge,
                ),
                const SizedBox(height: 12),
              ],
              // 후년기 (광고 필요)
              if (fortune.lifeCycles.laterYears.isNotEmpty)
                _buildLifeCycleCard(
                  theme,
                  cycleKey: 'laterYears',
                  title: '후년기',
                  ageRange: '55세 이후',
                  content: fortune.lifeCycles.laterYears,
                ),
              if (fortune.lifeCycles.keyYears.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  '중요 전환점:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...fortune.lifeCycles.keyYears.map((y) => _buildListItem(theme, y)),
              ],
            ],
          ),
          const SizedBox(height: 32),
        ],

        // 행운 정보
        if (_hasLucky(fortune.luckyElements)) ...[
          _buildSection(
            theme,
            title: '행운 정보',
            children: [
              if (fortune.luckyElements.colors.isNotEmpty)
                _buildLuckyItem(theme, '행운의 색상', fortune.luckyElements.colors.join(', ')),
              if (fortune.luckyElements.numbers.isNotEmpty)
                _buildLuckyItem(theme, '행운의 숫자', fortune.luckyElements.numbers.join(', ')),
              if (fortune.luckyElements.directions.isNotEmpty)
                _buildLuckyItem(theme, '좋은 방향', fortune.luckyElements.directions.join(', ')),
              if (fortune.luckyElements.seasons.isNotEmpty)
                _buildLuckyItem(theme, '유리한 계절', fortune.luckyElements.seasons),
              if (fortune.luckyElements.partnerElements.isNotEmpty)
                _buildLuckyItem(theme, '궁합이 좋은 띠', fortune.luckyElements.partnerElements.join(', ')),
            ],
          ),
          const SizedBox(height: 32),
        ],

        // 종합 조언
        if (fortune.overallAdvice.isNotEmpty) ...[
          _buildSection(
            theme,
            title: '종합 인생 조언',
            children: [
              _buildParagraph(theme, fortune.overallAdvice),
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

  Widget _buildTitle(AppThemeExtension theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '평생운세',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '타고난 사주로 본 나의 운명',
          style: TextStyle(
            fontSize: 16,
            color: theme.textSecondary,
          ),
        ),
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

  Widget _buildListItem(AppThemeExtension theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 15,
              color: theme.textSecondary,
              height: 1.6,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: theme.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
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

  Widget _buildConsultButton(BuildContext context, AppThemeExtension theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.go('/saju/chat?type=lifetimeFortune'),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.textPrimary,
          foregroundColor: theme.backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'AI에게 평생운세 상담받기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// v7.0: 나의 사주 소개 섹션 (카드 스타일)
  Widget _buildMySajuIntroSection(AppThemeExtension theme, MySajuIntroSection intro) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.textMuted.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: theme.textPrimary, size: 22),
              const SizedBox(width: 8),
              Text(
                intro.title.isNotEmpty ? intro.title : '나의 사주, 나는 누구인가요?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            intro.reading,
            style: TextStyle(
              fontSize: 15,
              color: theme.textSecondary,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasPersonality(PersonalitySection personality) {
    return personality.description.isNotEmpty ||
        personality.coreTraits.isNotEmpty ||
        personality.strengths.isNotEmpty;
  }

  bool _hasLifeCycles(LifeCyclesSection lifeCycles) {
    return lifeCycles.youth.isNotEmpty ||
        lifeCycles.middleAge.isNotEmpty ||
        lifeCycles.laterYears.isNotEmpty;
  }

  bool _hasLucky(LuckyElementsSection lucky) {
    return lucky.colors.isNotEmpty ||
        lucky.numbers.isNotEmpty ||
        lucky.directions.isNotEmpty ||
        lucky.seasons.isNotEmpty;
  }

  /// 인생 주기 카드 (잠금/해제 상태에 따른 UI)
  Widget _buildLifeCycleCard(
    AppThemeExtension theme, {
    required String cycleKey,
    required String title,
    required String ageRange,
    required String content,
  }) {
    final isUnlocked = _unlockedCycles.contains(cycleKey);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? theme.textMuted.withValues(alpha: 0.3)
              : theme.textMuted.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Text(
                '$title ($ageRange)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              const Spacer(),
              if (!isUnlocked)
                Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: theme.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 내용 또는 잠금 UI
          if (isUnlocked)
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                color: theme.textSecondary,
                height: 1.8,
              ),
            )
          else
            _buildLockedContent(theme, cycleKey, title),
        ],
      ),
    );
  }

  /// 잠금 상태 UI
  Widget _buildLockedContent(AppThemeExtension theme, String cycleKey, String title) {
    return Column(
      children: [
        Text(
          '광고를 시청하면 $title 운세를\n확인할 수 있습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: theme.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoadingAd ? null : () => _showRewardedAdAndUnlock(cycleKey, title),
            icon: _isLoadingAd
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.textSecondary,
                    ),
                  )
                : Icon(Icons.play_circle_outline, size: 20, color: theme.textPrimary),
            label: Text(
              _isLoadingAd ? '광고 로딩 중...' : '광고 보고 $title 확인하기',
              style: TextStyle(
                fontSize: 14,
                color: theme.textPrimary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: theme.textMuted.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 광고 보고 잠금 해제 (기존 FortuneCategoryChipSection 패턴 참고)
  Future<void> _showRewardedAdAndUnlock(String cycleKey, String title) async {
    if (_isLoadingAd) return;

    setState(() => _isLoadingAd = true);

    // 웹에서는 광고 스킵하고 바로 해제 (테스트용)
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _unlockedCycles.add(cycleKey);
          _isLoadingAd = false;
        });
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title 운세가 해제되었습니다! (웹 테스트)'),
              duration: const Duration(seconds: 2),
            ),
          );
        } catch (_) {}
      }
      return;
    }

    // 광고가 로드되어 있는지 확인
    if (!AdService.instance.isRewardedLoaded) {
      await AdService.instance.loadRewardedAd(
        onLoaded: () async {
          final shown = await AdService.instance.showRewardedAd(
            onRewarded: (amount, type) async {
              if (mounted) {
                setState(() {
                  _unlockedCycles.add(cycleKey);
                  _isLoadingAd = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title 운세가 해제되었습니다!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          );

          if (!shown && mounted) {
            setState(() => _isLoadingAd = false);
            _showAdNotReadyDialog(title);
          }
        },
        onFailed: (error) {
          if (mounted) {
            setState(() => _isLoadingAd = false);
            _showAdNotReadyDialog(title);
          }
        },
      );
    } else {
      final shown = await AdService.instance.showRewardedAd(
        onRewarded: (amount, type) async {
          if (mounted) {
            setState(() {
              _unlockedCycles.add(cycleKey);
              _isLoadingAd = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title 운세가 해제되었습니다!'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      );

      if (!shown && mounted) {
        setState(() => _isLoadingAd = false);
        _showAdNotReadyDialog(title);
      }
    }
  }

  void _showAdNotReadyDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('광고 준비 중'),
        content: Text('$title 운세를 보려면 광고를 시청해야 합니다.\n잠시 후 다시 시도해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
