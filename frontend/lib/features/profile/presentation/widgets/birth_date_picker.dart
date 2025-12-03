import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';

/// 생년월일 선택 위젯
class BirthDatePicker extends StatelessWidget {
  const BirthDatePicker({
    super.key,
    required this.selectedDate,
    required this.isLunar,
    required this.onDateChanged,
    required this.onIsLunarChanged,
  });

  final DateTime? selectedDate;
  final bool isLunar;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<bool> onIsLunarChanged;

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('ko', 'KR'),
    );

    if (picked != null) {
      onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.birthDateLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSizes.sm),

        // 날짜 선택 버튼
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? '${selectedDate!.year}년 ${selectedDate!.month}월 ${selectedDate!.day}일'
                        : '생년월일을 선택하세요',
                    style: TextStyle(
                      color: selectedDate != null
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                      fontSize: AppSizes.fontMd,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.textSecondary,
                  size: AppSizes.iconMd,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSizes.md),

        // 음양력 선택
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: const Text(AppStrings.calendarSolar),
                value: false,
                groupValue: isLunar,
                onChanged: (value) => onIsLunarChanged(value ?? false),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: const Text(AppStrings.calendarLunar),
                value: true,
                groupValue: isLunar,
                onChanged: (value) => onIsLunarChanged(value ?? false),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
