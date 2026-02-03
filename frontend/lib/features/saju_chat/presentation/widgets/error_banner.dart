import 'package:flutter/material.dart';

/// 에러 배너 위젯
///
/// 탭하면 닫기 가능 (onDismiss 콜백)
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const ErrorBanner({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: theme.colorScheme.errorContainer,
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (onDismiss != null)
              Icon(
                Icons.close,
                size: 16,
                color: theme.colorScheme.onErrorContainer,
              ),
          ],
        ),
      ),
    );
  }
}
