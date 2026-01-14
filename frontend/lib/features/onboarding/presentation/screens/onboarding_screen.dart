import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/admin_config.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../../../../router/routes.dart';
import '../../../profile/domain/entities/gender.dart';
import '../../../profile/domain/entities/relationship_type.dart';
import '../../../profile/domain/entities/saju_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

import '../../../profile/presentation/widgets/birth_date_input_widget.dart';
import '../../../profile/presentation/widgets/birth_time_input_widget.dart';
import '../../../profile/presentation/widgets/birth_time_options.dart';
import '../../../profile/presentation/widgets/calendar_type_dropdown.dart';
import '../../../profile/presentation/widgets/city_search_field.dart';
import '../../../profile/presentation/widgets/gender_toggle_buttons.dart';
import '../../../profile/presentation/widgets/profile_name_input.dart';
import '../../../profile/presentation/widgets/time_correction_banner.dart';

/// 앱 최초 실행 시 사주 정보 입력 화면 (온보딩)
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // 위젯 rebuild를 위한 key (reset 시 갱신)
  Key _formKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    // 폼 상태 초기화 및 위젯 rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileFormProvider.notifier).reset();
      // 위젯들의 controller도 초기화하기 위해 key 변경
      if (mounted) {
        setState(() {
          _formKey = UniqueKey();
        });
      }
    });
  }

  Future<void> _onSave() async {
    // 유효성 검사 (Form State StateNotifier 내부 로직 이용)
    final formNotifier = ref.read(profileFormProvider.notifier);
    final formState = ref.read(profileFormProvider);

    // 디버깅: 현재 폼 상태 출력
    print('[Onboarding] === Form State Debug ===');
    print('[Onboarding] displayName: "${formState.displayName}"');
    print('[Onboarding] gender: ${formState.gender}');
    print('[Onboarding] birthDate: ${formState.birthDate}');
    print('[Onboarding] birthCity: "${formState.birthCity}"');
    print('[Onboarding] birthTimeUnknown: ${formState.birthTimeUnknown}');
    print('[Onboarding] birthTimeMinutes: ${formState.birthTimeMinutes}');
    print('[Onboarding] isLunar: ${formState.isLunar}');
    print('[Onboarding] isValid: ${formState.isValid}');
    print('[Onboarding] ===========================');

    try {
        await formNotifier.saveProfile();
        if (mounted) {
            context.go(Routes.menu);
        }
    } catch (e) {
        // 에러 처리
        print('[Onboarding] saveProfile error: $e');
        if (mounted) {
             ShadToaster.of(context).show(
              ShadToast.destructive(
                title: const Text('입력 오류'),
                description: const Text('모든 정보를 올바르게 입력해주세요.\n(이름, 성별, 생년월일, 도시)'),
              ),
            );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.textPrimary,
        title: Text(
          '사주 정보 입력',
          style: TextStyle(color: theme.textPrimary),
        ),
        centerTitle: true,
        // Admin 버튼 - 개발 환경에서만 표시
        actions: [
          if (AdminConfig.isAdminModeAvailable)
            _isAdminLoading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.admin_panel_settings),
                    tooltip: '개발자 모드',
                    onPressed: () => _handleAdminLogin(context),
                  ),
        ],
      ),
      body: MysticBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            key: _formKey,  // key로 rebuild 제어
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '정확한 만세력을 위해\n정보를 입력해주세요.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 32),

                // 1. 이름
                const ProfileNameInput(),
                const SizedBox(height: 24),

                // 2. 성별
                const GenderToggleButtons(),
                const SizedBox(height: 24),

                // 3. 생년월일시
                _buildBirthSection(context),
                const SizedBox(height: 24),

                // 4. 출생 도시
                const CitySearchField(),
                const SizedBox(height: 16),

                // 5. 진태양시 보정 배너
                const TimeCorrectionBanner(),
                const SizedBox(height: 40),

                // 완료 버튼
                ShadButton(
                  size: ShadButtonSize.lg,
                  onPressed: _onSave,
                  child: const Text('만세력 보러가기'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBirthSection(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CalendarTypeDropdown(),
        SizedBox(height: 12),
        BirthDateInputWidget(), // 날짜 직접 입력
        SizedBox(height: 12),
        BirthTimeInputWidget(), // 시간 직접 입력 + 오전/오후
        SizedBox(height: 12),
        BirthTimeOptions(),
      ],
    );
  }

  bool _isAdminLoading = false;

  /// Admin 프로필 자동 생성 및 채팅 화면 이동
  ///
  /// ProfileForm.saveProfile()을 사용하여 일반 사용자와 동일한 로직으로 처리
  /// - saju_analyses 테이블에 만세력 데이터 자동 생성
  /// - AI 분석 백그라운드 트리거
  Future<void> _handleAdminLogin(BuildContext context) async {
    if (_isAdminLoading) return;

    setState(() {
      _isAdminLoading = true;
    });

    try {
      // 1. 기존 Admin 프로필 확인 (Hive 캐시에서)
      final allProfiles = await ref.read(allProfilesProvider.future);
      final existingAdmin = allProfiles.where(
        (p) => p.relationType == RelationshipType.admin,
      ).firstOrNull;

      if (existingAdmin != null) {
        // 기존 Admin 프로필이 있으면 활성화만
        final profileListNotifier = ref.read(profileListProvider.notifier);
        await profileListNotifier.setActiveProfile(existingAdmin.id);
        await ref.read(activeProfileProvider.notifier).refresh();
      } else {
        // 2. 없으면 ProfileForm을 통해 새로 생성
        // ProfileForm.saveProfile()은 saju_analyses 데이터도 함께 생성함
        final formNotifier = ref.read(profileFormProvider.notifier);

        // Admin 정보로 폼 설정
        formNotifier.updateDisplayName(AdminConfig.displayName);
        formNotifier.updateGender(Gender.female);
        formNotifier.updateBirthDate(AdminConfig.birthDate);
        formNotifier.updateIsLunar(AdminConfig.isLunar);
        formNotifier.updateBirthCity(AdminConfig.birthCity);
        formNotifier.updateBirthTimeUnknown(AdminConfig.birthTimeUnknown);
        formNotifier.updateRelationType(RelationshipType.admin);

        // 프로필 저장 (saju_analyses 자동 생성 + AI 분석 트리거)
        await formNotifier.saveProfile();
      }

      // 3. 화면 이동
      if (mounted) {
        context.go(Routes.menu);
      }
    } catch (e) {
      // 에러 처리
      if (mounted) {
        setState(() {
          _isAdminLoading = false;
        });
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
