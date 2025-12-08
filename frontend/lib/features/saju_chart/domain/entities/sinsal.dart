/// 신살(神煞) 엔티티
/// 사주에서 특정 조합으로 나타나는 길흉 요소
library;

/// 신살 종류
enum SinSal {
  // 길신 (Lucky)
  /// 천을귀인 - 가장 강력한 길신, 귀인의 도움
  cheonEulGwiIn('천을귀인', '天乙貴人', SinSalType.lucky),

  /// 천덕귀인 - 하늘의 덕을 받는 귀인
  cheonDeokGwiIn('천덕귀인', '天德貴人', SinSalType.lucky),

  /// 월덕귀인 - 달의 덕을 받는 귀인
  wolDeokGwiIn('월덕귀인', '月德貴人', SinSalType.lucky),

  /// 문창귀인 - 학문과 문서에 밝음
  munChangGwiIn('문창귀인', '文昌貴人', SinSalType.lucky),

  /// 금여록 - 재물운이 좋음
  geumYeoRok('금여록', '金輿祿', SinSalType.lucky),

  /// 학당귀인 - 학업 성취
  hakDangGwiIn('학당귀인', '學堂貴人', SinSalType.lucky),

  /// 역마 (길신으로도 봄) - 이동, 변화, 활동
  yeokMa('역마', '驛馬', SinSalType.neutral),

  // 흉신 (Unlucky)
  /// 양인살 - 폭력성, 사고 위험
  yangInSal('양인살', '羊刃殺', SinSalType.unlucky),

  /// 도화살 - 이성 관계 복잡
  doHwaSal('도화살', '桃花殺', SinSalType.unlucky),

  /// 백호살 - 혈광지사, 질병 위험
  baekHoSal('백호살', '白虎殺', SinSalType.unlucky),

  /// 화개살 - 예술성, 종교성, 고독
  hwaGaeSal('화개살', '華蓋殺', SinSalType.neutral),

  /// 원진살 - 대인 관계 불화
  wonJinSal('원진살', '怨嗔殺', SinSalType.unlucky),

  /// 귀문관살 - 귀신과 관련, 영적 민감
  gwiMunGwanSal('귀문관살', '鬼門關殺', SinSalType.unlucky),

  /// 공망 - 비어있음, 허무
  gongMang('공망', '空亡', SinSalType.unlucky);

  final String korean;
  final String hanja;
  final SinSalType type;

  const SinSal(this.korean, this.hanja, this.type);
}

/// 신살 유형
enum SinSalType {
  /// 길신 - 좋은 영향
  lucky('길신', '吉神'),

  /// 흉신 - 나쁜 영향
  unlucky('흉신', '凶神'),

  /// 중립 - 상황에 따라 다름
  neutral('중립', '中立');

  final String korean;
  final String hanja;

  const SinSalType(this.korean, this.hanja);
}

/// 신살 탐지 결과
class SinSalResult {
  /// 발견된 신살
  final SinSal sinsal;

  /// 해당 지지 위치 (년/월/일/시)
  final String location;

  /// 관련 지지
  final String relatedJi;

  /// 설명
  final String description;

  const SinSalResult({
    required this.sinsal,
    required this.location,
    required this.relatedJi,
    required this.description,
  });
}
