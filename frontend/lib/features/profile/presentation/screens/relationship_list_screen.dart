import 'package:easy_localization/easy_localization.dart';
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
        title: Text('profile.relationTitle'.tr()),
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
            error: (err, stack) => Center(child: Text('profile.errorWithMessage'.tr(namedArgs: {'error': '$err'}))),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('profile.errorWithMessage'.tr(namedArgs: {'error': '$err'}))),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ShadInput(
              placeholder: Text('profile.searchByName'.tr()),
              leading: const Padding(
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
    debugPrint('👆 [RelationshipListScreen] 관계 옵션 열기: ${relation.effectiveDisplayName}');

    // 부모 context 캡처 (바텀시트 닫힌 후에도 유효)
    final parentContext = context;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text('profile.consultWithName'.tr(namedArgs: {'name': relation.effectiveDisplayName})),
              onTap: () {
                Navigator.pop(sheetContext);
                parentContext.go('${Routes.sajuChat}?profileId=${relation.toProfileId}');
              },
            ),
            // 수정 버튼 제거됨 - 삭제 후 재추가 방식으로 변경
            ListTile(
              leading: Icon(
                relation.isFavorite ? Icons.star : Icons.star_border,
                color: relation.isFavorite ? Colors.amber[600] : null,
              ),
              title: Text(relation.isFavorite ? 'profile.removeFavorite'.tr() : 'profile.addFavorite'.tr()),
              onTap: () async {
                Navigator.pop(sheetContext);
                try {
                  await ref.read(relationNotifierProvider.notifier).toggleFavorite(
                        relationId: relation.id,
                        fromProfileId: relation.fromProfileId,
                        isFavorite: !relation.isFavorite,
                      );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('profile.errorWithMessage'.tr(namedArgs: {'error': '$e'}))),
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red[400]),
              title: Text(
                'profile.deleteRelationTitle'.tr(),
                style: TextStyle(color: Colors.red[400]),
              ),
              onTap: () {
                debugPrint('🗑️ [RelationshipListScreen] 관계 삭제 버튼 클릭!');
                Navigator.pop(sheetContext);
                _showDeleteConfirmation(parentContext, ref, relation, scaffoldMessenger);
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
    ScaffoldMessengerState scaffoldMessenger,
  ) {
    debugPrint('🗑️ [RelationshipListScreen] 삭제 확인 다이얼로그 표시');
    debugPrint('  - relationId: ${relation.id}');
    debugPrint('  - fromProfileId: ${relation.fromProfileId}');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('profile.deleteRelationTitle'.tr()),
        content: Text('profile.deleteRelationConfirm'.tr(namedArgs: {'name': relation.effectiveDisplayName})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.buttonCancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              debugPrint('🗑️ [RelationshipListScreen] 삭제 실행 시작');

              try {
                await ref.read(relationNotifierProvider.notifier).delete(
                      relationId: relation.id,
                      fromProfileId: relation.fromProfileId,
                    );
                debugPrint('✅ [RelationshipListScreen] 삭제 성공');

                // Note: ref.invalidate() 제거! (defunct 에러 원인)
                // RelationNotifier.delete()가 트리거를 업데이트하여 자동 refetch됨

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('profile.deleteRelationSuccess'.tr(namedArgs: {'name': relation.effectiveDisplayName})),
                  ),
                );
              } catch (e) {
                debugPrint('❌ [RelationshipListScreen] 삭제 실패: $e');
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('profile.deleteRelationFailed'.tr(namedArgs: {'error': '$e'})),
                    backgroundColor: Colors.red[400],
                  ),
                );
              }
            },
            child: Text(
              'common.delete'.tr(),
              style: TextStyle(color: Colors.red[400]),
            ),
          ),
        ],
      ),
    );
  }
}
