import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';

/// 생년월일 직접 입력 위젯 (YYYYMMDD)
class BirthDateInputWidget extends ConsumerStatefulWidget {
  const BirthDateInputWidget({super.key});

  @override
  ConsumerState<BirthDateInputWidget> createState() => _BirthDateInputWidgetState();
}

class _BirthDateInputWidgetState extends ConsumerState<BirthDateInputWidget> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    
    // 초기값 바인딩 (수정 시 등)
    final birthDate = ref.read(profileFormProvider).birthDate;
    if (birthDate != null) {
        // YYYYMMDD 포맷으로 변환
        final y = birthDate.year.toString().padLeft(4, '0');
        final m = birthDate.month.toString().padLeft(2, '0');
        final d = birthDate.day.toString().padLeft(2, '0');
        _controller.text = '$y$m$d';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAndSave(String value) {
    if (value.isEmpty) {
        setState(() => _errorText = null);
        return;
    }

    // 숫자만 추출
    final cleanText = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanText.length != 8) {
        setState(() => _errorText = '생년월일 8자리를 입력해주세요 (예: 19900101)');
        // 잘못된 날짜는 null 처리
        ref.read(profileFormProvider.notifier).updateBirthDate(DateTime(0)); // 유효하지 않음 표시용 임의값 혹은 null 처리 필요하지만 provider가 non-nullable DateTime 요구시 주의
        // Provider update logic needs to handle invalid inputs safely or we just don't update until valid.
        return;
    }

    final year = int.tryParse(cleanText.substring(0, 4));
    final month = int.tryParse(cleanText.substring(4, 6));
    final day = int.tryParse(cleanText.substring(6, 8));

    if (year == null || month == null || day == null) {
         setState(() => _errorText = '올바른 날짜 형식이 아닙니다.');
         return;
    }

    if (month < 1 || month > 12 || day < 1 || day > 31) {
        setState(() => _errorText = '존재하지 않는 날짜입니다.');
        return;
    }

    try {
        final date = DateTime(year, month, day);
        // 날짜 유효성 이중 체크 (예: 2월 30일 방지)
        if (date.year != year || date.month != month || date.day != day) {
             setState(() => _errorText = '존재하지 않는 날짜입니다.');
             return;
        }

        setState(() => _errorText = null);
        ref.read(profileFormProvider.notifier).updateBirthDate(date);
    } catch (e) {
        setState(() => _errorText = '유효하지 않은 날짜입니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShadInput(
          controller: _controller,
          placeholder: Text(
            '생년월일 8자리 (예: 19971129)',
            style: TextStyle(color: theme.textMuted),
          ),
          style: TextStyle(color: theme.textPrimary),
          keyboardType: TextInputType.number,
          maxLength: 8,
          onChanged: _validateAndSave,
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              _errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
