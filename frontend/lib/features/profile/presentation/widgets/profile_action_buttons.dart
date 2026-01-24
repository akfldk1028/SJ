import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/profile_provider.dart';
import '../../../../router/routes.dart';
// 사주 분석 헬퍼 (모듈화)
import '../../data/relation_saju_helper.dart';

/// 프로필 액션 버튼
///
/// - Primary: "만세력 보러가기" 또는 "저장" (인연 편집 시)
/// - Secondary: "저장된 만세력 불러오기"
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 메인 버튼: 인연 편집이면 "저장", 아니면 "만세력 보러가기"
        ShadButton(
          enabled: isValid,
          onPressed: isValid ? () => _onSaveAndViewChart(context, ref) : null,
          child: Text(isRelationEdit ? '저장' : '만세력 보러가기'),
        ),
        // 인연 편집이 아닐 때만 "저장된 만세력 불러오기" 버튼 표시
        if (!isRelationEdit) ...[
          const SizedBox(height: 12),
          ShadButton.secondary(
            onPressed: () => _onLoadSavedProfiles(context),
            child: const Text('저장된 만세력 불러오기'),
          ),
        ],
      ],
    );
  }

  /// 프로필 저장 후 화면 이동
  /// - 인연 편집: Supabase saju_profiles 업데이트 + 사주분석 → 인연 리스트로 이동
  /// - 내 프로필: 로컬 저장 → 만세력 화면으로 이동
  Future<void> _onSaveAndViewChart(BuildContext context, WidgetRef ref) async {
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
        await ref.read(profileFormProvider.notifier).saveProfile(
          editingId: editingProfileId,
        );
      }

      // 화면 이동 (네비게이션만, provider 조작 없음)
      if (context.mounted) {
        if (isRelationEdit) {
          // 네비게이션만 수행 - RelationshipScreen에서 자체적으로 refresh
          // Note: 여기서 provider를 건드리면 ShellRoute의 RelationshipScreen이
          // 즉시 반응하여 defunct 에러 발생
          context.go(Routes.relationshipList);
        } else {
          // 일반 프로필 저장 시에만 Toast 표시 (같은 화면에서 이동하므로 안전)
          ShadToaster.of(context).show(
            ShadToast(
              title: const Text('저장 완료'),
              description: const Text('프로필이 저장되었습니다'),
            ),
          );
          context.go(Routes.sajuChart);
        }
      }
    } catch (e) {
      debugPrint('❌ [ProfileActionButtons] 저장 실패: $e');
      if (context.mounted) {
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('저장 실패'),
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

  /// 저장된 프로필 목록 표시
  void _onLoadSavedProfiles(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const _SavedProfilesSheet(),
    );
  }
}

/// 저장된 프로필 목록 바텀시트
class _SavedProfilesSheet extends ConsumerWidget {
  const _SavedProfilesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profileListProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '저장된 프로필',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          profilesAsync.when(
            data: (profiles) {
              if (profiles.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('저장된 프로필이 없습니다'),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: profiles.length,
                itemBuilder: (context, index) {
                  final profile = profiles[index];
                  return ListTile(
                    title: Text(profile.displayName),
                    subtitle: Text(
                      '${profile.birthDateFormatted} ${profile.calendarTypeLabel}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 불러오기 버튼
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: '불러오기',
                          onPressed: () {
                            ref.read(profileFormProvider.notifier).loadProfile(profile);
                            Navigator.pop(context);
                          },
                        ),
                        // 만세력 보기 버튼
                        IconButton(
                          icon: const Icon(Icons.visibility),
                          tooltip: '만세력 보기',
                          onPressed: () {
                            // 활성 프로필 설정 후 만세력 화면으로 이동
                            ref.read(profileListProvider.notifier).setActiveProfile(profile.id);
                            Navigator.pop(context);
                            context.go(Routes.sajuChart);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('오류: $e')),
          ),
        ],
      ),
    );
  }
}
