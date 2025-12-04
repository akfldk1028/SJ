/// 격국(格局) 엔티티
/// 사주의 전체적인 구조와 성격을 결정하는 틀

/// 격국 종류
enum GyeokGuk {
  // 기본 격국 (10가지)
  /// 정관격 - 정관이 가장 강한 격국
  jeonggwanGyeok('정관격', '正官格'),

  /// 정재격 - 정재가 가장 강한 격국
  jeongjaeGyeok('정재격', '正財格'),

  /// 식신격 - 식신이 가장 강한 격국
  siksinGyeok('식신격', '食神格'),

  /// 정인격 - 정인이 가장 강한 격국
  jeonginGyeok('정인격', '正印格'),

  /// 상관격 - 상관이 가장 강한 격국
  sanggwanGyeok('상관격', '傷官格'),

  /// 편인격 - 편인이 가장 강한 격국
  pyeoninGyeok('편인격', '偏印格'),

  /// 편재격 - 편재가 가장 강한 격국
  pyeonjaeGyeok('편재격', '偏財格'),

  /// 칠살격 (편관격) - 편관이 가장 강한 격국
  chilsalGyeok('칠살격', '七殺格'),

  /// 비견격 - 비견이 가장 강한 격국
  bigyeonGyeok('비견격', '比肩格'),

  /// 겁재격 - 겁재가 가장 강한 격국
  geopjaeGyeok('겁재격', '劫財格'),

  // 특수 격국 (3가지)
  /// 종왕격 - 비겁이 압도적으로 강한 격국
  jongwangGyeok('종왕격', '從旺格'),

  /// 종살격 - 관살이 압도적으로 강한 격국
  jongsalGyeok('종살격', '從殺格'),

  /// 종재격 - 재성이 압도적으로 강한 격국
  jongjaeGyeok('종재격', '從財格'),

  /// 중화격 - 균형 잡힌 격국
  junghwaGyeok('중화격', '中和格');

  final String korean;
  final String hanja;

  const GyeokGuk(this.korean, this.hanja);
}

/// 격국 분석 결과
class GyeokGukResult {
  /// 판정된 격국
  final GyeokGuk gyeokguk;

  /// 격국의 강도 (0-100)
  final int strength;

  /// 특수 격국 여부
  final bool isSpecial;

  /// 판정 근거
  final String reason;

  const GyeokGukResult({
    required this.gyeokguk,
    required this.strength,
    required this.isSpecial,
    required this.reason,
  });
}
