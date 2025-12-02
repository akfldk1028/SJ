import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/profile_name_input.dart';
import '../widgets/gender_toggle_buttons.dart';
import '../widgets/calendar_type_dropdown.dart';
import '../widgets/birth_date_picker.dart';
import '../widgets/birth_time_picker.dart';
import '../widgets/birth_time_options.dart';
import '../widgets/city_search_field.dart';
import '../widgets/time_correction_banner.dart';
import '../widgets/profile_action_buttons.dart';

/// 프로필 입력/수정 화면
///
/// 작은 위젯들을 조립만 하는 역할 (50줄 이하)
class ProfileEditScreen extends ConsumerWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 만들기'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileNameInput(),
            SizedBox(height: 24),
            GenderToggleButtons(),
            SizedBox(height: 24),
            _BirthDateSection(),
            SizedBox(height: 24),
            CitySearchField(),
            SizedBox(height: 16),
            TimeCorrectionBanner(),
            SizedBox(height: 32),
            ProfileActionButtons(),
          ],
        ),
      ),
    );
  }
}

/// 생년월일 섹션 (날짜 관련 입력 그룹)
class _BirthDateSection extends StatelessWidget {
  const _BirthDateSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CalendarTypeDropdown(),
        SizedBox(height: 12),
        BirthDatePicker(),
        SizedBox(height: 12),
        BirthTimePicker(),
        SizedBox(height: 12),
        BirthTimeOptions(),
      ],
    );
  }
}
