import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/ai_persona.dart';

/// 페르소나 가로 리스트 (원형 이모지)
///
/// 채팅 화면 상단에 표시되는 페르소나 선택기
/// 분면(MbtiQuadrant)이 선택되면 해당 분면의 페르소나만 표시
///
/// ```
/// ┌───────────────────────────────────┐
/// │  👵  🧙  🐱  🔮  👶  🗣️  📜  👴  │
/// └───────────────────────────────────┘
/// ```
class PersonaHorizontalList extends StatelessWidget {
  /// 표시할 페르소나 목록 (null이면 전체)
  final List<AiPersona>? personas;

  /// 현재 선택된 페르소나
  final AiPersona currentPersona;

  /// 페르소나 선택 콜백
  final ValueChanged<AiPersona> onPersonaSelected;

  /// 설정 버튼 클릭 (MBTI 선택기 열기)
  final VoidCallback? onSettingsTap;

  /// 아이템 크기
  final double itemSize;

  const PersonaHorizontalList({
    super.key,
    this.personas,
    required this.currentPersona,
    required this.onPersonaSelected,
    this.onSettingsTap,
    this.itemSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    final displayPersonas = personas ?? AiPersona.visibleValues;

    return Container(
      height: itemSize + 16,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 설정 아이콘 (MBTI 선택기 열기)
          if (onSettingsTap != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                icon: const Icon(Icons.tune, color: Colors.white70),
                onPressed: onSettingsTap,
                tooltip: 'saju_chat.selectByType'.tr(),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: itemSize * 0.8,
                  minHeight: itemSize * 0.8,
                ),
              ),
            ),
          // 페르소나 가로 리스트
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: displayPersonas.length,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (context, index) {
                final persona = displayPersonas[index];
                return _PersonaCircleItem(
                  persona: persona,
                  isSelected: persona == currentPersona,
                  size: itemSize,
                  onTap: () => onPersonaSelected(persona),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 원형 페르소나 아이템
class _PersonaCircleItem extends StatelessWidget {
  final AiPersona persona;
  final bool isSelected;
  final double size;
  final VoidCallback onTap;

  const _PersonaCircleItem({
    required this.persona,
    required this.isSelected,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: '${persona.displayName}\n${persona.description}',
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? const Color(0xFF3D5A80)
                  : const Color(0xFF2D2D44),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF98C1D9)
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF98C1D9).withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                persona.emoji,
                style: TextStyle(fontSize: size * 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 분면별 페르소나 그리드 (4x4)
///
/// MBTI 분면 선택 후 해당 분면의 페르소나를 그리드로 표시
class PersonaQuadrantGrid extends StatelessWidget {
  final MbtiQuadrant quadrant;
  final AiPersona currentPersona;
  final ValueChanged<AiPersona> onPersonaSelected;

  const PersonaQuadrantGrid({
    super.key,
    required this.quadrant,
    required this.currentPersona,
    required this.onPersonaSelected,
  });

  @override
  Widget build(BuildContext context) {
    final personas = AiPersona.getByQuadrant(quadrant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 분면 제목
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3D5A80),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  quadrant.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                quadrant.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // 그리드
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: personas.length,
          itemBuilder: (context, index) {
            final persona = personas[index];
            return _PersonaGridItem(
              persona: persona,
              isSelected: persona == currentPersona,
              onTap: () => onPersonaSelected(persona),
            );
          },
        ),
      ],
    );
  }
}

/// 그리드 페르소나 아이템
class _PersonaGridItem extends StatelessWidget {
  final AiPersona persona;
  final bool isSelected;
  final VoidCallback onTap;

  const _PersonaGridItem({
    required this.persona,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3D5A80)
              : const Color(0xFF2D2D44),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF98C1D9)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              persona.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Text(
              persona.displayName,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
