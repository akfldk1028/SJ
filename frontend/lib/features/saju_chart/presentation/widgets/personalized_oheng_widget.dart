import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/theme/app_theme.dart';
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
                      child: Text(
                        '$dayMaster(${myOheng.hanja})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'saju_chart.ohengRelationByDayMaster'.tr(namedArgs: {'oheng': myOheng.korean}),
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
    final color = _getOhengColor(r.targetOheng);
    final shadTheme = ShadTheme.of(context);

    return ShadAccordionItem(
      value: r,
      title: Row(
        children: [
          // 아이콘
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              r.icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 10),

          // 십신 카테고리 + 관계
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShadBadge.secondary(
                      backgroundColor: color.withValues(alpha: 0.15),
                      foregroundColor: theme.isDark ? Colors.white : color,
                      child: Text(
                        r.category.korean,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: color.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        r.relation,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.textPrimary,
                        ),
                      ),
                    ),
                  ],
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
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.1),
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
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  'saju_chart.interpretation'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              r.description,
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

    return [
      _OhengRelation(
        category: SipSinCategory.bigeop,
        targetOheng: myOheng,
        relation: '${myOheng.korean} = ${myOheng.korean}',
        meaning: 'saju_chart.bigeop_meaning'.tr(),
        icon: LucideIcons.users,
        description: 'saju_chart.bigeop_desc'.tr(),
      ),
      _OhengRelation(
        category: SipSinCategory.siksang,
        targetOheng: iGenerate,
        relation: '${myOheng.korean}생${iGenerate.korean}',
        meaning: 'saju_chart.siksang_meaning'.tr(),
        icon: LucideIcons.sparkles,
        description: 'saju_chart.siksang_desc'.tr(),
      ),
      _OhengRelation(
        category: SipSinCategory.jaeseong,
        targetOheng: iOvercome,
        relation: '${myOheng.korean}극${iOvercome.korean}',
        meaning: 'saju_chart.jaeseong_meaning'.tr(),
        icon: LucideIcons.coins,
        description: 'saju_chart.jaeseong_desc'.tr(),
      ),
      _OhengRelation(
        category: SipSinCategory.gwanseong,
        targetOheng: overcomesMe,
        relation: '${overcomesMe.korean}극${myOheng.korean}',
        meaning: 'saju_chart.gwanseong_meaning'.tr(),
        icon: LucideIcons.briefcase,
        description: 'saju_chart.gwanseong_desc'.tr(),
      ),
      _OhengRelation(
        category: SipSinCategory.inseong,
        targetOheng: generatesMe,
        relation: '${generatesMe.korean}생${myOheng.korean}',
        meaning: 'saju_chart.inseong_meaning'.tr(),
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
  final Oheng targetOheng;
  final String relation;
  final String meaning;
  final IconData icon;
  final String description;

  const _OhengRelation({
    required this.category,
    required this.targetOheng,
    required this.relation,
    required this.meaning,
    required this.icon,
    required this.description,
  });
}
