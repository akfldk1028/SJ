import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/profile_provider.dart';
// 사주 분석 헬퍼 (모듈화)
import '../../data/relation_saju_helper.dart';
// 광고 Provider
import '../../../../ad/providers/ad_provider.dart';

/// 프로필 액션 버튼
///
/// - 인연 편집: "저장"
/// - 일반 (수정/신규): "프로필 저장"
class ProfileActionButtons extends ConsumerWidget {
  const ProfileActionButtons({
    super.key,
    this.editingProfileId,
    this.isRelationEdit = false,
  });

  /// 수정 모드일 경우 기존 프로필 ID
  final String? editingProfileId;

  /// 인연 프로필 편집 여부 (true면 저장 후 인연 리스트로 이동)
  final bool isRelationEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(profileFormProvider);
    final isValid = formState.isValid;

    // 버튼 텍스트 결정:
    // - 인연 편집: "저장"
    // - 일반 (수정/신규): "프로필 저장"
    final buttonText = isRelationEdit ? '저장' : '프로필 저장';

    return ShadButton(
      enabled: isValid,
      onPressed: isValid ? () => _onSaveAndViewChart(context, ref) : null,
      child: Text(buttonText),
    );
  }

  /// 프로필 저장 후 화면 이동
  /// - 인연 편집: Supabase saju_profiles 업데이트 + 사주분석 → 인연 리스트로 이동
  /// - 내 프로필: 로컬 저장 → 만세력 화면으로 이동
  Future<void> _onSaveAndViewChart(BuildContext context, WidgetRef ref) async {
    debugPrint('🔍 [ProfileActionButtons._onSaveAndViewChart] 시작');
    debugPrint('  - isRelationEdit: $isRelationEdit');
    debugPrint('  - editingProfileId: $editingProfileId');

    try {
      // 인연 편집 모드: Supabase saju_profiles 테이블 업데이트 + 사주 분석
      if (isRelationEdit && editingProfileId != null) {
        debugPrint('📝 [ProfileActionButtons] 인연 수정 모드 - Supabase 업데이트');

        // Step 1: Supabase saju_profiles 업데이트
        await _updateSupabaseProfile(ref, editingProfileId!);

        // Step 2: 사주 분석 재계산 (만세력 + DB 저장만, GPT는 스킵)
        // Note: GPT 분석을 여기서 트리거하면 백그라운드 서비스가 provider를 업데이트하여
        // 네비게이션 중 defunct widget 에러가 발생함. GPT 분석은 나중에 별도로 트리거.
        final formState = ref.read(profileFormProvider);
        if (formState.birthDate != null) {
          debugPrint('📝 [ProfileActionButtons] 사주 분석 시작 (GPT 스킵)');
          await RelationSajuHelper.analyzeSajuProfile(
            ref: ref,
            profileId: editingProfileId!,
            displayName: formState.displayName,
            birthDate: formState.birthDate!,
            birthTimeMinutes: formState.birthTimeMinutes,
            birthTimeUnknown: formState.birthTimeUnknown,
            birthCity: formState.birthCity,
            isLunar: formState.isLunar,
            isLeapMonth: formState.isLeapMonth,
            useYaJasi: formState.useYaJasi,
            genderName: formState.gender?.name ?? 'male',
            triggerGptAnalysis: false, // GPT 분석 스킵 (defunct 에러 방지)
          );
          debugPrint('✅ [ProfileActionButtons] 사주 분석 완료');
        }
      } else {
        // 일반 모드: 로컬 저장소에 저장
        debugPrint('📝 [ProfileActionButtons] 일반 모드 - 로컬 저장');
        debugPrint('  (isRelationEdit=$isRelationEdit, editingProfileId=$editingProfileId)');
        await ref.read(profileFormProvider.notifier).saveProfile(
          editingId: editingProfileId,
        );
      }

      // 화면 이동
      if (context.mounted) {
        if (isRelationEdit) {
          // context.pop()으로 push에서 정상 리턴
          // → relationship_screen의 await context.push() 완료
          // → _onRefresh() 호출됨
          debugPrint('🔄 [ProfileActionButtons] pop으로 이전 화면 복귀');
          context.pop();
        } else {
          // 일반 모드 (수정/신규): 이전 화면으로 복귀
          debugPrint('🔄 [ProfileActionButtons] 저장 완료 - pop으로 이전 화면 복귀');

          // 내 프로필 수정 시 전면광고 표시
          if (editingProfileId != null) {
            debugPrint('📺 [ProfileActionButtons] 전면광고 표시 시도');
            final adController = ref.read(adControllerProvider.notifier);
            final adShown = await adController.showInterstitial();
            debugPrint('📺 [ProfileActionButtons] 전면광고 결과: $adShown');
          }

          if (context.mounted) {
            ShadToaster.of(context).show(
              ShadToast(
                title: Text('profile.saveSuccess'.tr()),
                description: Text('profile.profileSaved'.tr()),
              ),
            );
            context.pop();
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [ProfileActionButtons] 저장 실패: $e');
      if (context.mounted) {
        ShadToaster.of(context).show(
          ShadToast(
            title: Text('profile.saveFailed'.tr()),
            description: Text(e.toString()),
          ),
        );
      }
    }
  }

  /// Supabase saju_profiles 테이블 업데이트 (인연 수정용)
  Future<void> _updateSupabaseProfile(WidgetRef ref, String profileId) async {
    final formState = ref.read(profileFormProvider);
    final client = Supabase.instance.client;

    debugPrint('🔄 [ProfileActionButtons._updateSupabaseProfile] 시작');
    debugPrint('  - profileId: $profileId');
    debugPrint('  - displayName: ${formState.displayName}');
    debugPrint('  - birthDate: ${formState.birthDate}');
    debugPrint('  - gender: ${formState.gender}');

    final updateData = <String, dynamic>{
      'display_name': formState.displayName,
      'gender': formState.gender?.name ?? 'male',
      'birth_date': formState.birthDate?.toIso8601String().split('T')[0],
      'is_lunar': formState.isLunar,
      'is_leap_month': formState.isLeapMonth,
      'birth_time_minutes': formState.birthTimeUnknown ? null : formState.birthTimeMinutes,
      'birth_time_unknown': formState.birthTimeUnknown,
      'birth_city': formState.birthCity,
      'use_ya_jasi': formState.useYaJasi,
      'relation_type': formState.relationType.name,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    debugPrint('📤 [ProfileActionButtons] Supabase UPDATE 데이터: $updateData');

    await client
        .from('saju_profiles')
        .update(updateData)
        .eq('id', profileId);

    // 업데이트 검증
    final verifyResult = await client
        .from('saju_profiles')
        .select('display_name, birth_date')
        .eq('id', profileId)
        .maybeSingle();

    debugPrint('✅ [ProfileActionButtons] Supabase UPDATE 완료');
    debugPrint('  - 검증 결과: $verifyResult');

    // Provider 무효화는 navigation 후 새 화면에서 처리
    // (여기서 하면 defunct widget rebuild 에러 발생)
  }
}
