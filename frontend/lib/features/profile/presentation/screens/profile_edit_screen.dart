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
import '../widgets/birth_date_input_widget.dart';
import '../widgets/birth_time_input_widget.dart';
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
    this.profileData,
  });

  /// 수정 모드일 경우 기존 프로필 ID
  final String? profileId;

  /// 관계에서 수정할 때 전달받은 프로필 데이터 (ProfileRelationTarget)
  final dynamic profileData;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  /// 폼 리빌드를 위한 키 (데이터 로드 후 증가시켜 위젯 재생성)
  int _formKey = 0;

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 폼 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeForm();
    });
  }

  Future<void> _initializeForm() async {
    debugPrint('🔄 [ProfileEditScreen._initializeForm] 시작');
    debugPrint('  - profileId: ${widget.profileId}');
    debugPrint('  - profileData: ${widget.profileData}');
    debugPrint('  - profileData type: ${widget.profileData?.runtimeType}');

    final formNotifier = ref.read(profileFormProvider.notifier);

    if (widget.profileData != null) {
      // 관계에서 수정 모드: 전달받은 ProfileRelationTarget 사용
      debugPrint('📝 [ProfileEditScreen] 관계 수정 모드 - loadFromRelationTarget 호출');
      formNotifier.loadFromRelationTarget(widget.profileData);
      // 데이터 로드 후 폼 위젯 리빌드 (didChangeDependencies가 다시 실행되어 데이터 반영)
      if (mounted) {
        setState(() {
          _formKey++;
        });
        debugPrint('🔄 [ProfileEditScreen] 폼 리빌드 트리거: _formKey=$_formKey');
      }
    } else if (widget.profileId != null) {
      // 일반 수정 모드: 로컬 저장소에서 프로필 로드
      debugPrint('📝 [ProfileEditScreen] 일반 수정 모드 - 로컬 저장소에서 로드');
      final repository = ref.read(profileRepositoryProvider);
      final profile = await repository.getById(widget.profileId!);
      if (profile != null) {
        formNotifier.loadProfile(profile);
        // 데이터 로드 후 폼 위젯 리빌드
        if (mounted) {
          setState(() {
            _formKey++;
          });
          debugPrint('🔄 [ProfileEditScreen] 폼 리빌드 트리거: _formKey=$_formKey');
        }
      } else {
        debugPrint('⚠️ [ProfileEditScreen] 로컬 저장소에서 프로필을 찾을 수 없음');
      }
    } else {
      // 신규 모드: 폼 초기화 (리빌드 불필요 - 처음부터 빈 폼)
      debugPrint('📝 [ProfileEditScreen] 신규 모드 - 폼 초기화');
      formNotifier.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.profileId != null;
    final isRelationEdit = widget.profileData != null;
    // 본인 프로필 수정: profileId 있고 profileData 없음 → 관계 유형 변경 불가
    final isMyProfileEdit = isEditing && !isRelationEdit;
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              key: ValueKey('profile_form_$_formKey'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 본인 프로필 수정 시 관계 유형 변경 불가 (숨김)
                // 신규 모드 또는 인연 편집 모드에서만 표시
                if (!isMyProfileEdit) ...[
                  RelationshipTypeDropdown(key: ValueKey('rel_$_formKey')),
                  const SizedBox(height: 24),
                ],
                ProfileNameInput(key: ValueKey('name_$_formKey')),
                const SizedBox(height: 24),
                GenderToggleButtons(key: ValueKey('gender_$_formKey')),
                const SizedBox(height: 24),
                _BirthDateSection(key: ValueKey('birth_$_formKey')),
                const SizedBox(height: 24),
                CitySearchField(key: ValueKey('city_$_formKey')),
                const SizedBox(height: 16),
                const TimeCorrectionBanner(),
                const SizedBox(height: 32),
                ProfileActionButtons(
                  editingProfileId: widget.profileId,
                  isRelationEdit: isRelationEdit,
                ),
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
  const _BirthDateSection({super.key});

  @override
  Widget build(BuildContext context) {
    // key가 변경되면 자식 위젯들도 재생성됨
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CalendarTypeDropdown(key: key != null ? ValueKey('cal_${key.hashCode}') : null),
        // Phase 18: 음력 선택 시 윤달 옵션 표시
        LunarOptions(key: key != null ? ValueKey('lunar_${key.hashCode}') : null),
        const SizedBox(height: 12),
        BirthDateInputWidget(key: key != null ? ValueKey('date_${key.hashCode}') : null),
        const SizedBox(height: 12),
        BirthTimeInputWidget(key: key != null ? ValueKey('time_${key.hashCode}') : null),
        const SizedBox(height: 12),
        BirthTimeOptions(key: key != null ? ValueKey('time_opt_${key.hashCode}') : null),
      ],
    );
  }
}
