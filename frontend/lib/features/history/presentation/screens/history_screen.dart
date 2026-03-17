import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 대화 기록 화면 (Placeholder)
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('common.historyTitle'.tr()),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64),
            const SizedBox(height: 16),
            Text('common.historyEmpty'.tr()),
          ],
        ),
      ),
    );
  }
}
