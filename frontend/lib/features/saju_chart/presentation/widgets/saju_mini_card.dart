import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../domain/entities/pillar.dart';
import '../providers/saju_chart_provider.dart';
import 'pillar_display.dart';
import 'saju_detail_sheet.dart';

class SajuMiniCard extends ConsumerWidget {
  const SajuMiniCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sajuChartAsync = ref.watch(currentSajuChartProvider);

    // ⚡ 성능 최적화: watch → listen으로 변경
    // 사주 분석은 UI에 표시하지 않으므로 rebuild 트리거 불필요
    // listen은 side-effect만 실행하고 rebuild하지 않음
    ref.listen(currentSajuAnalysisProvider, (_, __) {});

    return sajuChartAsync.when(
      data: (sajuChart) {
        if (sajuChart == null) {
          return const ShadCard(
            title: Text('만세력'),
            child: Center(
              child: Text('프로필을 선택하여 만세력을 확인하세요'),
            ),
          );
        }

        return ShadCard(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '내 사주 (Four Pillars)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              // 간단한 음양력/평달윤달 표시
              ShadBadge.secondary(
                child: Text(
                  '${sajuChart.isLunarCalendar ? '음력' : '양력'} ${sajuChart.birthDateTime.year}',
                ),
              ),
            ],
          ),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ShadButton.outline(
                size: ShadButtonSize.sm,
                onPressed: () {
                  // Provider container를 bottom sheet에 전달
                  final container = ProviderScope.containerOf(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (sheetContext) => UncontrolledProviderScope(
                      container: container,
                      child: const SajuDetailSheet(),
                    ),
                  );
                },
                child: const Text('자세히 보기'),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 시주 (Time) - 시간 모르면 미정 표시 필요
                PillarDisplay(
                  label: '시주',
                  pillar: sajuChart.hourPillar ??
                      const Pillar(gan: '?', ji: '?'), // Placeholder
                ),
                // 일주 (Day)
                PillarDisplay(
                  label: '일주',
                  pillar: sajuChart.dayPillar,
                ),
                // 월주 (Month)
                PillarDisplay(
                  label: '월주',
                  pillar: sajuChart.monthPillar,
                ),
                // 연주 (Year)
                PillarDisplay(
                  label: '년주',
                  pillar: sajuChart.yearPillar,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const ShadCard(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => ShadCard(
        child: Center(
          child: Text('오류가 발생했습니다: $err'),
        ),
      ),
    );
  }
}
