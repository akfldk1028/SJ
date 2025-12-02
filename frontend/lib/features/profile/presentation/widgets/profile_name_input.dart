import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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

    // 초기값 설정
    final formState = ref.read(profileFormProvider);
    _controller.text = formState.displayName;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '이름',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ShadInput(
          controller: _controller,
          placeholder: const Text('최대 12글자 이내로 입력하세요'),
          maxLength: 12,
          onChanged: (value) {
            ref.read(profileFormProvider.notifier).updateDisplayName(value);
          },
        ),
      ],
    );
  }
}
