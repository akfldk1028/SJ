import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphview/GraphView.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../domain/entities/saju_profile.dart';
import '../../../domain/entities/relationship_type.dart';
import '../../../domain/entities/gender.dart';
import '../../../data/mock/mock_profiles.dart';
import '../../../data/models/profile_relation_model.dart';
import '../../providers/profile_provider.dart';
import '../../providers/relation_provider.dart';
import '../../../../../router/routes.dart';
import 'me_node_widget.dart';
import 'profile_node_widget.dart';
import 'relationship_group_node.dart';
import 'graph_controls.dart';
import 'saju_quick_view_sheet.dart';

/// 목업 데이터 사용 여부 (테스트용)
const bool _useMockData = false;

/// 관계 그래프 뷰 (SJ-Flow Large Tree 기능 사용)
class RelationshipGraphView extends ConsumerStatefulWidget {
  const RelationshipGraphView({super.key});

  @override
  ConsumerState<RelationshipGraphView> createState() =>
      _RelationshipGraphViewState();
}

class _RelationshipGraphViewState extends ConsumerState<RelationshipGraphView> {
  /// 줌 컨트롤용 TransformationController
  final TransformationController _transformController = TransformationController();

  /// SJ-Flow GraphViewController (TransformationController 연결)
  late final GraphViewController _controller;

  /// 그래프 (클래스 레벨 - 한 번만 생성)
  final Graph graph = Graph()..isTree = true;

  /// 트리 레이아웃 설정
  final BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();

  /// 알고리즘 (late - builder 참조)
  late final BuchheimWalkerAlgorithm algorithm;

  /// 현재 프로필 목록 (그래프 재구성 감지용)
  List<SajuProfile> _currentProfiles = [];

  @override
  void initState() {
    super.initState();

    // GraphViewController 초기화 (TransformationController 연결)
    _controller = GraphViewController(
      transformationController: _transformController,
    );

    // Configuration 설정 (Large Tree 스타일)
    builder
      ..siblingSeparation = 50
      ..levelSeparation = 150
      ..subtreeSeparation = 60
      ..useCurvedConnections = false  // 직선 연결
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT;

    // Algorithm 생성 (builder와 TreeEdgeRenderer 연결)
    algorithm = BuchheimWalkerAlgorithm(
      builder,
      TreeEdgeRenderer(builder),
    );

    // 초기 그래프 구성 (목업 데이터)
    if (_useMockData) {
      _buildGraphFromProfiles(MockProfiles.profiles, MockProfiles.profiles.first);
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  // === 줌 컨트롤 ===
  void _zoomIn() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.3).clamp(0.1, 5.0);
    final center = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );
    _transformController.value = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..scale(newScale)
      ..translate(-center.dx, -center.dy);
  }

  void _zoomOut() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.3).clamp(0.1, 5.0);
    final center = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );
    _transformController.value = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..scale(newScale)
      ..translate(-center.dx, -center.dy);
  }

  // === 노드 탭 핸들러 ===
  void _onNodeTap(Node node) {
    final nodeId = node.key?.value as String? ?? '';
    // 그룹 노드 탭 → 확장/축소
    if (nodeId.startsWith('group_')) {
      _controller.toggleNodeExpanded(graph, node, animate: true);
      setState(() {});
    }
  }

  // === 프로필 노드 탭 핸들러 ===
  void _onProfileTap(SajuProfile profile) {
    showSajuQuickView(
      context,
      profile: profile,
      onChatPressed: () {
        Navigator.pop(context);
        // 궁합 채팅으로 이동 (targetProfileId = 선택한 프로필)
        context.go('${Routes.sajuChat}?type=compatibility&profileId=${profile.id}');
      },
      onDetailPressed: () {
        Navigator.pop(context);
      },
    );
  }

  // === RelationshipType 문자열 변환 ===
  String _relationTypeToString(RelationshipType type) {
    if (type == RelationshipType.me) return 'me';
    if (type == RelationshipType.family) return 'family';
    if (type == RelationshipType.friend) return 'friend';
    if (type == RelationshipType.lover) return 'lover';
    if (type == RelationshipType.work) return 'work';
    return 'other';
  }

  RelationshipType _parseRelationType(String str) {
    if (str == 'me') return RelationshipType.me;
    if (str == 'family') return RelationshipType.family;
    if (str == 'friend') return RelationshipType.friend;
    if (str == 'lover') return RelationshipType.lover;
    if (str == 'work') return RelationshipType.work;
    return RelationshipType.other;
  }

  @override
  Widget build(BuildContext context) {
    // 목업 데이터 또는 실제 데이터
    if (_useMockData) {
      return _buildGraph(context, MockProfiles.profiles, {});
    }

    final activeProfileAsync = ref.watch(activeProfileProvider);

    return activeProfileAsync.when(
      data: (activeProfile) {
        if (activeProfile == null) {
          return const Center(child: Text('프로필이 없습니다'));
        }

        // Supabase 관계 데이터 조회 (카테고리별)
        final relationsByCategoryAsync = ref.watch(
          relationsByCategoryProvider(activeProfile.id),
        );

        return relationsByCategoryAsync.when(
          data: (relationsByCategory) {
            // 관계 데이터로 그래프 재구성
            _buildGraphFromRelations(activeProfile, relationsByCategory);
            return _buildGraph(context, [activeProfile], relationsByCategory);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  /// 프로필 목록 비교
  bool _isSameProfiles(List<SajuProfile> profiles) {
    if (_currentProfiles.length != profiles.length) return false;
    for (int i = 0; i < profiles.length; i++) {
      if (_currentProfiles[i].id != profiles[i].id) return false;
    }
    return true;
  }

  /// 그래프 빌드 (SJ-Flow Large Tree 방식)
  Widget _buildGraph(
    BuildContext context,
    List<SajuProfile> profiles,
    Map<String, List<ProfileRelationModel>> relationsByCategory,
  ) {
    return Column(
      children: [
        // SJ-Flow GraphView.builder (Expanded로 전체 영역 채움)
        Expanded(
          child: Stack(
            children: [
              GraphView.builder(
                controller: _controller,
                graph: graph,
                algorithm: algorithm,
                paint: Paint()
                  ..color = Colors.grey[500]!
                  ..strokeWidth = 1.5
                  ..style = PaintingStyle.stroke,
                centerGraph: false,  // false로 변경 - 원점(0,0)부터 시작
                animated: true,
                autoZoomToFit: true,  // 자동으로 화면에 맞춤
                panAnimationDuration: const Duration(milliseconds: 500),
                toggleAnimationDuration: const Duration(milliseconds: 400),
                builder: (Node node) => _buildNodeFromRelations(node, profiles, relationsByCategory),
              ),
              // 줌 컨트롤 (우측 하단)
              GraphControls(
                onZoomIn: _zoomIn,
                onZoomOut: _zoomOut,
                onZoomToFit: () => _controller.zoomToFit(),
                onResetView: () => _controller.resetView(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 노드 빌더 (기존 방식 - 미사용)
  Widget _buildNode(Node node, List<SajuProfile> profiles) {
    final nodeId = node.key?.value as String? ?? '';

    // Me 노드
    if (nodeId.startsWith('me_')) {
      if (nodeId == 'me_placeholder') {
        return const MeNodeWidget(profile: null, size: 90);
      }
      final profileId = nodeId.substring(3);
      final profile = profiles.where((p) => p.id == profileId).firstOrNull;
      return MeNodeWidget(
        profile: profile,
        size: 90,
        onTap: profile != null ? () => _onProfileTap(profile) : null,
      );
    }

    // Group 노드 (탭하면 확장/축소)
    if (nodeId.startsWith('group_')) {
      final relationTypeStr = nodeId.substring(6);
      final relationType = _parseRelationType(relationTypeStr);
      final count = profiles.where((p) => p.relationType == relationType).length;
      final isCollapsed = _controller.isNodeCollapsed(node);

      return GestureDetector(
        onTap: () => _onNodeTap(node),
        child: RelationshipGroupNode(
          type: relationType,
          count: count,
          width: 80,
          height: 45,
          isCollapsed: isCollapsed,
        ),
      );
    }

    // Profile 노드
    final profile = profiles.where((p) => p.id == nodeId).firstOrNull;
    if (profile == null) {
      return const SizedBox.shrink();
    }
    return ProfileNodeWidget(
      profile: profile,
      width: 110,
      height: 70,
      onTap: () => _onProfileTap(profile),
    );
  }

  /// 노드 빌더 (Supabase 관계 데이터 기반)
  Widget _buildNodeFromRelations(
    Node node,
    List<SajuProfile> profiles,
    Map<String, List<ProfileRelationModel>> relationsByCategory,
  ) {
    final nodeId = node.key?.value as String? ?? '';

    // Me 노드
    if (nodeId.startsWith('me_')) {
      if (nodeId == 'me_placeholder') {
        return const MeNodeWidget(profile: null, size: 90);
      }
      final profileId = nodeId.substring(3);
      final profile = profiles.where((p) => p.id == profileId).firstOrNull;
      return MeNodeWidget(
        profile: profile,
        size: 90,
        onTap: profile != null ? () => _onProfileTap(profile) : null,
      );
    }

    // Group 노드 (탭하면 확장/축소) - shadcn_ui 스타일
    if (nodeId.startsWith('group_')) {
      final categoryLabel = nodeId.substring(6); // 예: "친구", "가족"
      final relations = relationsByCategory[categoryLabel] ?? [];
      final relationType = _categoryToRelationType(categoryLabel);
      final isCollapsed = _controller.isNodeCollapsed(node);

      return GestureDetector(
        onTap: () => _onNodeTap(node),
        child: _ShadcnGroupNodeWidget(
          categoryLabel: categoryLabel,
          relationType: relationType,
          count: relations.length,
          isCollapsed: isCollapsed,
        ),
      );
    }

    // Relation 노드 (relation_{relationId} 형태)
    if (nodeId.startsWith('relation_')) {
      final relationId = nodeId.substring(9);
      // relationsByCategory에서 해당 relation 찾기
      ProfileRelationModel? relation;
      for (final relations in relationsByCategory.values) {
        relation = relations.where((r) => r.id == relationId).firstOrNull;
        if (relation != null) break;
      }

      if (relation != null) {
        return _ShadcnRelationNodeWidget(
          relation: relation,
          onTap: () => _onRelationTap(relation!),
        );
      }
    }

    return const SizedBox.shrink();
  }

  /// 카테고리 라벨을 RelationshipType으로 변환
  RelationshipType _categoryToRelationType(String categoryLabel) {
    switch (categoryLabel) {
      case '가족':
        return RelationshipType.family;
      case '친구':
        return RelationshipType.friend;
      case '연인':
        return RelationshipType.lover;
      case '직장':
        return RelationshipType.work;
      default:
        return RelationshipType.other;
    }
  }

  /// 관계 노드 탭 핸들러
  ///
  /// 관계 노드 클릭 시 QuickView(만세력) 표시 후 사주 상담/상세보기 선택 가능
  void _onRelationTap(ProfileRelationModel relation) {
    final toProfile = relation.toProfile;
    if (toProfile == null) return;

    // ProfileRelationTarget을 SajuProfile로 변환
    final sajuProfile = SajuProfile(
      id: toProfile.id,
      displayName: toProfile.displayName,
      gender: toProfile.gender == 'male' ? Gender.male : Gender.female,
      birthDate: toProfile.birthDate,
      isLunar: toProfile.isLunar,
      isLeapMonth: toProfile.isLeapMonth,
      birthTimeMinutes: toProfile.birthTimeMinutes,
      birthTimeUnknown: toProfile.birthTimeUnknown,
      useYaJasi: toProfile.useYaJasi,
      birthCity: toProfile.birthCity ?? '서울',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      relationType: _categoryToRelationType(relation.categoryLabel),
      profileType: 'other',
    );

    // QuickView 표시 (만세력 포함)
    showSajuQuickView(
      context,
      profile: sajuProfile,
      onChatPressed: () {
        Navigator.pop(context);
        // 궁합 채팅으로 이동
        context.go('${Routes.sajuChat}?type=compatibility&profileId=${relation.toProfileId}');
      },
      onDetailPressed: () {
        Navigator.pop(context);
        // TODO: 상세보기 화면으로 이동 (나중에 구현)
      },
    );
  }

  /// Supabase 관계 데이터로 그래프 구성
  void _buildGraphFromRelations(
    SajuProfile activeProfile,
    Map<String, List<ProfileRelationModel>> relationsByCategory,
  ) {
    // 기존 데이터 클리어
    graph.edges.clear();
    graph.nodes.clear();
    graph.notifyGraphObserver();

    // 루트 노드 (나)
    final meNode = Node.Id('me_${activeProfile.id}');
    graph.addNode(meNode);

    // 카테고리 순서 정의
    const categoryOrder = ['가족', '연인', '친구', '직장', '기타'];

    // 카테고리별 그룹 노드 및 관계 노드 생성
    for (final category in categoryOrder) {
      final relations = relationsByCategory[category] ?? [];
      if (relations.isEmpty) continue;

      // 그룹 노드
      final groupNode = Node.Id('group_$category');
      graph.addEdge(meNode, groupNode);

      // 개별 관계 노드
      for (final relation in relations) {
        final relationNode = Node.Id('relation_${relation.id}');
        graph.addEdge(groupNode, relationNode);
      }
    }

    print('[Graph] ===== Supabase 관계 그래프 구축 완료 =====');
    print('[Graph] 노드 수: ${graph.nodeCount()}, 엣지 수: ${graph.edges.length}');
  }

  /// 그래프 데이터 구성 (기존 graph에 추가) - 기존 방식
  ///
  /// [activeProfile] 활성 프로필을 루트 노드(왼쪽)로 사용
  void _buildGraphFromProfiles(List<SajuProfile> profiles, SajuProfile? activeProfile) {
    // 기존 데이터 클리어 (edges 먼저, 그 다음 nodes)
    graph.edges.clear();
    graph.nodes.clear();
    // 캐시 무효화를 위해 notifyGraphObserver 호출
    graph.notifyGraphObserver();

    _currentProfiles = profiles;

    if (profiles.isEmpty) {
      graph.addNode(Node.Id('me_placeholder'));
      return;
    }

    // Me 프로필: activeProfile 우선, 없으면 relationType.me, 그래도 없으면 첫 번째 프로필
    final meProfile = activeProfile ??
        profiles.where((p) => p.relationType == RelationshipType.me).firstOrNull ??
        profiles.first;

    // Me 노드 생성
    final meNode = Node.Id('me_${meProfile.id}');
    graph.addNode(meNode);

    // 관계별 그룹화
    final profilesByRelation = <RelationshipType, List<SajuProfile>>{};
    for (final profile in profiles) {
      if (profile.id == meProfile.id) continue;
      profilesByRelation
          .putIfAbsent(profile.relationType, () => [])
          .add(profile);
    }

    // 그룹 노드 및 프로필 노드 생성
    for (final entry in profilesByRelation.entries) {
      final relationType = entry.key;
      final groupProfiles = entry.value;

      // 그룹 노드
      final groupNode = Node.Id('group_${_relationTypeToString(relationType)}');
      graph.addEdge(meNode, groupNode);

      // 개별 프로필 노드
      for (final profile in groupProfiles) {
        final profileNode = Node.Id(profile.id);
        graph.addEdge(groupNode, profileNode);
      }
    }

    print('[Graph] ===== 그래프 구축 완료 =====');
    print('[Graph] 노드 수: ${graph.nodeCount()}, 엣지 수: ${graph.edges.length}');
    print('[Graph] 노드 목록:');
    for (final node in graph.nodes) {
      print('  - ${node.key?.value}');
    }
    print('[Graph] 엣지 목록:');
    for (final edge in graph.edges) {
      print('  - ${edge.source.key?.value} → ${edge.destination.key?.value}');
    }
  }
}

/// shadcn_ui 기반 그룹 노드 위젯
class _ShadcnGroupNodeWidget extends StatelessWidget {
  const _ShadcnGroupNodeWidget({
    required this.categoryLabel,
    required this.relationType,
    required this.count,
    required this.isCollapsed,
  });

  final String categoryLabel;
  final RelationshipType relationType;
  final int count;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    final colors = _getGradientColors(relationType);

    return Container(
      width: 100,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIcon(relationType),
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            '$categoryLabel $count',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isCollapsed ? Icons.expand_more : Icons.expand_less,
            size: 14,
            color: Colors.white70,
          ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors(RelationshipType type) {
    if (type == RelationshipType.family) {
      return const [Color(0xFFEF5350), Color(0xFFE57373)];
    }
    if (type == RelationshipType.friend) {
      return const [Color(0xFF26A69A), Color(0xFF4DB6AC)];
    }
    if (type == RelationshipType.lover) {
      return const [Color(0xFFEC407A), Color(0xFFF06292)];
    }
    if (type == RelationshipType.work) {
      return const [Color(0xFF42A5F5), Color(0xFF64B5F6)];
    }
    return const [Color(0xFF78909C), Color(0xFF90A4AE)];
  }

  IconData _getIcon(RelationshipType type) {
    if (type == RelationshipType.family) return Icons.home_rounded;
    if (type == RelationshipType.friend) return Icons.people_rounded;
    if (type == RelationshipType.lover) return Icons.favorite_rounded;
    if (type == RelationshipType.work) return Icons.work_rounded;
    return Icons.group_rounded;
  }
}

/// shadcn_ui 기반 관계 노드 위젯
class _ShadcnRelationNodeWidget extends StatelessWidget {
  const _ShadcnRelationNodeWidget({
    required this.relation,
    this.onTap,
  });

  final ProfileRelationModel relation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final toProfile = relation.toProfile;
    final displayName = relation.effectiveDisplayName;
    final birthDate = toProfile?.birthDate;
    final birthDateStr = birthDate != null
        ? '${birthDate.year}.${birthDate.month.toString().padLeft(2, '0')}.${birthDate.day.toString().padLeft(2, '0')}'
        : '';
    final avatarColor = _getAvatarColor(relation.categoryLabel);

    return GestureDetector(
      onTap: onTap,
      child: ShadCard(
        width: 150,
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아바타 (CircleAvatar 사용)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    avatarColor,
                    avatarColor.withValues(alpha: 0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: avatarColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  displayName.isNotEmpty ? displayName[0] : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // 이름 + 생년월일
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (birthDateStr.isNotEmpty)
                    Text(
                      birthDateStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(String category) {
    switch (category) {
      case '가족':
        return const Color(0xFFEF5350);
      case '연인':
        return const Color(0xFFEC407A);
      case '친구':
        return const Color(0xFF26A69A);
      case '직장':
        return const Color(0xFF42A5F5);
      default:
        return const Color(0xFF78909C);
    }
  }
}
