import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/mock/mock_fortune_data.dart';

/// Horizontal scrollable Saju pillars
class SajuPillarScroll extends StatelessWidget {
  const SajuPillarScroll({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: MockFortuneData.sajuPillars.length,
        itemBuilder: (context, index) {
          final pillar = MockFortuneData.sajuPillars[index];
          return _PillarCard(
            pillar: pillar,
            index: index,
          );
        },
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  final Map<String, String> pillar;
  final int index;

  const _PillarCard({
    required this.pillar,
    required this.index,
  });

  Color get _elementColor {
    final element = pillar['element']!;
    switch (element) {
      case 'wood':
        return AppColors.wood;
      case 'fire':
        return AppColors.fire;
      case 'earth':
        return AppColors.earth;
      case 'metal':
        return AppColors.metal;
      case 'water':
        return AppColors.water;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: EdgeInsets.only(right: index < 3 ? 12 : 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              pillar['name']!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CharacterBox(
                  character: pillar['heavenly']!,
                  color: _elementColor,
                ),
                const SizedBox(width: 6),
                _CharacterBox(
                  character: pillar['earthly']!,
                  color: _elementColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _elementColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                pillar['meaning']!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _elementColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterBox extends StatelessWidget {
  final String character;
  final Color color;

  const _CharacterBox({
    required this.character,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          character,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
