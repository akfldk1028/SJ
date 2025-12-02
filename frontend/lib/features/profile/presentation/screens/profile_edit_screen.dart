import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../router/routes.dart';

/// 프로필 입력 화면 (Placeholder)
class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profileTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, size: 64),
            const SizedBox(height: 16),
            const Text('프로필 입력 화면 (구현 예정)'),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.go(Routes.sajuChat),
              child: const Text('채팅 화면으로 이동 (임시)'),
            ),
          ],
        ),
      ),
    );
  }
}
