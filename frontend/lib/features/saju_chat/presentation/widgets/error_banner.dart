import 'package:flutter/material.dart';

/// 에러 배너 위젯
class ErrorBanner extends StatelessWidget {
  final String message;

  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.errorContainer,
      child: Text(
        message,
        style: TextStyle(color: theme.colorScheme.onErrorContainer),
        textAlign: TextAlign.center,
      ),
    );
  }
}
