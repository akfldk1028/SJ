import 'package:flutter/material.dart';

import '../../domain/models/ai_persona.dart';

/// 페르소나 선택 BottomSheet
///
/// 4개의 캐릭터 카드를 그리드로 표시
class PersonaSelectorSheet extends StatelessWidget {
  final AiPersona currentPersona;
  final ValueChanged<AiPersona> onPersonaSelected;

  const PersonaSelectorSheet({
    super.key,
    required this.currentPersona,
    required this.onPersonaSelected,
  });

  /// BottomSheet 열기 헬퍼
  static Future<AiPersona?> show(
    BuildContext context,
    AiPersona currentPersona,
  ) {
    return showModalBottomSheet<AiPersona>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PersonaSelectorSheet(
        currentPersona: currentPersona,
        onPersonaSelected: (persona) => Navigator.pop(context, persona),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들바
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // 제목
          Text(
            'AI 캐릭터 선택',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '대화 스타일을 선택하세요',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          // 캐릭터 그리드
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: AiPersona.visibleValues.map((persona) {
              return _PersonaCard(
                persona: persona,
                isSelected: persona == currentPersona,
                onTap: () => onPersonaSelected(persona),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 개별 페르소나 카드
class _PersonaCard extends StatelessWidget {
  final AiPersona persona;
  final bool isSelected;
  final VoidCallback onTap;

  const _PersonaCard({
    required this.persona,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(persona.emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              persona.displayName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              persona.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
