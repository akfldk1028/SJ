import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';

/// 출생 시간 선택 위젯
class BirthTimePicker extends StatelessWidget {
  const BirthTimePicker({
    super.key,
    required this.birthTimeMinutes,
    required this.birthTimeUnknown,
    required this.onTimeChanged,
    required this.onUnknownChanged,
  });

  final int? birthTimeMinutes;
  final bool birthTimeUnknown;
  final ValueChanged<int> onTimeChanged;
  final ValueChanged<bool> onUnknownChanged;

  TimeOfDay? get _timeOfDay {
    if (birthTimeMinutes == null) return null;
    return TimeOfDay(
      hour: birthTimeMinutes! ~/ 60,
      minute: birthTimeMinutes! % 60,
    );
  }

  String get _timeString {
    if (birthTimeUnknown) return '시간 모름';
    if (birthTimeMinutes == null) return '시간을 선택하세요';
    final time = _timeOfDay!;
    return '${time.hour.toString().padLeft(2, '0')}시 ${time.minute.toString().padLeft(2, '0')}분';
  }

  Future<void> _selectTime(BuildContext context) async {
    if (birthTimeUnknown) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: _timeOfDay ?? const TimeOfDay(hour: 12, minute: 0),
    );

    if (picked != null) {
      final minutes = picked.hour * 60 + picked.minute;
      onTimeChanged(minutes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.birthTimeLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.sm),

        // 시간 선택 버튼
        InkWell(
          onTap: birthTimeUnknown ? null : () => _selectTime(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
            decoration: BoxDecoration(
              color: birthTimeUnknown
                  ? AppColors.surfaceVariant.withOpacity(0.5)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _timeString,
                    style: TextStyle(
                      color: birthTimeUnknown
                          ? AppColors.textHint
                          : (birthTimeMinutes != null
                              ? AppColors.textPrimary
                              : AppColors.textHint),
                      fontSize: AppSizes.fontMd,
                    ),
                  ),
                ),
                Icon(
                  Icons.access_time,
                  color: birthTimeUnknown
                      ? AppColors.textHint
                      : AppColors.textSecondary,
                  size: AppSizes.iconMd,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSizes.sm),

        // 시간 모름 체크박스
        Row(
          children: [
            Checkbox(
              value: birthTimeUnknown,
              onChanged: (value) => onUnknownChanged(value ?? false),
            ),
            GestureDetector(
              onTap: () => onUnknownChanged(!birthTimeUnknown),
              child: const Text(AppStrings.birthTimeUnknown),
            ),
          ],
        ),
      ],
    );
  }
}
