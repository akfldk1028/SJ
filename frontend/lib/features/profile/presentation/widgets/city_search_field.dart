import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../saju_chart/domain/services/true_solar_time_service.dart';
import '../providers/profile_provider.dart';

/// 도시 검색 드롭다운 위젯
///
/// ShadSelect.withSearch 사용
/// - 드롭다운 클릭 → 검색 가능한 도시 목록 표시
/// - "서" 입력 → "서울", "서산" 등 필터링
/// - 선택 시 드롭다운 자동 닫힘
class CitySearchField extends ConsumerStatefulWidget {
  const CitySearchField({super.key});

  @override
  ConsumerState<CitySearchField> createState() => _CitySearchFieldState();
}

class _CitySearchFieldState extends ConsumerState<CitySearchField> {
  // 도시 목록 (중복 제거된 searchableCities 사용)
  static final List<String> _cities = TrueSolarTimeService.searchableCities;

  // 검색어 상태
  String _searchValue = '';

  // 선택된 도시
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    // 초기값 설정 (수정 모드 시 기존 도시 표시)
    final formState = ref.read(profileFormProvider);
    if (formState.birthCity.isNotEmpty && _cities.contains(formState.birthCity)) {
      _selectedCity = formState.birthCity;
    }
  }

  /// 검색어로 필터링된 도시 목록
  List<String> get _filteredCities {
    if (_searchValue.isEmpty) {
      return _cities;
    }
    return _cities.where((city) => city.contains(_searchValue)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '도시',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ShadSelect<String>.withSearch(
          // 선택된 값
          initialValue: _selectedCity,
          // 플레이스홀더
          placeholder: Text(
            '도시를 선택하세요',
            style: TextStyle(color: theme.textMuted),
          ),
          // 검색 입력 플레이스홀더
          searchPlaceholder: Text(
            '도시명 검색...',
            style: TextStyle(color: theme.textMuted),
          ),
          // 검색어 변경 시
          onSearchChanged: (value) {
            setState(() {
              _searchValue = value;
            });
          },
          // 선택 시
          onChanged: (city) {
            if (city != null) {
              setState(() {
                _selectedCity = city;
              });
              ref.read(profileFormProvider.notifier).updateBirthCity(city);
            }
          },
          // 선택된 값 표시
          selectedOptionBuilder: (context, value) {
            return Text(
              value,
              style: TextStyle(color: theme.textPrimary),
            );
          },
          // 옵션 목록
          options: [
            // 검색 결과가 없을 때
            if (_filteredCities.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('검색 결과가 없습니다'),
              ),
            // 필터링된 도시 목록
            ..._filteredCities.map(
              (city) => ShadOption(
                value: city,
                child: Text(city),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
