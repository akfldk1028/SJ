import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphview/GraphView.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;
import '../../../domain/entities/saju_profile.dart';
import '../../../domain/entities/relationship_type.dart';
import '../../../domain/entities/gender.dart';
import '../../../data/mock/mock_profiles.dart';
import '../../../data/models/profile_relation_model.dart';
// Note: Provider imports 제거됨 - props 기반 데이터 전달 방식으로 변경
import '../../../../../router/routes.dart';
import 'me_node_widget.dart';
import 'profile_node_widget.dart';
import 'relationship_group_node.dart';
import 'graph_controls.dart';
import 'saju_quick_view_sheet.dart';

/// 목업 데이터 사용 여부 (테스트용)
const bool _useMockData = false;

/// 관계 그래프 뷰 (SJ-Flow Large Tree 기능 사용)
///
/// 주의: Provider를 직접 watch하지 않음 (defunct widget 에러 방지)
/// 부모 위젯에서 데이터를 전달받음
class RelationshipGraphView extends ConsumerStatefulWidget {
  const RelationshipGraphView({
    super.key,
    required this.activeProfile,
    required this.relationsByCategory,
  });

  /// 활성 프로필
  final SajuProfile activeProfile;

  /// 카테고리별 관계 데이터
  final Map<String, List<ProfileRelationModel>> relationsByCategory;

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

  /// 현재 관계 데이터 (그래프 재구성 감지용)
  Map<String, List<ProfileRelationModel>>? _currentRelationsByCategory;

  /// 현재 활성 프로필 ID (그래프 재구성 감지용)
  String? _currentActiveProfileId;

  /// 그래프 초기화 완료 여부
  bool _isGraphInitialized = false;

  /// 그래프 버전 (Key로 사용하여 GraphView 강제 재생성)
  int _graphVersion = 0;

  @override
  void initState() {
    super.initState();

    // GraphViewController 초기화 (TransformationController 연결)
    _controller = GraphViewController(
      transformationController: _transformController,
    );

    // Configuration 설정 (Large Tree 스타일)
    // LEFT_RIGHT 방향: levelSeparation=가로, siblingSeparation=세로
    // 노드 크기: 그룹 노드 100x50, 관계 노드 150x~100
    // 세로 간격: 노드 높이(100) + 여백(100) = 200 이상 필요
    builder
      ..siblingSeparation = 120  // 세로 간격 (노드 간 순수 간격)
      ..levelSeparation = 200    // 가로 간격 (레벨 간 거리)
      ..subtreeSeparation = 150  // 서브트리 간 세로 간격
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

  /// dispose 여부 플래그
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    // GraphView 애니메이션이 끝나기 전 dispose 방지 - 지연 dispose
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transformController.dispose();
    });
    super.dispose();
  }

  // === 줌 컨트롤 ===
  /// 줌 인 - 현재 pan 위치 유지하면서 화면 중심 기준 확대
  void _zoomIn() {
    if (_isDisposed || !mounted) return;

    final currentMatrix = _transformController.value.clone();
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.3).clamp(0.1, 5.0);
    final scaleFactor = newScale / currentScale;

    // 화면 중심을 focal point로 사용
    final size = MediaQuery.of(context).size;
    final focalPoint = Offset(size.width / 2, size.height / 2);

    // 현재 translation 가져오기
    final translation = currentMatrix.getTranslation();

    // focal point 기준으로 스케일 적용 (pan 위치 유지)
    final newTx = focalPoint.dx - (focalPoint.dx - translation.x) * scaleFactor;
    final newTy = focalPoint.dy - (focalPoint.dy - translation.y) * scaleFactor;

    _transformController.value = Matrix4.identity()
      ..translate(newTx, newTy)
      ..scale(newScale);
  }

  /// 줌 아웃 - 현재 pan 위치 유지하면서 화면 중심 기준 축소
  void _zoomOut() {
    if (_isDisposed || !mounted) return;

    final currentMatrix = _transformController.value.clone();
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.3).clamp(0.1, 5.0);
    final scaleFactor = newScale / currentScale;

    // 화면 중심을 focal point로 사용
    final size = MediaQuery.of(context).size;
    final focalPoint = Offset(size.width / 2, size.height / 2);

    // 현재 translation 가져오기
    final translation = currentMatrix.getTranslation();

    // focal point 기준으로 스케일 적용 (pan 위치 유지)
    final newTx = focalPoint.dx - (focalPoint.dx - translation.x) * scaleFactor;
    final newTy = focalPoint.dy - (focalPoint.dy - translation.y) * scaleFactor;

    _transformController.value = Matrix4.identity()
      ..translate(newTx, newTy)
      ..scale(newScale);
  }

  // === 노드 탭 핸들러 ===
  void _onNodeTap(Node node) {
    if (_isDisposed || !mounted) return;
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
        // 궁합 채팅으로 이동 (targetProfileId = 선택한 프로필, autoMention으로 자동 멘션)
        context.go('${Routes.sajuChat}?type=compatibility&profileId=${profile.id}&autoMention=true');
      },
      onDetailPressed: () {
        Navigator.pop(context);
        // 사주 상세 화면으로 이동
        context.push('${Routes.sajuDetail}?profileId=${profile.id}');
      },
      onCompatibilityPressed: () {
        Navigator.pop(context);
        // 궁합 분석 목록 화면으로 이동
        context.push('${Routes.compatibilityList}?profileId=${profile.id}');
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
    // 목업 데이터 사용 시
    if (_useMockData) {
      return _buildGraph(context, MockProfiles.profiles, {});
    }

    // ========================================
    // Props 기반 데이터 사용 (Provider watch 안함!)
    // 부모(RelationshipScreen)에서 데이터를 전달받음
    // 이렇게 하면 상위에서 invalidate해도 이 위젯은 영향 없음
    // ========================================
    final activeProfile = widget.activeProfile;
    final relationsByCategory = widget.relationsByCategory;

    // 현재 관계 개수 계산
    final totalCount = relationsByCategory.values.fold<int>(0, (sum, list) => sum + list.length);
    debugPrint('📊 [Graph.build] Props로 받은 데이터: 총 $totalCount개');

    // 데이터가 변경되었을 때만 그래프 재구성
    final needsRebuild = !_isGraphInitialized ||
        _currentActiveProfileId != activeProfile.id ||
        !_isSameRelations(relationsByCategory);

    debugPrint('📊 [Graph.build] needsRebuild=$needsRebuild, initialized=$_isGraphInitialized');

    if (needsRebuild) {
      // PostFrameCallback으로 레이아웃 계산 후 그래프 재구성
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed) {
          _buildGraphFromRelations(activeProfile, relationsByCategory);
          _currentActiveProfileId = activeProfile.id;
          _currentRelationsByCategory = relationsByCategory;
          _isGraphInitialized = true;
          setState(() {});
        }
      });

      // 첫 빌드 시 로딩 표시
      if (!_isGraphInitialized) {
        return const Center(child: CircularProgressIndicator());
      }
    }

    return _buildGraph(context, [activeProfile], relationsByCategory);
  }

  /// 프로필 목록 비교
  bool _isSameProfiles(List<SajuProfile> profiles) {
    if (_currentProfiles.length != profiles.length) return false;
    for (int i = 0; i < profiles.length; i++) {
      if (_currentProfiles[i].id != profiles[i].id) return false;
    }
    return true;
  }

  /// 관계 데이터 비교
  bool _isSameRelations(Map<String, List<ProfileRelationModel>> newRelations) {
    if (_currentRelationsByCategory == null) return false;

    // 전체 관계 개수 비교 (삭제/추가 감지)
    final oldTotalCount = _currentRelationsByCategory!.values.fold<int>(0, (sum, list) => sum + list.length);
    final newTotalCount = newRelations.values.fold<int>(0, (sum, list) => sum + list.length);
    if (oldTotalCount != newTotalCount) {
      debugPrint('🔄 [Graph] 관계 개수 변경 감지: $oldTotalCount → $newTotalCount');
      return false;
    }

    // 카테고리 키 비교
    if (_currentRelationsByCategory!.length != newRelations.length) {
      debugPrint('🔄 [Graph] 카테고리 개수 변경 감지');
      return false;
    }

    for (final key in newRelations.keys) {
      final oldList = _currentRelationsByCategory![key];
      final newList = newRelations[key];
      if (oldList == null || newList == null) return false;
      if (oldList.length != newList.length) {
        debugPrint('🔄 [Graph] 카테고리 "$key" 관계 개수 변경: ${oldList.length} → ${newList.length}');
        return false;
      }

      for (int i = 0; i < oldList.length; i++) {
        final oldItem = oldList[i];
        final newItem = newList[i];
        // ID + display_name + birth_date 비교 (수정 감지)
        if (oldItem.id != newItem.id) return false;
        if (oldItem.toProfile?.displayName != newItem.toProfile?.displayName) {
          debugPrint('🔄 [Graph] 이름 변경 감지: ${oldItem.toProfile?.displayName} → ${newItem.toProfile?.displayName}');
          return false;
        }
        if (oldItem.toProfile?.birthDate != newItem.toProfile?.birthDate) {
          debugPrint('🔄 [Graph] 생년월일 변경 감지');
          return false;
        }
      }
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
                key: ValueKey('graph_v$_graphVersion'),
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
                onZoomToFit: () {
                  if (_isDisposed || !mounted) return;
                  _controller.zoomToFit();
                },
                onResetView: () {
                  if (_isDisposed || !mounted) return;
                  _controller.resetView();
                },
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
        // 궁합 채팅으로 이동 (autoMention으로 자동 멘션)
        context.go('${Routes.sajuChat}?type=compatibility&profileId=${relation.toProfileId}&autoMention=true');
      },
      onDetailPressed: () {
        Navigator.pop(context);
        // 사주 상세 화면으로 이동
        context.push('${Routes.sajuDetail}?profileId=${relation.toProfileId}');
      },
      onCompatibilityPressed: () {
        Navigator.pop(context);
        // 궁합 분석이 있으면 상세 화면, 없으면 궁합 목록 화면으로 이동
        if (relation.compatibilityAnalysisId != null) {
          context.push('${Routes.compatibilityDetail}?analysisId=${relation.compatibilityAnalysisId}');
        } else {
          context.push('${Routes.compatibilityList}?profileId=${relation.toProfileId}');
        }
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

    // 그래프 버전 증가 → GraphView.builder 강제 재생성 → 레이아웃 재계산
    _graphVersion++;

    print('[Graph] ===== Supabase 관계 그래프 구축 완료 (v$_graphVersion) =====');
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
///
/// 궁합 점수 표시 포함 (pair_hapchung의 overall_score)
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
    final compatibilityScore = relation.compatibilityScore;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ShadCard(
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
          // 궁합 점수 뱃지 (우측 상단)
          if (compatibilityScore != null)
            Positioned(
              top: -8,
              right: -8,
              child: _CompatibilityScoreBadge(score: compatibilityScore),
            ),
        ],
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

/// 궁합 점수 뱃지 위젯
///
/// 관계 노드의 우측 상단에 표시되는 원형 뱃지
class _CompatibilityScoreBadge extends StatelessWidget {
  const _CompatibilityScoreBadge({
    required this.score,
  });

  final int score;

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$score',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFFEC4899); // pink
    if (score >= 60) return const Color(0xFF3B82F6); // blue
    if (score >= 40) return const Color(0xFFF59E0B); // amber
    return const Color(0xFF6B7280); // gray
  }
}
