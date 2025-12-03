import '../../data/constants/cheongan_jiji.dart';

/// 사주의 기둥 (연주/월주/일주/시주)
/// 천간 1개 + 지지 1개로 구성
class Pillar {
  final String gan;  // 천간 (갑, 을, 병, ...)
  final String ji;   // 지지 (자, 축, 인, ...)

  const Pillar({
    required this.gan,
    required this.ji,
  });

  /// 기둥의 전체 이름 (예: "갑자")
  String get fullName => '$gan$ji';

  /// 천간의 오행
  String get ganOheng => cheonganOheng[gan] ?? '';

  /// 지지의 오행
  String get jiOheng => jijiOheng[ji] ?? '';

  /// 한자 표기 (예: "甲子")
  String get hanja => '${cheonganHanja[gan] ?? ''}${jijiHanja[ji] ?? ''}';

  /// 지지의 동물 (예: "쥐")
  String get jiAnimal => jijiAnimal[ji] ?? '';

  @override
  String toString() => fullName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pillar && other.gan == gan && other.ji == ji;
  }

  @override
  int get hashCode => Object.hash(gan, ji);

  /// JSON 직렬화
  Map<String, dynamic> toJson() => {
        'gan': gan,
        'ji': ji,
      };

  /// JSON 역직렬화
  factory Pillar.fromJson(Map<String, dynamic> json) {
    return Pillar(
      gan: json['gan'] as String,
      ji: json['ji'] as String,
    );
  }
}
