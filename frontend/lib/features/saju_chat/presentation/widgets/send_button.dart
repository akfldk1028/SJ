import 'package:flutter/material.dart';

/// 채팅 전송 버튼 위젯
class SendButton extends StatelessWidget {
  final bool enabled;
  final bool hasText;
  final VoidCallback? onPressed;

  const SendButton({
    super.key,
    required this.enabled,
    required this.hasText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = hasText && enabled;

    return IconButton.filled(
      onPressed: isActive ? onPressed : null,
      icon: const Icon(Icons.send),
      style: IconButton.styleFrom(
        backgroundColor: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        foregroundColor: isActive
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
