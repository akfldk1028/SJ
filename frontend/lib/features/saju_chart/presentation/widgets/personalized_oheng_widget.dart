import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/constants/cheongan_jiji_i18n.dart';
import '../../data/constants/sipsin_relations.dart';

/// 개인화된 오행 관계 설명 위젯 - shadcn_ui 기반 모던 UI
class PersonalizedOhengWidget extends StatelessWidget {
  final String dayMaster;
  final AppThemeExtension theme;

  const PersonalizedOhengWidget({
    super.key,
    required this.dayMaster,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final myOheng = cheonganToOheng[dayMaster];
    if (myOheng == null) return const SizedBox.shrink();

    final relations = _calculateRelations(myOheng);

    return ShadCard(
      padding: EdgeInsets.zero,
      backgroundColor: theme.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          _buildHeader(context, myOheng),

          // 구분선
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: theme.primaryColor.withValues(alpha: 0.1),
          ),

          // 아코디언
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: ShadAccordion<_OhengRelation>(
              children: relations.map((r) => _buildAccordionItem(context, r)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Oheng myOheng) {
    final color = _getOhengColor(myOheng);
    final shadTheme = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 오행 아이콘
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              _getOhengIcon(myOheng),
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),

          // 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'saju_chart.myDayMaster'.tr(),
                      style: shadTheme.textTheme.muted.copyWith(fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    ShadBadge(
                      backgroundColor: color.withValues(alpha: 0.15),
                      foregroundColor: color,
                      child: Builder(
                        builder: (ctx) {
                          final locale = ctx.locale.languageCode;
                          final isCjk = locale == 'ko' || locale == 'ja' || locale == 'zh';
                          final ohengDisplay = isCjk ? myOheng.hanja : SajuI18n.oheng(myOheng.korean, locale);
                          return Text(
                            '${SajuI18n.cheongan(dayMaster, locale)}($ohengDisplay)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'saju_chart.ohengRelationByDayMaster'.tr(namedArgs: {'oheng': _ohengI18nKey(myOheng).tr()}),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ShadAccordionItem<_OhengRelation> _buildAccordionItem(
    BuildContext context,
    _OhengRelation r,
  ) {
    final sourceColor = _getOhengColor(r.sourceOheng);
    final targetColor = _getOhengColor(r.targetOheng);

    return ShadAccordionItem(
      value: r,
      title: Row(
        children: [
          // 한자 관계
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: sourceColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: sourceColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Builder(
                    builder: (ctx) {
                      final locale = ctx.locale.languageCode;
                      final isCjk = locale == 'ko' || locale == 'ja' || locale == 'zh';
                      final srcDisplay = isCjk ? r.sourceOheng.hanja : SajuI18n.oheng(r.sourceOheng.korean, locale);
                      final tgtDisplay = isCjk ? r.targetOheng.hanja : SajuI18n.oheng(r.targetOheng.korean, locale);
                      return RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: srcDisplay,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: sourceColor,
                                height: 1.2,
                              ),
                            ),
                            TextSpan(
                              text: ' ${r.connector} ',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textSecondary.withValues(alpha: 0.6),
                                height: 1.2,
                              ),
                            ),
                            TextSpan(
                              text: tgtDisplay,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: targetColor,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  r.meaning,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: targetColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: targetColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.lightbulb,
                  size: 14,
                  color: targetColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'saju_chart.interpretation'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: targetColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              r.description,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: 13,
                height: 1.7,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_OhengRelation> _calculateRelations(Oheng myOheng) {
    final iGenerate = ohengSangsaeng[myOheng]!;
    final iOvercome = ohengSanggeuk[myOheng]!;
    final overcomesMe = _findOhengThatOvercomes(myOheng);
    final generatesMe = _findOhengThatGenerates(myOheng);

    final args = {'oheng': _ohengI18nKey(myOheng).tr()};

    return [
      _OhengRelation(
        category: SipSinCategory.bigeop,
        sourceOheng: myOheng,
        targetOheng: myOheng,
        connector: '=',
        meaning: 'saju_chart.bigeop_meaning'.tr(namedArgs: args),
        icon: LucideIcons.users,
        description: 'saju_chart.bigeop_desc'.tr(),
      ),
      _OhengRelation(
        category: SipSinCategory.siksang,
        sourceOheng: myOheng,
        targetOheng: iGenerate,
        connector: '生',
        meaning: 'saju_chart.siksang_meaning'.tr(namedArgs: args),
        icon: LucideIcons.sparkles,
        description: 'saju_chart.siksang_desc'.tr(),
      ),
      _OhengRelation(
        category: SipSinCategory.jaeseong,
        sourceOheng: myOheng,
        targetOheng: iOvercome,
        connector: '克',
        meaning: 'saju_chart.jaeseong_meaning'.tr(namedArgs: args),
        icon: LucideIcons.coins,
        description: 'saju_chart.jaeseong_desc'.tr(),
      ),
      _OhengRelation(
        category: SipSinCategory.gwanseong,
        sourceOheng: overcomesMe,
        targetOheng: myOheng,
        connector: '克',
        meaning: 'saju_chart.gwanseong_meaning'.tr(namedArgs: args),
        icon: LucideIcons.briefcase,
        description: 'saju_chart.gwanseong_desc'.tr(),
      ),
      _OhengRelation(
        category: SipSinCategory.inseong,
        sourceOheng: generatesMe,
        targetOheng: myOheng,
        connector: '生',
        meaning: 'saju_chart.inseong_meaning'.tr(namedArgs: args),
        icon: LucideIcons.shield,
        description: 'saju_chart.inseong_desc'.tr(),
      ),
    ];
  }

  Oheng _findOhengThatOvercomes(Oheng me) {
    for (final entry in ohengSanggeuk.entries) {
      if (entry.value == me) return entry.key;
    }
    return me;
  }

  Oheng _findOhengThatGenerates(Oheng me) {
    for (final entry in ohengSangsaeng.entries) {
      if (entry.value == me) return entry.key;
    }
    return me;
  }

  /// Oheng enum → i18n key (saju_chart.elementXxx)
  String _ohengI18nKey(Oheng oheng) => switch (oheng) {
    Oheng.mok => 'saju_chart.elementWood',
    Oheng.hwa => 'saju_chart.elementFire',
    Oheng.to => 'saju_chart.elementEarth',
    Oheng.geum => 'saju_chart.elementMetal',
    Oheng.su => 'saju_chart.elementWater',
  };

  Color _getOhengColor(Oheng oheng) {
    switch (oheng) {
      case Oheng.mok:
        return theme.woodColor ?? const Color(0xFF4CAF50);
      case Oheng.hwa:
        return theme.fireColor ?? const Color(0xFFE53935);
      case Oheng.to:
        return theme.earthColor ?? const Color(0xFFD4A574);
      case Oheng.geum:
        return theme.metalColor ?? const Color(0xFF78909C);
      case Oheng.su:
        return theme.waterColor ?? const Color(0xFF2196F3);
    }
  }

  IconData _getOhengIcon(Oheng oheng) {
    switch (oheng) {
      case Oheng.mok:
        return LucideIcons.treePine;
      case Oheng.hwa:
        return LucideIcons.flame;
      case Oheng.to:
        return LucideIcons.mountain;
      case Oheng.geum:
        return LucideIcons.swords;
      case Oheng.su:
        return LucideIcons.droplet;
    }
  }
}

class _OhengRelation {
  final SipSinCategory category;
  final Oheng sourceOheng;
  final Oheng targetOheng;
  final String connector; // "=", "生", "克"
  final String meaning;
  final IconData icon;
  final String description;

  const _OhengRelation({
    required this.category,
    required this.sourceOheng,
    required this.targetOheng,
    required this.connector,
    required this.meaning,
    required this.icon,
    required this.description,
  });
}
