import 'package:flutter/material.dart';

import '../../domain/models/ai_persona.dart';

/// 페르소나 아바타 위젯
///
/// 원형 배경에 이모지를 표시하는 간단한 아바타
class PersonaAvatar extends StatelessWidget {
  final AiPersona persona;
  final double size;
  final VoidCallback? onTap;
  final bool showBorder;

  const PersonaAvatar({
    super.key,
    required this.persona,
    this.size = 40,
    this.onTap,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceContainerHighest,
          border: showBorder
              ? Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Center(
          child: Text(
            persona.emoji,
            style: TextStyle(fontSize: size * 0.5),
          ),
        ),
      ),
    );
  }
}

/// AppBar용 페르소나 버튼
///
/// 현재 페르소나 아바타 + 드롭다운 아이콘
class PersonaAppBarButton extends StatelessWidget {
  final AiPersona persona;
  final VoidCallback onTap;

  const PersonaAppBarButton({
    super.key,
    required this.persona,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: '캐릭터 변경',
      icon: Text(
        persona.emoji,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
