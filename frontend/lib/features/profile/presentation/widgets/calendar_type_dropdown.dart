import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';

/// 양력/음력 선택 드롭다운
///
/// ShadSelect 사용
class CalendarTypeDropdown extends ConsumerWidget {
  const CalendarTypeDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final formState = ref.watch(profileFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'onboarding.labelBirthDateTime'.tr(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ShadSelect<bool>(
          initialValue: formState.isLunar,
          placeholder: Text('onboarding.calendarSolar'.tr()),
          options: [
            ShadOption(value: false, child: Text('onboarding.calendarSolar'.tr())),
            ShadOption(value: true, child: Text('onboarding.calendarLunar'.tr())),
          ],
          selectedOptionBuilder: (context, value) =>
              Text(value ? 'onboarding.calendarLunar'.tr() : 'onboarding.calendarSolar'.tr()),
          onChanged: (value) {
            if (value != null) {
              ref.read(profileFormProvider.notifier).updateIsLunar(value);
            }
          },
        ),
      ],
    );
  }
}
