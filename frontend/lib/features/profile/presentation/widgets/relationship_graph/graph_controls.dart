import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

class GraphControls extends StatelessWidget {
  const GraphControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    return Positioned(
      right: 16,
      bottom: 90, // FAB와 겹치지 않도록 위로 올림
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlButton(
            context,
            icon: Icons.add,
            onPressed: onZoomIn,
            tooltip: '확대',
            appTheme: appTheme,
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            context,
            icon: Icons.remove,
            onPressed: onZoomOut,
            tooltip: '축소',
            appTheme: appTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required AppThemeExtension appTheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: appTheme.isDark
            ? const Color(0xFF2A3540)
            : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: appTheme.isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: tooltip,
        iconSize: 24,
        color: appTheme.isDark
            ? Colors.white
            : Colors.black87,
      ),
    );
  }
}
