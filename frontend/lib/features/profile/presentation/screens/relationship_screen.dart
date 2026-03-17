import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../router/routes.dart';
import '../../data/models/profile_relation_model.dart';
import '../../data/relation_refresh_state.dart';
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
///
/// Note: 로컬 캐시 기반 UI 업데이트
/// - Provider는 초기 데이터 로드에만 사용
/// - 삭제/수정 후에는 로컬 캐시를 직접 업데이트 (ref.invalidate() 사용 안함)
/// - 이렇게 하면 Provider notification으로 인한 defunct widget 에러 방지
class RelationshipScreen extends ConsumerStatefulWidget {
  const RelationshipScreen({super.key});

  @override
  ConsumerState<RelationshipScreen> createState() => _RelationshipScreenState();
}

class _RelationshipScreenState extends ConsumerState<RelationshipScreen> {
  /// 로컬 데이터 캐시
  /// - Provider 데이터가 로드되면 여기에 복사
  /// - 삭제 시 여기서 직접 제거 (setState로 UI 업데이트)
  /// - null이면 Provider 데이터 사용, non-null이면 로컬 캐시 사용
  Map<String, List<ProfileRelationModel>>? _localCache;

  /// 새로고침 중 여부
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🔄 [RelationshipScreen] initState');
  }

  /// Pull-to-Refresh 콜백
  /// Provider invalidate로 모든 watcher (GraphView 포함) 업데이트
  Future<void> _onRefresh() async {
    if (_isRefreshing) return;

    debugPrint('🔄 [RelationshipScreen] _onRefresh 시작');
    setState(() => _isRefreshing = true);

    try {
      final activeProfile = ref.read(activeProfileProvider).value;
      if (activeProfile != null) {
        // Provider invalidate - 이 시점에서는 navigation 완료되어 안전
        // GraphView 등 모든 watcher가 새 데이터로 업데이트됨
        ref.invalidate(relationsByCategoryProvider(activeProfile.id));
        debugPrint('✅ [RelationshipScreen] Provider invalidate 완료');

        // 로컬 캐시도 클리어 → Provider 데이터 사용하도록
        setState(() {
          _localCache = null;
          _isRefreshing = false;
        });
      } else {
        if (mounted) {
          setState(() => _isRefreshing = false);
        }
      }
    } catch (e) {
      debugPrint('❌ [RelationshipScreen] _onRefresh 에러: $e');
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  /// 삭제 후 로컬 캐시에서 직접 제거
  /// Provider notification 없이 UI만 업데이트
  void _removeFromLocalCache(ProfileRelationModel relation) {
    if (_localCache == null) return;

    final category = relation.categoryLabel;
    final updatedCache = Map<String, List<ProfileRelationModel>>.from(_localCache!);

    if (updatedCache.containsKey(category)) {
      updatedCache[category] = updatedCache[category]!
          .where((r) => r.id != relation.id)
          .toList();

      // 빈 카테고리 제거
      if (updatedCache[category]!.isEmpty) {
        updatedCache.remove(category);
      }
    }

    setState(() {
      _localCache = updatedCache;
    });
    debugPrint('✅ [RelationshipScreen] 로컬 캐시에서 삭제됨: ${relation.id}');
  }

  @override
  Widget build(BuildContext context) {
    // 정적 플래그 확인 - 다른 화면에서 데이터 변경 후 돌아온 경우
    if (RelationRefreshState.checkAndClear()) {
      debugPrint('🔄 [RelationshipScreen] 플래그 감지 → 새로고침 예약');
      // build 중에는 setState 불가, PostFrameCallback으로 지연
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _onRefresh();
        }
      });
    }

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

          // 로컬 캐시가 있으면 사용 (Provider watch 안함 → notification 없음)
          if (_localCache != null) {
            return _buildBody(context, viewMode, _localCache!);
          }

          // 로컬 캐시가 없으면 Provider에서 초기 데이터 로드
          final relationsByCategoryAsync = ref.watch(
            relationsByCategoryProvider(activeProfile.id),
          );

          return relationsByCategoryAsync.when(
            data: (relationsByCategory) {
              // Provider 데이터를 로컬 캐시에 복사 (최초 1회)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _localCache == null) {
                  setState(() {
                    _localCache = Map.from(relationsByCategory);
                  });
                }
              });

              return _buildBody(context, viewMode, relationsByCategory);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => _buildErrorState(context, err),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildErrorState(context, err),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 추가 화면으로 이동 후 돌아오면 새로고침
          await context.push(Routes.relationshipAdd);
          // 애니메이션 완료 후 새로고침 (defunct 에러 방지)
          if (mounted) {
            await Future.delayed(const Duration(milliseconds: 300));
            if (mounted) {
              _onRefresh();
            }
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ViewModeType viewMode,
    Map<String, List<ProfileRelationModel>> relationsByCategory,
  ) {
    // activeProfile 가져오기 (이미 로드됨)
    final activeProfile = ref.read(activeProfileProvider).value;

    // 그래프 뷰
    if (viewMode == ViewModeType.graph) {
      // activeProfile이 없으면 안전하게 처리
      if (activeProfile == null) {
        return Center(child: Text('profile.noProfile'.tr()));
      }

      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            // Props로 데이터 전달 (GraphView는 Provider watch 안함)
            child: RelationshipGraphView(
              activeProfile: activeProfile,
              relationsByCategory: relationsByCategory,
            ),
          ),
        ),
      );
    }

    // 리스트 뷰: 관계가 없으면 빈 상태 표시
    if (relationsByCategory.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: EmptyRelationState(
                onAddPressed: () async {
                  await context.push(Routes.relationshipAdd);
                  if (mounted) {
                    await Future.delayed(const Duration(milliseconds: 300));
                    if (mounted) {
                      _onRefresh();
                    }
                  }
                },
              ),
            ),
          ],
        ),
      );
    }

    // Builder로 감싸서 Scaffold 안쪽 context 사용
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: Builder(
        builder: (scaffoldContext) => _buildListView(scaffoldContext, ref, relationsByCategory),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    ViewModeType viewMode,
  ) {
    return AppBar(
      title: Text('profile.relationshipMap'.tr()),
      centerTitle: true,
      actions: [
        // 뷰 모드 토글
        IconButton(
          icon: Icon(
            viewMode == ViewModeType.list
                ? Icons.account_tree_outlined
                : Icons.list_outlined,
          ),
          tooltip: viewMode == ViewModeType.list ? 'profile.graphView'.tr() : 'profile.listView'.tr(),
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
            'common.errorGeneral'.tr(),
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
    // 카테고리 순서 정의 (영문 내부 키)
    const categoryOrder = ['family', 'romantic', 'friend', 'work', 'other'];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16),
            child: ShadInput(
              placeholder: Text('profile.searchByName'.tr()),
              leading: const Padding(
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
              onAddPressed: () async {
                await context.push(Routes.relationshipAdd);
                if (mounted) {
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (mounted) {
                    _onRefresh();
                  }
                }
              },
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
    debugPrint('👆 [RelationshipScreen._showRelationDetail] 호출됨');
    debugPrint('  - relation.id: ${relation.id}');
    debugPrint('  - relation.toProfile: ${relation.toProfile}');

    // toProfile 정보가 있으면 QuickView 표시
    final toProfile = relation.toProfile;
    if (toProfile != null) {
      debugPrint('✅ [RelationshipScreen] toProfile 있음 → QuickView 표시');
      // 부모 context 캡처 (sheet가 닫힌 후에도 유효)
      final parentContext = context;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => _RelationQuickViewSheet(
          relation: relation,
          onChatPressed: () {
            Navigator.pop(sheetContext);
            // 궁합 채팅으로 이동 (autoMention으로 자동 멘션)
            parentContext.push(
              '${Routes.sajuChat}?type=compatibility&profileId=${relation.toProfileId}&autoMention=true',
            );
          },
          onEditPressed: null,  // 수정 기능 비활성화
          onDeletePressed: () {
            debugPrint('🗑️ [RelationshipScreen] 삭제 버튼 클릭됨!');
            Navigator.pop(sheetContext);
            // ScaffoldMessenger 없이 삭제 진행
            _showDeleteConfirmation(parentContext, ref, relation);
          },
        ),
      );
    } else {
      debugPrint('❌ [RelationshipScreen] toProfile가 NULL! QuickView 표시 불가');
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    ProfileRelationModel relation,
  ) {
    debugPrint('🗑️ [RelationshipScreen._showDeleteConfirmation] 호출됨');
    final displayName = relation.effectiveDisplayName;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('profile.deleteRelationTitle'.tr()),
        content: Text('profile.deleteRelationConfirm'.tr(namedArgs: {'name': displayName})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.buttonCancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              debugPrint('🗑️ [RelationshipScreen] 삭제 시작');
              debugPrint('  - relationId: ${relation.id}');
              debugPrint('  - fromProfileId: ${relation.fromProfileId}');

              try {
                // triggerRefresh: false - Provider notification 안함
                await ref.read(relationNotifierProvider.notifier).delete(
                      relationId: relation.id,
                      fromProfileId: relation.fromProfileId,
                      triggerRefresh: false,
                    );
                debugPrint('✅ [RelationshipScreen] 삭제 성공');

                // 다이얼로그 닫기 전에 로컬 캐시 업데이트
                // (다이얼로그가 닫히면 widget이 defunct될 수 있으므로)
                _removeFromLocalCache(relation);

                // 다이얼로그 닫기
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                // Note: ref.invalidate() 호출 안함!
                // 로컬 캐시를 직접 수정했으므로 Provider notification 불필요
                // 이렇게 하면 defunct widget 에러 완전 방지
              } catch (e) {
                debugPrint('❌ [RelationshipScreen] 삭제 실패: $e');
                // 에러 다이얼로그 표시
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('profile.deleteFailed'.tr()),
                      content: Text('$e'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('common.buttonConfirm'.tr()),
                        ),
                      ],
                    ),
                  );
                }
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

/// 관계 상세 QuickView Sheet
class _RelationQuickViewSheet extends StatelessWidget {
  final ProfileRelationModel relation;
  final VoidCallback onChatPressed;
  final VoidCallback? onEditPressed;  // nullable - 수정 기능 비활성화
  final VoidCallback onDeletePressed;

  const _RelationQuickViewSheet({
    required this.relation,
    required this.onChatPressed,
    this.onEditPressed,  // optional
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
                '${relation.localizedCategoryLabel} - ${relation.relationLabel}',
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
            // 액션 버튼 - 사주 상담 (shadcn_ui)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ShadButton(
                  onPressed: onChatPressed,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 16),
                      const SizedBox(width: 8),
                      Text('profile.sajuConsult'.tr()),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 삭제 버튼
            ShadButton.ghost(
              onPressed: onDeletePressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_outline, size: 16, color: Colors.red[400]),
                  const SizedBox(width: 8),
                  Text(
                    'profile.deleteRelation'.tr(),
                    style: TextStyle(color: Colors.red[400]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatBirthDate(DateTime date) {
    return 'profile.dateFormat'.tr(namedArgs: {
      'year': date.year.toString(),
      'month': date.month.toString(),
      'day': date.day.toString(),
    });
  }
}
