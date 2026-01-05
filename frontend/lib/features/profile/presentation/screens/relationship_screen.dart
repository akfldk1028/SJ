import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../router/routes.dart';
import '../../domain/entities/saju_profile.dart';
import '../../domain/entities/relationship_type.dart';
import '../../data/mock/mock_profiles.dart';
import '../providers/profile_provider.dart';
import '../widgets/relationship_category_section.dart';
import '../widgets/relationship_graph/relationship_graph_view.dart';
import '../widgets/relationship_graph/profile_quick_view_sheet.dart';

/// 목업 데이터 사용 여부 (테스트용)
const bool _useMockData = true;

/// 뷰 모드 타입
enum ViewModeType { list, graph }

/// 뷰 모드 Provider (간단히 StateProvider 사용)
final viewModeProvider = StateProvider<ViewModeType>((ref) => ViewModeType.graph);

/// 선택된 프로필 Provider
final selectedProfileProvider = StateProvider<SajuProfile?>((ref) => null);

/// 관계 화면 (리스트/그래프 전환 가능)
class RelationshipScreen extends ConsumerWidget {
  const RelationshipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(viewModeProvider);

    final theme = context.appTheme;

    // 목업 데이터 사용 시
    if (_useMockData) {
      final profiles = MockProfiles.profiles;
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: _buildAppBar(context, ref, viewMode),
        body: viewMode == ViewModeType.list
            ? _buildListView(context, ref, profiles)
            : const RelationshipGraphView(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push(Routes.profileEdit),
          backgroundColor: theme.primaryColor,
          child: Icon(Icons.person_add, color: theme.isDark ? const Color(0xFF0A0A0F) : Colors.white),
        ),
      );
    }

    // 실제 데이터 사용
    final profilesAsync = ref.watch(allProfilesProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: _buildAppBar(context, ref, viewMode),
      body: profilesAsync.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return _buildEmptyState(context);
          }
          return viewMode == ViewModeType.list
              ? _buildListView(context, ref, profiles)
              : const RelationshipGraphView();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.profileEdit),
        backgroundColor: theme.primaryColor,
        child: Icon(Icons.person_add, color: theme.isDark ? const Color(0xFF0A0A0F) : Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    ViewModeType viewMode,
  ) {
    final theme = context.appTheme;

    return AppBar(
      backgroundColor: theme.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_rounded, color: theme.primaryColor),
        onPressed: () => context.go('/menu'),
        tooltip: '메인으로 돌아가기',
      ),
      title: Text(
        '인연 관계도',
        style: TextStyle(
          color: theme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        // View mode toggle
        IconButton(
          icon: Icon(
            viewMode == ViewModeType.list
                ? Icons.account_tree_outlined
                : Icons.list_outlined,
            color: theme.textSecondary,
          ),
          tooltip: viewMode == ViewModeType.list ? '그래프 보기' : '리스트 보기',
          onPressed: () {
            ref.read(viewModeProvider.notifier).state =
                viewMode == ViewModeType.list
                    ? ViewModeType.graph
                    : ViewModeType.list;
          },
        ),
        // Search
        IconButton(
          icon: Icon(Icons.search, color: theme.textSecondary),
          onPressed: () {
            // TODO: Search functionality
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
          const SizedBox(height: 32),
          ShadButton(
            onPressed: () => context.push(Routes.profileEdit),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add, size: 18),
                SizedBox(width: 8),
                Text('인연 등록하기'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    WidgetRef ref,
    List<SajuProfile> profiles,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: ShadInput(
              placeholder: const Text('이름으로 검색'),
              leading: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.search, size: 16),
              ),
            ),
          ),

          // Sections by RelationshipType
          ...RelationshipType.values.map((type) {
            final filtered = profiles
                .where((p) => p.relationType == type)
                .toList();
            return RelationshipCategorySection(
              type: type,
              profiles: filtered,
              onAddPressed: type == RelationshipType.me
                  ? null
                  : () => context.push(Routes.profileEdit),
              onProfileTap: (profile) {
                _showProfileDetail(context, ref, profile);
              },
            );
          }),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showProfileDetail(
    BuildContext context,
    WidgetRef ref,
    SajuProfile profile,
  ) {
    showProfileQuickView(
      context,
      profile: profile,
      onChatPressed: () {
        Navigator.pop(context);
        // TODO: Navigate to chat with this profile
        // context.push('/saju/chat?profileId=${profile.id}');
      },
      onEditPressed: () {
        Navigator.pop(context);
        // TODO: Navigate to edit
        // context.push('${Routes.profileEdit}?id=${profile.id}');
      },
      onDeletePressed: () {
        Navigator.pop(context);
        _showDeleteConfirmation(context, ref, profile);
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    SajuProfile profile,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('인연 삭제'),
        content: Text('${profile.displayName}님을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              ref.read(activeProfileProvider.notifier).deleteProfile(profile.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${profile.displayName}님이 삭제되었습니다')),
              );
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
