import 'dart:async';
import 'package:flutter/material.dart';

import 'typing_indicator.dart';

/// AI가 생각 중일 때 표시하는 버블
///
/// GPT-5.2 Thinking은 30-60초 소요되므로
/// 사용자가 지루하지 않도록 순환 메시지 표시
///
/// 2026-01-04: 순환 메시지 + 애니메이션 추가
class ThinkingBubble extends StatefulWidget {
  const ThinkingBubble({super.key});

  @override
  State<ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<ThinkingBubble>
    with SingleTickerProviderStateMixin {
  /// 사주 테마 로딩 메시지
  static const List<String> _thinkingMessages = [
    '🔮 사주팔자를 풀어보고 있어요...',
    '⭐ 오행의 기운을 읽고 있어요...',
    '🌙 음양의 조화를 살펴보고 있어요...',
    '📜 운명의 흐름을 분석 중이에요...',
    '🧙 천간지지를 해석하고 있어요...',
    '✨ 당신만의 답을 준비하고 있어요...',
    '🎋 대운의 흐름을 살펴보고 있어요...',
    '🌟 숨겨진 기운을 찾고 있어요...',
    '🏮 길한 방향을 탐색 중이에요...',
    '🍀 행운의 기운을 모으고 있어요...',
  ];

  int _currentIndex = 0;
  Timer? _timer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 페이드 애니메이션 설정
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    // 3초마다 메시지 변경
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fadeController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % _thinkingMessages.length;
          });
          _fadeController.forward();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 아바타 (펄스 애니메이션)
          _PulsingAvatar(theme: theme),
          const SizedBox(width: 8),
          // 메시지 버블
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 순환 메시지
                  Flexible(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        _thinkingMessages[_currentIndex],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const TypingIndicator(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 펄스 애니메이션이 있는 아바타
class _PulsingAvatar extends StatefulWidget {
  final ThemeData theme;

  const _PulsingAvatar({required this.theme});

  @override
  State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: CircleAvatar(
        radius: 16,
        backgroundColor: widget.theme.colorScheme.secondaryContainer,
        child: Icon(
          Icons.auto_awesome,
          size: 18,
          color: widget.theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
