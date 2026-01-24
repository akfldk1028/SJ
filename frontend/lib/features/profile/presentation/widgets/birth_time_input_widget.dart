import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';

/// 출생시간 직접 입력 위젯 (24시간제 HH:MM)
class BirthTimeInputWidget extends ConsumerStatefulWidget {
  const BirthTimeInputWidget({super.key});

  @override
  ConsumerState<BirthTimeInputWidget> createState() => _BirthTimeInputWidgetState();
}

class _BirthTimeInputWidgetState extends ConsumerState<BirthTimeInputWidget> {
  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;

  @override
  void initState() {
    super.initState();
    _hourController = TextEditingController();
    _minuteController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider 값으로 controller 초기화 (위젯 생성 시 한 번만)
    final birthTimeMinutes = ref.read(profileFormProvider).birthTimeMinutes;
    if (_hourController.text.isEmpty && birthTimeMinutes != null) {
      final hours = birthTimeMinutes ~/ 60;
      final minutes = birthTimeMinutes % 60;
      _hourController.text = hours.toString().padLeft(2, '0');
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
    // 24시간제: 0~23시, 0~59분
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return;

    final totalMinutes = hour * 60 + minute;
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
              // 시간 입력 (24시간제: 00~23)
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
              // 24시간제 안내 텍스트
              Text(
                '(24시간)',
                style: TextStyle(
                  color: theme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
