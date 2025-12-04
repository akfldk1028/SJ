import '../../data/constants/sipsin_relations.dart';

/// 용신(用神) 엔티티
/// 사주에서 필요한 기운, 부족한 것을 보충하는 오행

/// 용신 선정 결과
class YongSinResult {
  /// 용신 오행
  final Oheng yongsin;

  /// 희신 오행 (용신을 생하는 오행)
  final Oheng heesin;

  /// 기신 오행 (용신을 극하는 오행)
  final Oheng gisin;

  /// 구신 오행 (용신을 설기하는 오행)
  final Oheng gusin;

  /// 한신 오행 (기신을 생하는 오행)
  final Oheng hansin;

  /// 선정 근거
  final String reason;

  /// 용신 선정 방식
  final YongSinMethod method;

  const YongSinResult({
    required this.yongsin,
    required this.heesin,
    required this.gisin,
    required this.gusin,
    required this.hansin,
    required this.reason,
    required this.method,
  });
}

/// 용신 선정 방식
enum YongSinMethod {
  /// 억부법 - 신강하면 설기, 신약하면 생조
  eokbu('억부법', '抑扶法'),

  /// 조후법 - 계절에 따른 한난조습 조절
  johu('조후법', '調候法'),

  /// 통관법 - 상극 관계를 소통시키는 오행
  tonggwan('통관법', '通關法'),

  /// 병약법 - 병(病)을 치료하는 약(藥)
  byeongYak('병약법', '病藥法');

  final String korean;
  final String hanja;

  const YongSinMethod(this.korean, this.hanja);
}

/// 오행 상생 관계 (용신 계산용)
/// A가 B를 생함
Oheng getGeneratingOheng(Oheng oheng) {
  switch (oheng) {
    case Oheng.mok:
      return Oheng.su; // 수생목
    case Oheng.hwa:
      return Oheng.mok; // 목생화
    case Oheng.to:
      return Oheng.hwa; // 화생토
    case Oheng.geum:
      return Oheng.to; // 토생금
    case Oheng.su:
      return Oheng.geum; // 금생수
  }
}

/// 오행 상극 관계 (용신 계산용)
/// A가 B를 극함
Oheng getOvercomingOheng(Oheng oheng) {
  switch (oheng) {
    case Oheng.mok:
      return Oheng.geum; // 금극목
    case Oheng.hwa:
      return Oheng.su; // 수극화
    case Oheng.to:
      return Oheng.mok; // 목극토
    case Oheng.geum:
      return Oheng.hwa; // 화극금
    case Oheng.su:
      return Oheng.to; // 토극수
  }
}

/// A를 설기하는 오행 (A가 생하는 오행)
Oheng getExhaustingOheng(Oheng oheng) {
  switch (oheng) {
    case Oheng.mok:
      return Oheng.hwa; // 목생화
    case Oheng.hwa:
      return Oheng.to; // 화생토
    case Oheng.to:
      return Oheng.geum; // 토생금
    case Oheng.geum:
      return Oheng.su; // 금생수
    case Oheng.su:
      return Oheng.mok; // 수생목
  }
}
