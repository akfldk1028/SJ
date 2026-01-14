import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../profile/data/models/profile_relation_model.dart';
import '../../../profile/data/relation_schema.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/presentation/providers/relation_provider.dart';

/// 인연 선택 결과
class RelationSelection {
  /// 선택된 관계 모델
  final ProfileRelationModel relation;

  /// 표시할 멘션 문자열 (예: "@친구/김동현")
  final String mentionText;

  const RelationSelection({
    required this.relation,
    required this.mentionText,
  });
}

/// 인연 선택 Bottom Sheet
///
/// + 버튼 클릭 시 바로 인연 목록 표시
/// 인연을 선택하면 궁합 채팅 시작
class RelationSelectorSheet extends ConsumerWidget {
  /// 선택 콜백
  final void Function(RelationSelection selection)? onSelected;

  const RelationSelectorSheet({
    super.key,
    this.onSelected,
  });

  /// Bottom Sheet 표시
  static Future<RelationSelection?> show(BuildContext context) async {
    return showModalBottomSheet<RelationSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RelationSelectorSheet(
        onSelected: (selection) {
          Navigator.of(context).pop(selection);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = context.appTheme;
    final activeProfileAsync = ref.watch(activeProfileProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: appTheme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들 바
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: appTheme.textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.people_outline,
                  color: appTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '인연 선택',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: appTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '상대방을 선택하면 궁합 분석 채팅이 시작됩니다',
                        style: TextStyle(
                          fontSize: 13,
                          color: appTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: appTheme.primaryColor.withOpacity(0.1), height: 1),
          // 인연 목록
          Flexible(
            child: activeProfileAsync.when(
              data: (activeProfile) {
                if (activeProfile == null) {
                  return _buildEmptyState(appTheme, '프로필을 먼저 등록해주세요');
                }
                return _RelationList(
                  fromProfileId: activeProfile.id,
                  onSelected: onSelected,
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => _buildEmptyState(appTheme, '오류: $e'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppThemeExtension appTheme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 48,
              color: appTheme.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: appTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// 인연 목록 위젯
class _RelationList extends ConsumerWidget {
  final String fromProfileId;
  final void Function(RelationSelection selection)? onSelected;

  const _RelationList({
    required this.fromProfileId,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = context.appTheme;
    final relationsAsync = ref.watch(relationsByCategoryProvider(fromProfileId));

    return relationsAsync.when(
      data: (categoryMap) {
        if (categoryMap.isEmpty) {
          return _buildEmptyState(appTheme);
        }

        // 카테고리 순서 정의
        final categoryOrder = ['가족', '연인', '친구', '직장', '기타'];
        final sortedCategories = categoryMap.keys.toList()
          ..sort((a, b) {
            final aIndex = categoryOrder.indexOf(a);
            final bIndex = categoryOrder.indexOf(b);
            return (aIndex == -1 ? 999 : aIndex) - (bIndex == -1 ? 999 : bIndex);
          });

        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: sortedCategories.length,
          itemBuilder: (context, index) {
            final category = sortedCategories[index];
            final relations = categoryMap[category] ?? [];

            return _CategorySection(
              category: category,
              relations: relations,
              onSelected: onSelected,
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            '오류: $e',
            style: TextStyle(color: appTheme.textMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppThemeExtension appTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 48,
              color: appTheme.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              '등록된 인연이 없습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: appTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '인연 목록에서 새 인연을 추가해주세요',
              style: TextStyle(
                fontSize: 13,
                color: appTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 카테고리 섹션
class _CategorySection extends StatelessWidget {
  final String category;
  final List<ProfileRelationModel> relations;
  final void Function(RelationSelection selection)? onSelected;

  const _CategorySection({
    required this.category,
    required this.relations,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    // 카테고리별 아이콘
    final categoryIcon = switch (category) {
      '가족' => Icons.home_outlined,
      '연인' => Icons.favorite_outline,
      '친구' => Icons.people_outline,
      '직장' => Icons.work_outline,
      _ => Icons.person_outline,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 카테고리 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(
                categoryIcon,
                size: 18,
                color: appTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                category,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: appTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: appTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${relations.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: appTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 관계 목록
        ...relations.map((relation) => _RelationTile(
              relation: relation,
              onTap: () {
                final relationType = ProfileRelationType.fromValue(relation.relationType);
                final displayName = relation.displayName ?? '이름 없음';
                final mentionText = '@${relationType.categoryLabel}/$displayName';
                onSelected?.call(RelationSelection(
                  relation: relation,
                  mentionText: mentionText,
                ));
              },
            )),
      ],
    );
  }
}

/// 관계 타일
class _RelationTile extends StatelessWidget {
  final ProfileRelationModel relation;
  final VoidCallback? onTap;

  const _RelationTile({
    required this.relation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;
    final relationType = ProfileRelationType.fromValue(relation.relationType);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 아바타
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: appTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: Text(
                  (relation.displayName?.isNotEmpty ?? false)
                      ? relation.displayName![0]
                      : '?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: appTheme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 이름 & 관계 유형
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    relation.displayName ?? '이름 없음',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: appTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    relationType.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      color: appTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // 즐겨찾기 아이콘
            if (relation.isFavorite)
              const Icon(
                Icons.star,
                size: 20,
                color: Colors.amber,
              ),
            const SizedBox(width: 8),
            // 화살표
            Icon(
              Icons.chevron_right,
              size: 24,
              color: appTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
