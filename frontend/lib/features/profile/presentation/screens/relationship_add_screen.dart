import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../../../../router/routes.dart';
import '../../../../AI/services/saju_analysis_service.dart';
import '../widgets/profile_name_input.dart';
import '../widgets/gender_toggle_buttons.dart';
import '../widgets/calendar_type_dropdown.dart';
import '../widgets/birth_date_input_widget.dart';
import '../widgets/birth_time_input_widget.dart';
import '../widgets/birth_time_options.dart';
import '../widgets/lunar_options.dart';
import '../widgets/city_search_field.dart';
import '../widgets/time_correction_banner.dart';
import '../providers/profile_provider.dart';
import '../providers/relation_provider.dart';
import '../../domain/entities/saju_profile.dart';
import '../../domain/entities/gender.dart';
import '../../domain/entities/relationship_type.dart';
import '../../data/relation_schema.dart';
// v4.0: 인연 사주 계산을 위한 추가 import
import '../../../saju_chart/domain/entities/daeun.dart' as daeun_entities;
import '../../../saju_chart/domain/services/jasi_service.dart';
import '../../../saju_chart/domain/services/saju_calculation_service.dart';
import '../../../saju_chart/presentation/providers/saju_chart_provider.dart'
    hide sajuAnalysisService;
import '../../../saju_chart/presentation/providers/saju_analysis_repository_provider.dart';

/// 인연 추가 화면 (관계인 프로필 생성)
///
/// 내 프로필이 아닌 다른 사람의 사주 정보를 입력하고
/// 나와의 관계를 설정하는 화면
class RelationshipAddScreen extends ConsumerStatefulWidget {
  const RelationshipAddScreen({super.key});

  @override
  ConsumerState<RelationshipAddScreen> createState() =>
      _RelationshipAddScreenState();
}

class _RelationshipAddScreenState extends ConsumerState<RelationshipAddScreen> {
  ProfileRelationType _selectedRelationType = ProfileRelationType.friendGeneral;
  String? _memo;
  bool _isFavorite = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileFormProvider.notifier).reset();
    });
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
        title: Text(
          '인연 추가하기',
          style: TextStyle(color: theme.textPrimary),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: MysticBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 안내 메시지
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_add,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '새로운 인연의 사주 정보를 입력해주세요.\n궁합 및 관계 분석에 활용됩니다.',
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 관계 유형 선택
                _buildRelationTypeSection(context, theme),
                const SizedBox(height: 24),

                // 이름 입력
                const ProfileNameInput(),
                const SizedBox(height: 24),

                // 성별 선택
                const GenderToggleButtons(),
                const SizedBox(height: 24),

                // 생년월일 섹션
                const _BirthDateSection(),
                const SizedBox(height: 24),

                // 출생 도시
                const CitySearchField(),
                const SizedBox(height: 16),
                const TimeCorrectionBanner(),
                const SizedBox(height: 24),

                // 메모 입력
                _buildMemoSection(context, theme),
                const SizedBox(height: 16),

                // 즐겨찾기 체크박스
                _buildFavoriteCheckbox(context, theme),
                const SizedBox(height: 32),

                // 저장 버튼
                _buildSaveButton(context, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 관계 유형 선택 섹션
  Widget _buildRelationTypeSection(BuildContext context, AppThemeExtension theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '관계 유형',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.textMuted.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ProfileRelationType>(
              value: _selectedRelationType,
              isExpanded: true,
              dropdownColor: theme.cardColor,
              style: TextStyle(color: theme.textPrimary, fontSize: 16),
              items: _buildRelationTypeItems(theme),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRelationType = value;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 관계 유형 드롭다운 아이템
  List<DropdownMenuItem<ProfileRelationType>> _buildRelationTypeItems(
    AppThemeExtension theme,
  ) {
    final categories = {
      '가족': ProfileRelationType.familyTypes,
      '연인': ProfileRelationType.romanticTypes,
      '친구': ProfileRelationType.friendTypes,
      '직장': ProfileRelationType.workTypes,
      '기타': ProfileRelationType.otherTypes,
    };

    final items = <DropdownMenuItem<ProfileRelationType>>[];

    for (final entry in categories.entries) {
      // 카테고리 헤더 (선택 불가)
      items.add(
        DropdownMenuItem<ProfileRelationType>(
          enabled: false,
          child: Text(
            '-- ${entry.key} --',
            style: TextStyle(
              color: theme.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );

      // 해당 카테고리의 관계 유형들
      for (final type in entry.value) {
        items.add(
          DropdownMenuItem<ProfileRelationType>(
            value: type,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                type.displayName,
                style: TextStyle(color: theme.textPrimary),
              ),
            ),
          ),
        );
      }
    }

    return items;
  }

  /// 메모 입력 섹션
  Widget _buildMemoSection(BuildContext context, AppThemeExtension theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '메모 (선택)',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ShadInput(
          placeholder: const Text('이 인연에 대한 메모를 입력하세요'),
          onChanged: (value) {
            _memo = value.isEmpty ? null : value;
          },
        ),
      ],
    );
  }

  /// 즐겨찾기 체크박스
  Widget _buildFavoriteCheckbox(BuildContext context, AppThemeExtension theme) {
    return Row(
      children: [
        ShadCheckbox(
          value: _isFavorite,
          onChanged: (value) {
            setState(() {
              _isFavorite = value ?? false;
            });
          },
        ),
        const SizedBox(width: 12),
        Text(
          '즐겨찾기에 추가',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        Icon(
          Icons.star,
          color: _isFavorite ? Colors.amber : theme.textSecondary,
          size: 20,
        ),
      ],
    );
  }

  /// 저장 버튼
  Widget _buildSaveButton(BuildContext context, AppThemeExtension theme) {
    final formState = ref.watch(profileFormProvider);
    final isValid = formState.isValid;

    return ShadButton(
      onPressed: isValid && !_isSaving ? () => _saveRelationship(context) : null,
      enabled: isValid && !_isSaving,
      child: _isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check, size: 20),
                SizedBox(width: 8),
                Text('인연 추가하기'),
              ],
            ),
    );
  }

  /// 인연 저장 (프로필 생성 + 관계 생성)
  Future<void> _saveRelationship(BuildContext context) async {
    // 중복 호출 방지
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      debugPrint('🔍 [_saveRelationship] Step 1: 활성 프로필 확인 시작');

      // 1. 활성 프로필 (나) 확인
      final activeProfile = ref.read(activeProfileProvider).value;
      if (activeProfile == null) {
        debugPrint('❌ [_saveRelationship] Step 1 실패: activeProfile이 null');
        throw Exception('내 프로필이 없습니다. 먼저 내 프로필을 등록해주세요.');
      }
      debugPrint('✅ [_saveRelationship] Step 1 완료: activeProfile.id = ${activeProfile.id}');

      // 2. 새 프로필 생성 (관계인용)
      debugPrint('🔍 [_saveRelationship] Step 2: 새 프로필 객체 생성');
      final formState = ref.read(profileFormProvider);
      debugPrint('   - formState.isValid = ${formState.isValid}');
      debugPrint('   - displayName = ${formState.displayName}');
      debugPrint('   - gender = ${formState.gender}');
      debugPrint('   - birthDate = ${formState.birthDate}');
      debugPrint('   - birthCity = ${formState.birthCity}');

      final now = DateTime.now();
      final newProfileId = const Uuid().v4();
      debugPrint('   - newProfileId = $newProfileId');

      final newProfile = SajuProfile(
        id: newProfileId,
        displayName: formState.displayName,
        gender: formState.gender!,
        birthDate: formState.birthDate!,
        isLunar: formState.isLunar,
        isLeapMonth: formState.isLeapMonth,
        birthTimeMinutes:
            formState.birthTimeUnknown ? null : formState.birthTimeMinutes,
        birthTimeUnknown: formState.birthTimeUnknown,
        useYaJasi: formState.useYaJasi,
        birthCity: formState.birthCity,
        timeCorrection: formState.timeCorrection,
        createdAt: now,
        updatedAt: now,
        isActive: false, // 관계인은 활성화하지 않음
        relationType: RelationshipType.other, // 관계인 프로필
        profileType: 'other', // 관계인 프로필 타입
        memo: _memo,
      );
      debugPrint('✅ [_saveRelationship] Step 2 완료: newProfile 객체 생성됨');

      // 3. 프로필 저장
      debugPrint('🔍 [_saveRelationship] Step 3: 프로필 저장 시작 (repository.save)');
      final repository = ref.read(profileRepositoryProvider);
      await repository.save(newProfile);
      debugPrint('✅ [_saveRelationship] Step 3 완료: 프로필 저장됨');

      // 3.5. 사주 분석 계산 및 DB 저장 (v4.0: 인연도 나와 동일하게 saju_analyses에 저장)
      debugPrint('🔍 [_saveRelationship] Step 3.5: 만세력 계산 및 saju_analyses 저장');
      String? toProfileAnalysisId; // 인연의 saju_analyses ID
      String? fromProfileAnalysisId; // 나의 saju_analyses ID
      try {
        // 3.5a. 사주 차트 계산 (만세력)
        final calculationService = ref.read(sajuCalculationServiceProvider);
        DateTime birthDateTime;
        if (newProfile.birthTimeUnknown || newProfile.birthTimeMinutes == null) {
          birthDateTime = DateTime(
            newProfile.birthDate.year,
            newProfile.birthDate.month,
            newProfile.birthDate.day,
            12, 0,
          );
        } else {
          final hours = newProfile.birthTimeMinutes! ~/ 60;
          final minutes = newProfile.birthTimeMinutes! % 60;
          birthDateTime = DateTime(
            newProfile.birthDate.year,
            newProfile.birthDate.month,
            newProfile.birthDate.day,
            hours, minutes,
          );
        }
        final chart = calculationService.calculate(
          birthDateTime: birthDateTime,
          birthCity: newProfile.birthCity,
          isLunarCalendar: newProfile.isLunar,
          isLeapMonth: newProfile.isLeapMonth,
          birthTimeUnknown: newProfile.birthTimeUnknown,
          jasiMode: newProfile.useYaJasi ? JasiMode.yaJasi : JasiMode.joJasi,
        );
        debugPrint('   ✅ 만세력 계산 완료: ${chart.yearPillar.fullName}, ${chart.monthPillar.fullName}, ${chart.dayPillar.fullName}, ${chart.hourPillar?.fullName ?? "시주없음"}');

        // 3.5b. 사주 분석 계산 (대운, 십신 등)
        final analysisService = ref.read(sajuAnalysisServiceProvider);
        final daeunGender = newProfile.gender.name == 'male'
            ? daeun_entities.Gender.male
            : daeun_entities.Gender.female;
        final analysis = analysisService.analyze(
          chart: chart,
          gender: daeunGender,
          currentYear: DateTime.now().year,
        );
        debugPrint('   ✅ 사주 분석 계산 완료');

        // 3.5c. DB에 저장 (saju_analyses 테이블) → ID 반환
        final dbNotifier = ref.read(currentSajuAnalysisDbProvider.notifier);
        final savedAnalysis = await dbNotifier.saveFromAnalysisWithProfileId(newProfileId, analysis);
        toProfileAnalysisId = savedAnalysis?.id;
        debugPrint('   ✅ saju_analyses DB 저장 완료: $newProfileId → toProfileAnalysisId: $toProfileAnalysisId');

        // 3.5d. 나(from_profile)의 saju_analyses ID 조회
        final repository = ref.read(sajuAnalysisRepositoryProvider);
        final myAnalysis = await repository.getByProfileId(activeProfile.id);
        fromProfileAnalysisId = myAnalysis?.id;
        debugPrint('   ✅ 나의 saju_analyses ID 조회: fromProfileAnalysisId: $fromProfileAnalysisId');
      } catch (e) {
        debugPrint('   ⚠️ 사주 분석 저장 실패 (무시됨): $e');
        // 분석 저장 실패해도 프로필/관계 저장은 계속 진행
      }

      // 3.6. GPT-5.2 분석 트리거 (Fire-and-forget)
      debugPrint('🔍 [_saveRelationship] Step 3.6: GPT 사주 분석 트리거 (백그라운드)');
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        sajuAnalysisService.analyzeOnProfileSave(
          userId: user.id,
          profileId: newProfileId,
          runInBackground: true,
          onComplete: (result) {
            debugPrint('✅ [_saveRelationship] 인연 GPT 사주 분석 완료');
            debugPrint('   - 평생운세: ${result.sajuBase?.success ?? false}');
            debugPrint('   - 오늘운세: ${result.dailyFortune?.success ?? false}');
          },
        );
        debugPrint('✅ [_saveRelationship] Step 3.6 완료: GPT 분석 백그라운드 시작됨');
      } else {
        debugPrint('⚠️ [_saveRelationship] Step 3.6 스킵: 로그인 정보 없음');
      }

      // 4. 관계 생성 (v4.0: saju_analyses 연결 포함)
      debugPrint('🔍 [_saveRelationship] Step 4: 관계 생성 시작 (relationNotifier.create)');
      debugPrint('   - fromProfileId = ${activeProfile.id}');
      debugPrint('   - toProfileId = $newProfileId');
      debugPrint('   - relationType = ${_selectedRelationType.value}');
      debugPrint('   - fromProfileAnalysisId = $fromProfileAnalysisId');
      debugPrint('   - toProfileAnalysisId = $toProfileAnalysisId');

      await ref.read(relationNotifierProvider.notifier).create(
            fromProfileId: activeProfile.id,
            toProfileId: newProfileId,
            relationType: _selectedRelationType.value,
            displayName: formState.displayName,
            memo: _memo,
            isFavorite: _isFavorite,
            fromProfileAnalysisId: fromProfileAnalysisId,
            toProfileAnalysisId: toProfileAnalysisId,
          );
      debugPrint('✅ [_saveRelationship] Step 4 완료: 관계 생성됨 (saju_analyses 연결: from=$fromProfileAnalysisId, to=$toProfileAnalysisId)');

      // 5. 목록 갱신
      debugPrint('🔍 [_saveRelationship] Step 5: Provider 갱신');
      ref.invalidate(profileListProvider);
      ref.invalidate(allProfilesProvider);
      ref.invalidate(relationsByCategoryProvider(activeProfile.id));
      debugPrint('✅ [_saveRelationship] Step 5 완료');

      // 6. 성공 메시지 및 화면 닫기
      debugPrint('🔍 [_saveRelationship] Step 6: 성공 처리 및 네비게이션');
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('인연 추가 완료'),
            description: Text('${formState.displayName}님이 추가되었습니다'),
          ),
        );
        // 네비게이션 후에는 setState가 불필요하므로 여기서 return
        debugPrint('✅ [_saveRelationship] 모든 단계 완료! 화면 이동');
        context.go(Routes.relationshipList);
        return;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [_saveRelationship] 에러 발생!');
      debugPrint('   - 에러: $e');
      debugPrint('   - 스택트레이스: $stackTrace');

      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('오류'),
            description: Text('인연 추가 실패: $e'),
          ),
        );
        // 에러 시에만 _isSaving 리셋
        setState(() {
          _isSaving = false;
        });
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
        LunarOptions(),
        SizedBox(height: 12),
        BirthDateInputWidget(),
        SizedBox(height: 12),
        BirthTimeInputWidget(),
        SizedBox(height: 12),
        BirthTimeOptions(),
      ],
    );
  }
}
