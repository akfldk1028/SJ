import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';

/// 프로필 이름 입력 위젯
///
/// ShadInput 사용, 최대 12자 제한
class ProfileNameInput extends ConsumerStatefulWidget {
  const ProfileNameInput({super.key});

  @override
  ConsumerState<ProfileNameInput> createState() => _ProfileNameInputState();
}

class _ProfileNameInputState extends ConsumerState<ProfileNameInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();

    // 초기값 설정은 didChangeDependencies에서 처리
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider 값으로 controller 초기화 (위젯 생성 시 한 번만)
    final formState = ref.read(profileFormProvider);
    if (_controller.text.isEmpty && formState.displayName.isNotEmpty) {
      _controller.text = formState.displayName;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'onboarding.labelName'.tr(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ShadInput(
          controller: _controller,
          placeholder: Text(
            'onboarding.placeholderName'.tr(),
            style: TextStyle(color: theme.textMuted),
          ),
          style: TextStyle(color: theme.textPrimary),
          maxLength: 12,
          onChanged: (value) {
            ref.read(profileFormProvider.notifier).updateDisplayName(value);
          },
        ),
      ],
    );
  }
}
