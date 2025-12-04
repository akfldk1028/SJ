import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/gender.dart';

/// 성별 선택 위젯
class GenderSelector extends StatelessWidget {
  const GenderSelector({
    super.key,
    required this.selectedGender,
    required this.onChanged,
  });

  final Gender? selectedGender;
  final ValueChanged<Gender> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.gender,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<Gender>(
          segments: [
            ButtonSegment(
              value: Gender.male,
              label: const Text(AppStrings.genderMale),
              icon: const Icon(Icons.male),
            ),
            ButtonSegment(
              value: Gender.female,
              label: const Text(AppStrings.genderFemale),
              icon: const Icon(Icons.female),
            ),
          ],
          selected: selectedGender != null ? {selectedGender!} : const {},
          emptySelectionAllowed: true,
          onSelectionChanged: (selected) {
            if (selected.isNotEmpty) {
              onChanged(selected.first);
            }
          },
          showSelectedIcon: false,
        ),
      ],
    );
  }
}
