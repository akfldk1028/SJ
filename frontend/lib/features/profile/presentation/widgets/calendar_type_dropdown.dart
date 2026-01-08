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
    ref.watch(profileFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '생년월일시',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ShadSelect<bool>(
          placeholder: const Text('양력'),
          options: const [
            ShadOption(value: false, child: Text('양력')),
            ShadOption(value: true, child: Text('음력')),
          ],
          selectedOptionBuilder: (context, value) =>
              Text(value ? '음력' : '양력'),
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
