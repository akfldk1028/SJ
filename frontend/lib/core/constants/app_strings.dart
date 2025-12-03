/// 앱 문자열 상수
abstract class AppStrings {
  // App
  static const String appName = '만톡';
  static const String appDescription = 'AI 사주 챗봇';

  // Onboarding
  static const String onboardingTitle1 = '만세력 기반 사주 분석';
  static const String onboardingDesc1 = '정확한 만세력 계산으로\n당신의 사주를 분석합니다';
  static const String onboardingTitle2 = 'AI와 대화하며 상담';
  static const String onboardingDesc2 = '궁금한 점을 자유롭게 물어보세요\nAI가 친절하게 답변해드립니다';
  static const String onboardingTitle3 = '참고용 정보입니다';
  static const String onboardingDesc3 = '사주 분석 결과는 재미로 참고해주세요\n중요한 결정은 전문가와 상담하세요';

  // Profile
  static const String profileTitle = '프로필 설정';
  static const String profileName = '이름';
  static const String profileNameHint = '이름을 입력하세요';
  static const String birthDate = '생년월일';
  static const String birthTime = '출생시간';
  static const String birthTimeUnknown = '시간 모름';
  static const String gender = '성별';
  static const String genderMale = '남성';
  static const String genderFemale = '여성';
  static const String calendarType = '달력 유형';
  static const String calendarSolar = '양력';
  static const String calendarLunar = '음력';
  static const String save = '저장';
  static const String presetMe = '나';
  static const String presetLover = '연인';
  static const String presetFamily = '가족';

  // Chat
  static const String chatTitle = '사주 상담';
  static const String chatInputHint = '궁금한 점을 물어보세요...';
  static const String chatSend = '전송';
  static const String chatLoading = '답변을 생성하고 있습니다...';
  static const String chatError = '오류가 발생했습니다';
  static const String chatRetry = '다시 시도';

  // Suggested Questions
  static const String suggestedQuestion1 = '올해 운세가 어떤가요?';
  static const String suggestedQuestion2 = '재물운은 어떤가요?';
  static const String suggestedQuestion3 = '연애운이 궁금해요';
  static const String suggestedQuestion4 = '취업/이직 운세는요?';

  // History
  static const String historyTitle = '대화 기록';
  static const String historyEmpty = '저장된 대화가 없습니다';

  // Settings
  static const String settingsTitle = '설정';
  static const String settingsProfile = '프로필 관리';
  static const String settingsNotification = '알림 설정';
  static const String settingsTerms = '이용약관';
  static const String settingsPrivacy = '개인정보처리방침';
  static const String settingsDisclaimer = '면책 안내';

  // Disclaimer
  static const String disclaimer = '사주 분석 결과는 재미와 참고를 위한 것입니다.\n'
      '중요한 결정은 반드시 전문가와 상담하세요.';

  // Errors
  static const String errorGeneral = '오류가 발생했습니다';
  static const String errorNetwork = '네트워크 연결을 확인해주세요';
  static const String errorProfileRequired = '프로필을 먼저 입력해주세요';

  // Buttons
  static const String buttonNext = '다음';
  static const String buttonStart = '시작하기';
  static const String buttonCancel = '취소';
  static const String buttonConfirm = '확인';
}
