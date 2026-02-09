import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/purchase_provider.dart';

/// 구매 복원 버튼
///
/// Apple 가이드라인 필수 요소
/// 기기 변경/앱 재설치 시 이전 구매 복원
class RestoreButtonWidget extends ConsumerWidget {
  const RestoreButtonWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;

    return TextButton(
      onPressed: () => _handleRestore(context, ref),
      child: Text(
        '구매 복원',
        style: TextStyle(
          color: theme.textMuted,
          fontSize: 13,
          decoration: TextDecoration.underline,
          decorationColor: theme.textMuted,
        ),
      ),
    );
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    await ref.read(purchaseNotifierProvider.notifier).restore();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구매가 복원되었습니다.')),
      );
    }
  }
}
