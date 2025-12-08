/// 천간(天干) 모델
/// JSON 파싱 및 타입 안전성 제공
class CheonganModel {
  final String hangul;
  final String hanja;
  final String oheng;
  final String eumYang; // 음/양
  final int order;

  const CheonganModel({
    required this.hangul,
    required this.hanja,
    required this.oheng,
    required this.eumYang,
    required this.order,
  });

  factory CheonganModel.fromJson(Map<String, dynamic> json) {
    return CheonganModel(
      hangul: json['hangul'] as String,
      hanja: json['hanja'] as String,
      oheng: json['oheng'] as String,
      eumYang: json['eum_yang'] as String,
      order: json['order'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'hangul': hangul,
        'hanja': hanja,
        'oheng': oheng,
        'eum_yang': eumYang,
        'order': order,
      };

  @override
  String toString() => '$hangul($hanja)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheonganModel && hangul == other.hangul;

  @override
  int get hashCode => hangul.hashCode;
}
