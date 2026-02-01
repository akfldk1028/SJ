import 'package:flutter/foundation.dart';
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

/// 궁합/개인사주 선택 결과
///
/// - 2명 선택: 궁합 분석 (합충형해파 1:1)
/// - 1명 선택 (나 제외): 해당 인연의 개인 사주 상담
class CompatibilitySelection {
  /// 선택된 관계 모델 (나 제외한 인연들)
  final List<ProfileRelationModel> relations;

  /// 표시할 멘션 문자열 목록
  final List<String> mentionTexts;

  /// "나" 포함 여부
  final bool includesOwner;

  /// "나"의 프로필 ID (includesOwner=true인 경우)
  final String? ownerProfileId;

  /// 개인 사주 모드 (1명만 선택, 나 아닌 다른 사람의 사주)
  final bool isSinglePersonMode;

  const CompatibilitySelection({
    required this.relations,
    required this.mentionTexts,
    required this.includesOwner,
    this.ownerProfileId,
    this.isSinglePersonMode = false,
  });

  /// 참가자 프로필 ID 목록 (항상 2명)
  /// - 나 포함: [나ID, 상대방ID]
  /// - 나 제외: [상대방1ID, 상대방2ID]
  List<String> get participantIds {
    final ids = relations.map((r) => r.toProfileId).toList();
    if (includesOwner && ownerProfileId != null && !ids.contains(ownerProfileId)) {
      return [ownerProfileId!, ...ids];
    }
    return ids;
  }

  /// 첫 번째 프로필 ID (profile_id용 - 채팅 기준 인물)
  /// - 나 포함: 나의 프로필 ID (ownerProfileId)
  /// - 나 제외: 첫 번째 선택된 인연 ID
  String? get primaryProfileId {
    if (includesOwner) {
      return ownerProfileId;
    }
    if (relations.isEmpty) return null;
    return relations.first.toProfileId;
  }

  /// 궁합 상대방 프로필 ID (target_profile_id용)
  /// - 나 포함: 나가 아닌 상대방 ID (relations의 첫 번째)
  /// - 나 제외: 두 번째 선택된 인연 ID (relations의 두 번째)
  String? get targetProfileId {
    if (relations.isEmpty) return null;
    if (includesOwner) {
      // 나 + 1명: 상대방은 relations의 첫 번째
      return relations.first.toProfileId;
    }
    // 인연 2명: 상대방은 relations의 두 번째
    if (relations.length < 2) return null;
    return relations[1].toProfileId;
  }

  /// 결합된 멘션 문자열
  String get combinedMentionText => mentionTexts.join(' ');
}

/// @deprecated 다중 인연 선택 결과 - v5.0에서 제거됨
/// 궁합은 항상 2명만 가능 (합충형해파는 1:1 관계)
/// CompatibilitySelection을 사용하세요
typedef MultiRelationSelection = CompatibilitySelection;

/// 인연 선택 Bottom Sheet
///
/// ## v5.0 궁합 선택 (항상 2명만)
/// - 단일 선택 모드: 1명 선택 → 즉시 반환
/// - 궁합 선택 모드: 2명만 선택 (나 포함: 나+1명, 나 제외: 2명)
///
/// ## 사용 예시
/// ```dart
/// // 단일 선택 (기존)
/// final selection = await RelationSelectorSheet.show(context);
///
/// // 궁합 선택 (2명만 - v5.0)
/// final compatSelection = await RelationSelectorSheet.showForCompatibility(context);
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

  /// 궁합 선택 Bottom Sheet 표시 (v5.0: 2명만 선택)
  ///
  /// - 나 포함: 나 + 1명 선택 → 딱 2명
  /// - 나 제외: 2명 선택 → 딱 2명
  static Future<CompatibilitySelection?> showForCompatibility(BuildContext context) async {
    return showModalBottomSheet<CompatibilitySelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CompatibilitySelectorSheet(),
    );
  }

  /// @deprecated 다중 선택 - v5.0에서 showForCompatibility로 대체
  static Future<CompatibilitySelection?> showMulti(BuildContext context) async {
    return showForCompatibility(context);
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

/// 궁합 인연 선택 Bottom Sheet (v5.1: 나를 목록에 포함, 최대 2명 선택)
class _CompatibilitySelectorSheet extends ConsumerStatefulWidget {
  const _CompatibilitySelectorSheet();

  @override
  ConsumerState<_CompatibilitySelectorSheet> createState() =>
      _CompatibilitySelectorSheetState();
}

class _CompatibilitySelectorSheetState
    extends ConsumerState<_CompatibilitySelectorSheet> {
  /// 선택된 프로필 ID 목록 (나 포함 가능, 최대 2명)
  final Set<String> _selectedProfileIds = {};

  /// 선택된 인연 모델 (프로필 ID → 모델 매핑용)
  final Map<String, ProfileRelationModel> _selectedRelationModels = {};

  /// "나"의 프로필 ID
  String? _ownerProfileId;

  /// "나"의 이름
  String? _ownerName;

  /// "나" 선택 여부
  bool get _isOwnerSelected => _ownerProfileId != null && _selectedProfileIds.contains(_ownerProfileId);

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
                        '궁합 인연 선택',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: appTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '1명: 개인 사주 · 2명: 궁합 분석 (선택: ${_selectedProfileIds.length}명)',
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

          // 인연 목록 ("나" 포함)
          Flexible(
            child: activeProfileAsync.when(
              data: (activeProfile) {
                if (activeProfile == null) {
                  return _buildEmptyState(appTheme, '프로필을 먼저 등록해주세요');
                }
                _ownerProfileId = activeProfile.id;
                _ownerName = activeProfile.displayName;
                return _CompatibilityRelationList(
                  fromProfileId: activeProfile.id,
                  ownerName: activeProfile.displayName,
                  selectedProfileIds: _selectedProfileIds,
                  onToggleOwner: _toggleOwner,
                  onToggleRelation: _toggleRelation,
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

  /// "나" 선택/해제
  void _toggleOwner() {
    if (_ownerProfileId == null) return;
    setState(() {
      if (_selectedProfileIds.contains(_ownerProfileId)) {
        _selectedProfileIds.remove(_ownerProfileId);
      } else if (_selectedProfileIds.length < 2) {
        _selectedProfileIds.add(_ownerProfileId!);
      }
    });
  }

  /// 인연 선택/해제 토글
  void _toggleRelation(ProfileRelationModel relation) {
    setState(() {
      final profileId = relation.toProfileId;
      if (_selectedProfileIds.contains(profileId)) {
        _selectedProfileIds.remove(profileId);
        _selectedRelationModels.remove(profileId);
      } else if (_selectedProfileIds.length < 2) {
        _selectedProfileIds.add(profileId);
        _selectedRelationModels[profileId] = relation;
      }
    });
  }

  /// 확인 버튼
  Widget _buildConfirmButton(AppThemeExtension appTheme) {
    final count = _selectedProfileIds.length;
    // 1명(나 제외한 인연 1명만) → 개인 사주, 2명 → 궁합
    final isSinglePerson = count == 1 && !_isOwnerSelected;
    final isCompatibility = count == 2;
    final isValid = isSinglePerson || isCompatibility;

    final buttonText = switch (count) {
      0 => '인연을 선택해주세요',
      1 when _isOwnerSelected => '상대방을 선택해주세요',
      1 => '이 사람의 사주 보기',
      2 => '2명 궁합 분석 시작',
      _ => '2명을 선택해주세요',
    };

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
              buttonText,
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
    final selectedRelations = <ProfileRelationModel>[];
    final mentionTexts = <String>[];
    bool includesOwner = false;

    // 1명만 선택 (나 제외) → 개인 사주 모드
    final isSinglePersonMode = _selectedProfileIds.length == 1 && !_isOwnerSelected;

    for (final profileId in _selectedProfileIds) {
      if (profileId == _ownerProfileId) {
        // "나" 선택됨
        includesOwner = true;
        mentionTexts.add('@나/${_ownerName ?? "나"}');
      } else {
        // 인연에서 찾기
        final relation = _selectedRelationModels[profileId];
        if (relation != null) {
          selectedRelations.add(relation);
          final relationType = ProfileRelationType.fromValue(relation.relationType);
          mentionTexts.add('@${relationType.categoryLabel}/${relation.displayName ?? "이름 없음"}');
        }
      }
    }

    final result = CompatibilitySelection(
      relations: selectedRelations,
      mentionTexts: mentionTexts,
      includesOwner: includesOwner,
      ownerProfileId: _ownerProfileId,
      isSinglePersonMode: isSinglePersonMode,
    );

    if (kDebugMode) {
      print('[RelationSelector] 선택 완료:');
      print('  - isSinglePersonMode: $isSinglePersonMode');
      print('  - includesOwner: $includesOwner');
      print('  - ownerProfileId: $_ownerProfileId');
      print('  - selectedRelations: ${selectedRelations.map((r) => "${r.displayName}(${r.toProfileId})").toList()}');
      print('  - participantIds: ${result.participantIds}');
      print('  - targetProfileId: ${result.targetProfileId}');
    }

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

/// 궁합 선택용 인연 목록 (나 포함)
class _CompatibilityRelationList extends ConsumerWidget {
  final String fromProfileId;
  final String? ownerName;
  final Set<String> selectedProfileIds;
  final VoidCallback onToggleOwner;
  final void Function(ProfileRelationModel relation) onToggleRelation;

  const _CompatibilityRelationList({
    required this.fromProfileId,
    required this.ownerName,
    required this.selectedProfileIds,
    required this.onToggleOwner,
    required this.onToggleRelation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = context.appTheme;
    final relationsAsync = ref.watch(relationsByCategoryProvider(fromProfileId));

    return relationsAsync.when(
      data: (categoryMap) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            // "나" 섹션 (맨 위)
            _buildOwnerSection(context, appTheme),

            // 카테고리별 인연 목록
            ..._buildCategorySections(categoryMap, appTheme),
          ],
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
          child: Text('오류: $e', style: TextStyle(color: appTheme.textMuted)),
        ),
      ),
    );
  }

  /// "나" 섹션 빌드
  Widget _buildOwnerSection(BuildContext context, AppThemeExtension appTheme) {
    final isSelected = selectedProfileIds.contains(fromProfileId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "나" 카테고리 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.person, size: 18, color: appTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                '나',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: appTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // "나" 타일
        InkWell(
          onTap: onToggleOwner,
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
                    color: appTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Text(
                      ownerName?.isNotEmpty == true ? ownerName![0] : '나',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: appTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 이름
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ownerName ?? '나',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: appTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '본인',
                        style: TextStyle(
                          fontSize: 13,
                          color: appTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // 별표 (나는 항상 표시)
                const Icon(Icons.star, size: 20, color: Colors.amber),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 카테고리별 섹션 빌드
  List<Widget> _buildCategorySections(
    Map<String, List<ProfileRelationModel>> categoryMap,
    AppThemeExtension appTheme,
  ) {
    if (categoryMap.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              '등록된 인연이 없습니다\n인연 목록에서 새 인연을 추가해주세요',
              style: TextStyle(fontSize: 14, color: appTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    // 카테고리 순서 정의
    final categoryOrder = ['가족', '연인', '친구', '직장', '기타'];
    final sortedCategories = categoryMap.keys.toList()
      ..sort((a, b) {
        final aIndex = categoryOrder.indexOf(a);
        final bIndex = categoryOrder.indexOf(b);
        return (aIndex == -1 ? 999 : aIndex) - (bIndex == -1 ? 999 : bIndex);
      });

    return sortedCategories.map((category) {
      final relations = categoryMap[category] ?? [];
      return _MultiCategorySection(
        category: category,
        relations: relations,
        selectedRelations: relations.where((r) => selectedProfileIds.contains(r.toProfileId)).toList(),
        onToggle: onToggleRelation,
      );
    }).toList();
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
