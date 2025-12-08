/// 오행(五行) 모델
/// JSON 파싱 및 타입 안전성 제공
class OhengModel {
  final String name; // 목, 화, 토, 금, 수
  final String hanja; // 木, 火, 土, 金, 水
  final String color; // hex color
  final String season; // 계절
  final String direction; // 방위

  const OhengModel({
    required this.name,
    required this.hanja,
    required this.color,
    required this.season,
    required this.direction,
  });

  factory OhengModel.fromJson(Map<String, dynamic> json) {
    return OhengModel(
      name: json['name'] as String,
      hanja: json['hanja'] as String,
      color: json['color'] as String,
      season: json['season'] as String,
      direction: json['direction'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'hanja': hanja,
        'color': color,
        'season': season,
        'direction': direction,
      };

  @override
  String toString() => '$name($hanja)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is OhengModel && name == other.name;

  @override
  int get hashCode => name.hashCode;
}
