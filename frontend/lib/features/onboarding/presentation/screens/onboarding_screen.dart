import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/mystic_background.dart';
import '../../../../router/routes.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

import '../../../profile/presentation/widgets/birth_date_input_widget.dart';
import '../../../profile/presentation/widgets/birth_time_options.dart';
import '../../../profile/presentation/widgets/birth_time_picker.dart';
import '../../../profile/presentation/widgets/calendar_type_dropdown.dart';
import '../../../profile/presentation/widgets/city_search_field.dart';
import '../../../profile/presentation/widgets/gender_toggle_buttons.dart';
import '../../../profile/presentation/widgets/profile_name_input.dart';
import '../../../profile/presentation/widgets/time_correction_banner.dart';

/// 앱 최초 실행 시 사주 정보 입력 화면 (온보딩) - 동양풍 다크 테마
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileFormProvider.notifier).reset();
    });
  }

  Future<void> _onSave() async {
    final formNotifier = ref.read(profileFormProvider.notifier);

    try {
        await formNotifier.saveProfile();
        if (mounted) {
            context.go(Routes.menu);
        }
    } catch (e) {
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
      body: MysticBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // 헤더 아이콘
                Center(
                  child: Text(
                    '🔮',
                    style: TextStyle(
                      fontSize: 60,
                      shadows: [
                        Shadow(
                          color: theme.primaryColor.withOpacity(0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // 타이틀
                Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        theme.primaryColor,
                        theme.accentColor ?? theme.primaryColor,
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      '당신의 운명을\n알아보세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'AI가 분석하는 정확한 사주풀이로\n오늘의 운세와 인생의 방향을 확인하세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),

                // 폼 컨테이너
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.isDark ? null : theme.cardColor,
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
                      color: theme.primaryColor.withOpacity(theme.isDark ? 0.15 : 0.12),
                    ),
                    boxShadow: theme.isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. 이름
                      const ProfileNameInput(),
                      const SizedBox(height: 20),

                      // 2. 성별
                      const GenderToggleButtons(),
                      const SizedBox(height: 20),

                      // 3. 생년월일시
                      _buildBirthSection(context),
                      const SizedBox(height: 20),

                      // 4. 출생 도시
                      const CitySearchField(),
                      const SizedBox(height: 12),

                      // 5. 진태양시 보정 배너
                      const TimeCorrectionBanner(),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 완료 버튼 - 골드 그라데이션
                GestureDetector(
                  onTap: _onSave,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.accentColor ?? theme.primaryColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '시작하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBirthSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CalendarTypeDropdown(),
        const SizedBox(height: 12),
        const BirthDateInputWidget(),
        const SizedBox(height: 12),
        const BirthTimePicker(),
        const SizedBox(height: 12),
        const BirthTimeOptions(),
      ],
    );
  }
}
