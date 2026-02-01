import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphview/GraphView.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../router/routes.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/saju_chart.dart';
import '../providers/saju_chart_provider.dart';

/// 사주 관계도 화면 - GraphView를 사용한 시각화
class SajuGraphScreen extends ConsumerStatefulWidget {
  const SajuGraphScreen({super.key});

  @override
  ConsumerState<SajuGraphScreen> createState() => _SajuGraphScreenState();
}

class _SajuGraphScreenState extends ConsumerState<SajuGraphScreen> {
  final Graph graph = Graph()..isTree = true;
  final GraphViewController controller = GraphViewController();

  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration()
    ..siblingSeparation = 60
    ..levelSeparation = 80
    ..subtreeSeparation = 80
    ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(activeProfileProvider);
    final chartAsync = ref.watch(currentSajuChartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('사주 관계도'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.sajuChart),
        ),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return _buildNoProfile(context);
          }
          return chartAsync.when(
            data: (chart) {
              if (chart == null) {
                return _buildNoChart(context);
              }
              return _buildGraphView(context, profile, chart);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _buildError(context, e.toString()),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(context, e.toString()),
      ),
    );
  }

  Widget _buildGraphView(BuildContext context, dynamic profile, SajuChart chart) {
    // 그래프 초기화
    _buildSajuGraph(chart);

    return Column(
      children: [
        // 헤더 정보
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                profile.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${chart.fullSajuHanja}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),

        // 그래프 뷰
        Expanded(
          child: GraphView.builder(
            graph: graph,
            algorithm: BuchheimWalkerAlgorithm(
              builder,
              TreeEdgeRenderer(builder),
            ),
            controller: controller,
            animated: true,
            autoZoomToFit: true,
            centerGraph: true,
            builder: (Node node) {
              final nodeData = node.key?.value as Map<String, dynamic>?;
              if (nodeData == null) {
                return const SizedBox.shrink();
              }
              return _buildNodeWidget(context, nodeData);
            },
          ),
        ),

        // 하단 범례
        _buildLegend(context),
      ],
    );
  }

  void _buildSajuGraph(SajuChart chart) {
    graph.nodes.clear();
    graph.edges.clear();

    // 루트 노드: 나 (일간)
    final rootNode = Node.Id({
      'type': 'root',
      'label': '나',
      'subLabel': chart.dayMaster,
      'oheng': chart.dayPillar.ganOheng,
    });

    // 4개 기둥 노드
    final yearNode = Node.Id({
      'type': 'pillar',
      'label': '년주',
      'gan': chart.yearPillar.gan,
      'ji': chart.yearPillar.ji,
      'oheng': chart.yearPillar.ganOheng,
    });

    final monthNode = Node.Id({
      'type': 'pillar',
      'label': '월주',
      'gan': chart.monthPillar.gan,
      'ji': chart.monthPillar.ji,
      'oheng': chart.monthPillar.ganOheng,
    });

    final dayNode = Node.Id({
      'type': 'pillar',
      'label': '일주',
      'gan': chart.dayPillar.gan,
      'ji': chart.dayPillar.ji,
      'oheng': chart.dayPillar.ganOheng,
      'isMe': true,
    });

    // 시주 (있을 경우)
    Node? hourNode;
    if (chart.hourPillar != null) {
      hourNode = Node.Id({
        'type': 'pillar',
        'label': '시주',
        'gan': chart.hourPillar!.gan,
        'ji': chart.hourPillar!.ji,
        'oheng': chart.hourPillar!.ganOheng,
      });
    }

    // 천간/지지 하위 노드들
    final yearGanNode = Node.Id({
      'type': 'gan',
      'label': chart.yearPillar.gan,
      'hanja': chart.yearPillar.ganHanja,
      'oheng': chart.yearPillar.ganOheng,
    });
    final yearJiNode = Node.Id({
      'type': 'ji',
      'label': chart.yearPillar.ji,
      'hanja': chart.yearPillar.jiHanja,
      'oheng': chart.yearPillar.jiOheng,
    });

    final monthGanNode = Node.Id({
      'type': 'gan',
      'label': chart.monthPillar.gan,
      'hanja': chart.monthPillar.ganHanja,
      'oheng': chart.monthPillar.ganOheng,
    });
    final monthJiNode = Node.Id({
      'type': 'ji',
      'label': chart.monthPillar.ji,
      'hanja': chart.monthPillar.jiHanja,
      'oheng': chart.monthPillar.jiOheng,
    });

    final dayGanNode = Node.Id({
      'type': 'gan',
      'label': chart.dayPillar.gan,
      'hanja': chart.dayPillar.ganHanja,
      'oheng': chart.dayPillar.ganOheng,
      'isMe': true,
    });
    final dayJiNode = Node.Id({
      'type': 'ji',
      'label': chart.dayPillar.ji,
      'hanja': chart.dayPillar.jiHanja,
      'oheng': chart.dayPillar.jiOheng,
    });

    // 엣지 연결: 루트 -> 기둥들
    graph.addEdge(rootNode, yearNode);
    graph.addEdge(rootNode, monthNode);
    graph.addEdge(rootNode, dayNode);
    if (hourNode != null) {
      graph.addEdge(rootNode, hourNode);
    }

    // 기둥 -> 천간/지지
    graph.addEdge(yearNode, yearGanNode);
    graph.addEdge(yearNode, yearJiNode);
    graph.addEdge(monthNode, monthGanNode);
    graph.addEdge(monthNode, monthJiNode);
    graph.addEdge(dayNode, dayGanNode);
    graph.addEdge(dayNode, dayJiNode);

    if (hourNode != null && chart.hourPillar != null) {
      final hourGanNode = Node.Id({
        'type': 'gan',
        'label': chart.hourPillar!.gan,
        'hanja': chart.hourPillar!.ganHanja,
        'oheng': chart.hourPillar!.ganOheng,
      });
      final hourJiNode = Node.Id({
        'type': 'ji',
        'label': chart.hourPillar!.ji,
        'hanja': chart.hourPillar!.jiHanja,
        'oheng': chart.hourPillar!.jiOheng,
      });
      graph.addEdge(hourNode, hourGanNode);
      graph.addEdge(hourNode, hourJiNode);
    }
  }

  Widget _buildNodeWidget(BuildContext context, Map<String, dynamic> data) {
    final type = data['type'] as String;
    final oheng = data['oheng'] as String?;
    final color = _getOhengColor(oheng);

    switch (type) {
      case 'root':
        return _buildRootNode(context, data, color);
      case 'pillar':
        return _buildPillarNode(context, data, color);
      case 'gan':
      case 'ji':
        return _buildGanJiNode(context, data, color);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRootNode(BuildContext context, Map<String, dynamic> data, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data['label'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            data['subLabel'] as String,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarNode(BuildContext context, Map<String, dynamic> data, Color color) {
    final isMe = data['isMe'] == true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? color : Colors.white,
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data['label'] as String,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${data['gan']}${data['ji']}',
            style: TextStyle(
              color: isMe ? Colors.white : color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGanJiNode(BuildContext context, Map<String, dynamic> data, Color color) {
    final isMe = data['isMe'] == true;
    final isGan = data['type'] == 'gan';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe ? color : color.withOpacity(0.1),
        border: Border.all(color: color, width: isMe ? 2 : 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data['hanja'] as String? ?? data['label'] as String,
            style: TextStyle(
              color: isMe ? Colors.white : color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            data['label'] as String,
            style: TextStyle(
              color: isMe ? Colors.white.withOpacity(0.8) : Colors.grey[600],
              fontSize: 13,
            ),
          ),
          Text(
            isGan ? '천간' : '지지',
            style: TextStyle(
              color: isMe ? Colors.white.withOpacity(0.6) : Colors.grey[400],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Color _getOhengColor(String? oheng) {
    switch (oheng) {
      case '목':
        return const Color(0xFF4CAF50); // 녹색
      case '화':
        return const Color(0xFFE53935); // 빨강
      case '토':
        return const Color(0xFFFF9800); // 노랑/주황
      case '금':
        return const Color(0xFF9E9E9E); // 흰색/회색
      case '수':
        return const Color(0xFF2196F3); // 파랑
      default:
        return Colors.grey;
    }
  }

  Widget _buildLegend(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem('목', const Color(0xFF4CAF50)),
          _buildLegendItem('화', const Color(0xFFE53935)),
          _buildLegendItem('토', const Color(0xFFFF9800)),
          _buildLegendItem('금', const Color(0xFF9E9E9E)),
          _buildLegendItem('수', const Color(0xFF2196F3)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildNoProfile(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('프로필이 없습니다', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          ShadButton(
            onPressed: () => context.go(Routes.profileEdit),
            child: const Text('프로필 등록하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoChart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('사주를 계산할 수 없습니다', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          ShadButton(
            onPressed: () => context.go(Routes.profileEdit),
            child: const Text('프로필 수정하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text('오류가 발생했습니다', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
