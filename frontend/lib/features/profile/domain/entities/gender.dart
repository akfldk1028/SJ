/// 성별 enum
enum Gender {
  male,
  female;

  /// 한글 표시명
  String get displayName {
    switch (this) {
      case Gender.male:
        return '남자';
      case Gender.female:
        return '여자';
    }
  }

  /// JSON 직렬화를 위한 문자열 변환
  static Gender fromString(String value) {
    switch (value.toLowerCase()) {
      case 'male':
      case 'm':
        return Gender.male;
      case 'female':
      case 'f':
        return Gender.female;
      default:
        throw ArgumentError('Invalid gender value: $value');
    }
  }
}
