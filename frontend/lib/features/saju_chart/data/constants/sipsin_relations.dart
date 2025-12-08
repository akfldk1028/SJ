/// 십신(十神) 관계 테이블
/// 일간을 기준으로 다른 천간과의 오행 관계에 따른 십신 분류
///
/// 십신 종류:
/// - 비견(比肩): 같은 오행, 같은 음양
/// - 겁재(劫財): 같은 오행, 다른 음양
/// - 식신(食神): 내가 생하는 오행, 같은 음양
/// - 상관(傷官): 내가 생하는 오행, 다른 음양
/// - 편재(偏財): 내가 극하는 오행, 같은 음양
/// - 정재(正財): 내가 극하는 오행, 다른 음양
/// - 편관(偏官/칠살): 나를 극하는 오행, 같은 음양
/// - 정관(正官): 나를 극하는 오행, 다른 음양
/// - 편인(偏印): 나를 생하는 오행, 같은 음양
/// - 정인(正印): 나를 생하는 오행, 다른 음양
library;

/// 십신 종류
enum SipSin {
  /// 비견 - 같은 오행, 같은 음양 (나와 같은 것)
  bigyeon('비견', '比肩'),

  /// 겁재 - 같은 오행, 다른 음양 (재물을 빼앗는 것)
  geopjae('겁재', '劫財'),

  /// 식신 - 내가 생하는 오행, 같은 음양 (먹을 것)
  siksin('식신', '食神'),

  /// 상관 - 내가 생하는 오행, 다른 음양 (관을 상하게 하는 것)
  sanggwan('상관', '傷官'),

  /// 편재 - 내가 극하는 오행, 같은 음양 (편벽된 재물)
  pyeonjae('편재', '偏財'),

  /// 정재 - 내가 극하는 오행, 다른 음양 (정당한 재물)
  jeongjae('정재', '正財'),

  /// 편관/칠살 - 나를 극하는 오행, 같은 음양 (편벽된 관직)
  pyeongwan('편관', '偏官'),

  /// 정관 - 나를 극하는 오행, 다른 음양 (정당한 관직)
  jeonggwan('정관', '正官'),

  /// 편인 - 나를 생하는 오행, 같은 음양 (편벽된 도장)
  pyeonin('편인', '偏印'),

  /// 정인 - 나를 생하는 오행, 다른 음양 (정당한 도장)
  jeongin('정인', '正印');

  final String korean;
  final String hanja;

  const SipSin(this.korean, this.hanja);
}

/// 오행
enum Oheng {
  mok('목', '木'), // 목
  hwa('화', '火'), // 화
  to('토', '土'), // 토
  geum('금', '金'), // 금
  su('수', '水'); // 수

  final String korean;
  final String hanja;

  const Oheng(this.korean, this.hanja);
}

/// 음양
enum EumYang {
  yang('양', '陽'), // 양 (갑, 병, 무, 경, 임)
  eum('음', '陰'); // 음 (을, 정, 기, 신, 계)

  final String korean;
  final String hanja;

  const EumYang(this.korean, this.hanja);
}

/// 천간 → 오행 매핑
const Map<String, Oheng> cheonganToOheng = {
  '갑': Oheng.mok,
  '을': Oheng.mok,
  '병': Oheng.hwa,
  '정': Oheng.hwa,
  '무': Oheng.to,
  '기': Oheng.to,
  '경': Oheng.geum,
  '신': Oheng.geum,
  '임': Oheng.su,
  '계': Oheng.su,
};

/// 천간 → 음양 매핑
const Map<String, EumYang> cheonganToEumYang = {
  '갑': EumYang.yang,
  '을': EumYang.eum,
  '병': EumYang.yang,
  '정': EumYang.eum,
  '무': EumYang.yang,
  '기': EumYang.eum,
  '경': EumYang.yang,
  '신': EumYang.eum,
  '임': EumYang.yang,
  '계': EumYang.eum,
};

/// 지지 → 오행 매핑
const Map<String, Oheng> jijiToOheng = {
  '인': Oheng.mok,
  '묘': Oheng.mok,
  '사': Oheng.hwa,
  '오': Oheng.hwa,
  '진': Oheng.to,
  '술': Oheng.to,
  '축': Oheng.to,
  '미': Oheng.to,
  '신': Oheng.geum,
  '유': Oheng.geum,
  '해': Oheng.su,
  '자': Oheng.su,
};

/// 지지 → 음양 매핑
const Map<String, EumYang> jijiToEumYang = {
  '자': EumYang.yang,
  '축': EumYang.eum,
  '인': EumYang.yang,
  '묘': EumYang.eum,
  '진': EumYang.yang,
  '사': EumYang.eum,
  '오': EumYang.yang,
  '미': EumYang.eum,
  '신': EumYang.yang,
  '유': EumYang.eum,
  '술': EumYang.yang,
  '해': EumYang.eum,
};

/// 오행 상생 관계 (A가 B를 생함)
/// 목→화→토→금→수→목
const Map<Oheng, Oheng> ohengSangsaeng = {
  Oheng.mok: Oheng.hwa, // 목생화
  Oheng.hwa: Oheng.to, // 화생토
  Oheng.to: Oheng.geum, // 토생금
  Oheng.geum: Oheng.su, // 금생수
  Oheng.su: Oheng.mok, // 수생목
};

/// 오행 상극 관계 (A가 B를 극함)
/// 목→토→수→화→금→목
const Map<Oheng, Oheng> ohengSanggeuk = {
  Oheng.mok: Oheng.to, // 목극토
  Oheng.to: Oheng.su, // 토극수
  Oheng.su: Oheng.hwa, // 수극화
  Oheng.hwa: Oheng.geum, // 화극금
  Oheng.geum: Oheng.mok, // 금극목
};

/// 일간 기준 십신 계산
/// [dayMaster] 일간 (갑, 을, 병, ...)
/// [targetGan] 대상 천간
/// 반환: 십신
SipSin calculateSipSin(String dayMaster, String targetGan) {
  final myOheng = cheonganToOheng[dayMaster];
  final myEumYang = cheonganToEumYang[dayMaster];
  final targetOheng = cheonganToOheng[targetGan];
  final targetEumYang = cheonganToEumYang[targetGan];

  if (myOheng == null ||
      myEumYang == null ||
      targetOheng == null ||
      targetEumYang == null) {
    throw ArgumentError('유효하지 않은 천간: $dayMaster 또는 $targetGan');
  }

  final sameEumYang = myEumYang == targetEumYang;

  // 같은 오행
  if (myOheng == targetOheng) {
    return sameEumYang ? SipSin.bigyeon : SipSin.geopjae;
  }

  // 내가 생하는 오행 (식상)
  if (ohengSangsaeng[myOheng] == targetOheng) {
    return sameEumYang ? SipSin.siksin : SipSin.sanggwan;
  }

  // 내가 극하는 오행 (재성)
  if (ohengSanggeuk[myOheng] == targetOheng) {
    return sameEumYang ? SipSin.pyeonjae : SipSin.jeongjae;
  }

  // 나를 극하는 오행 (관성)
  if (ohengSanggeuk[targetOheng] == myOheng) {
    return sameEumYang ? SipSin.pyeongwan : SipSin.jeonggwan;
  }

  // 나를 생하는 오행 (인성)
  if (ohengSangsaeng[targetOheng] == myOheng) {
    return sameEumYang ? SipSin.pyeonin : SipSin.jeongin;
  }

  throw StateError('십신 계산 오류: $dayMaster → $targetGan');
}

/// 일간 기준 모든 천간의 십신 매핑 생성
Map<String, SipSin> buildSipSinMap(String dayMaster) {
  const allGan = ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'];
  final result = <String, SipSin>{};

  for (final gan in allGan) {
    result[gan] = calculateSipSin(dayMaster, gan);
  }

  return result;
}

/// 십신별 분류 (비겁, 식상, 재성, 관성, 인성)
enum SipSinCategory {
  /// 비겁 (비견, 겁재)
  bigeop('비겁', '比劫'),

  /// 식상 (식신, 상관)
  siksang('식상', '食傷'),

  /// 재성 (편재, 정재)
  jaeseong('재성', '財星'),

  /// 관성 (편관, 정관)
  gwanseong('관성', '官星'),

  /// 인성 (편인, 정인)
  inseong('인성', '印星');

  final String korean;
  final String hanja;

  const SipSinCategory(this.korean, this.hanja);
}

/// 십신 → 카테고리 매핑
const Map<SipSin, SipSinCategory> sipsinToCategory = {
  SipSin.bigyeon: SipSinCategory.bigeop,
  SipSin.geopjae: SipSinCategory.bigeop,
  SipSin.siksin: SipSinCategory.siksang,
  SipSin.sanggwan: SipSinCategory.siksang,
  SipSin.pyeonjae: SipSinCategory.jaeseong,
  SipSin.jeongjae: SipSinCategory.jaeseong,
  SipSin.pyeongwan: SipSinCategory.gwanseong,
  SipSin.jeonggwan: SipSinCategory.gwanseong,
  SipSin.pyeonin: SipSinCategory.inseong,
  SipSin.jeongin: SipSinCategory.inseong,
};
