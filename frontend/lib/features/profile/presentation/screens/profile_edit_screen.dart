import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/admin_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';
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
import '../../domain/entities/saju_profile.dart';
import '../../domain/entities/gender.dart';
import '../../domain/entities/relationship_type.dart';

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
    final theme = context.appTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isEditing ? '프로필 수정' : '프로필 만들기',
          style: TextStyle(color: theme.textPrimary),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // Admin 버튼 - 개발 환경에서만 표시
        actions: [
          if (AdminConfig.isAdminModeAvailable && !isEditing)
            IconButton(
              icon: Icon(Icons.admin_panel_settings, color: theme.textPrimary),
              tooltip: '개발자 모드',
              onPressed: () => _handleAdminLogin(context, ref),
            ),
        ],
      ),
      body: MysticBackground(
        child: SafeArea(
          child: const SingleChildScrollView(
            padding: EdgeInsets.all(20),
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
        ),
      ),
    );
  }

  /// Admin 프로필 자동 생성 및 채팅 화면 이동
  Future<void> _handleAdminLogin(BuildContext context, WidgetRef ref) async {
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // 1. Admin 프로필 생성
      final now = DateTime.now();
      final adminProfile = SajuProfile(
        id: const Uuid().v4(),
        displayName: AdminConfig.displayName,
        gender: Gender.female,
        birthDate: AdminConfig.birthDate,
        isLunar: AdminConfig.isLunar,
        isLeapMonth: AdminConfig.isLeapMonth,
        birthTimeMinutes: null,
        birthTimeUnknown: AdminConfig.birthTimeUnknown,
        useYaJasi: true,
        birthCity: AdminConfig.birthCity,
        timeCorrection: 0,
        createdAt: now,
        updatedAt: now,
        isActive: true,
        relationType: RelationshipType.admin, // Admin relation type!
        memo: '개발자 테스트 계정',
      );

      // 2. 프로필 저장 (사주 분석 자동 실행됨)
      final activeProfileNotifier = ref.read(activeProfileProvider.notifier);
      await activeProfileNotifier.saveProfile(adminProfile);

      // 3. 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // 4. 채팅 화면으로 이동
      if (context.mounted) {
        context.go('/saju/chat');
      }
    } catch (e) {
      // 에러 처리
      if (context.mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Admin 로그인 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
