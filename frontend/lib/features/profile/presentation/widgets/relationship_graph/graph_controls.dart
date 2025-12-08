import 'package:flutter/material.dart';

class GraphControls extends StatelessWidget {
  const GraphControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitToScreen,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitToScreen;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlButton(
            icon: Icons.add,
            onPressed: onZoomIn,
            tooltip: 'Zoom In',
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.remove,
            onPressed: onZoomOut,
            tooltip: 'Zoom Out',
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.fit_screen,
            onPressed: onFitToScreen,
            tooltip: 'Fit to Screen',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
        color: Colors.black87,
      ),
    );
  }
}
