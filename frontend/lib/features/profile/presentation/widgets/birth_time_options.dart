import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/profile_provider.dart';

/// 출생시간 옵션 위젯
///
/// - "시간 모름" 체크박스
/// - "야자시/조자시" 체크박스 + 툴팁
class BirthTimeOptions extends ConsumerWidget {
  const BirthTimeOptions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    .updateBirthTimeUnknown(value ?? false);
              },
            ),
            const SizedBox(width: 8),
            const Text('시간 모름'),
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
                    .updateUseYaJasi(value ?? true);
              },
            ),
            const SizedBox(width: 8),
            const Text('야자시/조자시'),
            const SizedBox(width: 4),
            Tooltip(
              message: '자시(23-01시) 처리 방식을 선택합니다.\n'
                  '야자시: 23:00-01:00을 다음날 자시로 계산\n'
                  '조자시: 23:00-01:00을 당일 자시로 계산',
              child: const Icon(Icons.info_outline, size: 16),
            ),
          ],
        ),
      ],
    );
  }
}
