import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/purchase_provider.dart';

/// 구매 복원 버튼
///
/// Apple 가이드라인 필수 요소
/// 기기 변경/앱 재설치 시 이전 구매 복원
class RestoreButtonWidget extends ConsumerWidget {
  const RestoreButtonWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () => _handleRestore(context, ref),
      child: const Text(
        '구매 복원',
        style: TextStyle(
          color: Colors.white54,
          fontSize: 13,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white54,
        ),
      ),
    );
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(purchaseNotifierProvider.notifier).restore();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구매가 복원되었습니다.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('복원할 구매 내역이 없습니다.')),
        );
      }
    }
  }
}
