import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/pillar.dart';
import '../providers/saju_chart_provider.dart';
import 'pillar_display.dart';

class SajuDetailSheet extends ConsumerWidget {
  const SajuDetailSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sajuAnalysisAsync = ref.watch(currentSajuAnalysisProvider);

    return Container(
      constraints: const BoxConstraints(maxHeight: 600),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '사주 상세 분석',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '만세력과 오행 분포를 확인합니다.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          // Content
          Expanded(
            child: sajuAnalysisAsync.when(
              data: (analysis) {
                if (analysis == null) {
                  return const Center(
                    child: Text(
                      '분석 정보를 불러올 수 없습니다.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                final chart = analysis.chart;
                final oheng = analysis.ohengDistribution;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 만세력 차트 (Reference Chart)
                      _buildSectionTitle(context, '만세력 (Four Pillars)'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            PillarDisplay(
                              label: '시주',
                              pillar: chart.hourPillar ??
                                  const Pillar(gan: '?', ji: '?'),
                              size: 32,
                            ),
                            PillarDisplay(
                              label: '일주 (나)',
                              pillar: chart.dayPillar,
                              size: 32,
                            ),
                            PillarDisplay(
                              label: '월주',
                              pillar: chart.monthPillar,
                              size: 32,
                            ),
                            PillarDisplay(
                              label: '년주',
                              pillar: chart.yearPillar,
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 2. 오행 분포 (Five Elements)
                      _buildSectionTitle(context, '오행 분포'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _buildOhengBar(
                                context, '목 (Wood)', oheng.mok, AppColors.wood),
                            _buildOhengBar(
                                context, '화 (Fire)', oheng.hwa, AppColors.fire),
                            _buildOhengBar(context, '토 (Earth)', oheng.to,
                                AppColors.earth),
                            _buildOhengBar(context, '금 (Metal)', oheng.geum,
                                AppColors.metal),
                            _buildOhengBar(
                                context, '수 (Water)', oheng.su, AppColors.water),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '오류가 발생했습니다:\n$err',
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
    );
  }

  Widget _buildOhengBar(BuildContext context, String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                if (count > 0)
                  Container(
                    height: 12,
                    width: count * 40.0, // Scale factor
                    constraints: const BoxConstraints(maxWidth: 200),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$count개',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
