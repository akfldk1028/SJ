import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';
import '../../../domain/entities/saju_profile.dart';
import '../../../domain/entities/relationship_type.dart';
import '../../../data/mock/mock_profiles.dart';
import '../../providers/profile_provider.dart';
import 'me_node_widget.dart';
import 'profile_node_widget.dart';
import 'relationship_group_node.dart';
import 'graph_controls.dart';
import 'orthogonal_edge_renderer.dart';
import 'saju_quick_view_sheet.dart';

/// 목업 데이터 사용 여부 (테스트용)
const bool _useMockData = true;

/// 관계 그래프 뷰
///
/// 위젯 구조:
/// - RelationshipGraphView (StatefulWidget)
///   └─ LayoutBuilder (반응형)
///       └─ Stack
///           ├─ InteractiveViewer (줌/팬)
///           │   └─ GraphView
///           │       └─ Node builder (me/group/profile)
///           └─ GraphControls (줌 버튼)
class RelationshipGraphView extends ConsumerStatefulWidget {
  const RelationshipGraphView({super.key});

  @override
  ConsumerState<RelationshipGraphView> createState() =>
      _RelationshipGraphViewState();
}

class _RelationshipGraphViewState extends ConsumerState<RelationshipGraphView> {
  final TransformationController _transformationController =
      TransformationController();

  // 현재 스케일 추적
  double _currentScale = 1.0;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  // === 줌 컨트롤 ===
  void _handleZoomIn() {
    _currentScale = (_currentScale * 1.2).clamp(0.3, 3.0);
    _transformationController.value = Matrix4.identity()..scale(_currentScale);
  }

  void _handleZoomOut() {
    _currentScale = (_currentScale * 0.8).clamp(0.3, 3.0);
    _transformationController.value = Matrix4.identity()..scale(_currentScale);
  }

  void _handleFitToScreen() {
    _currentScale = 1.0;
    _transformationController.value = Matrix4.identity();
  }

  // === 노드 탭 핸들러 (사주 빠른보기) ===
  void _onNodeTap(SajuProfile profile) {
    showSajuQuickView(
      context,
      profile: profile,
      onChatPressed: () {
        Navigator.pop(context);
        // TODO: Navigate to chat with this profile
      },
      onDetailPressed: () {
        Navigator.pop(context);
        // TODO: Navigate to detail screen
      },
    );
  }

  // === RelationshipType 문자열 변환 (Web 호환) ===
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
      return _buildResponsiveGraph(context, MockProfiles.profiles);
    }

    final profilesAsync = ref.watch(allProfilesProvider);
    return profilesAsync.when(
      data: (profiles) => _buildResponsiveGraph(context, profiles),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  /// 반응형 그래프 빌더
  Widget _buildResponsiveGraph(BuildContext context, List<SajuProfile> profiles) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 화면 크기 판단
        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 400;   // 작은 모바일
        final isMobile = screenWidth < 600;    // 일반 모바일
        final isTablet = screenWidth < 900;    // 태블릿

        // 화면 크기별 설정
        final GraphConfig config;
        if (isCompact) {
          config = GraphConfig.compact();
        } else if (isMobile) {
          config = GraphConfig.mobile();
        } else if (isTablet) {
          config = GraphConfig.tablet();
        } else {
          config = GraphConfig.desktop();
        }

        return _buildGraph(context, profiles, config, constraints);
      },
    );
  }

  /// 그래프 빌드
  Widget _buildGraph(
    BuildContext context,
    List<SajuProfile> profiles,
    GraphConfig config,
    BoxConstraints constraints,
  ) {
    final graph = _buildGraphFromProfiles(profiles);

    final algorithm = BuchheimWalkerConfiguration()
      ..siblingSeparation = config.siblingSeparation
      ..levelSeparation = config.levelSeparation
      ..subtreeSeparation = config.subtreeSeparation
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT;

    // 그래프 위젯 (고정 크기로 생성)
    final graphWidget = Container(
      padding: EdgeInsets.all(config.padding),
      child: GraphView(
        graph: graph,
        algorithm: BuchheimWalkerAlgorithm(
          algorithm,
          OrthogonalEdgeRenderer(
            lineColor: Colors.grey.shade400,
            strokeWidth: config.edgeWidth,
          ),
        ),
        paint: Paint()
          ..color = Colors.grey.shade400
          ..strokeWidth = config.edgeWidth
          ..style = PaintingStyle.stroke,
        builder: (Node node) => _buildNode(node, profiles, config),
      ),
    );

    // 화면에 자동 맞춤 (FittedBox로 스케일링)
    return Stack(
      children: [
        // 그래프 영역 - FittedBox로 화면에 맞춤
        Positioned.fill(
          child: InteractiveViewer(
            transformationController: _transformationController,
            constrained: false,
            minScale: 0.3,
            maxScale: 3.0,
            boundaryMargin: const EdgeInsets.all(100),
            onInteractionUpdate: (details) {
              _currentScale = _transformationController.value.getMaxScaleOnAxis();
            },
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: graphWidget,
              ),
            ),
          ),
        ),

        // 줌 컨트롤
        GraphControls(
          onZoomIn: _handleZoomIn,
          onZoomOut: _handleZoomOut,
          onFitToScreen: _handleFitToScreen,
        ),
      ],
    );
  }

  /// 노드 빌더
  Widget _buildNode(Node node, List<SajuProfile> profiles, GraphConfig config) {
    final nodeId = node.key?.value as String? ?? '';

    // Me 노드
    if (nodeId.startsWith('me_')) {
      if (nodeId == 'me_placeholder') {
        return MeNodeWidget(profile: null, size: config.meNodeSize);
      }
      final profileId = nodeId.substring(3);
      final profile = profiles.where((p) => p.id == profileId).firstOrNull;
      return MeNodeWidget(
        profile: profile,
        size: config.meNodeSize,
        onTap: profile != null ? () => _onNodeTap(profile) : null,
      );
    }

    // Group 노드
    if (nodeId.startsWith('group_')) {
      final relationTypeStr = nodeId.substring(6);
      final relationType = _parseRelationType(relationTypeStr);
      final count = profiles.where((p) => p.relationType == relationType).length;

      return RelationshipGroupNode(
        type: relationType,
        count: count,
        width: config.groupNodeWidth,
        height: config.groupNodeHeight,
      );
    }

    // Profile 노드
    final profile = profiles.where((p) => p.id == nodeId).firstOrNull;
    if (profile == null) {
      return const SizedBox.shrink();
    }
    return ProfileNodeWidget(
      profile: profile,
      width: config.profileNodeWidth,
      height: config.profileNodeHeight,
      onTap: () => _onNodeTap(profile),
    );
  }

  /// 그래프 구조 생성
  Graph _buildGraphFromProfiles(List<SajuProfile> profiles) {
    final graph = Graph();

    if (profiles.isEmpty) {
      graph.addNode(Node.Id('me_placeholder'));
      return graph;
    }

    // Me 프로필 찾기
    final meProfile = profiles
        .where((p) => p.relationType == RelationshipType.me)
        .firstOrNull ?? profiles.first;

    // Me 노드 생성
    final meNode = Node.Id('me_${meProfile.id}');
    graph.addNode(meNode);

    // 관계별 그룹화
    final profilesByRelation = <RelationshipType, List<SajuProfile>>{};
    for (final profile in profiles) {
      if (profile.id == meProfile.id) continue;
      profilesByRelation.putIfAbsent(profile.relationType, () => []).add(profile);
    }

    // 그룹 노드 및 프로필 노드 생성
    for (final entry in profilesByRelation.entries) {
      final relationType = entry.key;
      final groupProfiles = entry.value;

      // 그룹 노드
      final groupNode = Node.Id('group_${_relationTypeToString(relationType)}');
      graph.addNode(groupNode);
      graph.addEdge(meNode, groupNode);

      // 개별 프로필 노드
      for (final profile in groupProfiles) {
        final profileNode = Node.Id(profile.id);
        graph.addNode(profileNode);
        graph.addEdge(groupNode, profileNode);
      }
    }

    return graph;
  }
}

/// 그래프 설정 (FittedBox가 자동 스케일링하므로 고정 크기 사용)
class GraphConfig {
  final int siblingSeparation;
  final int levelSeparation;
  final int subtreeSeparation;
  final double padding;
  final double edgeWidth;
  final double meNodeSize;
  final double groupNodeWidth;
  final double groupNodeHeight;
  final double profileNodeWidth;
  final double profileNodeHeight;

  const GraphConfig({
    required this.siblingSeparation,
    required this.levelSeparation,
    required this.subtreeSeparation,
    required this.padding,
    required this.edgeWidth,
    required this.meNodeSize,
    required this.groupNodeWidth,
    required this.groupNodeHeight,
    required this.profileNodeWidth,
    required this.profileNodeHeight,
  });

  /// 기본 설정 - FittedBox가 화면에 맞게 스케일링
  factory GraphConfig.standard() => const GraphConfig(
    siblingSeparation: 80,
    levelSeparation: 100,
    subtreeSeparation: 100,
    padding: 40,
    edgeWidth: 2.0,
    meNodeSize: 90,
    groupNodeWidth: 80,
    groupNodeHeight: 45,
    profileNodeWidth: 110,
    profileNodeHeight: 70,
  );

  // 하위 호환성을 위해 유지
  factory GraphConfig.compact() => GraphConfig.standard();
  factory GraphConfig.mobile() => GraphConfig.standard();
  factory GraphConfig.tablet() => GraphConfig.standard();
  factory GraphConfig.desktop() => GraphConfig.standard();
}
