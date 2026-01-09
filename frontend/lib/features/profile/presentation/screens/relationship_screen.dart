import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../router/routes.dart';
import '../../data/models/profile_relation_model.dart';
import '../providers/profile_provider.dart';
import '../providers/relation_provider.dart';
import '../widgets/relation_category_section.dart';
import '../widgets/relationship_graph/relationship_graph_view.dart';

/// 뷰 모드 타입
enum ViewModeType { list, graph }

/// 뷰 모드 Provider
final viewModeProvider = StateProvider<ViewModeType>((ref) => ViewModeType.graph);

/// 관계 화면 (리스트/그래프 전환 가능)
///
/// Supabase profile_relations 테이블 기반
/// activeProfile을 기준으로 연결된 관계들을 표시
class RelationshipScreen extends ConsumerWidget {
  const RelationshipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(viewModeProvider);
    final activeProfileAsync = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: _buildAppBar(context, ref, viewMode),
      body: activeProfileAsync.when(
        data: (activeProfile) {
          // 활성 프로필이 없으면 프로필 생성 안내
          if (activeProfile == null) {
            return NoActiveProfileState(
              onCreateProfile: () => context.push(Routes.profileEdit),
            );
          }

          // 관계 목록 조회 (카테고리별 그룹핑)
          final relationsByCategoryAsync = ref.watch(
            relationsByCategoryProvider(activeProfile.id),
          );

          return relationsByCategoryAsync.when(
            data: (relationsByCategory) {
              // 관계가 없으면 빈 상태 표시
              if (relationsByCategory.isEmpty) {
                return EmptyRelationState(
                  onAddPressed: () => context.push(Routes.profileEdit),
                );
              }

              return viewMode == ViewModeType.list
                  ? _buildListView(context, ref, relationsByCategory)
                  : const RelationshipGraphView();
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => _buildErrorState(context, err),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildErrorState(context, err),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.profileEdit),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    ViewModeType viewMode,
  ) {
    return AppBar(
      title: const Text('인연 관계도'),
      centerTitle: true,
      actions: [
        // 뷰 모드 토글
        IconButton(
          icon: Icon(
            viewMode == ViewModeType.list
                ? Icons.account_tree_outlined
                : Icons.list_outlined,
          ),
          tooltip: viewMode == ViewModeType.list ? '그래프 보기' : '리스트 보기',
          onPressed: () {
            ref.read(viewModeProvider.notifier).state =
                viewMode == ViewModeType.list
                    ? ViewModeType.graph
                    : ViewModeType.list;
          },
        ),
        // 검색
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // TODO: 검색 기능
          },
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            '오류가 발생했습니다',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    WidgetRef ref,
    Map<String, List<ProfileRelationModel>> relationsByCategory,
  ) {
    // 카테고리 순서 정의
    const categoryOrder = ['가족', '연인', '친구', '직장', '기타'];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        children: [
          // 검색 바
          const Padding(
            padding: EdgeInsets.all(16),
            child: ShadInput(
              placeholder: Text('이름으로 검색'),
              leading: Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.search, size: 16),
              ),
            ),
          ),

          // 카테고리별 섹션
          ...categoryOrder.map((category) {
            final relations = relationsByCategory[category] ?? [];
            return RelationCategorySection(
              categoryLabel: category,
              relations: relations,
              onAddPressed: () => context.push(Routes.profileEdit),
              onRelationTap: (relation) {
                _showRelationDetail(context, ref, relation);
              },
            );
          }),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showRelationDetail(
    BuildContext context,
    WidgetRef ref,
    ProfileRelationModel relation,
  ) {
    // toProfile 정보가 있으면 QuickView 표시
    final toProfile = relation.toProfile;
    if (toProfile != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _RelationQuickViewSheet(
          relation: relation,
          onChatPressed: () {
            Navigator.pop(context);
            // 상대방 프로필 기준 채팅 화면으로 이동
            context.push(
              '${Routes.sajuChat}?profileId=${relation.toProfileId}',
            );
          },
          onEditPressed: () {
            Navigator.pop(context);
            // TODO: 관계 수정 화면
          },
          onDeletePressed: () {
            Navigator.pop(context);
            _showDeleteConfirmation(context, ref, relation);
          },
        ),
      );
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    ProfileRelationModel relation,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('관계 삭제'),
        content: Text('${relation.effectiveDisplayName}님과의 관계를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(relationNotifierProvider.notifier).delete(
                      relationId: relation.id,
                      fromProfileId: relation.fromProfileId,
                    );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${relation.effectiveDisplayName}님과의 관계가 삭제되었습니다'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('삭제 실패: $e'),
                      backgroundColor: Colors.red[400],
                    ),
                  );
                }
              }
            },
            child: Text(
              '삭제',
              style: TextStyle(color: Colors.red[400]),
            ),
          ),
        ],
      ),
    );
  }
}

/// 관계 상세 QuickView Sheet
class _RelationQuickViewSheet extends StatelessWidget {
  final ProfileRelationModel relation;
  final VoidCallback onChatPressed;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  const _RelationQuickViewSheet({
    required this.relation,
    required this.onChatPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    final toProfile = relation.toProfile;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // 아바타
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  relation.effectiveDisplayName.substring(0, 1),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 이름
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  relation.effectiveDisplayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (relation.isFavorite)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.star,
                      size: 20,
                      color: Colors.amber[600],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // 관계 유형
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${relation.categoryLabel} - ${relation.relationLabel}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            // 생년월일
            if (toProfile != null)
              Text(
                _formatBirthDate(toProfile.birthDate),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            // 메모
            if (relation.memo != null && relation.memo!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  relation.memo!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ),
            const SizedBox(height: 24),
            // 액션 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEditPressed,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('수정'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onChatPressed,
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('사주 상담'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 삭제 버튼
            TextButton.icon(
              onPressed: onDeletePressed,
              icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[400]),
              label: Text(
                '관계 삭제',
                style: TextStyle(color: Colors.red[400]),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatBirthDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}
