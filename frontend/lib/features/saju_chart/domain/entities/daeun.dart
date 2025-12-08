import '../entities/pillar.dart';

/// 대운(大運) 엔티티
/// 10년 단위로 변화하는 운의 흐름
class DaeUn {
  /// 대운 기둥 (천간 + 지지)
  final Pillar pillar;

  /// 대운 시작 나이
  final int startAge;

  /// 대운 종료 나이
  final int endAge;

  /// 대운 순서 (1번째, 2번째, ...)
  final int order;

  const DaeUn({
    required this.pillar,
    required this.startAge,
    required this.endAge,
    required this.order,
  });

  /// 대운 기간 문자열
  String get ageRange => '$startAge~$endAge세';
}

/// 대운 분석 결과
class DaeUnResult {
  /// 대운 시작 나이 (대운수)
  final int startAge;

  /// 순행/역행 여부
  final bool isForward;

  /// 대운 목록 (보통 8-10개)
  final List<DaeUn> daeUnList;

  /// 성별
  final Gender gender;

  /// 년간 음양
  final bool isYearGanYang;

  const DaeUnResult({
    required this.startAge,
    required this.isForward,
    required this.daeUnList,
    required this.gender,
    required this.isYearGanYang,
  });
}

/// 성별
enum Gender {
  male('남', '男'),
  female('여', '女');

  final String korean;
  final String hanja;

  const Gender(this.korean, this.hanja);
}

/// 세운(歲運) 엔티티
/// 1년 단위의 운
class SeUn {
  /// 세운 기둥 (천간 + 지지)
  final Pillar pillar;

  /// 해당 연도
  final int year;

  /// 나이
  final int age;

  const SeUn({
    required this.pillar,
    required this.year,
    required this.age,
  });
}

/// 월운(月運) 엔티티
/// 1개월 단위의 운
class WolUn {
  /// 월운 기둥
  final Pillar pillar;

  /// 해당 연도
  final int year;

  /// 해당 월 (음력 기준)
  final int month;

  const WolUn({
    required this.pillar,
    required this.year,
    required this.month,
  });
}
