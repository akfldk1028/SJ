import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../router/routes.dart';
import '../../../profile/domain/entities/saju_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/saju_chart.dart';
import '../providers/saju_chart_provider.dart';
import '../widgets/pillar_column_widget.dart';
import '../widgets/saju_info_header.dart';

/// 만세력 결과 화면
///
/// 포스텔러 스타일 레이아웃:
/// - 헤더: 이름 + 띠 + 생년월일 정보
/// - 사주 테이블: 시주/일주/월주/년주
class SajuChartScreen extends ConsumerWidget {
  const SajuChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(activeProfileProvider);
    final chartAsync = ref.watch(currentSajuChartProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('saju_chart.manseryeok'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.profileEdit),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: 공유 기능
              ShadToaster.of(context).show(
                ShadToast(
                  title: Text('saju_chart.preparing'.tr()),
                  description: Text('saju_chart.shareComingSoon'.tr()),
                ),
              );
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return _buildNoProfile(context);
          }

          return chartAsync.when(
            data: (chart) {
              if (chart == null) {
                return _buildNoChart(context);
              }
              return _buildChartContent(context, ref, profile, chart);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _buildError(context, e.toString()),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(context, e.toString()),
      ),
    );
  }

  Widget _buildNoProfile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'saju_chart.noProfile'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'saju_chart.registerProfileFirst'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          ShadButton(
            onPressed: () => context.go(Routes.profileEdit),
            child: Text('saju_chart.registerProfile'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildNoChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 64,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'saju_chart.cannotCalculateSaju'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ShadButton(
            onPressed: () => context.go(Routes.profileEdit),
            child: Text('saju_chart.editProfile'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'saju_chart.errorOccurred'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartContent(
    BuildContext context,
    WidgetRef ref,
    SajuProfile profile,
    SajuChart chart,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 프로필 정보 헤더
          SajuInfoHeader(
            profile: profile,
            chart: chart,
          ),
          const SizedBox(height: 24),

          // 사주팔자 제목
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome, size: 20),
              const SizedBox(width: 8),
              Text(
                'saju_chart.fourPillars'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.auto_awesome, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              chart.fullSajuHanja,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 사주 테이블 (시주-일주-월주-년주 순서)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 시주
                if (chart.hourPillar != null)
                  PillarColumnWidget(
                    pillar: chart.hourPillar!,
                    label: 'saju_chart.hourPillar'.tr(),
                  )
                else
                  const UnknownHourPillarWidget(),

                _buildPillarDivider(context),

                // 일주 (나)
                PillarColumnWidget(
                  pillar: chart.dayPillar,
                  label: 'saju_chart.dayPillarMe'.tr(),
                  isDayMaster: true,
                ),

                _buildPillarDivider(context),

                // 월주
                PillarColumnWidget(
                  pillar: chart.monthPillar,
                  label: 'saju_chart.monthPillar'.tr(),
                ),

                _buildPillarDivider(context),

                // 년주
                PillarColumnWidget(
                  pillar: chart.yearPillar,
                  label: 'saju_chart.yearPillar'.tr(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 일간 설명
          _buildDayMasterInfo(context, chart),
          const SizedBox(height: 24),

          // 하단 버튼들
          ShadButton(
            onPressed: () {
              context.go(Uri(path: Routes.sajuChat, queryParameters: {'profileId': profile.id}).toString());
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 20),
                const SizedBox(width: 8),
                Text('saju_chart.startAiConsultation'.tr()),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ShadButton.outline(
            onPressed: () => context.go(Routes.sajuGraph),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_tree_outlined, size: 20),
                const SizedBox(width: 8),
                Text('saju_chart.viewRelationGraph'.tr()),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ShadButton.secondary(
            onPressed: () => context.go(Routes.profileEdit),
            child: Text('saju_chart.editProfile'.tr()),
          ),
        ],
      ),
    );
  }

  /// 일간(나) 설명 위젯
  Widget _buildDayMasterInfo(BuildContext context, SajuChart chart) {
    final dayMaster = chart.dayMaster;
    final dayMasterOheng = chart.dayPillar.ganOheng;

    // 일간별 간단한 설명
    final descriptions = {
      '갑': 'saju_chart.dayMasterGap'.tr(),
      '을': 'saju_chart.dayMasterEul'.tr(),
      '병': 'saju_chart.dayMasterByeong'.tr(),
      '정': 'saju_chart.dayMasterJeong'.tr(),
      '무': 'saju_chart.dayMasterMu'.tr(),
      '기': 'saju_chart.dayMasterGi'.tr(),
      '경': 'saju_chart.dayMasterGyeong'.tr(),
      '신': 'saju_chart.dayMasterSin'.tr(),
      '임': 'saju_chart.dayMasterIm'.tr(),
      '계': 'saju_chart.dayMasterGye'.tr(),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'saju_chart.yourDayMaster'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            descriptions[dayMaster] ?? '$dayMaster ($dayMasterOheng)',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'saju_chart.dayMasterExplanation'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 사주 기둥 간 구분선
  Widget _buildPillarDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 200,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
