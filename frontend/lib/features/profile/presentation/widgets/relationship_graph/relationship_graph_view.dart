import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphview/GraphView.dart';
import '../../../domain/entities/saju_profile.dart';
import '../../../domain/entities/relationship_type.dart';
import '../../../data/mock/mock_profiles.dart';
import '../../providers/profile_provider.dart';
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
      _buildGraphFromProfiles(MockProfiles.profiles);
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
      return _buildGraph(context, MockProfiles.profiles);
    }

    final profilesAsync = ref.watch(allProfilesProvider);
    return profilesAsync.when(
      data: (profiles) {
        // 프로필 변경 시 그래프 재구성
        if (!_isSameProfiles(profiles)) {
          _buildGraphFromProfiles(profiles);
        }
        return _buildGraph(context, profiles);
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
  Widget _buildGraph(BuildContext context, List<SajuProfile> profiles) {
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
                builder: (Node node) => _buildNode(node, profiles),
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

  /// 노드 빌더
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

  /// 그래프 데이터 구성 (기존 graph에 추가)
  void _buildGraphFromProfiles(List<SajuProfile> profiles) {
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

    // Me 프로필 찾기
    final meProfile = profiles
            .where((p) => p.relationType == RelationshipType.me)
            .firstOrNull ??
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
