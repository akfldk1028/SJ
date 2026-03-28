import 'dart:math' show sin, pi;
import 'package:flutter/material.dart';
import 'zodiac_animal_avatar.dart';

/// 십이지신 온보딩용 채팅 버블
///
/// AI 동물이 말하는 느낌의 대화 버블.
/// 타이핑 효과 + 아바타 + 말풍선.
class ZodiacChatBubble extends StatefulWidget {
  /// 메시지 텍스트
  final String text;

  /// 동물 이모지
  final String emoji;

  /// 이미지 URL (Supabase Storage)
  final String? imageUrl;

  /// 글로우 색상
  final Color accentColor;

  /// AI 메시지인지 유저 메시지인지
  final bool isAi;

  /// 타이핑 애니메이션 여부
  final bool typewrite;

  /// 타이핑 완료 콜백
  final VoidCallback? onTypewriteComplete;

  /// 자식 위젯 (입력 필드 등 임베드용)
  final Widget? child;

  const ZodiacChatBubble({
    super.key,
    this.text = '',
    this.emoji = '🐴',
    this.imageUrl,
    this.accentColor = Colors.orange,
    this.isAi = true,
    this.typewrite = true,
    this.onTypewriteComplete,
    this.child,
  });

  @override
  State<ZodiacChatBubble> createState() => _ZodiacChatBubbleState();
}

class _ZodiacChatBubbleState extends State<ZodiacChatBubble>
    with SingleTickerProviderStateMixin {
  String _displayText = '';
  bool _typewriteComplete = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();

    if (widget.typewrite && widget.text.isNotEmpty) {
      _startTypewrite();
    } else {
      _displayText = widget.text;
      _typewriteComplete = true;
    }
  }

  Future<void> _startTypewrite() async {
    for (int i = 0; i <= widget.text.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted) return;
      setState(() {
        _displayText = widget.text.substring(0, i);
      });
    }
    if (mounted) {
      setState(() => _typewriteComplete = true);
      widget.onTypewriteComplete?.call();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              widget.isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (widget.isAi) ...[
              ZodiacSmallAvatar(
                emoji: widget.emoji,
                imageUrl: widget.imageUrl,
                glowColor: widget.accentColor,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: widget.isAi
                      ? widget.accentColor.withAlpha(20)
                      : Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(widget.isAi ? 4 : 16),
                    bottomRight: Radius.circular(widget.isAi ? 16 : 4),
                  ),
                  border: Border.all(
                    color: widget.isAi
                        ? widget.accentColor.withAlpha(40)
                        : Colors.white.withAlpha(20),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_displayText.isNotEmpty)
                      Text(
                        _displayText,
                        style: TextStyle(
                          color: Colors.white.withAlpha(230),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    if (!_typewriteComplete && widget.typewrite)
                      _TypingIndicator(color: widget.accentColor),
                    if (widget.child != null && _typewriteComplete) ...[
                      const SizedBox(height: 12),
                      widget.child!,
                    ],
                  ],
                ),
              ),
            ),
            if (!widget.isAi) const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

/// 타이핑 중 점 애니메이션
class _TypingIndicator extends StatefulWidget {
  final Color color;
  const _TypingIndicator({required this.color});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final delay = i * 0.2;
              final t = (_controller.value - delay).clamp(0.0, 1.0);
              final opacity = (0.3 + 0.7 * (0.5 + 0.5 * sin(t * pi * 2))).clamp(0.3, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
