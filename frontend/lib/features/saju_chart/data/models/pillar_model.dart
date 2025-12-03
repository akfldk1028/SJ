import '../../domain/entities/pillar.dart';

/// Pillar 모델
/// Entity를 확장하여 JSON 직렬화 기능 추가
class PillarModel extends Pillar {
  const PillarModel({
    required super.gan,
    required super.ji,
  });

  /// Entity를 Model로 변환
  factory PillarModel.fromEntity(Pillar entity) {
    return PillarModel(
      gan: entity.gan,
      ji: entity.ji,
    );
  }

  /// Entity로 변환
  Pillar toEntity() {
    return Pillar(
      gan: gan,
      ji: ji,
    );
  }

  /// JSON 직렬화
  @override
  Map<String, dynamic> toJson() => {
        'gan': gan,
        'ji': ji,
        'fullName': fullName,
        'hanja': hanja,
        'ganOheng': ganOheng,
        'jiOheng': jiOheng,
        'jiAnimal': jiAnimal,
      };

  /// JSON 역직렬화
  factory PillarModel.fromJson(Map<String, dynamic> json) {
    return PillarModel(
      gan: json['gan'] as String,
      ji: json['ji'] as String,
    );
  }

  /// copyWith
  PillarModel copyWith({
    String? gan,
    String? ji,
  }) {
    return PillarModel(
      gan: gan ?? this.gan,
      ji: ji ?? this.ji,
    );
  }
}
