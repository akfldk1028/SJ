import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// AI가 제안한 후속 질문을 표시하는 위젯
///
/// - questions가 null이거나 비어있으면 기본 질문 표시
/// - 동적으로 AI 응답에서 추출한 질문 표시 가능
class SuggestedQuestions extends StatelessWidget {
  final Function(String) onQuestionSelected;

  /// AI가 제안한 후속 질문 목록 (null이면 기본 질문 사용)
  final List<String>? questions;

  const SuggestedQuestions({
    super.key,
    required this.onQuestionSelected,
    this.questions,
  });

  /// 기본 질문 목록 (AI 응답에서 질문이 없을 때 사용)
  static List<String> get _defaultQuestions => [
    'saju_chat.defaultQuestion1'.tr(),
    'saju_chat.defaultQuestion2'.tr(),
    'saju_chat.defaultQuestion3'.tr(),
    'saju_chat.defaultQuestion4'.tr(),
  ];

  @override
  Widget build(BuildContext context) {
    // 동적 질문이 있으면 사용, 없으면 기본 질문 사용
    final displayQuestions = (questions != null && questions!.isNotEmpty)
        ? questions!
        : _defaultQuestions;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: displayQuestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(
              displayQuestions[index],
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onPressed: () => onQuestionSelected(displayQuestions[index]),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}
