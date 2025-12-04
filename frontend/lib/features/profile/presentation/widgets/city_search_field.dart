import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../saju_chart/domain/services/true_solar_time_service.dart';
import '../providers/profile_provider.dart';

/// 도시 선택 위젯
///
/// ShadSelect 드롭다운으로 전환
/// 전체 도시 목록을 바로 선택 가능
class CitySearchField extends ConsumerWidget {
  const CitySearchField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(profileFormProvider);
    final cities = TrueSolarTimeService.searchableCities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '출생 도시',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ShadSelect<String>(
          placeholder: const Text('출생 도시를 선택하세요'),
          initialValue: formState.birthCity.isNotEmpty ? formState.birthCity : null,
          selectedOptionBuilder: (context, value) {
            final correction = TrueSolarTimeService.getLongitudeCorrectionMinutes(value);
            final correctionText = correction >= 0
                ? '+${correction.round()}분'
                : '${correction.round()}분';
            return Text('$value ($correctionText)');
          },
          options: cities.map((city) {
            final correction = TrueSolarTimeService.getLongitudeCorrectionMinutes(city);
            final correctionText = correction >= 0
                ? '+${correction.round()}분'
                : '${correction.round()}분';
            return ShadOption(
              value: city,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(city),
                  Text(
                    correctionText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (city) {
            if (city != null) {
              ref.read(profileFormProvider.notifier).updateBirthCity(city);
            }
          },
        ),
        // 선택된 도시의 보정 시간 표시
        if (formState.birthCity.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '진태양시 보정: ${formState.timeCorrection >= 0 ? '+${formState.timeCorrection}' : formState.timeCorrection}분 (경도 기준)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}
