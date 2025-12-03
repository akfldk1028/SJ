import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../domain/entities/gender.dart';
import '../providers/profile_form_provider.dart';
import '../providers/profile_provider.dart';

/// 프로필 입력/수정 화면 (Shadcn UI)
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({
    super.key,
    this.profileId,
  });

  final String? profileId;
  bool get isEditMode => profileId != null;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _displayNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (!widget.isEditMode) return;

    final profile = await ref.read(
      profileByIdProvider(widget.profileId!).future,
    );

    if (profile != null) {
      ref.read(profileFormProvider.notifier).initFromProfile(profile);
      _displayNameController.text = profile.displayName;
    }
  }

  Future<void> _save() async {
    final formState = ref.read(profileFormProvider);
    if (!formState.isValid) return;

    setState(() => _isLoading = true);

    try {
      final profile = ref.read(profileFormProvider.notifier).toProfile(
            existingId: widget.profileId,
          );

      if (profile == null) return;

      if (widget.isEditMode) {
        await ref.read(profileListProvider.notifier).updateProfile(profile);
      } else {
        await ref.read(profileListProvider.notifier).addProfile(profile);
      }

      if (mounted) {
        context.go('/chat/${profile.id}');
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('오류'),
            content: Text('저장 실패: $e'),
            actions: [
              PrimaryButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(profileFormProvider);
    final formNotifier = ref.read(profileFormProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      headers: [
        AppBar(
          leading: [
            IconButton.ghost(
              icon: const Icon(RadixIcons.arrowLeft),
              onPressed: () => context.go('/home'),
            ),
          ],
          title: Text(widget.isEditMode ? '프로필 수정' : '사주 정보 입력'),
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필명
            _buildSection(
              theme,
              title: '프로필명',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프리셋 버튼들
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['나', '배우자', '자녀', '부모'].map((preset) {
                      final isSelected = formState.displayName == preset;
                      return isSelected
                          ? PrimaryButton(
                              size: ButtonSize.small,
                              onPressed: () {
                                formNotifier.setDisplayName(preset);
                                _displayNameController.text = preset;
                              },
                              child: Text(preset),
                            )
                          : OutlineButton(
                              size: ButtonSize.small,
                              onPressed: () {
                                formNotifier.setDisplayName(preset);
                                _displayNameController.text = preset;
                              },
                              child: Text(preset),
                            );
                    }).toList(),
                  ),
                  const Gap(12),
                  TextField(
                    controller: _displayNameController,
                    placeholder: const Text('직접 입력'),
                    onChanged: formNotifier.setDisplayName,
                  ),
                ],
              ),
            ),
            const Gap(24),

            // 성별
            _buildSection(
              theme,
              title: '성별',
              child: Row(
                children: [
                  Expanded(
                    child: formState.gender == Gender.male
                        ? PrimaryButton(
                            onPressed: () => formNotifier.setGender(Gender.male),
                            child: const Text('남성'),
                          )
                        : OutlineButton(
                            onPressed: () => formNotifier.setGender(Gender.male),
                            child: const Text('남성'),
                          ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: formState.gender == Gender.female
                        ? PrimaryButton(
                            onPressed: () => formNotifier.setGender(Gender.female),
                            child: const Text('여성'),
                          )
                        : OutlineButton(
                            onPressed: () => formNotifier.setGender(Gender.female),
                            child: const Text('여성'),
                          ),
                  ),
                ],
              ),
            ),
            const Gap(24),

            // 생년월일
            _buildSection(
              theme,
              title: '생년월일',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DatePicker(
                          value: formState.birthDate,
                          onChanged: (date) {
                            if (date != null) formNotifier.setBirthDate(date);
                          },
                          placeholder: const Text('날짜 선택'),
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      Checkbox(
                        state: formState.isLunar
                            ? CheckboxState.checked
                            : CheckboxState.unchecked,
                        onChanged: (state) {
                          formNotifier.setIsLunar(state == CheckboxState.checked);
                        },
                      ),
                      const Gap(8),
                      const Text('음력'),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(24),

            // 출생시간
            _buildSection(
              theme,
              title: '출생시간',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        state: formState.birthTimeUnknown
                            ? CheckboxState.checked
                            : CheckboxState.unchecked,
                        onChanged: (state) {
                          formNotifier.setBirthTimeUnknown(
                            state == CheckboxState.checked,
                          );
                        },
                      ),
                      const Gap(8),
                      const Text('시간 모름'),
                    ],
                  ),
                  if (!formState.birthTimeUnknown) ...[
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(
                          child: Select<int>(
                            value: formState.birthTimeMinutes != null
                                ? formState.birthTimeMinutes! ~/ 60
                                : null,
                            itemBuilder: (context, item) => Text('$item시'),
                            onChanged: (hour) {
                              if (hour != null) {
                                final minutes = formState.birthTimeMinutes != null
                                    ? formState.birthTimeMinutes! % 60
                                    : 0;
                                formNotifier.setBirthTime(hour, minutes);
                              }
                            },
                            placeholder: const Text('시'),
                            popup: SelectPopup(
                              items: SelectItemList(
                                children: List.generate(
                                  24,
                                  (i) => SelectItemButton(
                                    value: i,
                                    child: Text('$i시'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Gap(8),
                        Expanded(
                          child: Select<int>(
                            value: formState.birthTimeMinutes != null
                                ? formState.birthTimeMinutes! % 60
                                : null,
                            itemBuilder: (context, item) => Text('$item분'),
                            onChanged: (minute) {
                              if (minute != null) {
                                final hour = formState.birthTimeMinutes != null
                                    ? formState.birthTimeMinutes! ~/ 60
                                    : 0;
                                formNotifier.setBirthTime(hour, minute);
                              }
                            },
                            placeholder: const Text('분'),
                            popup: SelectPopup(
                              items: SelectItemList(
                                children: List.generate(
                                  60,
                                  (i) => SelectItemButton(
                                    value: i,
                                    child: Text('$i분'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Gap(24),

            // 출생지
            _buildSection(
              theme,
              title: '출생지 (선택)',
              child: Select<String?>(
                value: formState.birthPlace,
                itemBuilder: (context, item) => Text(item ?? '선택 안함'),
                onChanged: formNotifier.setBirthPlace,
                placeholder: const Text('출생지 선택'),
                popup: SelectPopup(
                  items: SelectItemList(
                    children: [
                      const SelectItemButton(value: null, child: Text('선택 안함')),
                      ...['서울', '부산', '대구', '인천', '광주', '대전', '울산', '세종', '경기', '강원', '충북', '충남', '전북', '전남', '경북', '경남', '제주']
                          .map((place) => SelectItemButton(
                                value: place,
                                child: Text(place),
                              )),
                    ],
                  ),
                ),
              ),
            ),
            const Gap(32),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                onPressed: formState.isValid && !_isLoading ? _save : null,
                child: _isLoading
                    ? const CircularProgressIndicator(size: 20)
                    : const Text('상담 시작하기'),
              ),
            ),
            const Gap(24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, {required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.typography.large.copyWith(fontWeight: FontWeight.w600),
        ),
        const Gap(12),
        child,
      ],
    );
  }
}
