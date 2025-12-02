import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';

/// 사주 챗봇 화면 (Placeholder)
class SajuChatScreen extends StatelessWidget {
  const SajuChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.chatTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: 히스토리 화면 이동
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: 설정 화면 이동
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64),
            SizedBox(height: 16),
            Text('사주 챗봇 화면 (구현 예정)'),
            SizedBox(height: 8),
            Text(
              AppStrings.disclaimer,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
