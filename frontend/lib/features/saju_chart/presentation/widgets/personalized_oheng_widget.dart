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
                      '나의 일간',
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
                  '${myOheng.korean} 오행 기준 나의 관계도',
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
                  '해석',
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
        meaning: '친구, 형제, 경쟁자',
        icon: LucideIcons.users,
        description:
            '나와 같은 오행을 가진 사람들입니다. 서로 이해하고 공감하기 쉬워 친구나 동료가 되기 좋습니다. 하지만 같은 것을 추구하기에 경쟁 관계가 될 수도 있어요. 비겁이 강하면 독립심과 자존심이 강한 편입니다.',
      ),
      _OhengRelation(
        category: SipSinCategory.siksang,
        targetOheng: iGenerate,
        relation: '${myOheng.korean}생${iGenerate.korean}',
        meaning: '표현력, 재능, 창작',
        icon: LucideIcons.sparkles,
        description:
            '내가 에너지를 내어 만들어내는 기운입니다. 말솜씨, 글재주, 예술적 재능으로 나타나요. 식상이 강하면 자기표현을 잘하고 끼가 많습니다. 자녀운과도 연결되어, 아이디어나 작품을 "낳는다"고 해석하기도 해요.',
      ),
      _OhengRelation(
        category: SipSinCategory.jaeseong,
        targetOheng: iOvercome,
        relation: '${myOheng.korean}극${iOvercome.korean}',
        meaning: '재물운, 관리능력',
        icon: LucideIcons.coins,
        description:
            '내가 컨트롤하고 다스리는 기운이에요. 돈을 벌고 관리하는 능력, 현실적인 감각과 연결됩니다. 재성이 강하면 재물에 대한 욕심이 있고 실리적입니다. 남자에게는 아내나 여자친구를 의미하기도 해요.',
      ),
      _OhengRelation(
        category: SipSinCategory.gwanseong,
        targetOheng: overcomesMe,
        relation: '${overcomesMe.korean}극${myOheng.korean}',
        meaning: '직장, 규율, 책임감',
        icon: LucideIcons.briefcase,
        description:
            '나를 제어하고 규율하는 기운입니다. 직장, 직업, 사회적 규범과 연결돼요. 관성이 적절하면 책임감 있고 사회적으로 인정받습니다. 너무 강하면 스트레스나 압박감을 느낄 수 있어요. 여자에게는 남편이나 남자친구를 의미하기도 합니다.',
      ),
      _OhengRelation(
        category: SipSinCategory.inseong,
        targetOheng: generatesMe,
        relation: '${generatesMe.korean}생${myOheng.korean}',
        meaning: '도움, 보호, 학업',
        icon: LucideIcons.shield,
        description:
            '나를 길러주고 보호하는 기운이에요. 어머니, 스승, 귀인의 도움과 연결됩니다. 인성이 강하면 학문을 좋아하고 사려 깊습니다. 문서운, 자격증운과도 관계가 있어 공부나 시험에 유리할 수 있어요.',
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
