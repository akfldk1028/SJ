import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';

/// 출생시간 옵션 위젯
///
/// - "시간 모름" 체크박스
/// - "야자시/조자시" 체크박스 + 툴팁
class BirthTimeOptions extends ConsumerWidget {
  const BirthTimeOptions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final formState = ref.watch(profileFormProvider);

    return Column(
      children: [
        // 시간 모름 체크박스
        Row(
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
        ),
        const SizedBox(height: 12),
        // 야자시/조자시 체크박스
        Row(
          children: [
            ShadCheckbox(
              value: formState.useYaJasi,
              onChanged: (value) {
                ref.read(profileFormProvider.notifier)
                    .updateUseYaJasi(value);
              },
            ),
            const SizedBox(width: 8),
            Text('야자시 적용', style: TextStyle(color: theme.textPrimary)),
            const SizedBox(width: 4),
            Tooltip(
              message: '자시(23-01시) 일주 변경 시점 선택\n\n'
                  '✓ 야자시(夜子時) - 전통 방식\n'
                  '  • 23:00-24:00 → 당일 일주 유지\n'
                  '  • 00:00-01:00 → 익일 일주 적용\n\n'
                  '✗ 정자시(正子時) - 현대 방식 (80%)\n'
                  '  • 23:00-01:00 → 모두 익일 일주 적용',
              child: Icon(Icons.info_outline, size: 16, color: theme.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}
