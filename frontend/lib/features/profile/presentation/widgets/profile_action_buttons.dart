import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';
import '../../../../router/routes.dart';

/// 프로필 액션 버튼
///
/// - Primary: "만세력 보러가기"
/// - Secondary: "저장된 만세력 불러오기"
class ProfileActionButtons extends ConsumerWidget {
  const ProfileActionButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(profileFormProvider);
    final isValid = formState.isValid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 만세력 보러가기 버튼
        ShadButton(
          enabled: isValid,
          onPressed: isValid ? () => _onSaveAndViewChart(context, ref) : null,
          child: const Text('만세력 보러가기'),
        ),
        const SizedBox(height: 12),
        // 저장된 만세력 불러오기 버튼
        ShadButton.secondary(
          onPressed: () => _onLoadSavedProfiles(context),
          child: const Text('저장된 만세력 불러오기'),
        ),
      ],
    );
  }

  /// 프로필 저장 후 만세력 화면으로 이동
  Future<void> _onSaveAndViewChart(BuildContext context, WidgetRef ref) async {
    try {
      // 프로필 저장
      final profile = await ref.read(profileFormProvider.notifier).saveProfile();

      // 성공 메시지
      if (context.mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text('저장 완료'),
            description: Text('프로필이 저장되었습니다'),
          ),
        );

        // 만세력 화면으로 이동 (구현 예정)
        // context.push('${Routes.sajuChart}?profileId=${profile.id}');

        // 임시: 채팅 화면으로 이동
        context.go(Routes.sajuChat);
      }
    } catch (e) {
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

  /// 저장된 프로필 목록 표시
  void _onLoadSavedProfiles(BuildContext context) {
    // TODO: 프로필 목록 바텀시트 표시
    showModalBottomSheet(
      context: context,
      builder: (context) => const _SavedProfilesSheet(),
    );
  }
}

/// 저장된 프로필 목록 바텀시트 (임시)
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
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // 프로필 불러오기
                        ref.read(profileFormProvider.notifier).loadProfile(profile);
                        Navigator.pop(context);
                      },
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
