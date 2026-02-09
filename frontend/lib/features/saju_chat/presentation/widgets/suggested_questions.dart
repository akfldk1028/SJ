import 'package:flutter/material.dart';

/// AI가 제안한 후속 질문을 표시하는 위젯
///
/// - questions가 null이거나 비어있으면 기본 질문 표시
/// - 동적으로 AI 응답에서 추출한 질문 표시 가능
class SuggestedQuestions extends StatelessWidget {
  final Function(String) onQuestionSelected;

  /// AI가 제안한 후속 질문 목록 (null이면 기본 질문 사용)
  final List<String>? questions;

  /// 비활성화 여부 (토큰 소진 시 회색 처리)
  final bool enabled;

  const SuggestedQuestions({
    super.key,
    required this.onQuestionSelected,
    this.questions,
    this.enabled = true,
  });

  /// 기본 질문 목록 (AI 응답에서 질문이 없을 때 사용)
  static const List<String> _defaultQuestions = [
    '올해 이직운이 궁금해요',
    '나의 타고난 성향은?',
    '재물운이 언제 좋아질까요?',
    '연애운을 알고 싶어요',
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
          return Opacity(
            opacity: enabled ? 1.0 : 0.4,
            child: ActionChip(
              label: Text(
                displayQuestions[index],
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onPressed: enabled
                  ? () => onQuestionSelected(displayQuestions[index])
                  : null,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }
}
