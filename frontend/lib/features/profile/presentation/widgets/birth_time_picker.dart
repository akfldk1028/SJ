import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';

/// 출생시간 선택 위젯
///
/// CupertinoDatePicker 기반 (time mode), HH:mm 형식
/// TimeUnknown 시 비활성화
class BirthTimePicker extends ConsumerWidget {
  const BirthTimePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(profileFormProvider);
    final birthTimeMinutes = formState.birthTimeMinutes;
    final birthTimeUnknown = formState.birthTimeUnknown;

    // 시간 모름 체크 시 비활성화
    final isEnabled = !birthTimeUnknown;

    // 분을 시:분으로 변환
    final hours = (birthTimeMinutes ?? 0) ~/ 60;
    final minutes = (birthTimeMinutes ?? 0) % 60;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isEnabled
              ? Theme.of(context).colorScheme.outline
              : Theme.of(context).disabledColor,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEnabled
                  ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}'
                  : '시간 모름',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isEnabled ? null : Theme.of(context).disabledColor,
              ),
            ),
          ),
          if (isEnabled)
            TextButton(
              onPressed: () => _showTimePicker(context, ref, hours, minutes),
              child: const Text('변경'),
            ),
        ],
      ),
    );
  }

  void _showTimePicker(
    BuildContext context,
    WidgetRef ref,
    int initialHour,
    int initialMinute,
  ) {
    int selectedHour = initialHour;
    int selectedMinute = initialMinute;

    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 250,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    final totalMinutes = selectedHour * 60 + selectedMinute;
                    ref.read(profileFormProvider.notifier).updateBirthTime(totalMinutes);
                    Navigator.pop(context);
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: DateTime(2000, 1, 1, initialHour, initialMinute),
                onDateTimeChanged: (dateTime) {
                  selectedHour = dateTime.hour;
                  selectedMinute = dateTime.minute;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
