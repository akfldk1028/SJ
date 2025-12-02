import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';

/// 대화 기록 화면 (Placeholder)
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.historyTitle),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64),
            SizedBox(height: 16),
            Text(AppStrings.historyEmpty),
          ],
        ),
      ),
    );
  }
}
