/// 12운성(十二運星) 테이블
/// 천간의 지지에 따른 기운의 강약을 12단계로 표현
///
/// 12운성 순서: 장생→목욕→관대→건록→제왕→쇠→병→사→묘→절→태→양
/// 양간(갑병무경임)은 순행, 음간(을정기신계)은 역행
library;

// ============================================================================
// 12운성 정의
// ============================================================================

/// 12운성 종류
enum TwelveUnsung {
  jangSaeng('장생', '長生', 1, '탄생, 시작의 기운'),
  mokYok('목욕', '沐浴', 2, '씻음, 정화의 단계'),
  gwanDae('관대', '冠帶', 3, '성장, 관을 쓰는 시기'),
  geonRok('건록', '建祿', 4, '녹을 세움, 왕성한 활동'),
  jeWang('제왕', '帝旺', 5, '최고 전성기'),
  soe('쇠', '衰', 6, '쇠퇴의 시작'),
  byung('병', '病', 7, '병듦, 약해짐'),
  sa('사', '死', 8, '기운의 죽음'),
  myo('묘', '墓', 9, '묻힘, 창고'),
  jeol('절', '絶', 10, '끊어짐, 절멸'),
  tae('태', '胎', 11, '잉태, 새 생명의 시작'),
  yang('양', '養', 12, '기름, 양육');

  final String korean;
  final String hanja;
  final int order;
  final String meaning;

  const TwelveUnsung(this.korean, this.hanja, this.order, this.meaning);

  /// 기운의 강약 (높을수록 강함)
  int get strength {
    switch (this) {
      case TwelveUnsung.jeWang:
        return 10; // 최강
      case TwelveUnsung.geonRok:
        return 9;
      case TwelveUnsung.gwanDae:
        return 8;
      case TwelveUnsung.jangSaeng:
        return 7;
      case TwelveUnsung.yang:
        return 6;
      case TwelveUnsung.tae:
        return 5;
      case TwelveUnsung.mokYok:
        return 4;
      case TwelveUnsung.soe:
        return 3;
      case TwelveUnsung.byung:
        return 2;
      case TwelveUnsung.sa:
        return 1;
      case TwelveUnsung.myo:
        return 1;
      case TwelveUnsung.jeol:
        return 0; // 최약
    }
  }

  /// 길흉 판단
  String get fortuneType {
    switch (this) {
      case TwelveUnsung.jangSaeng:
      case TwelveUnsung.gwanDae:
      case TwelveUnsung.geonRok:
      case TwelveUnsung.jeWang:
        return '길';
      case TwelveUnsung.mokYok:
      case TwelveUnsung.soe:
      case TwelveUnsung.tae:
      case TwelveUnsung.yang:
        return '평';
      case TwelveUnsung.byung:
      case TwelveUnsung.sa:
      case TwelveUnsung.myo:
      case TwelveUnsung.jeol:
        return '흉';
    }
  }
}

/// 12운성 리스트 (순서대로)
const List<TwelveUnsung> unsungOrder = [
  TwelveUnsung.jangSaeng,
  TwelveUnsung.mokYok,
  TwelveUnsung.gwanDae,
  TwelveUnsung.geonRok,
  TwelveUnsung.jeWang,
  TwelveUnsung.soe,
  TwelveUnsung.byung,
  TwelveUnsung.sa,
  TwelveUnsung.myo,
  TwelveUnsung.jeol,
  TwelveUnsung.tae,
  TwelveUnsung.yang,
];

// ============================================================================
// 12운성 테이블 (천간별 지지에서의 운성)
// ============================================================================

/// 양간의 장생 지지
const Map<String, String> yangGanJangSaengJiji = {
  '갑': '해', // 갑목은 해에서 장생
  '병': '인', // 병화는 인에서 장생
  '무': '인', // 무토는 인에서 장생 (화를 따름)
  '경': '사', // 경금은 사에서 장생
  '임': '신', // 임수는 신에서 장생
};

/// 음간의 장생 지지
const Map<String, String> eumGanJangSaengJiji = {
  '을': '오', // 을목은 오에서 장생
  '정': '유', // 정화는 유에서 장생
  '기': '유', // 기토는 유에서 장생 (화를 따름)
  '신': '자', // 신금은 자에서 장생
  '계': '묘', // 계수는 묘에서 장생
};

/// 지지 순서 (자→축→인→묘→진→사→오→미→신→유→술→해)
const List<String> jijiOrder = [
  '자',
  '축',
  '인',
  '묘',
  '진',
  '사',
  '오',
  '미',
  '신',
  '유',
  '술',
  '해',
];

/// 양간 여부 확인
bool isYangGan(String gan) {
  return gan == '갑' || gan == '병' || gan == '무' || gan == '경' || gan == '임';
}

/// 12운성 계산
/// [gan] 천간 (갑, 을, 병, ...)
/// [ji] 지지 (자, 축, 인, ...)
/// 반환: 해당 천간이 해당 지지에서 갖는 12운성
TwelveUnsung calculateTwelveUnsung(String gan, String ji) {
  // 장생 지지 찾기
  final isYang = isYangGan(gan);
  final jangSaengJiji =
      isYang ? yangGanJangSaengJiji[gan] : eumGanJangSaengJiji[gan];

  if (jangSaengJiji == null) {
    throw ArgumentError('유효하지 않은 천간: $gan');
  }

  // 장생 지지의 인덱스
  final jangSaengIndex = jijiOrder.indexOf(jangSaengJiji);
  // 대상 지지의 인덱스
  final targetIndex = jijiOrder.indexOf(ji);

  if (jangSaengIndex == -1 || targetIndex == -1) {
    throw ArgumentError('유효하지 않은 지지: $ji');
  }

  int unsungIndex;
  if (isYang) {
    // 양간은 순행 (장생→목욕→관대→...)
    unsungIndex = (targetIndex - jangSaengIndex + 12) % 12;
  } else {
    // 음간은 역행 (장생←목욕←관대←...)
    unsungIndex = (jangSaengIndex - targetIndex + 12) % 12;
  }

  return unsungOrder[unsungIndex];
}

/// 특정 천간의 모든 지지에 대한 12운성 맵 생성
Map<String, TwelveUnsung> buildTwelveUnsungMap(String gan) {
  final result = <String, TwelveUnsung>{};
  for (final ji in jijiOrder) {
    result[ji] = calculateTwelveUnsung(gan, ji);
  }
  return result;
}

/// 특정 천간이 특정 운성을 갖는 지지들 조회
List<String> findJijiByUnsung(String gan, TwelveUnsung unsung) {
  final result = <String>[];
  for (final ji in jijiOrder) {
    if (calculateTwelveUnsung(gan, ji) == unsung) {
      result.add(ji);
    }
  }
  return result;
}

// ============================================================================
// 12운성 해석
// ============================================================================

/// 12운성별 상세 해석
const Map<TwelveUnsung, String> unsungInterpretation = {
  TwelveUnsung.jangSaeng: '새로운 시작, 창의적 에너지. 독립심이 강하고 새로운 일에 도전하는 기질.',
  TwelveUnsung.mokYok: '정화와 변화의 시기. 감정적이고 예술적 기질, 다소 불안정할 수 있음.',
  TwelveUnsung.gwanDae: '성장과 발전. 자신감이 넘치고 사회적 인정을 받는 시기.',
  TwelveUnsung.geonRok: '활발한 활동기. 실력을 발휘하고 재물을 모으는 시기.',
  TwelveUnsung.jeWang: '최고 전성기. 왕성한 에너지와 지도력, 다소 독선적일 수 있음.',
  TwelveUnsung.soe: '점진적 쇠퇴. 내면의 성숙, 경험을 바탕으로 한 지혜.',
  TwelveUnsung.byung: '기력 약화. 내향적이고 깊은 사색, 건강 관리 필요.',
  TwelveUnsung.sa: '기운의 정지. 완고함, 한 분야에 깊이 파고드는 집중력.',
  TwelveUnsung.myo: '잠재된 에너지. 재물 저장, 비밀스러운 능력, 고집.',
  TwelveUnsung.jeol: '단절과 전환. 기존 것의 종료, 새로운 시작을 위한 준비.',
  TwelveUnsung.tae: '잉태의 에너지. 새로운 가능성, 계획 단계.',
  TwelveUnsung.yang: '성장을 위한 준비. 양육과 보호, 점진적 발전.',
};

/// 12운성 해석 조회
String getUnsungInterpretation(TwelveUnsung unsung) {
  return unsungInterpretation[unsung] ?? '';
}
