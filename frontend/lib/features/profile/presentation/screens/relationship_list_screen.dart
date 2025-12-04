import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../router/routes.dart';
import '../../domain/entities/relationship_type.dart';
import '../../domain/entities/saju_profile.dart';
import '../providers/profile_provider.dart';
import '../widgets/relationship_category_section.dart';

class RelationshipListScreen extends ConsumerWidget {
  const RelationshipListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(allProfilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('인연'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              // Navigate to add profile
              context.go(Routes.profileEdit);
            },
          ),
        ],
      ),
      body: profilesAsync.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildList(context, profiles);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<SajuProfile> profiles) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ShadInput(
              placeholder: const Text('이름으로 검색'),
              leading: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.search, size: 16),
              ),
            ),
          ),

          // Sections by RelationshipType
          ...RelationshipType.values.map((type) {
            final filtered = profiles.where((p) => p.relationType == type).toList();
            return RelationshipCategorySection(
              type: type,
              profiles: filtered,
              onAddPressed: type == RelationshipType.me 
                  ? null // 'Me' section usually doesn't need add button here
                  : () {
                      // TODO: Pre-select relationship type when adding
                      context.go(Routes.profileEdit);
                    },
              onProfileTap: (profile) {
                // TODO: Show profile detail or start chat
                // For now, edit profile
                // context.goNamed(Routes.profileEdit, queryParameters: {'id': profile.id});
              },
            );
          }),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 24),
          ShadButton(
            onPressed: () => context.go(Routes.profileEdit),
            child: const Text('인연 등록하기'),
          ),
        ],
      ),
    );
  }
}
