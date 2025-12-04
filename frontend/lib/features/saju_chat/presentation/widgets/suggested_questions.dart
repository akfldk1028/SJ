import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SuggestedQuestions extends StatelessWidget {
  final Function(String) onQuestionSelected;

  const SuggestedQuestions({
    super.key,
    required this.onQuestionSelected,
  });

  static const List<String> _questions = [
    "올해 이직운이 궁금해요",
    "나의 타고난 성향은?",
    "재물운이 언제 좋아질까요?",
    "연애운을 알고 싶어요",
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _questions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(_questions[index]),
            onPressed: () => onQuestionSelected(_questions[index]),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Colors.black12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}
