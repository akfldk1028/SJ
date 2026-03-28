import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../AI/fortune/common/locale_utils.dart';
import '../../../../AI/jina/personas/zodiac/zodiac_identity.dart';
import '../../../../AI/jina/personas/zodiac/zodiac_image_service.dart';
import '../../../../core/services/posthog_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../router/routes.dart';
import '../../../profile/domain/entities/gender.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../saju_chart/domain/services/true_solar_time_service.dart';
import '../../../saju_chart/domain/services/saju_calculation_service.dart';
import '../widgets/zodiac/zodiac_animal_avatar.dart';
import '../widgets/zodiac/zodiac_element_background.dart';
import '../widgets/zodiac/zodiac_reveal_animation.dart';

/// 십이지신 대화형 온보딩 스크린
///
/// [Phase 0] 올해 동물 풀스크린 등장 (탭하면 진행)
/// [Phase 1] 스토리 플로우로 프로필 수집 (이름→생년월일→시간→성별)
/// [Phase 2] 수호동물 공개 (ZodiacRevealAnimation)
/// [Phase 3] CTA → 프로필 저장 → 메인 화면
class ZodiacOnboardingScreen extends ConsumerStatefulWidget {
  const ZodiacOnboardingScreen({super.key});

  @override
  ConsumerState<ZodiacOnboardingScreen> createState() =>
      _ZodiacOnboardingScreenState();
}

class _ZodiacOnboardingScreenState
    extends ConsumerState<ZodiacOnboardingScreen> {
  // ── Data ────────────────────────────────────────────────────────────────
  late final ZodiacIdentity _yearIdentity;
  String _bgElement = '화';

  // ── Phases: 0=intro, 1=story, 2=reveal, 3=complete ────────────────────
  int _phase = 0;

  // ── Story steps (Phase 1): 0=greeting, 1=name, 2=date, 3=time, 4=gender, 5=preReveal
  int _chatStep = 0;

  // ── Controllers ───────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  bool _isLunar = false;

  // ── Input guards ──────────────────────────────────────────────────────
  bool _nameSubmitted = false;
  bool _dateSubmitted = false;
  bool _timeSubmitted = false;
  bool _genderSubmitted = false;

  // ── Profile data ──────────────────────────────────────────────────────
  String _name = '';
  DateTime? _birthDate;
  Gender? _gender;
  int? _birthTimeMinutes;
  bool _birthTimeUnknown = false;
  ZodiacIdentity? _userIdentity;

  // ── Save ───────────────────────────────────────────────────────────────
  bool _saving = false;

  bool get _isKo => context.locale.languageCode == 'ko';

  // ═══════════════════════════════════════════════════════════════════════
  // Lifecycle
  // ═══════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _yearIdentity = ZodiacIdentity.currentYear();
    _bgElement = _yearIdentity.elementName;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileFormProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Phase transitions
  // ═══════════════════════════════════════════════════════════════════════

  void _startStory() {
    if (!mounted || _phase != 0) return;
    setState(() {
      _phase = 1;
      _chatStep = 0;
    });
    // Auto-advance from greeting to name after 2s
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && _phase == 1 && _chatStep == 0) {
        setState(() => _chatStep = 1);
      }
    });
  }

  void _startReveal() {
    if (!mounted || _birthDate == null) return;

    // 실제 SajuCalculationService로 일주 계산 (진태양시/DST 보정 포함)
    final city = TrueSolarTimeService.defaultCityForLocale(
      context.locale.languageCode,
    );
    final saju = SajuCalculationService();
    final chart = saju.calculate(
      birthDateTime: _birthDate!,
      birthCity: city,
      isLunarCalendar: _isLunar,
      birthTimeUnknown: _birthTimeUnknown,
    );

    // 일주의 천간+지지로 ZodiacIdentity 생성
    _userIdentity = ZodiacIdentity.fromGanji(
      chart.dayPillar.gan,
      chart.dayPillar.ji,
    );
    setState(() {
      _phase = 2;
      _bgElement = _userIdentity!.elementName;
    });
  }

  void _onRevealComplete() {
    if (!mounted) return;
    setState(() => _phase = 3);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Story flow handlers
  // ═══════════════════════════════════════════════════════════════════════

  void _onNameDone() {
    if (_nameSubmitted || !mounted) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || name.length > 12) return;
    _nameSubmitted = true;
    _name = name;
    ref.read(profileFormProvider.notifier).updateDisplayName(name);
    setState(() => _chatStep = 2);
  }

  void _onDateSubmit() {
    if (_dateSubmitted || !mounted) return;
    final text = _dateCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length != 8) return;

    final year = int.tryParse(text.substring(0, 4));
    final month = int.tryParse(text.substring(4, 6));
    final day = int.tryParse(text.substring(6, 8));
    if (year == null || month == null || day == null) return;
    if (month < 1 || month > 12 || day < 1 || day > 31) return;

    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) return;

    _dateSubmitted = true;
    _birthDate = date;
    final notifier = ref.read(profileFormProvider.notifier);
    notifier.updateBirthDate(date);
    notifier.updateIsLunar(_isLunar);
    setState(() => _chatStep = 3);
  }

  void _onTimeDone(int? minutes) {
    if (_timeSubmitted || !mounted) return;
    _timeSubmitted = true;
    _birthTimeMinutes = minutes;
    _birthTimeUnknown = minutes == null;
    final notifier = ref.read(profileFormProvider.notifier);
    if (minutes != null) {
      notifier.updateBirthTime(minutes);
      notifier.updateBirthTimeUnknown(false);
    } else {
      notifier.updateBirthTimeUnknown(true);
    }
    setState(() => _chatStep = 4);
  }

  void _onGenderDone(Gender gender) {
    if (_genderSubmitted || !mounted) return;
    _genderSubmitted = true;
    _gender = gender;
    ref.read(profileFormProvider.notifier).updateGender(gender);
    setState(() => _chatStep = 5);
    // Auto-advance to reveal
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _phase == 1 && _chatStep == 5) _startReveal();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Save & navigate
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _saveAndContinue() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final notifier = ref.read(profileFormProvider.notifier);

      // 데이터 전체 재확인 (provider 상태 유실 방어)
      notifier.updateDisplayName(_name);
      if (_birthDate != null) notifier.updateBirthDate(_birthDate!);
      notifier.updateIsLunar(_isLunar);
      if (_birthTimeMinutes != null) {
        notifier.updateBirthTime(_birthTimeMinutes!);
        notifier.updateBirthTimeUnknown(false);
      } else {
        notifier.updateBirthTimeUnknown(true);
      }
      if (_gender != null) notifier.updateGender(_gender!);
      notifier.updateBirthCity(
        TrueSolarTimeService.defaultCityForLocale(context.locale.languageCode),
      );

      await notifier.saveProfile();

      // 유저 오행에 맞는 테마 자동 적용
      if (_userIdentity != null) {
        final elementTheme = _elementToTheme(_userIdentity!.elementNameEn);
        if (elementTheme != null) {
          await ref.read(appThemeNotifierProvider.notifier).setTheme(elementTheme);
        }
      }

      PosthogService.trackEvent('zodiac_onboarding_completed');
      if (mounted) context.go(Routes.menu);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        // 에러 표시 후 재시도 가능
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error'),
            content: Text('$e'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _saveAndContinue(); // 재시도
                },
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go(Routes.menu);
                },
                child: const Text('Skip'),
              ),
            ],
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Localization
  // ═══════════════════════════════════════════════════════════════════════

  String _localizedName(ZodiacIdentity identity) {
    const animalKeyMap = {
      '쥐': 'rat', '소': 'ox', '호랑이': 'tiger', '토끼': 'rabbit',
      '용': 'dragon', '뱀': 'snake', '말': 'horse', '양': 'sheep',
      '원숭이': 'monkey', '닭': 'rooster', '개': 'dog', '돼지': 'pig',
    };
    final key = animalKeyMap[identity.animalName];
    if (key == null) return identity.fullName;

    final animal = 'saju_chat.zodiac_$key'.tr();
    if (_isKo) return '${identity.colorName} $animal';

    // 글로벌: 오행 색 + 동물 (Red Horse, Blue Dragon 등)
    const elementColorEn = {
      'Wood': 'Green', 'Fire': 'Red', 'Earth': 'Golden',
      'Metal': 'White', 'Water': 'Black',
    };
    final color = elementColorEn[identity.elementNameEn] ?? '';
    return '$color $animal';
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Language selector
  // ═══════════════════════════════════════════════════════════════════════

  static const _langs = [
    ('ko', '🇰🇷', '한국어'), ('en', '🇺🇸', 'English'),
    ('ja', '🇯🇵', '日本語'), ('zh', '🇨🇳', '中文'),
    ('vi', '🇻🇳', 'Tiếng Việt'), ('th', '🇹🇭', 'ไทย'),
    ('id', '🇮🇩', 'Indonesia'), ('ms', '🇲🇾', 'Melayu'),
    ('my', '🇲🇲', 'မြန်မာ'), ('fr', '🇫🇷', 'Français'),
    ('de', '🇩🇪', 'Deutsch'), ('es', '🇪🇸', 'Español'),
    ('pt', '🇧🇷', 'Português'), ('it', '🇮🇹', 'Italiano'),
    ('hi', '🇮🇳', 'हिन्दी'), ('ar', '🇸🇦', 'العربية'),
    ('ru', '🇷🇺', 'Русский'),
  ];

  Widget _buildLanguageButton() {
    final code = context.locale.languageCode;
    final flag =
        _langs.where((l) => l.$1 == code).map((l) => l.$2).firstOrNull ??
            '🌐';
    return IconButton(
      onPressed: _showLanguageSheet,
      icon: Text(flag, style: const TextStyle(fontSize: 20)),
    );
  }

  void _showLanguageSheet() {
    final current = context.locale.languageCode;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _langs.length,
            itemBuilder: (_, i) {
              final (code, flag, name) = _langs[i];
              final active = current == code;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _onLanguageChanged(code);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: active
                        ? _yearIdentity.themeColor.withAlpha(40)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: active
                          ? _yearIdentity.themeColor
                          : Colors.white.withAlpha(30),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$flag $name',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      color: active
                          ? _yearIdentity.themeColor
                          : Colors.white.withAlpha(200),
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onLanguageChanged(String code) {
    context.setLocale(Locale(code));
    FortuneLocaleUtils.setCurrentLocale(code);

    _nameCtrl.clear();
    _name = '';
    _birthDate = null;
    _userIdentity = null;
    _nameSubmitted = false;
    _dateSubmitted = false;
    _timeSubmitted = false;
    _genderSubmitted = false;
    ref.read(profileFormProvider.notifier).reset();
    setState(() {
      _chatStep = 0;
      _phase = 1;
      _bgElement = _yearIdentity.elementName;
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && _phase == 1 && _chatStep == 0) {
        setState(() => _chatStep = 1);
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        body: ZodiacElementBackground(
          elementName: _bgElement,
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _buildCurrentPhase(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPhase() {
    switch (_phase) {
      case 0:
        return _buildIntro();
      case 1:
        return _buildStory();
      case 2:
        return _buildReveal();
      case 3:
        return _buildComplete();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Phase 0: Intro ─────────────────────────────────────────────────────

  Widget _buildIntro() {
    return GestureDetector(
      key: const ValueKey('phase_intro'),
      onTap: _startStory,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZodiacAnimalAvatar(
              emoji: _yearIdentity.animalEmoji,
              imageUrl: ZodiacImageService.getImageUrl(_yearIdentity, large: true),
              size: 280,
              glowColor: _yearIdentity.themeColor,
            ),
            const SizedBox(height: 32),
            Text(
              _localizedName(_yearIdentity),
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: _yearIdentity.themeColor.withAlpha(180),
                    blurRadius: 30,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'onboarding.zodiac_introTagline'.tr(namedArgs: {
                'year': '${DateTime.now().year}',
                'animal': _localizedName(_yearIdentity),
              }),
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withAlpha(200),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Text(
              'onboarding.zodiac_tapToContinue'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withAlpha(100),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Phase 1: Story flow ────────────────────────────────────────────────

  Widget _buildStory() {
    return Column(
      key: const ValueKey('phase_story'),
      children: [
        // Language button (top right)
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 4, right: 4),
            child: _buildLanguageButton(),
          ),
        ),
        // Story content
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _buildStoryStep(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoryStep() {
    switch (_chatStep) {
      case 0:
        return _buildStepGreeting();
      case 1:
        return _buildStepName();
      case 2:
        return _buildStepDate();
      case 3:
        return _buildStepTime();
      case 4:
        return _buildStepGender();
      case 5:
        return _buildStepPreReveal();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Speech bubble wrapper ───────────────────────────────────────────────

  /// 캐릭터가 말하는 것처럼 말풍선 + 아바타
  Widget _speechBubble({
    Key? key,
    required String text,
    Widget? child,
    double avatarSize = 180,
    bool large = false,
  }) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 큰 캐릭터 아바타
        ZodiacAnimalAvatar(
          emoji: _yearIdentity.animalEmoji,
          imageUrl: ZodiacImageService.getImageUrl(_yearIdentity, large: large || avatarSize > 140),
          size: avatarSize,
          glowColor: _yearIdentity.themeColor,
          animate: avatarSize > 140,
        ),
        const SizedBox(height: 8),
        // 말풍선 꼬리 (역삼각형)
        CustomPaint(
          size: const Size(20, 10),
          painter: _BubbleTailPainter(color: Colors.white.withAlpha(20)),
        ),
        // 말풍선 본체
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _yearIdentity.themeColor.withAlpha(40),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (child != null) ...[
                const SizedBox(height: 20),
                child,
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 0: Greeting ───────────────────────────────────────────────────

  Widget _buildStepGreeting() {
    final yearName = _localizedName(_yearIdentity);
    return _speechBubble(
      key: const ValueKey('step_greeting'),
      text: 'onboarding.zodiac_greeting'.tr(namedArgs: {
        'year': '${DateTime.now().year}',
        'yearAnimal': yearName,
      }),
      avatarSize: 200,
      large: true,
    );
  }

  // ── Step 1: Name ───────────────────────────────────────────────────────

  Widget _buildStepName() {
    return _speechBubble(
      key: const ValueKey('step_name'),
      text: 'onboarding.zodiac_askName'.tr(),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'onboarding.zodiac_namePlaceholder'.tr(),
                hintStyle: TextStyle(color: Colors.white.withAlpha(80)),
                filled: true,
                fillColor: Colors.white.withAlpha(15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _onNameDone(),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            onPressed: _onNameDone,
            icon: const Icon(Icons.arrow_forward_rounded),
            style: IconButton.styleFrom(
              backgroundColor: _yearIdentity.themeColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(52, 52),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Date ───────────────────────────────────────────────────────

  Widget _buildStepDate() {
    return _speechBubble(
      key: const ValueKey('step_date'),
      text: 'onboarding.zodiac_askDate'.tr(namedArgs: {'name': _name}),
      child: Column(
        children: [
          // 왜 생년월일이 중요한지 설명 (외국인 UX)
          Text(
            'onboarding.zodiac_dateExplain'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withAlpha(140),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // 음력/양력 토글
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _calendarToggle(
                label: 'onboarding.calendarSolar'.tr(),
                selected: !_isLunar,
                onTap: () => setState(() => _isLunar = false),
              ),
              const SizedBox(width: 12),
              _calendarToggle(
                label: 'onboarding.calendarLunar'.tr(),
                selected: _isLunar,
                onTap: () => setState(() => _isLunar = true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 8자리 직접 입력
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dateCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2),
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  decoration: InputDecoration(
                    hintText: 'onboarding.placeholderBirthDate'.tr(),
                    hintStyle: TextStyle(color: Colors.white.withAlpha(60), fontSize: 16),
                    filled: true,
                    fillColor: Colors.white.withAlpha(15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    counterText: '',
                  ),
                  onSubmitted: (_) => _onDateSubmit(),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _onDateSubmit,
                icon: const Icon(Icons.arrow_forward_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: _yearIdentity.themeColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(52, 52),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calendarToggle({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? _yearIdentity.themeColor.withAlpha(60)
              : Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? _yearIdentity.themeColor
                : Colors.white.withAlpha(30),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white.withAlpha(150),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // ── Step 3: Time ───────────────────────────────────────────────────────

  Widget _buildStepTime() {
    return _speechBubble(
      key: const ValueKey('step_time'),
      text: 'onboarding.zodiac_askTime'.tr(),
      child: Column(
        children: [
          Text(
            'onboarding.zodiac_timeExplain'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withAlpha(140),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 12, minute: 0),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: _yearIdentity.themeColor,
                        surface: const Color(0xFF1A1A2E),
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (time != null) _onTimeDone(time.hour * 60 + time.minute);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: _yearIdentity.themeColor.withAlpha(100)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'onboarding.zodiac_pickTime'.tr(),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _onTimeDone(null),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withAlpha(150),
            ),
            child: Text(
              'onboarding.zodiac_dontKnow'.tr(),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 4: Gender ─────────────────────────────────────────────────────

  Widget _buildStepGender() {
    return _speechBubble(
      key: const ValueKey('step_gender'),
      text: 'onboarding.zodiac_askGender'.tr(),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => _onGenderDone(Gender.male),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.withAlpha(50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'onboarding.zodiac_male'.tr(),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => _onGenderDone(Gender.female),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.withAlpha(50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'onboarding.zodiac_female'.tr(),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 5: Pre-reveal ─────────────────────────────────────────────────

  Widget _buildStepPreReveal() {
    return _speechBubble(
      key: const ValueKey('step_prereveal'),
      text: 'onboarding.zodiac_preReveal'.tr(),
      avatarSize: 200,
      large: true,
    );
  }

  // ── Phase 2: Reveal ────────────────────────────────────────────────────

  Widget _buildReveal() {
    return SizedBox.expand(
      key: const ValueKey('phase_reveal'),
      child: ZodiacRevealAnimation(
        animalEmoji: _userIdentity!.animalEmoji,
        imageUrl: ZodiacImageService.getImageUrl(_userIdentity!, large: true),
        fullName: _localizedName(_userIdentity!),
        ganjiHanja: _userIdentity!.ganjiHanja,
        themeColor: _userIdentity!.themeColor,
        elementName: _userIdentity!.elementName,
        onComplete: _onRevealComplete,
      ),
    );
  }

  // ── Phase 3: Complete ──────────────────────────────────────────────────

  Widget _buildComplete() {
    return Center(
      key: const ValueKey('phase_complete'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZodiacAnimalAvatar(
              emoji: _userIdentity!.animalEmoji,
              imageUrl: ZodiacImageService.getImageUrl(_userIdentity!, large: true),
              size: 220,
              glowColor: _userIdentity!.themeColor,
            ),
            const SizedBox(height: 24),
            Text(
              _localizedName(_userIdentity!),
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: _userIdentity!.themeColor.withAlpha(150),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _userIdentity!.ganjiHanja,
              style: TextStyle(
                fontSize: 20,
                color: Colors.white.withAlpha(150),
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'onboarding.zodiac_yourGuardian'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white.withAlpha(200),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'onboarding.zodiac_guardianExplain'.tr(namedArgs: {
                'element': _isKo
                    ? _userIdentity!.elementName
                    : _userIdentity!.elementNameEn,
              }),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withAlpha(140),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _userIdentity!.themeColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      _userIdentity!.themeColor.withAlpha(100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('onboarding.zodiac_letsGo'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 오행 → 테마 매핑
  static AppThemeType? _elementToTheme(String elementEn) {
    const map = {
      'Wood': AppThemeType.elementWood,
      'Fire': AppThemeType.elementFire,
      'Earth': AppThemeType.elementEarth,
      'Metal': AppThemeType.elementMetal,
      'Water': AppThemeType.elementWater,
    };
    return map[elementEn];
  }
}

/// 말풍선 꼬리 (역삼각형)
class _BubbleTailPainter extends CustomPainter {
  final Color color;
  const _BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
