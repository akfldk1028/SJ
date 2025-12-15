import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/saju_chart.dart';
import '../../domain/services/hapchung_service.dart';

/// 합충형파해 탭 위젯
/// 천간합/충, 지지 육합/삼합/방합/충/형/파/해/원진 표시
class HapchungTab extends StatelessWidget {
  final SajuChart chart;

  const HapchungTab({super.key, required this.chart});

  @override
  Widget build(BuildContext context) {
    // 시주가 없으면 빈 문자열로 대체
    final result = HapchungService.analyzeSaju(
      yearGan: chart.yearPillar.gan,
      monthGan: chart.monthPillar.gan,
      dayGan: chart.dayPillar.gan,
      hourGan: chart.hourPillar?.gan ?? '',
      yearJi: chart.yearPillar.ji,
      monthJi: chart.monthPillar.ji,
      dayJi: chart.dayPillar.ji,
      hourJi: chart.hourPillar?.ji ?? '',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 요약 카드
          _buildSummaryCard(context, result),
          const SizedBox(height: 24),

          // 합(合) 관계 섹션
          if (result.totalHaps > 0) ...[
            _buildSectionTitle(context, '합(合) 관계', Icons.favorite, AppColors.success),
            const SizedBox(height: 12),
            _buildHapSection(context, result),
            const SizedBox(height: 24),
          ],

          // 충(沖) 관계 섹션
          if (result.totalChungs > 0) ...[
            _buildSectionTitle(context, '충(沖) 관계', Icons.flash_on, AppColors.error),
            const SizedBox(height: 12),
            _buildChungSection(context, result),
            const SizedBox(height: 24),
          ],

          // 형파해원진 섹션
          if (result.totalNegatives > 0) ...[
            _buildSectionTitle(context, '형파해원진', Icons.warning_amber, AppColors.warning),
            const SizedBox(height: 12),
            _buildNegativeSection(context, result),
            const SizedBox(height: 24),
          ],

          // 관계 없음 표시
          if (!result.hasRelations)
            _buildNoRelationCard(context),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, HapchungAnalysisResult result) {
    final totalGood = result.totalHaps;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // 합 개수
          Expanded(
            child: _buildSummaryItem(
              context,
              label: '합',
              count: totalGood,
              color: AppColors.success,
              icon: Icons.favorite,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.border,
          ),
          // 충 개수
          Expanded(
            child: _buildSummaryItem(
              context,
              label: '충',
              count: result.totalChungs,
              color: AppColors.error,
              icon: Icons.flash_on,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.border,
          ),
          // 형파해 개수
          Expanded(
            child: _buildSummaryItem(
              context,
              label: '형파해',
              count: result.totalNegatives,
              color: AppColors.warning,
              icon: Icons.warning_amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$count개',
          style: TextStyle(
            color: count > 0 ? color : AppColors.textMuted,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildHapSection(BuildContext context, HapchungAnalysisResult result) {
    return Column(
      children: [
        // 천간합
        if (result.cheonganHaps.isNotEmpty) ...[
          _buildSubSectionTitle(context, '천간합'),
          const SizedBox(height: 8),
          ...result.cheonganHaps.map((hap) => _buildRelationCard(
                context,
                type: '합',
                gan1: hap.gan1,
                gan2: hap.gan2,
                pillar1: hap.pillar1,
                pillar2: hap.pillar2,
                description: hap.description,
                color: AppColors.success,
              )),
          const SizedBox(height: 16),
        ],

        // 지지육합
        if (result.jijiYukhaps.isNotEmpty) ...[
          _buildSubSectionTitle(context, '지지육합'),
          const SizedBox(height: 8),
          ...result.jijiYukhaps.map((yukhap) => _buildRelationCard(
                context,
                type: '육합',
                gan1: yukhap.ji1,
                gan2: yukhap.ji2,
                pillar1: yukhap.pillar1,
                pillar2: yukhap.pillar2,
                description: yukhap.description,
                color: AppColors.success,
              )),
          const SizedBox(height: 16),
        ],

        // 삼합
        if (result.jijiSamhaps.isNotEmpty) ...[
          _buildSubSectionTitle(context, '삼합/반합'),
          const SizedBox(height: 8),
          ...result.jijiSamhaps.map((samhap) => _buildSamhapCard(
                context,
                samhap: samhap,
              )),
          const SizedBox(height: 16),
        ],

        // 방합
        if (result.jijiBanghaps.isNotEmpty) ...[
          _buildSubSectionTitle(context, '방합'),
          const SizedBox(height: 8),
          ...result.jijiBanghaps.map((banghap) => _buildBanghapCard(
                context,
                banghap: banghap,
              )),
        ],
      ],
    );
  }

  Widget _buildChungSection(BuildContext context, HapchungAnalysisResult result) {
    return Column(
      children: [
        // 천간충
        if (result.cheonganChungs.isNotEmpty) ...[
          _buildSubSectionTitle(context, '천간충'),
          const SizedBox(height: 8),
          ...result.cheonganChungs.map((chung) => _buildRelationCard(
                context,
                type: '충',
                gan1: chung.gan1,
                gan2: chung.gan2,
                pillar1: chung.pillar1,
                pillar2: chung.pillar2,
                description: chung.description,
                color: AppColors.error,
              )),
          const SizedBox(height: 16),
        ],

        // 지지충
        if (result.jijiChungs.isNotEmpty) ...[
          _buildSubSectionTitle(context, '지지충'),
          const SizedBox(height: 8),
          ...result.jijiChungs.map((chung) => _buildRelationCard(
                context,
                type: '충',
                gan1: chung.ji1,
                gan2: chung.ji2,
                pillar1: chung.pillar1,
                pillar2: chung.pillar2,
                description: chung.description,
                color: AppColors.error,
              )),
        ],
      ],
    );
  }

  Widget _buildNegativeSection(
      BuildContext context, HapchungAnalysisResult result) {
    return Column(
      children: [
        // 형
        if (result.jijiHyungs.isNotEmpty) ...[
          _buildSubSectionTitle(context, '형(刑)'),
          const SizedBox(height: 8),
          ...result.jijiHyungs.map((hyung) => _buildRelationCard(
                context,
                type: '형',
                gan1: hyung.ji1,
                gan2: hyung.ji2,
                pillar1: hyung.pillar1,
                pillar2: hyung.pillar2,
                description: hyung.description,
                color: AppColors.warning,
              )),
          const SizedBox(height: 16),
        ],

        // 파
        if (result.jijiPas.isNotEmpty) ...[
          _buildSubSectionTitle(context, '파(破)'),
          const SizedBox(height: 8),
          ...result.jijiPas.map((pa) => _buildRelationCard(
                context,
                type: '파',
                gan1: pa.ji1,
                gan2: pa.ji2,
                pillar1: pa.pillar1,
                pillar2: pa.pillar2,
                description: pa.description,
                color: AppColors.warning,
              )),
          const SizedBox(height: 16),
        ],

        // 해
        if (result.jijiHaes.isNotEmpty) ...[
          _buildSubSectionTitle(context, '해(害)'),
          const SizedBox(height: 8),
          ...result.jijiHaes.map((hae) => _buildRelationCard(
                context,
                type: '해',
                gan1: hae.ji1,
                gan2: hae.ji2,
                pillar1: hae.pillar1,
                pillar2: hae.pillar2,
                description: hae.description,
                color: AppColors.warning,
              )),
          const SizedBox(height: 16),
        ],

        // 원진
        if (result.wonjins.isNotEmpty) ...[
          _buildSubSectionTitle(context, '원진(怨嗔)'),
          const SizedBox(height: 8),
          ...result.wonjins.map((wonjin) => _buildRelationCard(
                context,
                type: '원진',
                gan1: wonjin.ji1,
                gan2: wonjin.ji2,
                pillar1: wonjin.pillar1,
                pillar2: wonjin.pillar2,
                description: wonjin.description,
                color: AppColors.warning,
              )),
        ],
      ],
    );
  }

  Widget _buildSubSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRelationCard(
    BuildContext context, {
    required String type,
    required String gan1,
    required String gan2,
    required String pillar1,
    required String pillar2,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // 간지 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGanJiBox(gan1, color),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    type,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildGanJiBox(gan2, color),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 설명
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$pillar1주 ↔ $pillar2주',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGanJiBox(String char, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSamhapCard(BuildContext context, {required SamhapResult samhap}) {
    final color = AppColors.success;
    final label = samhap.isFullSamhap ? '삼합' : '반합';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // 삼합 지지 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: samhap.jijis
                  .map((ji) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _buildGanJiBox(ji, color),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${samhap.pillars.join(", ")}주',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  samhap.description,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanghapCard(
      BuildContext context, {
      required BanghapResult banghap,
    }) {
    final color = AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // 방합 지지 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: banghap.jijis
                  .map((ji) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _buildGanJiBox(ji, color),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '방합',
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${banghap.direction} ${banghap.season}',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  banghap.description,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRelationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.textMuted,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '합충형파해 관계가 없습니다',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '사주 내 간지들 간에 특별한 합충 관계가 발견되지 않았습니다.\n안정적인 구조를 가지고 있습니다.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
