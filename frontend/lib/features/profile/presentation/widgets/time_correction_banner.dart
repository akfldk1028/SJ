import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';

/// 진태양시 보정 배너
///
/// 도시 선택 시 보정 시간 자동 표시
/// 예: "입력하신 지역 정보에 따라 -26분을 보정합니다"
class TimeCorrectionBanner extends ConsumerWidget {
  const TimeCorrectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '입력하신 지역 정보에 따라 $correctionText을 보정합니다',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
