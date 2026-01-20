/// 앱 라우트 상수 정의
abstract class Routes {
  // Splash & Onboarding
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';

  // Home & Menu
  static const String home = '/home';
  static const String menu = '/menu';

  // Profile
  static const String profileSelect = '/profile/select';
  static const String profileEdit = '/profile/edit';
  static const String relationshipList = '/relationships';
  static const String relationshipAdd = '/relationships/add';

  // Saju
  static const String sajuChat = '/saju/chat';
  static const String sajuChart = '/saju/chart';
  static const String sajuGraph = '/saju/graph';
  static const String sajuDetail = '/saju/detail';

  // Fortune
  static const String dailyFortuneDetail = '/fortune/daily';
  static const String monthlyFortune = '/fortune/monthly';
  static const String newYearFortune = '/fortune/new-year';
  static const String yearly2025Fortune = '/fortune/yearly-2025';
  static const String traditionalSaju = '/fortune/traditional-saju';
  static const String compatibility = '/fortune/compatibility';

  // History
  static const String history = '/history';

  // Calendar
  static const String calendar = '/calendar';

  // Settings
  static const String settings = '/settings';
  static const String settingsProfile = '/settings/profile';
  static const String settingsNotification = '/settings/notification';
  static const String settingsTerms = '/settings/terms';
  static const String settingsPrivacy = '/settings/privacy';
  static const String settingsDisclaimer = '/settings/disclaimer';
  static const String iconGenerator = '/settings/icon-generator';
}
