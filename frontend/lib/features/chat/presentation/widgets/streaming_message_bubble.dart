import 'package:shadcn_flutter/shadcn_flutter.dart';

/// 스트리밍 중인 AI 응답 버블 위젯 (Shadcn UI)
class StreamingMessageBubble extends StatelessWidget {
  const StreamingMessageBubble({
    super.key,
    required this.content,
  });

  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 아바타
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              RadixIcons.star,
              size: 18,
              color: Colors.white,
            ),
          ),
          const Gap(8),

          // 메시지 버블
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: content.isEmpty
                  ? _buildTypingIndicator(theme)
                  : _buildStreamingText(theme),
            ),
          ),
        ],
      ),
    );
  }

  /// 타이핑 인디케이터 (점 3개 애니메이션)
  Widget _buildTypingIndicator(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TypingDot(delay: 0, color: theme.colorScheme.primary),
        const Gap(4),
        _TypingDot(delay: 150, color: theme.colorScheme.primary),
        const Gap(4),
        _TypingDot(delay: 300, color: theme.colorScheme.primary),
      ],
    );
  }

  /// 스트리밍 중인 텍스트
  Widget _buildStreamingText(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content,
          style: theme.typography.base.copyWith(
            color: theme.colorScheme.secondaryForeground,
          ),
        ),
        const Gap(4),
        // 커서 애니메이션
        _BlinkingCursor(color: theme.colorScheme.primary),
      ],
    );
  }
}

/// 타이핑 도트 애니메이션
class _TypingDot extends StatefulWidget {
  const _TypingDot({
    required this.delay,
    required this.color,
  });

  final int delay;
  final Color color;

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -4 * _animation.value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.color.scaleAlpha(0.6 + 0.4 * _animation.value),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

/// 깜빡이는 커서
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor({required this.color});

  final Color color;

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: Container(
            width: 2,
            height: 16,
            color: widget.color,
          ),
        );
      },
    );
  }
}
