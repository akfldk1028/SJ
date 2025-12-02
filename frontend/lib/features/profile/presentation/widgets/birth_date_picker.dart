import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/profile_provider.dart';

/// 생년월일 선택 위젯
///
/// ShadDatePicker 사용, YYYY/MM/DD 형식
class BirthDatePicker extends ConsumerWidget {
  const BirthDatePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(profileFormProvider);
    final birthDate = formState.birthDate;

    return ShadDatePicker(
      selected: birthDate,
      onChanged: (date) {
        if (date != null) {
          ref.read(profileFormProvider.notifier).updateBirthDate(date);
        }
      },
      // 1900년부터 현재까지만 선택 가능
      minDate: DateTime(1900, 1, 1),
      maxDate: DateTime.now(),
    );
  }
}
