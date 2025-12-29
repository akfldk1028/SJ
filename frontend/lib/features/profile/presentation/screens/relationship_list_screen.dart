import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../router/routes.dart';
import '../../data/models/profile_relation_model.dart';
import '../providers/profile_provider.dart';
import '../providers/relation_provider.dart';
import '../widgets/relation_category_section.dart';

/// 관계 목록 화면 (리스트 뷰 전용)
///
/// Supabase profile_relations 테이블 기반
/// activeProfile을 기준으로 연결된 관계들을 리스트로 표시
class RelationshipListScreen extends ConsumerWidget {
  const RelationshipListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfileAsync = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('인연'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 검색 기능
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              context.go(Routes.profileEdit);
            },
          ),
        ],
      ),
      body: activeProfileAsync.when(
        data: (activeProfile) {
          // 활성 프로필이 없으면 프로필 생성 안내
          if (activeProfile == null) {
            return NoActiveProfileState(
              onCreateProfile: () => context.go(Routes.profileEdit),
            );
          }

          // 관계 목록 조회 (카테고리별 그룹핑)
          final relationsByCategoryAsync = ref.watch(
            relationsByCategoryProvider(activeProfile.id),
          );

          return relationsByCategoryAsync.when(
            data: (relationsByCategory) {
              if (relationsByCategory.isEmpty) {
                return EmptyRelationState(
                  onAddPressed: () => context.go(Routes.profileEdit),
                );
              }
              return _buildList(context, ref, relationsByCategory);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    Map<String, List<ProfileRelationModel>> relationsByCategory,
  ) {
    // 카테고리 순서 정의
    const categoryOrder = ['가족', '연인', '친구', '직장', '기타'];

    return SingleChildScrollView(
      child: Column(
        children: [
          // 검색 바
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: ShadInput(
              placeholder: Text('이름으로 검색'),
              leading: Padding(
                padding: EdgeInsets.all(8.0),
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
              onAddPressed: () => context.go(Routes.profileEdit),
              onRelationTap: (relation) {
                _showRelationOptions(context, ref, relation);
              },
            );
          }),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showRelationOptions(
    BuildContext context,
    WidgetRef ref,
    ProfileRelationModel relation,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text('${relation.effectiveDisplayName}님과 사주 상담'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 채팅 화면으로 이동
                // context.go('/saju/chat?profileId=${relation.toProfileId}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('관계 수정'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 관계 수정 화면
              },
            ),
            ListTile(
              leading: Icon(
                relation.isFavorite ? Icons.star : Icons.star_border,
                color: relation.isFavorite ? Colors.amber[600] : null,
              ),
              title: Text(relation.isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await ref.read(relationNotifierProvider.notifier).toggleFavorite(
                        relationId: relation.id,
                        fromProfileId: relation.fromProfileId,
                        isFavorite: !relation.isFavorite,
                      );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('오류: $e')),
                    );
                  }
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red[400]),
              title: Text(
                '관계 삭제',
                style: TextStyle(color: Colors.red[400]),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, ref, relation);
              },
            ),
          ],
        ),
      ),
    );
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
