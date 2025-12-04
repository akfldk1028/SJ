import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/profile_provider.dart';

/// 생년월일 선택 위젯
///
/// Provider 상태를 직접 watch하여 동기화 보장
/// 연도/월/일 드롭다운으로 빠른 선택 가능
class BirthDatePicker extends ConsumerWidget {
  const BirthDatePicker({super.key});

  // 연도 범위: 1900 ~ 현재 연도 (역순)
  static List<int> get _years {
    final currentYear = DateTime.now().year;
    return List.generate(currentYear - 1899, (i) => currentYear - i);
  }

  static const List<int> _months = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  /// 해당 월의 일수 계산
  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// 일 목록 생성
  List<int> _getDays(int? year, int? month) {
    if (year == null || month == null) {
      return List.generate(31, (i) => i + 1);
    }
    final daysInMonth = _getDaysInMonth(year, month);
    return List.generate(daysInMonth, (i) => i + 1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(profileFormProvider);
    final birthDate = formState.birthDate;

    final selectedYear = birthDate?.year;
    final selectedMonth = birthDate?.month;
    final selectedDay = birthDate?.day;

    final days = _getDays(selectedYear, selectedMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '생년월일',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // 연도 선택
            Expanded(
              flex: 3,
              child: _buildYearDropdown(context, ref, selectedYear, selectedMonth, selectedDay),
            ),
            const SizedBox(width: 8),
            // 월 선택
            Expanded(
              flex: 2,
              child: _buildMonthDropdown(context, ref, selectedYear, selectedMonth, selectedDay),
            ),
            const SizedBox(width: 8),
            // 일 선택
            Expanded(
              flex: 2,
              child: _buildDayDropdown(context, ref, days, selectedYear, selectedMonth, selectedDay),
            ),
          ],
        ),
      ],
    );
  }

  /// 연도 드롭다운
  Widget _buildYearDropdown(BuildContext context, WidgetRef ref, int? selectedYear, int? selectedMonth, int? selectedDay) {
    return ShadSelect<int>(
      key: ValueKey('year_$selectedYear'),
      placeholder: const Text('연도'),
      initialValue: selectedYear,
      selectedOptionBuilder: (context, value) => Text('$value년'),
      options: _years.map((year) => ShadOption(
        value: year,
        child: Text('$year년'),
      )).toList(),
      onChanged: (value) {
        if (value != null) {
          // 일 조정 (2월 등 일수가 다른 경우)
          int? adjustedDay = selectedDay;
          if (selectedMonth != null && selectedDay != null) {
            final daysInMonth = _getDaysInMonth(value, selectedMonth);
            if (selectedDay > daysInMonth) {
              adjustedDay = daysInMonth;
            }
          }

          if (selectedMonth != null && adjustedDay != null) {
            final date = DateTime(value, selectedMonth, adjustedDay);
            ref.read(profileFormProvider.notifier).updateBirthDate(date);
          } else if (selectedMonth != null) {
            final date = DateTime(value, selectedMonth, 1);
            ref.read(profileFormProvider.notifier).updateBirthDate(date);
          } else {
            final date = DateTime(value, 1, 1);
            ref.read(profileFormProvider.notifier).updateBirthDate(date);
          }
        }
      },
    );
  }

  /// 월 드롭다운
  Widget _buildMonthDropdown(BuildContext context, WidgetRef ref, int? selectedYear, int? selectedMonth, int? selectedDay) {
    return ShadSelect<int>(
      key: ValueKey('month_$selectedMonth'),
      placeholder: const Text('월'),
      initialValue: selectedMonth,
      selectedOptionBuilder: (context, value) => Text('$value월'),
      options: _months.map((month) => ShadOption(
        value: month,
        child: Text('$month월'),
      )).toList(),
      onChanged: (value) {
        if (value != null) {
          final year = selectedYear ?? DateTime.now().year;

          // 일 조정
          int? adjustedDay = selectedDay;
          if (selectedDay != null) {
            final daysInMonth = _getDaysInMonth(year, value);
            if (selectedDay > daysInMonth) {
              adjustedDay = daysInMonth;
            }
          }

          final date = DateTime(year, value, adjustedDay ?? 1);
          ref.read(profileFormProvider.notifier).updateBirthDate(date);
        }
      },
    );
  }

  /// 일 드롭다운
  Widget _buildDayDropdown(BuildContext context, WidgetRef ref, List<int> days, int? selectedYear, int? selectedMonth, int? selectedDay) {
    final validDay = selectedDay != null && days.contains(selectedDay) ? selectedDay : null;

    return ShadSelect<int>(
      key: ValueKey('day_${selectedMonth}_$validDay'),
      placeholder: const Text('일'),
      initialValue: validDay,
      selectedOptionBuilder: (context, value) => Text('$value일'),
      options: days.map((day) => ShadOption(
        value: day,
        child: Text('$day일'),
      )).toList(),
      onChanged: (value) {
        if (value != null) {
          final year = selectedYear ?? DateTime.now().year;
          final month = selectedMonth ?? 1;
          final date = DateTime(year, month, value);
          ref.read(profileFormProvider.notifier).updateBirthDate(date);
        }
      },
    );
  }
}
