import 'package:flutter/material.dart';
import '../../data/mock/mock_fortune_data.dart';
import '../../../../core/theme/app_theme.dart';

/// Saju table widget - 테마 적용
class SajuTable extends StatelessWidget {
  const SajuTable({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final pillars = MockFortuneData.sajuPillarsDetailed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.06),
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header row
            _buildHeaderRow(context, pillars),
            _buildDivider(context),
            // 십신(천간) row
            _buildSimpleRow(context, '십신', pillars, 'tenGod1'),
            _buildDivider(context),
            // 천간 row
            _buildHeavenlyRow(context, pillars),
            _buildDivider(context),
            // 지지 row
            _buildEarthlyRow(context, pillars),
            _buildDivider(context),
            // 십신(지지) row
            _buildSimpleRow(context, '십신', pillars, 'tenGod2'),
            _buildDivider(context),
            // 지장간 row
            _buildSimpleRow(context, '지장간', pillars, 'jijanggan'),
            _buildDivider(context),
            // 12운성 row
            _buildSimpleRow(context, '12운성', pillars, 'twelveState'),
            _buildDivider(context),
            // 12신살 row
            _buildSimpleRow(context, '12신살', pillars, 'twelveStar'),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final theme = context.appTheme;
    return Container(
      height: 1,
      color: theme.isDark
          ? theme.textMuted.withOpacity(0.2)
          : Colors.grey[100],
    );
  }

  Widget _buildHeaderRow(BuildContext context, List<Map<String, dynamic>> pillars) {
    final theme = context.appTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: theme.isDark
            ? theme.primaryColor.withOpacity(0.1)
            : theme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 56),
          ...pillars.map((p) => Expanded(
                child: Center(
                  child: Text(
                    p['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildHeavenlyRow(BuildContext context, List<Map<String, dynamic>> pillars) {
    final theme = context.appTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _buildRowLabel(context, '천간'),
          ...pillars.map((p) {
            final heavenly = p['heavenly'] as Map<String, dynamic>;
            final color = _getElementColor(heavenly['element']);
            final elementKr = MockFortuneData.getElementKorean(heavenly['element']);
            final korean = heavenly['korean'] as String;

            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        heavenly['char'] as String,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$korean$elementKr',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEarthlyRow(BuildContext context, List<Map<String, dynamic>> pillars) {
    final theme = context.appTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _buildRowLabel(context, '지지'),
          ...pillars.map((p) {
            final earthly = p['earthly'] as Map<String, dynamic>;
            final color = _getElementColor(earthly['element']);
            final elementKr = MockFortuneData.getElementKorean(earthly['element']);
            final korean = earthly['korean'] as String;

            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        earthly['char'] as String,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$korean$elementKr',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSimpleRow(BuildContext context, String label, List<Map<String, dynamic>> pillars, String key) {
    final theme = context.appTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _buildRowLabel(context, label),
          ...pillars.map((p) => Expanded(
                child: Center(
                  child: Text(
                    p[key] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textSecondary,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRowLabel(BuildContext context, String label) {
    final theme = context.appTheme;

    return SizedBox(
      width: 56,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: theme.textMuted,
          ),
        ),
      ),
    );
  }

  Color _getElementColor(String element) {
    switch (element) {
      case 'wood':
        return const Color(0xFF4CAF50); // Green
      case 'fire':
        return const Color(0xFFE91E63); // Red/Pink
      case 'earth':
        return const Color(0xFFFF9800); // Orange/Yellow
      case 'metal':
        return const Color(0xFF9E9E9E); // Gray
      case 'water':
        return const Color(0xFF2196F3); // Blue
      default:
        return const Color(0xFF666666);
    }
  }
}
