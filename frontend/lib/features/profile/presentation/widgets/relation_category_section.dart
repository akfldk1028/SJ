import 'package:flutter/material.dart';
import '../../data/models/profile_relation_model.dart';

/// 관계 카테고리 섹션 위젯 (ProfileRelationModel 기반)
///
/// Supabase profile_relations 테이블 데이터 표시용
/// 카테고리별로 관계 목록을 그룹핑하여 표시
class RelationCategorySection extends StatelessWidget {
  /// 카테고리 라벨 (가족, 연인, 친구, 직장, 기타)
  final String categoryLabel;

  /// 해당 카테고리의 관계 목록
  final List<ProfileRelationModel> relations;

  /// 추가 버튼 콜백 (null이면 버튼 숨김)
  final VoidCallback? onAddPressed;

  /// 관계 항목 탭 콜백
  final Function(ProfileRelationModel) onRelationTap;

  /// 즐겨찾기 토글 콜백 (null이면 아이콘 숨김)
  final Function(ProfileRelationModel, bool)? onFavoriteToggle;

  const RelationCategorySection({
    super.key,
    required this.categoryLabel,
    required this.relations,
    this.onAddPressed,
    required this.onRelationTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    // 빈 섹션은 숨김
    if (relations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$categoryLabel ${relations.length}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (onAddPressed != null)
                GestureDetector(
                  onTap: onAddPressed,
                  child: Icon(
                    Icons.add,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
        // 관계 목록
        ...relations.map((relation) => _buildRelationItem(context, relation)),
      ],
    );
  }

  Widget _buildRelationItem(BuildContext context, ProfileRelationModel relation) {
    final toProfile = relation.toProfile;
    final displayName = relation.effectiveDisplayName;
    final birthDateText = toProfile != null
        ? _formatBirthDate(toProfile.birthDate)
        : '';

    return InkWell(
      onTap: () => onRelationTap(relation),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 아바타
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  displayName.isNotEmpty ? displayName.substring(0, 1) : '?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      // 즐겨찾기 아이콘
                      if (relation.isFavorite)
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber[600],
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      // 관계 유형 라벨
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(context).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          relation.relationLabel,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: _getCategoryColor(context),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                      if (birthDateText.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          birthDateText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // 메모 표시
            if (relation.memo != null && relation.memo!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  relation.memo!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 생년월일 포맷팅
  String _formatBirthDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  /// 카테고리별 색상
  Color _getCategoryColor(BuildContext context) {
    switch (categoryLabel) {
      case '가족':
        return Colors.red[400]!;
      case '연인':
        return Colors.pink[400]!;
      case '친구':
        return Colors.blue[400]!;
      case '직장':
        return Colors.green[400]!;
      default:
        return Colors.grey[600]!;
    }
  }
}

/// 빈 관계 상태 위젯
class EmptyRelationState extends StatelessWidget {
  final VoidCallback? onAddPressed;

  const EmptyRelationState({
    super.key,
    this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            '등록된 인연이 없습니다',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '소중한 사람들의 사주를 등록해보세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          if (onAddPressed != null) ...[
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('인연 등록하기'),
            ),
          ],
        ],
      ),
    );
  }
}

/// 프로필 미선택 상태 위젯
class NoActiveProfileState extends StatelessWidget {
  final VoidCallback? onCreateProfile;

  const NoActiveProfileState({
    super.key,
    this.onCreateProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            '나의 프로필을 먼저 등록해주세요',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '프로필을 등록하면 인연 관계를 추가할 수 있습니다',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          if (onCreateProfile != null) ...[
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onCreateProfile,
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('프로필 등록하기'),
            ),
          ],
        ],
      ),
    );
  }
}
