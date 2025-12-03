/// 성별 열거형
///
/// 주의: 순수 Dart만 사용! Flutter import 금지!
enum Gender {
  male('male', '남성'),
  female('female', '여성');

  const Gender(this.value, this.displayName);

  /// DB에 저장되는 값
  final String value;

  /// UI에 표시되는 이름
  final String displayName;

  /// 문자열에서 Gender로 변환
  static Gender fromString(String value) {
    return Gender.values.firstWhere(
      (g) => g.value == value,
      orElse: () => Gender.male,
    );
  }
}
