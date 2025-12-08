import 'package:flutter/material.dart';

/// 헤더 뷰 - 환영 메시지 및 날짜 표시
///
/// 위젯 트리 최적화:
/// - const 생성자 사용
/// - 100줄 이하 유지
/// - 애니메이션 별도 처리
class HeaderView extends StatelessWidget {
  final AnimationController animationController;

  const HeaderView({
    super.key,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.1, 0.3, curve: Curves.fastOutSlowIn),
      ),
    );

    return AnimatedBuilder(
      animation: headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1.0 - headerAnimation.value)),
          child: Opacity(
            opacity: headerAnimation.value,
            child: child,
          ),
        );
      },
      child: const Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GreetingText(),
            SizedBox(height: 8),
            _DateDisplay(),
          ],
        ),
      ),
    );
  }
}

/// 환영 메시지 위젯
class _GreetingText extends StatelessWidget {
  const _GreetingText();

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? '좋은 아침이에요'
        : hour < 18
            ? '좋은 오후에요'
            : '좋은 저녁이에요';

    return Text(
      greeting,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.2,
      ),
    );
  }
}

/// 날짜 표시 위젯
class _DateDisplay extends StatelessWidget {
  const _DateDisplay();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[now.weekday - 1];
    final formattedDate = '${now.year}년 ${now.month}월 ${now.day}일 $weekday요일';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today,
            size: 14,
            color: Color(0xFFFFB74D), // 골드
          ),
          const SizedBox(width: 6),
          Text(
            formattedDate,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
