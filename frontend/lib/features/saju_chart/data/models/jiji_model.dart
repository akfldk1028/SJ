/// 지지(地支) 모델
/// JSON 파싱 및 타입 안전성 제공
class JijiModel {
  final String hangul;
  final String hanja;
  final String oheng;
  final String eumYang; // 음/양
  final String animal; // 띠 동물
  final int month; // 해당 월 (음력 기준, 인월=1월)
  final int hourStart; // 시작 시간
  final int hourEnd; // 종료 시간
  final int order;

  const JijiModel({
    required this.hangul,
    required this.hanja,
    required this.oheng,
    required this.eumYang,
    required this.animal,
    required this.month,
    required this.hourStart,
    required this.hourEnd,
    required this.order,
  });

  factory JijiModel.fromJson(Map<String, dynamic> json) {
    return JijiModel(
      hangul: json['hangul'] as String,
      hanja: json['hanja'] as String,
      oheng: json['oheng'] as String,
      eumYang: json['eum_yang'] as String,
      animal: json['animal'] as String,
      month: json['month'] as int,
      hourStart: json['hour_start'] as int,
      hourEnd: json['hour_end'] as int,
      order: json['order'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'hangul': hangul,
        'hanja': hanja,
        'oheng': oheng,
        'eum_yang': eumYang,
        'animal': animal,
        'month': month,
        'hour_start': hourStart,
        'hour_end': hourEnd,
        'order': order,
      };

  @override
  String toString() => '$hangul($hanja) - $animal';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JijiModel && hangul == other.hangul;

  @override
  int get hashCode => hangul.hashCode;
}
