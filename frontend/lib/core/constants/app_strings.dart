/// 앱 전역 문자열 정의
class AppStrings {
  AppStrings._();

  // App Info
  static const String appName = '만톡';
  static const String appTagline = 'AI 사주 상담';

  // Profile
  static const String profileTitle = '사주 정보 입력';
  static const String profileNameLabel = '이 프로필의 이름';
  static const String genderLabel = '성별';
  static const String genderMale = '남성';
  static const String genderFemale = '여성';
  static const String birthDateLabel = '생년월일';
  static const String birthTimeLabel = '태어난 시간';
  static const String birthTimeUnknown = '시간을 모릅니다';
  static const String calendarSolar = '양력';
  static const String calendarLunar = '음력';
  static const String birthPlaceLabel = '태어난 곳 (선택)';
  static const String saveButton = '저장하기';

  // Profile Presets
  static const List<String> profileNamePresets = [
    '나',
    '연인',
    '가족',
    '친구',
  ];

  // Birth Place Options
  static const List<String> birthPlaceOptions = [
    '서울', '부산', '대구', '인천', '광주',
    '대전', '울산', '세종', '경기', '강원',
    '충북', '충남', '전북', '전남', '경북',
    '경남', '제주', '해외',
  ];

  // Validation Messages
  static const String requiredField = '필수 입력 항목입니다';
  static const String invalidDate = '올바른 날짜를 선택해주세요';
  static const String minProfileRequired = '최소 1개의 프로필이 필요합니다';

  // Error Messages
  static const String networkError = '네트워크 연결을 확인해주세요';
  static const String serverError = '서버 오류가 발생했습니다';
  static const String unknownError = '알 수 없는 오류가 발생했습니다';

  // Chat
  static const String chatPlaceholder = '무엇이든 물어보세요...';
  static const String disclaimer = '사주 풀이는 참고용이며, 중요한 결정은 전문가와 상담하세요.';

  // Common
  static const String confirm = '확인';
  static const String cancel = '취소';
  static const String delete = '삭제';
  static const String edit = '수정';
  static const String retry = '다시 시도';
}
