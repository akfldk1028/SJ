import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../widgets/profile_name_input.dart';
import '../widgets/gender_toggle_buttons.dart';
import '../widgets/calendar_type_dropdown.dart';
import '../widgets/birth_date_picker.dart';
import '../widgets/birth_time_picker.dart';
import '../widgets/birth_time_options.dart';
import '../widgets/city_search_field.dart';
import '../widgets/time_correction_banner.dart';
import '../widgets/profile_action_buttons.dart';
import '../widgets/relationship_type_dropdown.dart';
import '../providers/profile_provider.dart';

/// 프로필 입력/수정 화면 - 동양풍 다크 테마
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({
    super.key,
    this.profileId,
  });

  final String? profileId;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeForm();
    });
  }

  Future<void> _initializeForm() async {
    final formNotifier = ref.read(profileFormProvider.notifier);

    if (widget.profileId != null) {
      final repository = ref.read(profileRepositoryProvider);
      final profile = await repository.getById(widget.profileId!);
      if (profile != null) {
        formNotifier.loadProfile(profile);
      }
    } else {
      formNotifier.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isEditing = widget.profileId != null;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: MysticBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 헤더
              _buildHeader(context, theme, isEditing),
              // 컨텐츠
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 아바타 섹션
                      _buildAvatarSection(theme),
                      const SizedBox(height: 32),
                      // 폼 컨테이너
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.isDark ? null : Colors.white,
                          gradient: theme.isDark
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF1A1A24),
                                    const Color(0xFF14141C),
                                  ],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.primaryColor.withOpacity(theme.isDark ? 0.15 : 0.2),
                          ),
                          boxShadow: theme.isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            RelationshipTypeDropdown(),
                            SizedBox(height: 20),
                            ProfileNameInput(),
                            SizedBox(height: 20),
                            GenderToggleButtons(),
                            SizedBox(height: 20),
                            _BirthDateSection(),
                            SizedBox(height: 20),
                            CitySearchField(),
                            SizedBox(height: 12),
                            TimeCorrectionBanner(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const ProfileActionButtons(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppThemeExtension theme, bool isEditing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.15),
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: theme.primaryColor,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          Text(
            isEditing ? '프로필 수정' : '프로필 만들기',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(AppThemeExtension theme) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.primaryColor,
                theme.accentColor ?? theme.primaryColor,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '은',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                color: theme.isDark ? const Color(0xFF0A0A0F) : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '사진 변경',
          style: TextStyle(
            fontSize: 14,
            color: theme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
