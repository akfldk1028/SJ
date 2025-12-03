import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../saju_chart/domain/services/true_solar_time_service.dart';
import '../providers/profile_provider.dart';

/// 도시 검색 입력 위젯
///
/// ShadInput + Autocomplete
/// 부분 검색 + 별칭 매핑 지원 (부산 → 부산광역시)
class CitySearchField extends ConsumerStatefulWidget {
  const CitySearchField({super.key});

  @override
  ConsumerState<CitySearchField> createState() => _CitySearchFieldState();
}

class _CitySearchFieldState extends ConsumerState<CitySearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();

    // 초기값 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final formState = ref.read(profileFormProvider);
      _controller.text = formState.birthCity;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '출생 도시',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (textEditingValue) {
            // 부분 검색 + 별칭 매핑 사용
            return TrueSolarTimeService.searchCities(textEditingValue.text);
          },
          onSelected: (city) {
            _controller.text = city;
            ref.read(profileFormProvider.notifier).updateBirthCity(city);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            // Autocomplete의 controller 사용
            return ShadInput(
              controller: controller,
              focusNode: focusNode,
              placeholder: const Text('도시명을 입력하세요 (예: 부산, 서울)'),
              trailing: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.search, size: 20),
              ),
              onChanged: (value) {
                // 사용자가 입력 중일 때는 직접 입력값 저장
                ref.read(profileFormProvider.notifier).updateBirthCity(value);
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 250,
                    maxWidth: 320,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final city = options.elementAt(index);
                      // 시간 보정값 표시
                      final correction = TrueSolarTimeService.getLongitudeCorrectionMinutes(city);
                      final correctionText = correction >= 0
                          ? '+${correction.round()}분'
                          : '${correction.round()}분';

                      return ListTile(
                        title: Text(city),
                        subtitle: Text(
                          '진태양시 보정: $correctionText',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        onTap: () => onSelected(city),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        // 선택된 도시의 보정 시간 표시
        Consumer(
          builder: (context, ref, _) {
            final formState = ref.watch(profileFormProvider);
            if (formState.birthCity.isEmpty) {
              return const SizedBox.shrink();
            }

            final correction = formState.timeCorrection;
            final correctionText = correction >= 0
                ? '+$correction분'
                : '$correction분';

            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '진태양시 보정: $correctionText (경도 기준)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
