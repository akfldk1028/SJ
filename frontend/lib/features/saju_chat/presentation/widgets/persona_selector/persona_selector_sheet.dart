import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../domain/models/ai_persona.dart';
import 'mbti_axis_selector.dart';
import 'persona_horizontal_list.dart';

/// 페르소나 선택 BottomSheet (MBTI 4축 기반)
///
/// ## UI 구조
/// ```
/// ┌─────────────────────────────────┐
/// │      AI PERSONA Setting         │
/// ├─────────────────────────────────┤
/// │            N                    │
/// │     NF     │     NT             │
/// │  F ────── ● ────── T            │ ← MbtiAxisSelector
/// │     SF     │     ST             │
/// │            S                    │
/// ├─────────────────────────────────┤
/// │     "NF - 감성형" 선택됨         │
/// ├─────────────────────────────────┤
/// │  ┌──┬──┬──┬──┐                  │
/// │  │👵│👶│👴│  │ ← 4×4 그리드     │
/// │  └──┴──┴──┴──┘                  │
/// ├─────────────────────────────────┤
/// │    [ 특별한 페르소나 ]           │
/// └─────────────────────────────────┘
/// ```
class PersonaSelectorSheet extends StatefulWidget {
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
    final theme = context.appTheme;
    return showModalBottomSheet<AiPersona>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => PersonaSelectorSheet(
          currentPersona: currentPersona,
          onPersonaSelected: (persona) => Navigator.pop(context, persona),
        ),
      ),
    );
  }

  @override
  State<PersonaSelectorSheet> createState() => _PersonaSelectorSheetState();
}

class _PersonaSelectorSheetState extends State<PersonaSelectorSheet> {
  /// 선택된 MBTI 분면
  MbtiQuadrant? _selectedQuadrant;

  /// 전체 보기 모드
  bool _showAllPersonas = false;

  @override
  void initState() {
    super.initState();
    // 현재 페르소나의 분면으로 초기화
    _selectedQuadrant = widget.currentPersona.quadrant;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 핸들바
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 제목
          Text(
            'saju_chat.personaSelectorTitle'.tr(),
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'saju_chat.personaSelectorSubtitle'.tr(),
            style: TextStyle(
              color: theme.textMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // 컨텐츠 영역
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // MBTI 4축 선택기
                  Center(
                    child: MbtiAxisSelector(
                      selectedQuadrant: _selectedQuadrant,
                      onQuadrantSelected: (quadrant) {
                        setState(() {
                          _selectedQuadrant = quadrant;
                          _showAllPersonas = false;
                        });
                      },
                      size: 220,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 선택된 분면 표시
                  if (_selectedQuadrant != null && !_showAllPersonas) ...[
                    PersonaQuadrantGrid(
                      quadrant: _selectedQuadrant!,
                      currentPersona: widget.currentPersona,
                      onPersonaSelected: widget.onPersonaSelected,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 전체 보기
                  if (_showAllPersonas) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'saju_chat.allPersonas'.tr(),
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildAllPersonasGrid(),
                    const SizedBox(height: 16),
                  ],

                  // 특별한 페르소나 버튼
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showAllPersonas = !_showAllPersonas;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                      side: BorderSide(color: theme.primaryColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      _showAllPersonas ? 'saju_chat.showByType'.tr() : 'saju_chat.specialPersonas'.tr(),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 전체 페르소나 그리드
  Widget _buildAllPersonasGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: AiPersona.visibleValues.length,
      itemBuilder: (context, index) {
        final persona = AiPersona.visibleValues[index];
        return _AllPersonaGridItem(
          persona: persona,
          isSelected: persona == widget.currentPersona,
          onTap: () => widget.onPersonaSelected(persona),
        );
      },
    );
  }
}

/// 전체 보기용 그리드 아이템
class _AllPersonaGridItem extends StatelessWidget {
  final AiPersona persona;
  final bool isSelected;
  final VoidCallback onTap;

  const _AllPersonaGridItem({
    required this.persona,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 분면별 색상
    Color quadrantColor;
    switch (persona.quadrant) {
      case MbtiQuadrant.NF:
        quadrantColor = const Color(0xFFE63946); // 빨강 (감성)
        break;
      case MbtiQuadrant.NT:
        quadrantColor = const Color(0xFF457B9D); // 파랑 (분석)
        break;
      case MbtiQuadrant.SF:
        quadrantColor = const Color(0xFF2A9D8F); // 초록 (친근)
        break;
      case MbtiQuadrant.ST:
        quadrantColor = const Color(0xFFF4A261); // 주황 (현실)
        break;
    }

    final theme = context.appTheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? quadrantColor.withValues(alpha: 0.3)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? quadrantColor : Colors.transparent,
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
                color: theme.textPrimary.withValues(alpha: 0.9),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            // 분면 표시
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: quadrantColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                persona.quadrant.displayName,
                style: TextStyle(
                  color: quadrantColor,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
