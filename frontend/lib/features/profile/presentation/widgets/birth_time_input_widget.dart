import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';

/// 출생시간 직접 입력 위젯 (HH:MM + 오전/오후 토글)
class BirthTimeInputWidget extends ConsumerStatefulWidget {
  const BirthTimeInputWidget({super.key});

  @override
  ConsumerState<BirthTimeInputWidget> createState() => _BirthTimeInputWidgetState();
}

class _BirthTimeInputWidgetState extends ConsumerState<BirthTimeInputWidget> {
  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;
  bool _isAm = true; // true = 오전, false = 오후

  @override
  void initState() {
    super.initState();
    _hourController = TextEditingController();
    _minuteController = TextEditingController();

    // 초기값 바인딩
    final birthTimeMinutes = ref.read(profileFormProvider).birthTimeMinutes;
    if (birthTimeMinutes != null) {
      final totalHours = birthTimeMinutes ~/ 60;
      final minutes = birthTimeMinutes % 60;

      // 24시간 -> 12시간 변환
      if (totalHours == 0) {
        _hourController.text = '12';
        _isAm = true;
      } else if (totalHours < 12) {
        _hourController.text = totalHours.toString();
        _isAm = true;
      } else if (totalHours == 12) {
        _hourController.text = '12';
        _isAm = false;
      } else {
        _hourController.text = (totalHours - 12).toString();
        _isAm = false;
      }
      _minuteController.text = minutes.toString().padLeft(2, '0');
    }
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _updateTime() {
    final hourText = _hourController.text;
    final minuteText = _minuteController.text;

    if (hourText.isEmpty || minuteText.isEmpty) return;

    final hour = int.tryParse(hourText);
    final minute = int.tryParse(minuteText);

    if (hour == null || minute == null) return;
    if (hour < 1 || hour > 12 || minute < 0 || minute > 59) return;

    // 12시간 -> 24시간 변환
    int totalHours;
    if (_isAm) {
      totalHours = hour == 12 ? 0 : hour;
    } else {
      totalHours = hour == 12 ? 12 : hour + 12;
    }

    final totalMinutes = totalHours * 60 + minute;
    ref.read(profileFormProvider.notifier).updateBirthTime(totalMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final formState = ref.watch(profileFormProvider);
    final birthTimeUnknown = formState.birthTimeUnknown;
    final isEnabled = !birthTimeUnknown;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: IgnorePointer(
        ignoring: !isEnabled,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border.all(
              color: isEnabled
                  ? theme.textMuted.withOpacity(0.3)
                  : theme.textMuted.withOpacity(0.1),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 20, color: theme.textSecondary),
              const SizedBox(width: 12),
              // 시간 입력
              SizedBox(
                width: 45,
                child: ShadInput(
                  controller: _hourController,
                  placeholder: Text('00', style: TextStyle(color: theme.textMuted)),
                  style: TextStyle(color: theme.textPrimary, fontSize: 16),
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  textAlign: TextAlign.center,
                  onChanged: (_) => _updateTime(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(':', style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              // 분 입력
              SizedBox(
                width: 45,
                child: ShadInput(
                  controller: _minuteController,
                  placeholder: Text('00', style: TextStyle(color: theme.textMuted)),
                  style: TextStyle(color: theme.textPrimary, fontSize: 16),
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  textAlign: TextAlign.center,
                  onChanged: (_) => _updateTime(),
                ),
              ),
              const SizedBox(width: 12),
              // 오전/오후 토글
              Container(
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.textMuted.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAmPmButton(theme, '오전', _isAm, () {
                      setState(() => _isAm = true);
                      _updateTime();
                    }),
                    _buildAmPmButton(theme, '오후', !_isAm, () {
                      setState(() => _isAm = false);
                      _updateTime();
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmPmButton(AppThemeExtension theme, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.textSecondary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
