import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/ai_persona.dart';
import '../../providers/persona_provider.dart';

/// 사이드바용 페르소나 선택 그리드
///
/// 2x2 그리드로 4개의 캐릭터를 표시
/// 선택된 캐릭터는 하이라이트 표시
class PersonaSelectorGrid extends ConsumerWidget {
  const PersonaSelectorGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPersona = ref.watch(personaNotifierProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'AI 캐릭터',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 2x2 그리드
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.2,
            children: AiPersona.values.map((persona) {
              return _PersonaGridCard(
                persona: persona,
                isSelected: persona == currentPersona,
                onTap: () {
                  ref.read(personaNotifierProvider.notifier).setPersona(persona);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 개별 페르소나 그리드 카드
class _PersonaGridCard extends StatelessWidget {
  final AiPersona persona;
  final bool isSelected;
  final VoidCallback onTap;

  const _PersonaGridCard({
    required this.persona,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(persona.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(
                persona.displayName,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
