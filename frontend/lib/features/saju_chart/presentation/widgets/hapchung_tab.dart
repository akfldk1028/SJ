import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/constants/cheongan_jiji_i18n.dart';
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
    final locale = context.locale.languageCode;
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
            _buildSectionHeader(context, 'saju_chart.hapRelation'.tr(), 'saju_chart.hapchungExplanationBody'.tr().split('\n').first, _hapColor, Icons.favorite_rounded),
            const SizedBox(height: 12),
            _buildHapSection(context, result),
            const SizedBox(height: 24),
          ],

          // 충(沖) 관계 섹션
          if (result.totalChungs > 0) ...[
            _buildSectionHeader(context, 'saju_chart.chungRelation'.tr(), 'saju_chart.hapchungExplanationBody'.tr().split('\n')[1], _chungColor, Icons.flash_on_rounded),
            const SizedBox(height: 12),
            _buildChungSection(context, result),
            const SizedBox(height: 24),
          ],

          // 형파해원진 섹션 (각각 분리)
          if (result.jijiHyungs.isNotEmpty) ...[
            _buildSectionHeader(context, 'saju_chart.hyeongRelation'.tr(), 'saju_chart.hapchungExplanationBody'.tr().split('\n')[2], _hyungColor, Icons.gavel_rounded),
            const SizedBox(height: 12),
            ...result.jijiHyungs.map((hyung) => _buildRelationCard(
              context,
              type: SajuI18n.relationType('형', locale),
              koreanType: '형',
              char1: hyung.ji1,
              char2: hyung.ji2,
              pillar1: hyung.pillar1,
              pillar2: hyung.pillar2,
              description: SajuI18n.hapchungDesc(hyung.description, locale),
              color: _hyungColor,
            )),
            const SizedBox(height: 24),
          ],

          if (result.jijiPas.isNotEmpty) ...[
            _buildSectionHeader(context, 'saju_chart.paRelation'.tr(), 'saju_chart.hapchungExplanationBody'.tr().split('\n')[3], _paColor, Icons.broken_image_rounded),
            const SizedBox(height: 12),
            ...result.jijiPas.map((pa) => _buildRelationCard(
              context,
              type: SajuI18n.relationType('파', locale),
              koreanType: '파',
              char1: pa.ji1,
              char2: pa.ji2,
              pillar1: pa.pillar1,
              pillar2: pa.pillar2,
              description: SajuI18n.hapchungDesc(pa.description, locale),
              color: _paColor,
            )),
            const SizedBox(height: 24),
          ],

          if (result.jijiHaes.isNotEmpty) ...[
            _buildSectionHeader(context, 'saju_chart.haeRelation'.tr(), 'saju_chart.hapchungExplanationBody'.tr().split('\n')[4], _haeColor, Icons.block_rounded),
            const SizedBox(height: 12),
            ...result.jijiHaes.map((hae) => _buildRelationCard(
              context,
              type: SajuI18n.relationType('해', locale),
              koreanType: '해',
              char1: hae.ji1,
              char2: hae.ji2,
              pillar1: hae.pillar1,
              pillar2: hae.pillar2,
              description: SajuI18n.hapchungDesc(hae.description, locale),
              color: _haeColor,
            )),
            const SizedBox(height: 24),
          ],

          if (result.wonjins.isNotEmpty) ...[
            _buildSectionHeader(context, 'saju_chart.wonJinRelation'.tr(), 'saju_chart.hapchungExplanationBody'.tr().split('\n')[5], _wonjinColor, Icons.sentiment_very_dissatisfied_rounded),
            const SizedBox(height: 12),
            ...result.wonjins.map((wonjin) => _buildRelationCard(
              context,
              type: SajuI18n.relationType('원진', locale),
              koreanType: '원진',
              char1: wonjin.ji1,
              char2: wonjin.ji2,
              pillar1: wonjin.pillar1,
              pillar2: wonjin.pillar2,
              description: SajuI18n.hapchungDesc(wonjin.description, locale),
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
            'saju_chart.hapchungTitle'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSummaryItem(context, 'saju_chart.hapRelation'.tr().split('(').first, result.totalHaps, _hapColor, Icons.favorite_rounded),
              _buildSummaryDivider(),
              _buildSummaryItem(context, 'saju_chart.chungRelation'.tr().split('(').first, result.totalChungs, _chungColor, Icons.flash_on_rounded),
              _buildSummaryDivider(),
              _buildSummaryItem(context, 'saju_chart.hyeongRelation'.tr().split('(').first, result.jijiHyungs.length, _hyungColor, Icons.gavel_rounded),
              _buildSummaryDivider(),
              _buildSummaryItem(context, 'saju_chart.paRelation'.tr().split('(').first, result.jijiPas.length, _paColor, Icons.broken_image_rounded),
              _buildSummaryDivider(),
              _buildSummaryItem(context, 'saju_chart.haeRelation'.tr().split('(').first, result.jijiHaes.length, _haeColor, Icons.block_rounded),
              _buildSummaryDivider(),
              _buildSummaryItem(context, 'saju_chart.wonJinRelation'.tr().split('(').first, result.wonjins.length, _wonjinColor, Icons.sentiment_very_dissatisfied_rounded),
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
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
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

  Widget _buildHapSection(BuildContext context, HapchungAnalysisResult result) {
    final locale = context.locale.languageCode;
    return Column(
      children: [
        // 천간합
        if (result.cheonganHaps.isNotEmpty) ...[
          _buildSubSectionTitle(context, 'saju_chart.cheonganHap'.tr()),
          const SizedBox(height: 8),
          ...result.cheonganHaps.map((hap) => _buildRelationCard(
            context,
            type: SajuI18n.relationType('합', locale),
            koreanType: '합',
            char1: hap.gan1,
            char2: hap.gan2,
            pillar1: hap.pillar1,
            pillar2: hap.pillar2,
            description: SajuI18n.hapchungDesc(hap.description, locale),
            color: _hapColor,
          )),
          const SizedBox(height: 16),
        ],

        // 지지육합
        if (result.jijiYukhaps.isNotEmpty) ...[
          _buildSubSectionTitle(context, 'saju_chart.jijiYukhap'.tr()),
          const SizedBox(height: 8),
          ...result.jijiYukhaps.map((yukhap) => _buildRelationCard(
            context,
            type: SajuI18n.relationType('육합', locale),
            koreanType: '육합',
            char1: yukhap.ji1,
            char2: yukhap.ji2,
            pillar1: yukhap.pillar1,
            pillar2: yukhap.pillar2,
            description: SajuI18n.hapchungDesc(yukhap.description, locale),
            color: _hapColor,
          )),
          const SizedBox(height: 16),
        ],

        // 삼합
        if (result.jijiSamhaps.isNotEmpty) ...[
          _buildSubSectionTitle(context, 'saju_chart.samhap'.tr()),
          const SizedBox(height: 8),
          ...result.jijiSamhaps.map((samhap) => _buildSamhapCard(context, samhap: samhap)),
          const SizedBox(height: 16),
        ],

        // 방합
        if (result.jijiBanghaps.isNotEmpty) ...[
          _buildSubSectionTitle(context, 'saju_chart.banghap'.tr()),
          const SizedBox(height: 8),
          ...result.jijiBanghaps.map((banghap) => _buildBanghapCard(context, banghap: banghap)),
        ],
      ],
    );
  }

  Widget _buildChungSection(BuildContext context, HapchungAnalysisResult result) {
    final locale = context.locale.languageCode;
    return Column(
      children: [
        // 천간충
        if (result.cheonganChungs.isNotEmpty) ...[
          _buildSubSectionTitle(context, 'saju_chart.cheonganChung'.tr()),
          const SizedBox(height: 8),
          ...result.cheonganChungs.map((chung) => _buildRelationCard(
            context,
            type: SajuI18n.relationType('충', locale),
            koreanType: '충',
            char1: chung.gan1,
            char2: chung.gan2,
            pillar1: chung.pillar1,
            pillar2: chung.pillar2,
            description: SajuI18n.hapchungDesc(chung.description, locale),
            color: _chungColor,
          )),
          const SizedBox(height: 16),
        ],

        // 지지충
        if (result.jijiChungs.isNotEmpty) ...[
          _buildSubSectionTitle(context, 'saju_chart.jijiChung'.tr()),
          const SizedBox(height: 8),
          ...result.jijiChungs.map((chung) => _buildRelationCard(
            context,
            type: SajuI18n.relationType('충', locale),
            koreanType: '충',
            char1: chung.ji1,
            char2: chung.ji2,
            pillar1: chung.pillar1,
            pillar2: chung.pillar2,
            description: SajuI18n.hapchungDesc(chung.description, locale),
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

  // 한자 이름 생성 (형/파/해/원진용) — locale 인식
  String _getHanjaName(String type, String char1, String char2, String locale) {
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

    final display1 = SajuI18n.jiji(char1, locale);
    final display2 = SajuI18n.jiji(char2, locale);
    final displayType = SajuI18n.relationType(type, locale);

    return '$display1$display2 $displayType($hanja1$hanja2$typeHanja)';
  }

  // 형/파/해/원진 부가 설명 (i18n)
  String? _getRelationExplanation(String type, String char1, String char2) {
    if (type == '형') {
      if ((char1 == '자' && char2 == '묘') || (char1 == '묘' && char2 == '자')) {
        return 'saju_detail.hyung_murye'.tr();
      } else if ((char1 == '인' || char1 == '사' || char1 == '신') &&
                 (char2 == '인' || char2 == '사' || char2 == '신')) {
        return 'saju_detail.hyung_mueun'.tr();
      } else if ((char1 == '축' || char1 == '술' || char1 == '미') &&
                 (char2 == '축' || char2 == '술' || char2 == '미')) {
        return 'saju_detail.hyung_jise'.tr();
      } else if (char1 == char2) {
        return 'saju_detail.hyung_ja'.tr();
      }
    } else if (type == '파') {
      return 'saju_detail.pa_desc'.tr();
    } else if (type == '해') {
      return 'saju_detail.hae_desc'.tr();
    } else if (type == '원진') {
      return 'saju_detail.wonjin_desc'.tr();
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
    String? koreanType,
  }) {
    final locale = context.locale.languageCode;
    // 형/파/해/원진인 경우 한자 이름과 설명 생성 (원본 한글 키로 판별)
    final koType = koreanType ?? type;
    final bool showHanjaName = ['형', '파', '해', '원진'].contains(koType);
    final hanjaName = showHanjaName ? _getHanjaName(koType, char1, char2, locale) : null;
    final explanation = _getRelationExplanation(koType, char1, char2);

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
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                // 간지 표시 (천간 또는 지지)
                _buildCharacterBox(_localizeGanJi(char1, locale), color, koreanChar: char1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.sync_alt_rounded,
                    color: color,
                    size: 24,
                  ),
                ),
                _buildCharacterBox(_localizeGanJi(char2, locale), color, koreanChar: char2),
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
                    Expanded(
                      child: Text(
                        '${SajuI18n.pillarName('${pillar1}주', locale)} ↔ ${SajuI18n.pillarName('${pillar2}주', locale)}',
                        style: TextStyle(
                          color: theme.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                // description 표시: 한국어는 항상 표시, 비한국어는 번역된 경우만
                if (description.isNotEmpty && (locale == 'ko' || !RegExp(r'^[\uAC00-\uD7A3()\s]+$').hasMatch(description))) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
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
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              color: theme.textMuted,
                              fontSize: 13,
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

  /// 천간 또는 지지 한글 → locale별 표시
  /// 천간(갑~계)이면 cheongan, 지지(자~해)이면 jiji로 변환
  String _localizeGanJi(String korean, String locale) {
    const cheonganSet = {'갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'};
    if (cheonganSet.contains(korean)) {
      return SajuI18n.cheongan(korean, locale);
    }
    return SajuI18n.jiji(korean, locale);
  }

  Widget _buildCharacterBox(String localizedChar, Color color, {String? koreanChar}) {
    return Builder(
      builder: (context) {
        final loc = context.locale.languageCode;
        final isCjk = loc == 'ko' || loc == 'ja' || loc == 'zh';
        // Non-CJK: show locale name + 한글(한자)
        if (!isCjk && koreanChar != null && localizedChar != koreanChar) {
          final hanja = _getHanjaForChar(koreanChar);
          return Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.6), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  localizedChar,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  hanja != null ? '$koreanChar($hanja)' : koreanChar,
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          );
        }
        // CJK: show 한자 or 한글 only
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.6), width: 1.5),
          ),
          child: Center(
            child: Text(
              localizedChar,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 한글 간지 → 한자 반환 (천간/지지)
  String? _getHanjaForChar(String korean) {
    // 천간에서 찾기
    final cheonganHanja = SajuI18n.cheongan(korean, 'ja');
    if (cheonganHanja != korean) return cheonganHanja;
    // 지지에서 찾기
    final jijiHanja = SajuI18n.jiji(korean, 'ja');
    if (jijiHanja != korean) return jijiHanja;
    return null;
  }

  Widget _buildSamhapCard(BuildContext context, {required SamhapResult samhap}) {
    final theme = context.appTheme;
    final locale = context.locale.languageCode;
    final label = SajuI18n.relationType(
      samhap.isFullSamhap ? '삼합' : samhap.displayLabel,
      locale,
    );
    final isHalfSamhap = !samhap.isFullSamhap;

    // 반합 설명 (i18n)
    String? halfExplanation;
    if (isHalfSamhap) {
      halfExplanation = 'saju_detail.halfSamhap_desc'.tr();
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
                      'saju_chart.samhapPartial'.tr(),
                      style: TextStyle(
                        color: _hapColor.withOpacity(0.6),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                ...samhap.jijis.map((ji) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _buildCharacterBox(SajuI18n.jiji(ji, context.locale.languageCode), _hapColor, koreanChar: ji),
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
                      samhap.pillars.map((p) => SajuI18n.pillarName('${p}주', context.locale.languageCode)).join(', '),
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  SajuI18n.hapchungDesc(samhap.description, context.locale.languageCode),
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
                              fontSize: 13,
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
    final locale = context.locale.languageCode;
    final label = SajuI18n.relationType(banghap.displayLabel, locale);
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
                        '${SajuI18n.direction(banghap.direction, context.locale.languageCode)} · ${SajuI18n.season(banghap.season, context.locale.languageCode)}',
                        style: TextStyle(
                          color: theme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      if (isHalfBanghap)
                        Text(
                          'saju_chart.banghapPartial'.tr(),
                          style: TextStyle(
                            color: _hapColor.withOpacity(0.6),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                ...banghap.jijis.map((ji) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _buildCharacterBox(SajuI18n.jiji(ji, context.locale.languageCode), _hapColor, koreanChar: ji),
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
                  SajuI18n.hapchungDesc(banghap.description, context.locale.languageCode),
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
                              fontSize: 13,
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
    final locale = context.locale.languageCode;
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
                'saju_chart.hapchungExplanationTitle'.tr(),
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
            'saju_chart.hapchungDetailBody'.tr(),
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
                _buildTermRow(SajuI18n.relationType('합', locale), 'saju_chart.hapTermHap'.tr(), _hapColor),
                _buildTermRow(SajuI18n.relationType('충', locale), 'saju_chart.hapTermChung'.tr(), _chungColor),
                _buildTermRow(SajuI18n.relationType('형', locale), 'saju_chart.hapTermHyung'.tr(), _hyungColor),
                _buildTermRow(SajuI18n.relationType('파', locale), 'saju_chart.hapTermPa'.tr(), _paColor),
                _buildTermRow(SajuI18n.relationType('해', locale), 'saju_chart.hapTermHae'.tr(), _haeColor),
                _buildTermRow(SajuI18n.relationType('원진', locale), 'saju_chart.hapTermWonjin'.tr(), _wonjinColor),
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
                    fontSize: 13,
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
                    fontSize: 13,
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
            'saju_chart.noHapchungRelation'.tr(),
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'saju_chart.noHapchungDescription'.tr(),
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
