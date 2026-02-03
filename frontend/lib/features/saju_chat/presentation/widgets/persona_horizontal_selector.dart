/// 페르소나 가로 선택기 (채팅 화면 상단)
///
/// 5개 페르소나 선택:
/// - BasePerson 1개 (MBTI 4축 조절 가능)
/// - SpecialCharacter 4개 (MBTI 조절 불가, 고정 성격)
///
/// ## 위젯 트리 분리
/// ```
/// 대화창: 🎭 👶 🗣️ 👴 😱 (5개 선택지)
/// 사이드바: MBTI 4축 선택기 (Base 선택 시만 활성화)
/// 모바일: MBTI 버튼 탭 시 BottomSheet로 4축 선택기 표시
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/chat_persona.dart';
import '../providers/chat_persona_provider.dart';
import '../providers/chat_session_provider.dart';
import '../providers/chat_provider.dart';
import 'persona_selector/persona_selector.dart';

class PersonaHorizontalSelector extends ConsumerStatefulWidget {
  const PersonaHorizontalSelector({super.key});

  @override
  ConsumerState<PersonaHorizontalSelector> createState() => _PersonaHorizontalSelectorState();
}

class _PersonaHorizontalSelectorState extends ConsumerState<PersonaHorizontalSelector>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  /// MBTI 4축 선택기 BottomSheet 표시
  void _showMbtiSelectorSheet(BuildContext context, WidgetRef ref) {
    final appTheme = context.appTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: appTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) => Consumer(
        builder: (consumerContext, consumerRef, _) {
          final currentQuadrant = consumerRef.watch(mbtiQuadrantNotifierProvider);
          final quadrantColor = _getPersonaColor(ChatPersona.fromMbtiQuadrant(currentQuadrant));

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 핸들바
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: appTheme.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 제목
                  Text(
                    'AI 성향 선택 (MBTI)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: appTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '터치하거나 드래그해서 성향을 선택하세요',
                    style: TextStyle(
                      fontSize: 13,
                      color: appTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // MBTI 4축 선택기
                  MbtiAxisSelector(
                    selectedQuadrant: currentQuadrant,
                    onQuadrantSelected: (quadrant) {
                      consumerRef.read(mbtiQuadrantNotifierProvider.notifier).setQuadrant(quadrant);
                      // 메시지 없는 세션이면 세션의 MBTI도 업데이트
                      consumerRef.read(chatSessionNotifierProvider.notifier)
                          .updateCurrentSessionPersona(mbtiQuadrant: quadrant);
                    },
                    size: 300,
                  ),
                  const SizedBox(height: 24),
                  // 선택된 분면 표시 (실시간 업데이트)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: quadrantColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: quadrantColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: quadrantColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentQuadrant.displayName,
                              style: TextStyle(
                                color: quadrantColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentQuadrant.description,
                              style: TextStyle(
                                color: quadrantColor.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPersona = ref.watch(chatPersonaNotifierProvider);
    final appTheme = context.appTheme;

    // 현재 세션의 메시지 수 확인 (대화 시작 후 페르소나 잠금)
    final sessionState = ref.watch(chatSessionNotifierProvider);
    final currentSessionId = sessionState.currentSessionId;
    final hasMessages = currentSessionId != null
        ? ref.watch(chatNotifierProvider(currentSessionId)).messages.isNotEmpty
        : false;

    // 페르소나 잠금 상태: 메시지가 있으면 변경 불가
    final isPersonaLocked = hasMessages;

    // 현재 페르소나의 색상
    final quadrantColor = _getPersonaColor(currentPersona);

    // 페르소나 아이템 크기 계산용 상수
    const double circleSize = 44;

    // ═══════════════════════════════════════════════════════════════════════════
    // 접힌 상태: 선택된 페르소나만 표시 (컴팩트)
    // ═══════════════════════════════════════════════════════════════════════════
    if (!_isExpanded) {
      return GestureDetector(
        onTap: () => setState(() => _isExpanded = true),
        onLongPress: () => _showPersonaInfoDialog(context, currentPersona, quadrantColor),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: appTheme.cardColor.withValues(alpha: 0.8),
            border: Border(
              bottom: BorderSide(
                color: appTheme.primaryColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // 선택된 페르소나 아이콘
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: quadrantColor.withValues(alpha: 0.15),
                  border: Border.all(
                    color: quadrantColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    currentPersona.icon,
                    size: 18,
                    color: quadrantColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 선택된 페르소나 이름
              Text(
                currentPersona.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: appTheme.textPrimary,
                ),
              ),
              // info 아이콘 (탭하면 설명 팝업)
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showPersonaInfoDialog(context, currentPersona, quadrantColor),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: appTheme.textMuted,
                ),
              ),
              const Spacer(),
              // 잠금 상태: "새 채팅을 눌러야 페르소나를 바꿀 수 있어요!" 안내
              if (isPersonaLocked)
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                '상단의 + 버튼을 눌러 새 채팅을 시작하면\n페르소나를 변경할 수 있어요!',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: appTheme.primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: appTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: appTheme.primaryColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: appTheme.primaryColor.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+ 새 채팅에서 변경 가능',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: appTheme.primaryColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // 펼치기 힌트
              if (!isPersonaLocked)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '페르소나 변경',
                      style: TextStyle(
                        fontSize: 12,
                        color: appTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.expand_more,
                      size: 20,
                      color: appTheme.textMuted,
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 펼친 상태: 전체 페르소나 목록 (기존 UI)
    // ═══════════════════════════════════════════════════════════════════════════
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: appTheme.cardColor.withValues(alpha: 0.8),
      ),
      child: Row(
        children: [
          // 페르소나 목록 (가로 스크롤)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: ChatPersona.visibleValues.map((persona) {
                  final isSelected = persona == currentPersona;
                  final personaColor = _getPersonaColor(persona);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _buildPersonaCircle(
                      context,
                      persona,
                      isSelected: isSelected,
                      accentColor: isSelected ? personaColor : appTheme.primaryColor,
                      size: circleSize,
                      isLocked: isPersonaLocked,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // 접기 버튼
          GestureDetector(
            onTap: () => setState(() => _isExpanded = false),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appTheme.textMuted.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.expand_less,
                size: 20,
                color: appTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 페르소나 상세 설명 팝업
  void _showPersonaInfoDialog(BuildContext context, ChatPersona persona, Color accentColor) {
    final appTheme = context.appTheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: appTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 페르소나 아이콘
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.15),
                border: Border.all(color: accentColor.withOpacity(0.4), width: 2),
              ),
              child: Center(
                child: Icon(persona.icon, size: 32, color: accentColor),
              ),
            ),
            const SizedBox(height: 14),
            // 이름
            Text(
              persona.displayName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: appTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            // 짧은 설명 뱃지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                persona.description,
                style: TextStyle(
                  fontSize: 13,
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 상세 설명
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: appTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                persona.detailedDescription,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: appTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('닫기', style: TextStyle(color: accentColor, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaCircle(
    BuildContext context,
    ChatPersona persona, {
    required bool isSelected,
    required Color accentColor,
    double size = 44,
    bool isLocked = false,
    VoidCallback? onTapSelected,
  }) {
    final appTheme = context.appTheme;
    final iconSize = (size * 0.5).clamp(18.0, 22.0);

    final displayName = persona.shortName;

    // 잠금 상태: 선택된 페르소나만 활성화 표시, 나머지는 흐리게
    final isDisabled = isLocked && !isSelected;

    return GestureDetector(
      onTap: isLocked
          ? null
          : () {
              if (isSelected && onTapSelected != null) {
                onTapSelected();
              } else {
                ref.read(chatPersonaNotifierProvider.notifier).setPersona(persona);
                // MBTI 페르소나면 mbtiQuadrant도 동기화
                if (persona.mbtiQuadrant != null) {
                  ref.read(mbtiQuadrantNotifierProvider.notifier).setQuadrant(persona.mbtiQuadrant!);
                }
                ref.read(chatSessionNotifierProvider.notifier)
                    .updateCurrentSessionPersona(
                      chatPersona: persona,
                      mbtiQuadrant: persona.isMbtiPersona
                          ? persona.mbtiQuadrant
                          : persona.canAdjustMbti
                              ? ref.read(mbtiQuadrantNotifierProvider)
                              : null,
                    );
              }
            },
      onLongPress: () => _showPersonaInfoDialog(context, persona, accentColor),
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? accentColor.withValues(alpha: 0.15)
                    : appTheme.backgroundColor.withValues(alpha: 0.3),
                border: Border.all(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.5)
                      : appTheme.textMuted.withValues(alpha: 0.15),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Icon(
                  persona.icon,
                  size: iconSize,
                  color: isSelected
                      ? accentColor
                      : appTheme.textMuted.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? accentColor
                    : appTheme.textMuted.withValues(alpha: 0.8),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPersonaColor(ChatPersona persona) {
    switch (persona) {
      case ChatPersona.nfSensitive:
        return const Color(0xFFE63946); // 빨강 - 감성
      case ChatPersona.ntAnalytic:
        return const Color(0xFF457B9D); // 파랑 - 분석
      case ChatPersona.sfFriendly:
        return const Color(0xFF2A9D8F); // 초록 - 친근
      case ChatPersona.stRealistic:
        return const Color(0xFFF4A261); // 주황 - 현실
      case ChatPersona.babyMonk:
        return const Color(0xFFAB47BC); // 보라 - 아기동자
      case ChatPersona.yinYangGrandpa:
        return const Color(0xFF66BB6A); // 녹색 - 음양 할배
      case ChatPersona.sewerSaju:
        return const Color(0xFF78909C); // 회색 - 시궁창
      default:
        return const Color(0xFF457B9D);
    }
  }
}
