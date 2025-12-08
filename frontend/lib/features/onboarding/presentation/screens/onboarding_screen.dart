import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';


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

/// 앱 최초 실행 시 사주 정보 입력 화면 (온보딩)
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    // 폼 상태 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileFormProvider.notifier).reset();
    });
  }

  Future<void> _onSave() async {
    // 유효성 검사 (Form State StateNotifier 내부 로직 이용)
    final formNotifier = ref.read(profileFormProvider.notifier);
    
    try {
        await formNotifier.saveProfile();
        if (mounted) {
            context.go(Routes.menu);
        }
    } catch (e) {
        // 에러 처리
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('사주 정보 입력'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '정확한 만세력을 위해\n정보를 입력해주세요.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
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
    );
  }

  Widget _buildBirthSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // '생년월일시' 라벨은 CalendarTypeDropdown 내부에 포함되어 있으므로 제거
        const CalendarTypeDropdown(),
        const SizedBox(height: 12),
        const BirthDateInputWidget(), // 텍스트 입력 위젯으로 교체
        const SizedBox(height: 12),
        const BirthTimePicker(),
        const SizedBox(height: 12),
        const BirthTimeOptions(),
      ],
    );
  }
}
