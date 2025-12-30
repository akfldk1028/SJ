import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/profile_provider.dart';

/// 음력/윤달 옵션 위젯
///
/// - 음력 선택 시에만 윤달 관련 옵션 표시
/// - 해당 연도 윤달 정보 표시
/// - 윤달 체크박스 (조건 충족 시에만 활성화)
/// - 에러 메시지 표시
class LunarOptions extends ConsumerWidget {
  const LunarOptions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(profileFormProvider);
    final theme = Theme.of(context);

    // 음력이 아니면 표시하지 않음
    if (!formState.isLunar) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        // 윤달 정보 표시
        if (formState.leapMonthInfo != null) ...[
          _LeapMonthInfoBanner(
            info: formState.leapMonthInfo!,
            canSelectLeapMonth: formState.canSelectLeapMonth,
          ),
          const SizedBox(height: 8),
        ],

        // 윤달 체크박스
        Row(
          children: [
            ShadCheckbox(
              value: formState.isLeapMonth,
              enabled: formState.canSelectLeapMonth,
              onChanged: formState.canSelectLeapMonth
                  ? (value) {
                      ref.read(profileFormProvider.notifier).updateIsLeapMonth(value);
                    }
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              '윤달',
              style: TextStyle(
                color: formState.canSelectLeapMonth
                    ? theme.textTheme.bodyMedium?.color
                    : theme.disabledColor,
              ),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message: formState.canSelectLeapMonth
                  ? '이 날짜는 윤달에 해당합니다.'
                  : '해당 연월에는 윤달이 없습니다.',
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: formState.canSelectLeapMonth
                    ? theme.iconTheme.color
                    : theme.disabledColor,
              ),
            ),
          ],
        ),

        // 에러 메시지
        if (formState.leapMonthError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formState.leapMonthError!,
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// 윤달 정보 배너
class _LeapMonthInfoBanner extends StatelessWidget {
  final dynamic info; // LeapMonthInfo
  final bool canSelectLeapMonth;

  const _LeapMonthInfoBanner({
    required this.info,
    required this.canSelectLeapMonth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // LeapMonthInfo의 formatted 문자열 사용
    final infoText = info.formatted as String;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: canSelectLeapMonth
            ? theme.colorScheme.primaryContainer.withAlpha(128)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: canSelectLeapMonth
              ? theme.colorScheme.primary.withAlpha(128)
              : theme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            canSelectLeapMonth ? Icons.check_circle : Icons.info_outline,
            size: 16,
            color: canSelectLeapMonth
                ? theme.colorScheme.primary
                : theme.iconTheme.color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              infoText,
              style: TextStyle(
                fontSize: 12,
                color: canSelectLeapMonth
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
