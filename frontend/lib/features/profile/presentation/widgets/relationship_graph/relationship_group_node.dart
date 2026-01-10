import 'package:flutter/material.dart';
import '../../../domain/entities/relationship_type.dart';

/// 관계 그룹 노드 (가족, 친구, 연인 등)
///
/// 모던 글래스모피즘 스타일
/// - isCollapsed: 접힘 상태 표시 (SJ-Flow Large Tree 기능)
class RelationshipGroupNode extends StatelessWidget {
  const RelationshipGroupNode({
    super.key,
    required this.type,
    required this.count,
    this.width = 80,
    this.height = 45,
    this.onTap,
    this.isCollapsed = false,
  });

  final RelationshipType type;
  final int count;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    final fontSize = height * 0.28;
    final borderRadius = height * 0.45;
    final colors = _getGradientColors(type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: [
            // 주 그림자 (컬러)
            BoxShadow(
              color: colors[0].withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            // 부드러운 내부 광택
            BoxShadow(
              color: Colors.white.withOpacity(0.15),
              blurRadius: 1,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 광택 효과 (상단)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: height * 0.45,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(borderRadius),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            // 콘텐츠
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 아이콘
                  Icon(
                    _getIcon(type),
                    size: fontSize * 0.9,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(width: 4),
                  // 텍스트
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  // 확장/축소 인디케이터
                  const SizedBox(width: 2),
                  Icon(
                    isCollapsed
                        ? Icons.expand_more_rounded
                        : Icons.expand_less_rounded,
                    size: fontSize * 0.8,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientColors(RelationshipType type) {
    if (type == RelationshipType.family) {
      return const [Color(0xFFEF5350), Color(0xFFE57373)]; // 레드 계열
    }
    if (type == RelationshipType.friend) {
      return const [Color(0xFF26A69A), Color(0xFF4DB6AC)]; // 틸 계열
    }
    if (type == RelationshipType.lover) {
      return const [Color(0xFFEC407A), Color(0xFFF06292)]; // 핑크 계열
    }
    if (type == RelationshipType.work) {
      return const [Color(0xFF42A5F5), Color(0xFF64B5F6)]; // 블루 계열
    }
    if (type == RelationshipType.me) {
      return const [Color(0xFFEC407A), Color(0xFFAB47BC)]; // 핑크-퍼플
    }
    return const [Color(0xFF78909C), Color(0xFF90A4AE)]; // 그레이 계열
  }

  IconData _getIcon(RelationshipType type) {
    if (type == RelationshipType.family) return Icons.home_rounded;
    if (type == RelationshipType.friend) return Icons.people_rounded;
    if (type == RelationshipType.lover) return Icons.favorite_rounded;
    if (type == RelationshipType.work) return Icons.work_rounded;
    if (type == RelationshipType.me) return Icons.person_rounded;
    return Icons.group_rounded;
  }
}
