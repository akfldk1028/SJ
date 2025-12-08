import 'package:flutter/material.dart';
import '../../../domain/entities/saju_profile.dart';
import '../../../domain/entities/relationship_type.dart';

/// 개별 프로필 노드
///
/// 모던 카드 스타일 - 부드러운 그림자와 그라데이션 악센트
class ProfileNodeWidget extends StatelessWidget {
  const ProfileNodeWidget({
    super.key,
    required this.profile,
    required this.onTap,
    this.width = 110,
    this.height = 70,
  });

  final SajuProfile profile;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final avatarRadius = height * 0.26;
    final nameSize = height * 0.18;
    final dateSize = height * 0.13;
    final padding = height * 0.1;
    final colors = _getRelationshipColors(profile.relationType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(height * 0.22),
          boxShadow: [
            // 주 그림자
            BoxShadow(
              color: colors.primary.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            // 작은 그림자
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 왼쪽 악센트 바
            Positioned(
              left: 0,
              top: height * 0.15,
              bottom: height * 0.15,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors.primary, colors.secondary],
                  ),
                ),
              ),
            ),
            // 콘텐츠
            Padding(
              padding: EdgeInsets.fromLTRB(padding * 1.2, padding * 0.6, padding, padding * 0.6),
              child: Row(
                children: [
                  // 아바타 (그라데이션)
                  Container(
                    width: avatarRadius * 2,
                    height: avatarRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colors.primary, colors.secondary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withOpacity(0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        profile.displayName.isNotEmpty ? profile.displayName[0] : '?',
                        style: TextStyle(
                          fontSize: avatarRadius * 0.85,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: padding * 0.9),
                  // 텍스트
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          profile.displayName,
                          style: TextStyle(
                            fontSize: nameSize,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF263238),
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (height > 50) ...[
                          SizedBox(height: height * 0.04),
                          Text(
                            profile.birthDateFormatted,
                            style: TextStyle(
                              fontSize: dateSize,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF78909C),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ],
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

  _ColorPair _getRelationshipColors(RelationshipType relationType) {
    if (relationType == RelationshipType.family) {
      return const _ColorPair(Color(0xFFEF5350), Color(0xFFFF8A80)); // 레드 계열
    }
    if (relationType == RelationshipType.friend) {
      return const _ColorPair(Color(0xFF26A69A), Color(0xFF4DB6AC)); // 틸 계열
    }
    if (relationType == RelationshipType.lover) {
      return const _ColorPair(Color(0xFFEC407A), Color(0xFFF48FB1)); // 핑크 계열
    }
    if (relationType == RelationshipType.work) {
      return const _ColorPair(Color(0xFF42A5F5), Color(0xFF64B5F6)); // 블루 계열
    }
    if (relationType == RelationshipType.me) {
      return const _ColorPair(Color(0xFFEC407A), Color(0xFFAB47BC)); // 핑크-퍼플
    }
    return const _ColorPair(Color(0xFF78909C), Color(0xFF90A4AE)); // 그레이 계열
  }
}

class _ColorPair {
  final Color primary;
  final Color secondary;

  const _ColorPair(this.primary, this.secondary);
}
