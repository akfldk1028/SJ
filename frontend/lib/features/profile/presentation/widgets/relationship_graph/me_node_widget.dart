import 'package:flutter/material.dart';
import '../../../domain/entities/saju_profile.dart';

/// "나" 노드 - Root 노드로 특별한 스타일
///
/// 그라데이션 배경과 글래스모피즘 효과
class MeNodeWidget extends StatelessWidget {
  const MeNodeWidget({
    super.key,
    required this.profile,
    this.size = 90,
    this.onTap,
  });

  final SajuProfile? profile;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatarRadius = size * 0.24;
    final fontSize = size * 0.2;
    final nameSize = size * 0.14;
    final dateSize = size * 0.1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8BBD9), // soft pink
              Color(0xFFE1BEE7), // soft purple
            ],
          ),
          boxShadow: [
            // 외부 그림자 (부드럽게)
            BoxShadow(
              color: const Color(0xFFE91E63).withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            // 내부 하이라이트
            const BoxShadow(
              color: Colors.white,
              blurRadius: 2,
              offset: Offset(-1, -1),
            ),
          ],
        ),
        child: Container(
          margin: EdgeInsets.all(size * 0.035),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.85),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 아바타 (그라데이션)
              Container(
                width: avatarRadius * 2,
                height: avatarRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFEC407A), // vibrant pink
                      Color(0xFFAB47BC), // purple accent
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC407A).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    profile?.displayName.isNotEmpty == true
                        ? profile!.displayName[0]
                        : '나',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              SizedBox(height: size * 0.045),
              // 이름
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size * 0.06),
                child: Text(
                  profile?.displayName ?? '나',
                  style: TextStyle(
                    fontSize: nameSize,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF37474F),
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 생년월일
              if (profile != null && size > 70)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    profile!.birthDateFormatted,
                    style: TextStyle(
                      fontSize: dateSize,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF78909C),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
