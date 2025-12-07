import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:graphview/GraphView.dart';
import '../../domain/entities/saju_profile.dart';
import '../../domain/entities/relationship_type.dart';
import 'profile_provider.dart';

part 'relationship_graph_provider.g.dart';

/// View mode types for relationship display
enum ViewModeType { list, graph }

/// ViewMode Provider
/// Manages the current view mode (list or graph)
@riverpod
class ViewMode extends _$ViewMode {
  @override
  ViewModeType build() => ViewModeType.graph;

  /// Toggle between list and graph view
  void toggle() {
    state = state == ViewModeType.list
        ? ViewModeType.graph
        : ViewModeType.list;
  }

  /// Set a specific view mode
  void setMode(ViewModeType mode) {
    state = mode;
  }
}

/// SelectedProfile Provider
/// Manages the currently selected profile for detail view
@riverpod
class SelectedProfile extends _$SelectedProfile {
  @override
  SajuProfile? build() => null;

  /// Select a profile
  void select(SajuProfile profile) {
    state = profile;
  }

  /// Clear the selected profile
  void clear() {
    state = null;
  }
}

/// RelationshipGraph Provider
/// Constructs a graph structure from all profiles
/// Structure:
/// - Root node: "me" profile
/// - Group nodes: One for each RelationshipType
/// - Profile nodes: Individual profiles under each group
@riverpod
Graph relationshipGraph(Ref ref) {
  final profilesAsync = ref.watch(allProfilesProvider);
  final profiles = profilesAsync.valueOrNull ?? [];
  final graph = Graph();

  if (profiles.isEmpty) {
    // Return empty graph with placeholder
    final placeholderNode = Node.Id('me_placeholder');
    graph.addNode(placeholderNode);
    return graph;
  }

  // Find the "me" profile (root node)
  final meProfile = profiles.where((p) => p.relationType == RelationshipType.me).firstOrNull;

  // Create root node (use "me" profile or placeholder)
  final rootNodeId = meProfile?.id ?? 'me_placeholder';
  final rootNode = Node.Id(rootNodeId);
  graph.addNode(rootNode);

  // Group profiles by relationship type (excluding "me")
  final groupedProfiles = <RelationshipType, List<SajuProfile>>{};
  for (final profile in profiles) {
    if (profile.relationType != RelationshipType.me) {
      groupedProfiles.putIfAbsent(
        profile.relationType,
        () => [],
      ).add(profile);
    }
  }

  // Create group nodes and connect profiles
  for (final entry in groupedProfiles.entries) {
    final relationType = entry.key;
    final profilesInGroup = entry.value;

    // Create group node (Web 호환 - .name 대신 직접 변환)
    final groupNodeId = 'group_${_relationTypeToString(relationType)}';
    final groupNode = Node.Id(groupNodeId);
    graph.addNode(groupNode);

    // Connect group node to root
    graph.addEdge(rootNode, groupNode);

    // Create and connect individual profile nodes to group node
    for (final profile in profilesInGroup) {
      final profileNode = Node.Id(profile.id);
      graph.addNode(profileNode);
      graph.addEdge(groupNode, profileNode);
    }
  }

  return graph;
}

/// GraphAlgorithm Provider
/// Provides the Buchheim-Walker algorithm configuration for graph layout
@riverpod
BuchheimWalkerConfiguration graphAlgorithm(Ref ref) {
  return BuchheimWalkerConfiguration()
    ..siblingSeparation = 60
    ..levelSeparation = 100
    ..subtreeSeparation = 80
    ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
}

/// RelationshipType을 문자열로 변환 (Web 호환)
String _relationTypeToString(RelationshipType type) {
  if (type == RelationshipType.me) return 'me';
  if (type == RelationshipType.family) return 'family';
  if (type == RelationshipType.friend) return 'friend';
  if (type == RelationshipType.lover) return 'lover';
  if (type == RelationshipType.work) return 'work';
  return 'other';
}
