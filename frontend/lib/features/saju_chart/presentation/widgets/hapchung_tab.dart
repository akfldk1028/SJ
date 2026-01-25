import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/saju_chart.dart';
import '../../domain/services/hapchung_service.dart';

/// 합충형파해 탭 위젯
/// 천간합/충, 지지 육합/삼합/방합/충/형/파/해/원진 표시
class HapchungTab extends StatelessWidget {
  final SajuChart chart;

  const HapchungTab({super.key, required this.chart});

  // 관계 타입별 색상 정의
  static const _hapColor = Color(0xFF4CAF50); // 합 - 녹색
  static const _chungColor = Color(0xFFE53935); // 충 - 빨강
  static const _hyungColor = Color(0xFFFF9800); // 형 - 주황
  static const _paColor = Color(0xFF9C27B0); // 파 - 보라
  static const _haeColor = Color(0xFF795548); // 해 - 갈색
  static const _wonjinColor = Color(0xFF607D8B); // 원진 - 청회색

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
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
          // 합충형파해란? 설명 카드
          _buildExplanationCard(context),
          const SizedBox(height: 16),

          // 요약 카드 (개선된 디자인)
          _buildSummaryCard(context, result),
          const SizedBox(height: 24),

          // 합(合) 관계 섹션
          if (result.totalHaps > 0) ...[
            _buildSectionHeader(context, '합(合) 관계', '조화와 화합의 기운', _hapColor, Icons.favorite_rounded),
            const SizedBox(height: 12),
            _buildHapSection(context, result),
            const SizedBox(height: 24),
          ],

          // 충(沖) 관계 섹션
          if (result.totalChungs > 0) ...[
            _buildSectionHeader(context, '충(沖) 관계', '대립과 변화의 기운', _chungColor, Icons.flash_on_rounded),
            const SizedBox(height: 12),
            _buildChungSection(context, result),
            const SizedBox(height: 24),
          ],

          // 형파해원진 섹션 (각각 분리)
          if (result.jijiHyungs.isNotEmpty) ...[
            _buildSectionHeader(context, '형(刑)', '벌과 시련의 기운', _hyungColor, Icons.gavel_rounded),
            const SizedBox(height: 12),
            ...result.jijiHyungs.map((hyung) => _buildRelationCard(
              context,
              type: '형',
              char1: hyung.ji1,
              char2: hyung.ji2,
              pillar1: hyung.pillar1,
              pillar2: hyung.pillar2,
              description: hyung.description,
              color: _hyungColor,
            )),
            const SizedBox(height: 24),
          ],

          if (result.jijiPas.isNotEmpty) ...[
            _buildSectionHeader(context, '파(破)', '파괴와 단절의 기운', _paColor, Icons.broken_image_rounded),
            const SizedBox(height: 12),
            ...result.jijiPas.map((pa) => _buildRelationCard(
              context,
              type: '파',
              char1: pa.ji1,
              char2: pa.ji2,
              pillar1: pa.pillar1,
              pillar2: pa.pillar2,
              description: pa.description,
              color: _paColor,
            )),
            const SizedBox(height: 24),
          ],

          if (result.jijiHaes.isNotEmpty) ...[
            _buildSectionHeader(context, '해(害)', '해침과 방해의 기운', _haeColor, Icons.block_rounded),
            const SizedBox(height: 12),
            ...result.jijiHaes.map((hae) => _buildRelationCard(
              context,
              type: '해',
              char1: hae.ji1,
              char2: hae.ji2,
              pillar1: hae.pillar1,
              pillar2: hae.pillar2,
              description: hae.description,
              color: _haeColor,
            )),
            const SizedBox(height: 24),
          ],

          if (result.wonjins.isNotEmpty) ...[
            _buildSectionHeader(context, '원진(怨嗔)', '원망과 미움의 기운', _wonjinColor, Icons.sentiment_very_dissatisfied_rounded),
            const SizedBox(height: 12),
            ...result.wonjins.map((wonjin) => _buildRelationCard(
              context,
              type: '원진',
              char1: wonjin.ji1,
              char2: wonjin.ji2,
              pillar1: wonjin.pillar1,
              pillar2: wonjin.pillar2,
              description: wonjin.description,
              color: _wonjinColor,
            )),
            const SizedBox(height: 24),
          ],

          // 관계 없음 표시
          if (!result.hasRelations) _buildNoRelationCard(context),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, HapchungAnalysisResult result) {
    final theme = context.appTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.surfaceElevated,
            theme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '합충형파해 분석',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryItem(context, '합', result.totalHaps, _hapColor, Icons.favorite_rounded),
              _buildSummaryDivider(),
              _buildSummaryItem(context, '충', result.totalChungs, _chungColor, Icons.flash_on_rounded),
              _buildSummaryDivider(),
              _buildSummaryItem(context, '형', result.jijiHyungs.length, _hyungColor, Icons.gavel_rounded),
              _buildSummaryDivider(),
              _buildSummaryItem(context, '파', result.jijiPas.length, _paColor, Icons.broken_image_rounded),
              _buildSummaryDivider(),
              _buildSummaryItem(context, '해', result.jijiHaes.length, _haeColor, Icons.block_rounded),
              _buildSummaryDivider(),
              _buildSummaryItem(context, '원진', result.wonjins.length, _wonjinColor, Icons.sentiment_very_dissatisfied_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDivider() {
    return Builder(
      builder: (context) {
        final theme = context.appTheme;
        return Container(
          width: 1,
          height: 50,
          color: theme.border.withOpacity(0.5),
        );
      },
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, int count, Color color, IconData icon) {
    final theme = context.appTheme;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: count > 0 ? color.withOpacity(0.15) : theme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: count > 0 ? color.withOpacity(0.3) : theme.border,
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: count > 0 ? color : theme.textMuted,
              size: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: count > 0 ? color : theme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count',
            style: TextStyle(
              color: count > 0 ? color : theme.textMuted,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle, Color color, IconData icon) {
    final theme = context.appTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHapSection(BuildContext context, HapchungAnalysisResult result) {
    return Column(
      children: [
        // 천간합
        if (result.cheonganHaps.isNotEmpty) ...[
          _buildSubSectionTitle(context, '천간합 (天干合)'),
          const SizedBox(height: 8),
          ...result.cheonganHaps.map((hap) => _buildRelationCard(
            context,
            type: '합',
            char1: hap.gan1,
            char2: hap.gan2,
            pillar1: hap.pillar1,
            pillar2: hap.pillar2,
            description: hap.description,
            color: _hapColor,
          )),
          const SizedBox(height: 16),
        ],

        // 지지육합
        if (result.jijiYukhaps.isNotEmpty) ...[
          _buildSubSectionTitle(context, '지지육합 (地支六合)'),
          const SizedBox(height: 8),
          ...result.jijiYukhaps.map((yukhap) => _buildRelationCard(
            context,
            type: '육합',
            char1: yukhap.ji1,
            char2: yukhap.ji2,
            pillar1: yukhap.pillar1,
            pillar2: yukhap.pillar2,
            description: yukhap.description,
            color: _hapColor,
          )),
          const SizedBox(height: 16),
        ],

        // 삼합
        if (result.jijiSamhaps.isNotEmpty) ...[
          _buildSubSectionTitle(context, '삼합 (三合)'),
          const SizedBox(height: 8),
          ...result.jijiSamhaps.map((samhap) => _buildSamhapCard(context, samhap: samhap)),
          const SizedBox(height: 16),
        ],

        // 방합
        if (result.jijiBanghaps.isNotEmpty) ...[
          _buildSubSectionTitle(context, '방합 (方合)'),
          const SizedBox(height: 8),
          ...result.jijiBanghaps.map((banghap) => _buildBanghapCard(context, banghap: banghap)),
        ],
      ],
    );
  }

  Widget _buildChungSection(BuildContext context, HapchungAnalysisResult result) {
    return Column(
      children: [
        // 천간충
        if (result.cheonganChungs.isNotEmpty) ...[
          _buildSubSectionTitle(context, '천간충 (天干沖)'),
          const SizedBox(height: 8),
          ...result.cheonganChungs.map((chung) => _buildRelationCard(
            context,
            type: '충',
            char1: chung.gan1,
            char2: chung.gan2,
            pillar1: chung.pillar1,
            pillar2: chung.pillar2,
            description: chung.description,
            color: _chungColor,
          )),
          const SizedBox(height: 16),
        ],

        // 지지충
        if (result.jijiChungs.isNotEmpty) ...[
          _buildSubSectionTitle(context, '지지충 (地支沖)'),
          const SizedBox(height: 8),
          ...result.jijiChungs.map((chung) => _buildRelationCard(
            context,
            type: '충',
            char1: chung.ji1,
            char2: chung.ji2,
            pillar1: chung.pillar1,
            pillar2: chung.pillar2,
            description: chung.description,
            color: _chungColor,
          )),
        ],
      ],
    );
  }

  Widget _buildSubSectionTitle(BuildContext context, String title) {
    final theme = context.appTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: theme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // 한자 이름 생성 (형/파/해/원진용)
  String _getHanjaName(String type, String char1, String char2) {
    // 한자 매핑
    const jiToHanja = {
      '자': '子', '축': '丑', '인': '寅', '묘': '卯',
      '진': '辰', '사': '巳', '오': '午', '미': '未',
      '신': '申', '유': '酉', '술': '戌', '해': '亥',
    };
    final hanja1 = jiToHanja[char1] ?? char1;
    final hanja2 = jiToHanja[char2] ?? char2;

    final typeHanja = switch (type) {
      '형' => '刑',
      '파' => '破',
      '해' => '害',
      '원진' => '怨嗔',
      '충' => '沖',
      '합' => '合',
      '육합' => '六合',
      _ => type,
    };

    return '$char1$char2$type($hanja1$hanja2$typeHanja)';
  }

  // 형/파/해/원진 부가 설명
  String? _getRelationExplanation(String type, String char1, String char2) {
    if (type == '형') {
      // 자묘형 (무례지형), 인사신형 (무은지형), 축술미형 (지세지형), 진진형/오오형/유유형/해해형 (자형)
      if ((char1 == '자' && char2 == '묘') || (char1 == '묘' && char2 == '자')) {
        return '무례지형(無禮之刑): 예의 없음으로 인한 형벌. 무례하고 은혜를 모르는 일이 생길 수 있습니다.';
      } else if ((char1 == '인' || char1 == '사' || char1 == '신') &&
                 (char2 == '인' || char2 == '사' || char2 == '신')) {
        return '무은지형(無恩之刑): 은혜 없음으로 인한 형벌. 배신이나 배은망덕한 일이 생길 수 있습니다.';
      } else if ((char1 == '축' || char1 == '술' || char1 == '미') &&
                 (char2 == '축' || char2 == '술' || char2 == '미')) {
        return '지세지형(持勢之刑): 권세를 믿고 함부로 행동. 교만이나 독선으로 문제가 생길 수 있습니다.';
      } else if (char1 == char2) {
        return '자형(自刑): 스스로를 해치는 형. 자기 파괴적 행동이나 내적 갈등이 있을 수 있습니다.';
      }
    } else if (type == '파') {
      return '관계의 단절이나 깨짐을 의미합니다. 일이 중도에 무산되거나 관계가 끊어질 수 있습니다.';
    } else if (type == '해') {
      return '서로를 해치는 관계입니다. 가까운 사람과의 갈등이나 방해가 있을 수 있습니다.';
    } else if (type == '원진') {
      return '원망과 미움의 관계입니다. 해소되지 않는 감정적 앙금이나 갈등이 있을 수 있습니다.';
    }
    return null;
  }

  Widget _buildRelationCard(
    BuildContext context, {
    required String type,
    required String char1,
    required String char2,
    required String pillar1,
    required String pillar2,
    required String description,
    required Color color,
  }) {
    // 형/파/해/원진인 경우 한자 이름과 설명 생성
    final bool showHanjaName = ['형', '파', '해', '원진'].contains(type);
    final hanjaName = showHanjaName ? _getHanjaName(type, char1, char2) : null;
    final explanation = _getRelationExplanation(type, char1, char2);

    final theme = context.appTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 상단: 타입 뱃지와 간지 표시
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                // 타입 뱃지 (크고 눈에 띄게)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    type,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 한자 이름 표시 (형/파/해/원진)
                if (hanjaName != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hanjaName,
                      style: TextStyle(
                        color: color.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                // 간지 표시
                _buildCharacterBox(char1, color),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.sync_alt_rounded,
                    color: color,
                    size: 24,
                  ),
                ),
                _buildCharacterBox(char2, color),
              ],
            ),
          ),
          // 하단: 설명
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: theme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '$pillar1주 ↔ $pillar2주',
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                // 형/파/해/원진 상세 설명
                if (explanation != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: color.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            explanation,
                            style: TextStyle(
                              color: theme.textMuted,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterBox(String char, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSamhapCard(BuildContext context, {required SamhapResult samhap}) {
    final theme = context.appTheme;
    final label = samhap.isFullSamhap ? '삼합' : samhap.displayLabel;
    final isHalfSamhap = !samhap.isFullSamhap;

    // 반합 설명
    String? halfExplanation;
    if (isHalfSamhap) {
      halfExplanation = '삼합의 2글자만 있는 경우로, 완전한 삼합보다 약하지만 화합의 기운이 있습니다.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _hapColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _hapColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _hapColor.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 반합 설명 (연하게)
                if (isHalfSamhap) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '(삼합의 일부)',
                      style: TextStyle(
                        color: _hapColor.withOpacity(0.6),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                ...samhap.jijis.map((ji) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _buildCharacterBox(ji, _hapColor),
                )),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: theme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${samhap.pillars.join(", ")}주',
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  samhap.description,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                // 반합인 경우 추가 설명
                if (halfExplanation != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _hapColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: _hapColor.withOpacity(0.7)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            halfExplanation,
                            style: TextStyle(
                              color: theme.textMuted,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanghapCard(BuildContext context, {required BanghapResult banghap}) {
    final theme = context.appTheme;
    final label = banghap.displayLabel;
    final isHalfBanghap = !banghap.isFullBanghap;

    // 반방합 설명
    String? halfExplanation;
    if (isHalfBanghap) {
      halfExplanation = '방합의 2글자만 있는 경우로, 완전한 방합보다 약하지만 같은 방향의 기운이 모입니다.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _hapColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _hapColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: _hapColor.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${banghap.direction}방 ${banghap.season}',
                        style: TextStyle(
                          color: theme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      if (isHalfBanghap)
                        Text(
                          '(방합의 일부)',
                          style: TextStyle(
                            color: _hapColor.withOpacity(0.6),
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                ...banghap.jijis.map((ji) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _buildCharacterBox(ji, _hapColor),
                )),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banghap.description,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                // 반방합인 경우 추가 설명
                if (halfExplanation != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _hapColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: _hapColor.withOpacity(0.7)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            halfExplanation,
                            style: TextStyle(
                              color: theme.textMuted,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard(BuildContext context) {
    final theme = context.appTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withOpacity(0.1),
            theme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '합충형파해란?',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '사주팔자의 간지(干支)들 사이의 관계를 분석합니다. '
            '합(合)은 화합과 조화를, 충(沖)은 대립과 변화를 의미합니다. '
            '형(刑)·파(破)·해(害)·원진은 갈등과 어려움을 나타냅니다.',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildTermRow('합(合)', '서로 끌어당기고 화합하는 관계 (긍정적)', _hapColor),
                _buildTermRow('충(沖)', '서로 부딪히고 대립하는 관계 (변화)', _chungColor),
                _buildTermRow('형(刑)', '벌과 시련, 법적 문제', _hyungColor),
                _buildTermRow('파(破)', '깨지고 파손되는 관계', _paColor),
                _buildTermRow('해(害)', '방해하고 해치는 관계', _haeColor),
                _buildTermRow('원진(怨嗔)', '원망과 미움의 관계', _wonjinColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermRow(String term, String description, Color color) {
    return Builder(
      builder: (context) {
        final theme = context.appTheme;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  term,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoRelationCard(BuildContext context) {
    final theme = context.appTheme;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '합충형파해 관계가 없습니다',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '사주 내 간지들 간에 특별한 합충 관계가 발견되지 않았습니다.\n안정적인 구조를 가지고 있습니다.',
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
