import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';

/// 진태양시 보정 배너
///
/// 도시 선택 시 보정 시간 자동 표시
/// 예: "입력하신 지역 정보에 따라 -26분을 보정합니다"
class TimeCorrectionBanner extends ConsumerWidget {
  const TimeCorrectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.appTheme;
    final formState = ref.watch(profileFormProvider);
    final timeCorrection = formState.timeCorrection;
    final birthCity = formState.birthCity;

    // 도시가 선택되지 않았거나 보정값이 0이면 표시 안 함
    if (birthCity.isEmpty || timeCorrection == 0) {
      return const SizedBox.shrink();
    }

    final correctionText = timeCorrection > 0
        ? '+$timeCorrection분'
        : '$timeCorrection분';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.15),
            (theme.accentColor ?? theme.primaryColor).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.schedule,
              color: theme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '진태양시 보정',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$birthCity 기준 $correctionText 보정 적용',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
