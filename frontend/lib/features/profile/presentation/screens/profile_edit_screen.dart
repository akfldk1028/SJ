import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/profile_name_input.dart';
import '../widgets/gender_toggle_buttons.dart';
import '../widgets/calendar_type_dropdown.dart';
import '../widgets/birth_date_picker.dart';
import '../widgets/birth_time_picker.dart';
import '../widgets/birth_time_options.dart';
import '../widgets/lunar_options.dart';
import '../widgets/city_search_field.dart';
import '../widgets/time_correction_banner.dart';
import '../widgets/profile_action_buttons.dart';
import '../widgets/relationship_type_dropdown.dart';
import '../providers/profile_provider.dart';

/// 프로필 입력/수정 화면
///
/// 작은 위젯들을 조립만 하는 역할
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({
    super.key,
    this.profileId,
  });

  /// 수정 모드일 경우 기존 프로필 ID
  final String? profileId;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 폼 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeForm();
    });
  }

  Future<void> _initializeForm() async {
    final formNotifier = ref.read(profileFormProvider.notifier);

    if (widget.profileId != null) {
      // 수정 모드: 기존 프로필 로드
      final repository = ref.read(profileRepositoryProvider);
      final profile = await repository.getById(widget.profileId!);
      if (profile != null) {
        formNotifier.loadProfile(profile);
      }
    } else {
      // 신규 모드: 폼 초기화
      formNotifier.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.profileId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '프로필 수정' : '프로필 만들기'),
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
            RelationshipTypeDropdown(),
            SizedBox(height: 24),
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
        // Phase 18: 음력 선택 시 윤달 옵션 표시
        LunarOptions(),
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
