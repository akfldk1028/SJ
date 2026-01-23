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
        title: const Text('만세력'),
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
                const ShadToast(
                  title: Text('준비 중'),
                  description: Text('공유 기능은 곧 추가됩니다'),
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
            '프로필이 없습니다',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '프로필을 먼저 등록해주세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          ShadButton(
            onPressed: () => context.go(Routes.profileEdit),
            child: const Text('프로필 등록하기'),
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
            '사주를 계산할 수 없습니다',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ShadButton(
            onPressed: () => context.go(Routes.profileEdit),
            child: const Text('프로필 수정하기'),
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
            '오류가 발생했습니다',
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
                '사주팔자',
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
                    label: '시주',
                  )
                else
                  const UnknownHourPillarWidget(),

                _buildPillarDivider(context),

                // 일주 (나)
                PillarColumnWidget(
                  pillar: chart.dayPillar,
                  label: '일주 (나)',
                  isDayMaster: true,
                ),

                _buildPillarDivider(context),

                // 월주
                PillarColumnWidget(
                  pillar: chart.monthPillar,
                  label: '월주',
                ),

                _buildPillarDivider(context),

                // 년주
                PillarColumnWidget(
                  pillar: chart.yearPillar,
                  label: '년주',
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
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 20),
                SizedBox(width: 8),
                Text('AI 사주 상담 시작하기'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ShadButton.outline(
            onPressed: () => context.go(Routes.sajuGraph),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_tree_outlined, size: 20),
                SizedBox(width: 8),
                Text('사주 관계도 보기'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ShadButton.secondary(
            onPressed: () => context.go(Routes.profileEdit),
            child: const Text('프로필 수정하기'),
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
      '갑': '갑목(甲木) - 큰 나무처럼 곧고 강직한 성품',
      '을': '을목(乙木) - 풀이나 덩굴처럼 유연하고 적응력 있는 성품',
      '병': '병화(丙火) - 태양처럼 밝고 열정적인 성품',
      '정': '정화(丁火) - 촛불처럼 은은하고 섬세한 성품',
      '무': '무토(戊土) - 산처럼 믿음직하고 안정적인 성품',
      '기': '기토(己土) - 논밭처럼 포용력 있고 실용적인 성품',
      '경': '경금(庚金) - 바위나 철처럼 강하고 결단력 있는 성품',
      '신': '신금(辛金) - 보석처럼 예리하고 섬세한 성품',
      '임': '임수(壬水) - 바다처럼 넓고 지혜로운 성품',
      '계': '계수(癸水) - 시냇물처럼 맑고 직관적인 성품',
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
                '당신의 일간 (日干)',
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
            '일간은 사주팔자에서 "나 자신"을 나타냅니다. '
            'AI 상담에서 더 자세한 해석을 받아보세요.',
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
