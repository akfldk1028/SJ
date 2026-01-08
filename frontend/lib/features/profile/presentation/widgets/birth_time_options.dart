import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';

/// 출생시간 옵션 위젯
///
/// - "시간 모름" 체크박스
class BirthTimeOptions extends ConsumerWidget {
  const BirthTimeOptions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final formState = ref.watch(profileFormProvider);

    return Row(
      children: [
        ShadCheckbox(
          value: formState.birthTimeUnknown,
          onChanged: (value) {
            ref.read(profileFormProvider.notifier)
                .updateBirthTimeUnknown(value);
          },
        ),
        const SizedBox(width: 8),
        Text('시간 모름', style: TextStyle(color: theme.textPrimary)),
      ],
    );
  }
}
