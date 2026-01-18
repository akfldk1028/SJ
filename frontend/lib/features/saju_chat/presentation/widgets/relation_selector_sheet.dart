import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../profile/data/models/profile_relation_model.dart';
import '../../../profile/data/relation_schema.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/presentation/providers/relation_provider.dart';

/// 단일 인연 선택 결과 (기존 호환용)
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

/// 다중 인연 선택 결과 (Phase 50 신규)
class MultiRelationSelection {
  /// 선택된 관계 모델 목록 (2~4명)
  final List<ProfileRelationModel> relations;

  /// 표시할 멘션 문자열 목록
  final List<String> mentionTexts;

  /// "나" 포함 여부
  final bool includesOwner;

  /// "나"의 프로필 ID (includesOwner=true인 경우)
  final String? ownerProfileId;

  const MultiRelationSelection({
    required this.relations,
    required this.mentionTexts,
    required this.includesOwner,
    this.ownerProfileId,
  });

  /// 참가자 프로필 ID 목록
  List<String> get participantIds {
    final ids = relations.map((r) => r.toProfileId).toList();
    if (includesOwner && ownerProfileId != null && !ids.contains(ownerProfileId)) {
      return [ownerProfileId!, ...ids];
    }
    return ids;
  }

  /// 결합된 멘션 문자열
  String get combinedMentionText => mentionTexts.join(' ');
}

/// 인연 선택 Bottom Sheet
///
/// ## Phase 50 다중 선택 지원
/// - 단일 선택 모드: 기존 동작 (1명 선택 → 즉시 반환)
/// - 다중 선택 모드: 2~4명 선택 + "나 포함/제외" 토글
///
/// ## 사용 예시
/// ```dart
/// // 단일 선택 (기존)
/// final selection = await RelationSelectorSheet.show(context);
///
/// // 다중 선택 (신규)
/// final multiSelection = await RelationSelectorSheet.showMulti(context);
/// ```
class RelationSelectorSheet extends ConsumerWidget {
  /// 단일 선택 콜백
  final void Function(RelationSelection selection)? onSelected;

  const RelationSelectorSheet({
    super.key,
    this.onSelected,
  });

  /// 단일 선택 Bottom Sheet 표시 (기존 호환)
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

  /// 다중 선택 Bottom Sheet 표시 (Phase 50 신규)
  static Future<MultiRelationSelection?> showMulti(BuildContext context) async {
    return showModalBottomSheet<MultiRelationSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _MultiRelationSelectorSheet(),
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

/// 다중 인연 선택 Bottom Sheet (Phase 50 신규)
class _MultiRelationSelectorSheet extends ConsumerStatefulWidget {
  const _MultiRelationSelectorSheet();

  @override
  ConsumerState<_MultiRelationSelectorSheet> createState() =>
      _MultiRelationSelectorSheetState();
}

class _MultiRelationSelectorSheetState
    extends ConsumerState<_MultiRelationSelectorSheet> {
  /// 선택된 인연 목록
  final List<ProfileRelationModel> _selectedRelations = [];

  /// "나" 포함 여부
  bool _includesOwner = true;

  /// "나"의 프로필 ID
  String? _ownerProfileId;

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;
    final activeProfileAsync = ref.watch(activeProfileProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                  Icons.group_outlined,
                  color: appTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '다중 궁합 인연 선택',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: appTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '2~4명을 선택하세요 (선택: ${_selectedRelations.length}명${_includesOwner ? ' + 나' : ''})',
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

          // "나 포함/제외" 토글
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: appTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _includesOwner ? Icons.person : Icons.person_off_outlined,
                    size: 20,
                    color: appTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _includesOwner ? '나를 포함한 궁합' : '나를 제외한 궁합 (선택한 사람들끼리)',
                      style: TextStyle(
                        fontSize: 14,
                        color: appTheme.textPrimary,
                      ),
                    ),
                  ),
                  Switch(
                    value: _includesOwner,
                    onChanged: (value) {
                      setState(() {
                        _includesOwner = value;
                      });
                    },
                    activeColor: appTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ),

          Divider(color: appTheme.primaryColor.withOpacity(0.1), height: 1),

          // 선택된 인연 표시
          if (_selectedRelations.isNotEmpty)
            _buildSelectedChips(appTheme),

          // 인연 목록
          Flexible(
            child: activeProfileAsync.when(
              data: (activeProfile) {
                if (activeProfile == null) {
                  return _buildEmptyState(appTheme, '프로필을 먼저 등록해주세요');
                }
                _ownerProfileId = activeProfile.id;
                return _MultiRelationList(
                  fromProfileId: activeProfile.id,
                  selectedRelations: _selectedRelations,
                  onToggle: _toggleRelation,
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

          // 확인 버튼
          _buildConfirmButton(appTheme),
        ],
      ),
    );
  }

  /// 선택된 인연 칩 표시
  Widget _buildSelectedChips(AppThemeExtension appTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: _selectedRelations.map((relation) {
          return Chip(
            label: Text(
              relation.displayName ?? '이름 없음',
              style: TextStyle(fontSize: 12, color: appTheme.textPrimary),
            ),
            deleteIcon: Icon(Icons.close, size: 16, color: appTheme.textMuted),
            onDeleted: () => _toggleRelation(relation),
            backgroundColor: appTheme.primaryColor.withOpacity(0.1),
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        }).toList(),
      ),
    );
  }

  /// 인연 선택/해제 토글
  void _toggleRelation(ProfileRelationModel relation) {
    setState(() {
      final exists = _selectedRelations.any((r) => r.id == relation.id);
      if (exists) {
        _selectedRelations.removeWhere((r) => r.id == relation.id);
      } else {
        // 최대 4명 (나 포함 시 3명, 나 제외 시 4명)
        final maxCount = _includesOwner ? 3 : 4;
        if (_selectedRelations.length < maxCount) {
          _selectedRelations.add(relation);
        }
      }
    });
  }

  /// 확인 버튼
  Widget _buildConfirmButton(AppThemeExtension appTheme) {
    // 최소 인원 체크 (나 포함: 1명 이상, 나 제외: 2명 이상)
    final minRequired = _includesOwner ? 1 : 2;
    final isValid = _selectedRelations.length >= minRequired;

    // 총 참가자 수 계산
    final totalCount = _includesOwner
        ? _selectedRelations.length + 1
        : _selectedRelations.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isValid ? _confirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: appTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isValid
                  ? '${totalCount}명 궁합 분석 시작'
                  : '최소 ${minRequired}명을 선택해주세요',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 확인 및 반환
  void _confirm() {
    final mentionTexts = _selectedRelations.map((relation) {
      final relationType = ProfileRelationType.fromValue(relation.relationType);
      final displayName = relation.displayName ?? '이름 없음';
      return '@${relationType.categoryLabel}/$displayName';
    }).toList();

    final result = MultiRelationSelection(
      relations: _selectedRelations,
      mentionTexts: mentionTexts,
      includesOwner: _includesOwner,
      ownerProfileId: _ownerProfileId,
    );

    Navigator.of(context).pop(result);
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

/// 다중 선택용 인연 목록 위젯
class _MultiRelationList extends ConsumerWidget {
  final String fromProfileId;
  final List<ProfileRelationModel> selectedRelations;
  final void Function(ProfileRelationModel relation) onToggle;

  const _MultiRelationList({
    required this.fromProfileId,
    required this.selectedRelations,
    required this.onToggle,
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

            return _MultiCategorySection(
              category: category,
              relations: relations,
              selectedRelations: selectedRelations,
              onToggle: onToggle,
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

/// 다중 선택용 카테고리 섹션
class _MultiCategorySection extends StatelessWidget {
  final String category;
  final List<ProfileRelationModel> relations;
  final List<ProfileRelationModel> selectedRelations;
  final void Function(ProfileRelationModel relation) onToggle;

  const _MultiCategorySection({
    required this.category,
    required this.relations,
    required this.selectedRelations,
    required this.onToggle,
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
        ...relations.map((relation) {
          final isSelected = selectedRelations.any((r) => r.id == relation.id);
          return _MultiRelationTile(
            relation: relation,
            isSelected: isSelected,
            onTap: () => onToggle(relation),
          );
        }),
      ],
    );
  }
}

/// 다중 선택용 관계 타일
class _MultiRelationTile extends StatelessWidget {
  final ProfileRelationModel relation;
  final bool isSelected;
  final VoidCallback? onTap;

  const _MultiRelationTile({
    required this.relation,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;
    final relationType = ProfileRelationType.fromValue(relation.relationType);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? appTheme.primaryColor.withOpacity(0.1) : null,
        child: Row(
          children: [
            // 체크박스
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? appTheme.primaryColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? appTheme.primaryColor : appTheme.textMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
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
          ],
        ),
      ),
    );
  }
}

/// 인연 목록 위젯 (단일 선택 - 기존)
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

/// 카테고리 섹션 (단일 선택 - 기존)
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

/// 관계 타일 (단일 선택 - 기존)
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
