import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/config/admin_config.dart';
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

  /// 수정 모드 여부 (기존 프로필 있으면 수정 모드)
  bool _isEditMode = false;
  String? _editingProfileId;

  @override
  void initState() {
    super.initState();
    // 폼 상태 초기화 및 위젯 rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 기존 활성 프로필이 있으면 수정 모드로 폼 초기화
      final activeProfile = await ref.read(activeProfileProvider.future);
      if (activeProfile != null) {
        ref.read(profileFormProvider.notifier).loadProfile(activeProfile);
        _isEditMode = true;
        _editingProfileId = activeProfile.id;
      } else {
        ref.read(profileFormProvider.notifier).reset();
        _isEditMode = false;
        _editingProfileId = null;
      }
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
        // 한국어 외 로케일: 도시 필드가 숨겨져 있으므로 기본값 '서울' 설정
        if (context.locale.languageCode != 'ko' && formState.birthCity.isEmpty) {
          formNotifier.updateBirthCity('서울');
        }

        // 수정 모드면 기존 프로필 ID 전달하여 업데이트
        await formNotifier.saveProfile(editingId: _editingProfileId);
        if (mounted) {
            context.go(Routes.menu);
        }
    } catch (e) {
        // 에러 처리
        print('[Onboarding] saveProfile error: $e');
        if (mounted) {
             ShadToaster.of(context).show(
              ShadToast.destructive(
                title: Text('onboarding.inputError'.tr()),
                description: Text('onboarding.inputErrorDesc'.tr()),
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
          'onboarding.formTitle'.tr(),
          style: TextStyle(color: theme.textPrimary),
        ),
        centerTitle: true,
        actions: [
          _buildLocaleButton(context, '🇰🇷', 'ko'),
          _buildLocaleButton(context, '🇺🇸', 'en'),
          _buildLocaleButton(context, '🇯🇵', 'ja'),
        ],
      ),
      body: MysticBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // iPad/큰 화면: 폼 최대 너비 제한 + 세로 중앙 정렬
              final isWide = constraints.maxWidth > 600;
              final formMaxWidth = isWide ? 500.0 : double.infinity;

              return SingleChildScrollView(
                key: _formKey,  // key로 rebuild 제어
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 40 : 20,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 40, // padding 제외
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: formMaxWidth),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'onboarding.formDescription'.tr(),
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

                          // 4. 출생 도시 (한국어만 - 도시 데이터가 한국 지역만 존재)
                          if (context.locale.languageCode == 'ko') ...[
                            const CitySearchField(),
                            const SizedBox(height: 16),

                            // 5. 진태양시 보정 배너
                            const TimeCorrectionBanner(),
                          ],
                          const SizedBox(height: 40),

                          // 완료 버튼
                          ShadButton(
                            size: ShadButtonSize.lg,
                            onPressed: _onSave,
                            child: Text('onboarding.submitButton'.tr()),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLocaleButton(BuildContext context, String flag, String langCode) {
    final isActive = context.locale.languageCode == langCode;
    return Opacity(
      opacity: isActive ? 1.0 : 0.4,
      child: IconButton(
        onPressed: () => context.setLocale(Locale(langCode)),
        icon: Text(flag, style: const TextStyle(fontSize: 20)),
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
