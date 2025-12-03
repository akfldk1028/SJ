import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/profile_provider.dart';

/// 생년월일 선택 위젯
///
/// 연도/월/일 드롭다운으로 빠른 선택 가능
/// 1900년~현재 연도 지원
class BirthDatePicker extends ConsumerStatefulWidget {
  const BirthDatePicker({super.key});

  @override
  ConsumerState<BirthDatePicker> createState() => _BirthDatePickerState();
}

class _BirthDatePickerState extends ConsumerState<BirthDatePicker> {
  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;

  // 연도 범위: 1900 ~ 현재 연도
  late final List<int> _years;
  final List<int> _months = List.generate(12, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    // 최신 연도가 먼저 오도록 역순 정렬
    _years = List.generate(currentYear - 1899, (i) => currentYear - i);

    // 초기값 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final formState = ref.read(profileFormProvider);
      if (formState.birthDate != null) {
        setState(() {
          _selectedYear = formState.birthDate!.year;
          _selectedMonth = formState.birthDate!.month;
          _selectedDay = formState.birthDate!.day;
        });
      }
    });
  }

  /// 해당 월의 일수 계산
  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// 일 목록 생성
  List<int> _getDays() {
    if (_selectedYear == null || _selectedMonth == null) {
      return List.generate(31, (i) => i + 1);
    }
    final daysInMonth = _getDaysInMonth(_selectedYear!, _selectedMonth!);
    return List.generate(daysInMonth, (i) => i + 1);
  }

  /// 날짜 업데이트
  void _updateDate() {
    if (_selectedYear != null && _selectedMonth != null && _selectedDay != null) {
      // 선택된 일이 해당 월의 일수를 초과하면 조정
      final daysInMonth = _getDaysInMonth(_selectedYear!, _selectedMonth!);
      final day = _selectedDay! > daysInMonth ? daysInMonth : _selectedDay!;

      final date = DateTime(_selectedYear!, _selectedMonth!, day);
      ref.read(profileFormProvider.notifier).updateBirthDate(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDays();

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
              child: _buildYearDropdown(),
            ),
            const SizedBox(width: 8),
            // 월 선택
            Expanded(
              flex: 2,
              child: _buildMonthDropdown(),
            ),
            const SizedBox(width: 8),
            // 일 선택
            Expanded(
              flex: 2,
              child: _buildDayDropdown(days),
            ),
          ],
        ),
      ],
    );
  }

  /// 연도 드롭다운
  Widget _buildYearDropdown() {
    return ShadSelect<int>(
      placeholder: const Text('연도'),
      selectedOptionBuilder: (context, value) => Text('$value년'),
      options: _years.map((year) => ShadOption(
        value: year,
        child: Text('$year년'),
      )).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedYear = value;
            // 일 조정 (2월 등 일수가 다른 경우)
            if (_selectedMonth != null && _selectedDay != null) {
              final daysInMonth = _getDaysInMonth(value, _selectedMonth!);
              if (_selectedDay! > daysInMonth) {
                _selectedDay = daysInMonth;
              }
            }
          });
          _updateDate();
        }
      },
      initialValue: _selectedYear,
    );
  }

  /// 월 드롭다운
  Widget _buildMonthDropdown() {
    return ShadSelect<int>(
      placeholder: const Text('월'),
      selectedOptionBuilder: (context, value) => Text('$value월'),
      options: _months.map((month) => ShadOption(
        value: month,
        child: Text('$month월'),
      )).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedMonth = value;
            // 일 조정
            if (_selectedYear != null && _selectedDay != null) {
              final daysInMonth = _getDaysInMonth(_selectedYear!, value);
              if (_selectedDay! > daysInMonth) {
                _selectedDay = daysInMonth;
              }
            }
          });
          _updateDate();
        }
      },
      initialValue: _selectedMonth,
    );
  }

  /// 일 드롭다운
  Widget _buildDayDropdown(List<int> days) {
    return ShadSelect<int>(
      placeholder: const Text('일'),
      selectedOptionBuilder: (context, value) => Text('$value일'),
      options: days.map((day) => ShadOption(
        value: day,
        child: Text('$day일'),
      )).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedDay = value;
          });
          _updateDate();
        }
      },
      initialValue: _selectedDay != null && days.contains(_selectedDay)
          ? _selectedDay
          : null,
    );
  }
}
