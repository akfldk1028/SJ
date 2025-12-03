import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../saju_chart/domain/services/true_solar_time_service.dart';
import '../providers/profile_provider.dart';

/// 도시 검색 입력 위젯
///
/// ShadInput + Autocomplete
/// 25개 도시 목록에서 검색 및 선택
class CitySearchField extends ConsumerStatefulWidget {
  const CitySearchField({super.key});

  @override
  ConsumerState<CitySearchField> createState() => _CitySearchFieldState();
}

class _CitySearchFieldState extends ConsumerState<CitySearchField> {
  late final TextEditingController _controller;

  // 도시 목록 (TrueSolarTimeService에서 가져오기)
  static final List<String> _cities =
      TrueSolarTimeService.cityLongitude.keys.where((k) => k != 'default').toList();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();

    // 초기값 설정
    final formState = ref.read(profileFormProvider);
    _controller.text = formState.birthCity;
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
          '도시',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return _cities;
            }
            return _cities.where((city) {
              return city.contains(textEditingValue.text);
            });
          },
          onSelected: (city) {
            _controller.text = city;
            ref.read(profileFormProvider.notifier).updateBirthCity(city);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            // Autocomplete의 controller 무시하고 우리 controller 사용
            return ShadInput(
              controller: _controller,
              focusNode: focusNode,
              placeholder: const Text('도시명을 입력하세요'),
              suffix: const Icon(Icons.search, size: 20),
              onChanged: (value) {
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
                    maxHeight: 200,
                    maxWidth: 300,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final city = options.elementAt(index);
                      return ListTile(
                        title: Text(city),
                        onTap: () => onSelected(city),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
