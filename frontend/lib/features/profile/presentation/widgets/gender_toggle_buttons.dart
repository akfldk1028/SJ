import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/gender.dart';
import '../providers/profile_provider.dart';

/// 성별 선택 토글 버튼
///
/// ShadButton 2개 (여자/남자), 선택 시 배경색 변경
class GenderToggleButtons extends ConsumerWidget {
  const GenderToggleButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final formState = ref.watch(profileFormProvider);
    final selectedGender = formState.gender;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '성별',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _GenderButton(
                label: '여자',
                gender: Gender.female,
                isSelected: selectedGender == Gender.female,
                onTap: () {
                  ref.read(profileFormProvider.notifier).updateGender(Gender.female);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GenderButton(
                label: '남자',
                gender: Gender.male,
                isSelected: selectedGender == Gender.male,
                onTap: () {
                  ref.read(profileFormProvider.notifier).updateGender(Gender.male);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 개별 성별 버튼
class _GenderButton extends StatelessWidget {
  final String label;
  final Gender gender;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderButton({
    required this.label,
    required this.gender,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    if (isSelected) {
      return ShadButton(
        width: double.infinity,
        onPressed: onTap,
        child: Text(label),
      );
    }

    return ShadButton.outline(
      width: double.infinity,
      onPressed: onTap,
      child: Text(
        label,
        style: TextStyle(color: theme.textPrimary),
      ),
    );
  }
}
