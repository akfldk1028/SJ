import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';

/// 출생시간 선택 위젯
///
/// CupertinoTimePicker 기반, HH:mm 형식
/// TimeUnknown 시 비활성화
class BirthTimePicker extends ConsumerWidget {
  const BirthTimePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
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
        color: theme.cardColor,
        border: Border.all(
          color: isEnabled
              ? theme.textMuted.withOpacity(0.3)
              : theme.textMuted.withOpacity(0.1),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.access_time, size: 20, color: theme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEnabled
                  ? '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}'
                  : '시간 모름',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isEnabled ? theme.textPrimary : theme.textMuted,
              ),
            ),
          ),
          if (isEnabled)
            TextButton(
              onPressed: () => _showTimePicker(context, ref, hours, minutes),
              child: Text('변경', style: TextStyle(color: theme.primaryColor)),
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
                    Navigator.pop(context);
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
            Expanded(
              child: CupertinoTimerPicker(
                mode: CupertinoTimerPickerMode.hm,
                initialTimerDuration: Duration(
                  hours: initialHour,
                  minutes: initialMinute,
                ),
                onTimerDurationChanged: (duration) {
                  final totalMinutes = duration.inMinutes;
                  ref.read(profileFormProvider.notifier).updateBirthTime(totalMinutes);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
