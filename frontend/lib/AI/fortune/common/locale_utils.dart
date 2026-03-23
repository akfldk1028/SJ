/// # Locale Utilities for Fortune Prompts
///
/// ## 개요
/// 17개 언어 지원을 위한 공통 locale 유틸리티
///
/// ## 전략
/// - ko → 한국어 프롬프트 (기존)
/// - ja → 일본어 프롬프트 (기존)
/// - en → 영어 프롬프트 (기존)
/// - 그 외 14개 → 영어 프롬프트 + "Respond in {language}" 지시
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/common/locale_utils.dart`

/// 지원 언어 코드 → 언어 이름 매핑 (네이티브 표기 포함)
class FortuneLocaleUtils {
  FortuneLocaleUtils._();

  /// 앱에서 선택된 현재 locale (easy_localization 기준)
  ///
  /// platformDispatcher.locale은 시스템 언어이므로 앱 선택 언어와 다를 수 있음.
  /// UI 위젯(MainScaffold)에서 context.locale.languageCode로 동기화.
  static String _currentLocale = 'ko';

  /// 현재 앱 locale 가져오기
  static String get currentLocale => _currentLocale;

  /// 앱 locale 설정 (UI에서 context.locale.languageCode로 호출)
  static void setCurrentLocale(String locale) {
    if (_currentLocale != locale) {
      _currentLocale = locale;
    }
  }

  /// 언어 코드 → 언어 이름 (네이티브 표기 포함)
  static String languageName(String code) => switch (code) {
    'ko' => 'Korean (한국어)',
    'ja' => 'Japanese (日本語)',
    'en' => 'English',
    'zh' => 'Chinese (中文)',
    'vi' => 'Vietnamese (Tiếng Việt)',
    'th' => 'Thai (ภาษาไทย)',
    'fr' => 'French (Français)',
    'de' => 'German (Deutsch)',
    'es' => 'Spanish (Español)',
    'pt' => 'Portuguese (Português)',
    'it' => 'Italian (Italiano)',
    'ru' => 'Russian (Русский)',
    'ar' => 'Arabic (العربية)',
    'hi' => 'Hindi (हिन्दी)',
    'id' => 'Indonesian (Bahasa Indonesia)',
    'ms' => 'Malay (Bahasa Melayu)',
    'my' => 'Burmese (မြန်မာ)',
    _ => 'English',
  };

  /// 기본 3개 언어(ko/ja/en) 외의 언어인지 확인
  static bool needsLanguageDirective(String locale) =>
      locale != 'ko' && locale != 'ja' && locale != 'en';

  /// 영어 프롬프트 뒤에 추가할 언어 지시문 생성
  static String languageDirective(String locale) {
    final name = languageName(locale);
    return '\n\nCRITICAL: Respond 100% in $name. '
        'NEVER output Korean (한국어) text. Translate ALL Korean/Chinese terms to $name.';
  }

  /// 성별 문자열 (locale-aware)
  static String genderString(String genderKorean, String locale) {
    switch (locale) {
      case 'ja':
        return genderKorean == '남성' ? '男性' : '女性';
      case 'en':
        return genderKorean == '남성' ? 'Male' : 'Female';
      case 'ko':
        return genderKorean;
      default:
        // 기타 언어는 영어 기반
        return genderKorean == '남성' ? 'Male' : 'Female';
    }
  }
}
