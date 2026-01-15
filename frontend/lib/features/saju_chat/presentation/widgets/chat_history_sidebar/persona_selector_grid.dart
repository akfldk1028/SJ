import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/ai_persona.dart';
import '../../../domain/models/chat_persona.dart';
import '../../providers/chat_persona_provider.dart';
import '../persona_selector/mbti_axis_selector.dart';

/// 사이드바용 MBTI 4축 선택기
///
/// BasePerson 선택 시에만 활성화
/// SpecialCharacter 선택 시 비활성화 (고정 성격)
///
/// ## 위젯 트리 분리
/// ```
/// ┌─────────────────────────────────┐
/// │ ✨ AI 성향 (MBTI)               │
/// │ ┌───────────────────────────┐   │
/// │ │        N (직관)           │   │
/// │ │   NF   │   NT             │   │
/// │ │ F ─────●───── T           │   │ ← 4축 선택기
/// │ │   SF   │   ST             │   │
/// │ │        S (감각)           │   │
/// │ └───────────────────────────┘   │
/// │   ● NF - 따뜻하고 공감적인 상담  │ ← 선택된 분면
/// │                                 │
/// │   ⚠️ BasePerson 선택 시만 활성화 │
/// └─────────────────────────────────┘
/// ```
class PersonaSelectorGrid extends ConsumerWidget {
  const PersonaSelectorGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPersona = ref.watch(chatPersonaNotifierProvider);
    final currentQuadrant = ref.watch(mbtiQuadrantNotifierProvider);
    final canAdjust = ref.watch(canAdjustMbtiProvider);
    final theme = Theme.of(context);

    // 분면별 색상
    final quadrantColor = _getQuadrantColor(currentQuadrant);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 제목
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.psychology,
                size: 16,
                color: canAdjust ? theme.colorScheme.primary : theme.colorScheme.outline,
              ),
              const SizedBox(width: 6),
              Text(
                'AI 성향 (MBTI)',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: canAdjust ? null : theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 비활성화 안내 (SpecialCharacter 선택 시)
          if (!canAdjust) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentPersona.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${currentPersona.displayName} (고정 성격)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Base 선택 시 MBTI 조절 가능',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          // MBTI 4축 선택기 (BasePerson 선택 시만 활성화)
          if (canAdjust) ...[
            const SizedBox(height: 8),
            MbtiAxisSelector(
              selectedQuadrant: currentQuadrant,
              onQuadrantSelected: (quadrant) {
                ref.read(mbtiQuadrantNotifierProvider.notifier).setQuadrant(quadrant);
              },
              size: 180,
            ),
            const SizedBox(height: 16),

            // 선택된 분면 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: quadrantColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: quadrantColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: quadrantColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentQuadrant.displayName,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: quadrantColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currentQuadrant.description,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: quadrantColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 분면별 색상
  Color _getQuadrantColor(MbtiQuadrant quadrant) {
    switch (quadrant) {
      case MbtiQuadrant.NF:
        return const Color(0xFFE63946); // 빨강 (감성)
      case MbtiQuadrant.NT:
        return const Color(0xFF457B9D); // 파랑 (분석)
      case MbtiQuadrant.SF:
        return const Color(0xFF2A9D8F); // 초록 (친근)
      case MbtiQuadrant.ST:
        return const Color(0xFFF4A261); // 주황 (현실)
    }
  }
}
