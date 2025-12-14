/// 지장간(地藏干) 분석 서비스
/// 지지 속에 숨은 천간을 분석하고 십성 계산
library;

import '../../data/constants/jijanggan_table.dart';
import '../../data/constants/sipsin_relations.dart';
import '../entities/saju_chart.dart';

// ============================================================================
// 지장간 분석 결과 모델
// ============================================================================

/// 지장간 천간의 십성 정보
class JiJangGanSipSin {
  /// 지장간 천간
  final String gan;

  /// 천간 한자
  final String ganHanja;

  /// 오행
  final String oheng;

  /// 기운 유형 (여기/중기/정기)
  final JiJangGanType type;

  /// 세력 (일수)
  final int strength;

  /// 일간 기준 십성
  final SipSin sipsin;

  const JiJangGanSipSin({
    required this.gan,
    required this.ganHanja,
    required this.oheng,
    required this.type,
    required this.strength,
    required this.sipsin,
  });

  @override
  String toString() => '$gan(${type.korean}): ${sipsin.korean}';
}

/// 단일 궁성의 지장간 분석 결과
class JiJangGanResult {
  /// 궁성 이름 (년주/월주/일주/시주)
  final String pillarName;

  /// 지지
  final String jiji;

  /// 지장간 목록 (여기, 중기, 정기 순)
  final List<JiJangGanSipSin> jijangganList;

  const JiJangGanResult({
    required this.pillarName,
    required this.jiji,
    required this.jijangganList,
  });

  /// 정기 (본기) 조회
  JiJangGanSipSin? get jeongGi {
    for (final jjg in jijangganList) {
      if (jjg.type == JiJangGanType.jeongGi) return jjg;
    }
    return null;
  }

  /// 중기 조회
  JiJangGanSipSin? get jungGi {
    for (final jjg in jijangganList) {
      if (jjg.type == JiJangGanType.jungGi) return jjg;
    }
    return null;
  }

  /// 여기 조회
  JiJangGanSipSin? get yeoGi {
    for (final jjg in jijangganList) {
      if (jjg.type == JiJangGanType.yeoGi) return jjg;
    }
    return null;
  }

  /// 지장간 문자열 (여기중기정기 순)
  String get jijangganString {
    final sorted = [...jijangganList]..sort((a, b) =>
        a.type.strengthRank.compareTo(b.type.strengthRank));
    return sorted.map((j) => j.gan).join();
  }

  /// 지장간 한자 문자열
  String get jijangganHanjaString {
    final sorted = [...jijangganList]..sort((a, b) =>
        a.type.strengthRank.compareTo(b.type.strengthRank));
    return sorted.map((j) => j.ganHanja).join();
  }

  @override
  String toString() => '$pillarName($jiji): $jijangganString';
}

/// 사주 전체 지장간 분석 결과
class JiJangGanAnalysisResult {
  /// 년주 지장간
  final JiJangGanResult yearResult;

  /// 월주 지장간
  final JiJangGanResult monthResult;

  /// 일주 지장간
  final JiJangGanResult dayResult;

  /// 시주 지장간 (시간 모를 경우 null)
  final JiJangGanResult? hourResult;

  /// 일간
  final String dayGan;

  const JiJangGanAnalysisResult({
    required this.yearResult,
    required this.monthResult,
    required this.dayResult,
    this.hourResult,
    required this.dayGan,
  });

  /// 모든 결과 리스트
  List<JiJangGanResult> get allResults => [
        yearResult,
        monthResult,
        dayResult,
        if (hourResult != null) hourResult!,
      ];

  /// 전체 지장간에서 특정 십성의 개수
  int countSipSin(SipSin sipsin) {
    int count = 0;
    for (final result in allResults) {
      count += result.jijangganList
          .where((jjg) => jjg.sipsin == sipsin)
          .length;
    }
    return count;
  }

  /// 전체 지장간에서 특정 카테고리의 개수
  int countCategory(SipSinCategory category) {
    int count = 0;
    for (final result in allResults) {
      count += result.jijangganList
          .where((jjg) => sipsinToCategory[jjg.sipsin] == category)
          .length;
    }
    return count;
  }

  /// 십성별 분포
  Map<SipSin, int> get sipsinDistribution {
    final dist = <SipSin, int>{};
    for (final sipsin in SipSin.values) {
      dist[sipsin] = countSipSin(sipsin);
    }
    return dist;
  }

  /// 카테고리별 분포
  Map<SipSinCategory, int> get categoryDistribution {
    final dist = <SipSinCategory, int>{};
    for (final cat in SipSinCategory.values) {
      dist[cat] = countCategory(cat);
    }
    return dist;
  }
}

// ============================================================================
// 지장간 분석 서비스
// ============================================================================

/// 지장간 분석 서비스
class JiJangGanService {
  /// 천간 한자 매핑
  static const Map<String, String> _ganHanja = {
    '갑': '甲', '을': '乙', '병': '丙', '정': '丁', '무': '戊',
    '기': '己', '경': '庚', '신': '辛', '임': '壬', '계': '癸',
  };

  /// 천간 오행 매핑
  static const Map<String, String> _ganOheng = {
    '갑': '목', '을': '목', '병': '화', '정': '화', '무': '토',
    '기': '토', '경': '금', '신': '금', '임': '수', '계': '수',
  };

  /// 사주 차트에서 지장간 분석
  static JiJangGanAnalysisResult analyzeFromChart(SajuChart chart) {
    final dayGan = chart.dayPillar.gan;

    return JiJangGanAnalysisResult(
      yearResult: _analyzeJiJangGan(dayGan, chart.yearPillar.ji, '년주'),
      monthResult: _analyzeJiJangGan(dayGan, chart.monthPillar.ji, '월주'),
      dayResult: _analyzeJiJangGan(dayGan, chart.dayPillar.ji, '일주'),
      hourResult: chart.hourPillar != null
          ? _analyzeJiJangGan(dayGan, chart.hourPillar!.ji, '시주')
          : null,
      dayGan: dayGan,
    );
  }

  /// 개별 파라미터로 지장간 분석
  static JiJangGanAnalysisResult analyze({
    required String dayGan,
    required String yearJi,
    required String monthJi,
    required String dayJi,
    String? hourJi,
  }) {
    return JiJangGanAnalysisResult(
      yearResult: _analyzeJiJangGan(dayGan, yearJi, '년주'),
      monthResult: _analyzeJiJangGan(dayGan, monthJi, '월주'),
      dayResult: _analyzeJiJangGan(dayGan, dayJi, '일주'),
      hourResult: hourJi != null
          ? _analyzeJiJangGan(dayGan, hourJi, '시주')
          : null,
      dayGan: dayGan,
    );
  }

  /// 단일 지지의 지장간 분석
  static JiJangGanResult _analyzeJiJangGan(
    String dayGan,
    String jiji,
    String pillarName,
  ) {
    final jijangganList = <JiJangGanSipSin>[];
    final rawList = getJiJangGan(jiji);

    for (final jjg in rawList) {
      final sipsin = calculateSipSin(dayGan, jjg.gan);
      jijangganList.add(JiJangGanSipSin(
        gan: jjg.gan,
        ganHanja: _ganHanja[jjg.gan] ?? '',
        oheng: _ganOheng[jjg.gan] ?? '',
        type: jjg.type,
        strength: jjg.strength,
        sipsin: sipsin,
      ));
    }

    return JiJangGanResult(
      pillarName: pillarName,
      jiji: jiji,
      jijangganList: jijangganList,
    );
  }

  /// 단일 지지의 지장간 조회 (간단 버전)
  static List<String> getJiJangGanList(String jiji) {
    return getJiJangGan(jiji).map((j) => j.gan).toList();
  }

  /// 지지의 정기(본기) 조회
  static String? getMainGan(String jiji) {
    return getJeongGi(jiji);
  }

  /// 지지의 지장간 문자열 (여기중기정기 순)
  static String getJiJangGanString(String jiji) {
    final list = getJiJangGan(jiji);
    final sorted = [...list]..sort((a, b) =>
        a.type == JiJangGanType.yeoGi ? -1 :
        b.type == JiJangGanType.yeoGi ? 1 :
        a.type == JiJangGanType.jungGi ? -1 : 1);
    return sorted.map((j) => j.gan).join();
  }

  /// 지장간 십성 분석 (특정 지지)
  static List<JiJangGanSipSin> analyzeJiJangGanSipSin(
    String dayGan,
    String jiji,
  ) {
    final result = <JiJangGanSipSin>[];
    final rawList = getJiJangGan(jiji);

    for (final jjg in rawList) {
      final sipsin = calculateSipSin(dayGan, jjg.gan);
      result.add(JiJangGanSipSin(
        gan: jjg.gan,
        ganHanja: _ganHanja[jjg.gan] ?? '',
        oheng: _ganOheng[jjg.gan] ?? '',
        type: jjg.type,
        strength: jjg.strength,
        sipsin: sipsin,
      ));
    }

    return result;
  }

  /// 지장간에서 특정 십성 찾기
  static JiJangGanSipSin? findSipSinInJiJangGan(
    String dayGan,
    String jiji,
    SipSin targetSipsin,
  ) {
    final list = analyzeJiJangGanSipSin(dayGan, jiji);
    for (final jjg in list) {
      if (jjg.sipsin == targetSipsin) return jjg;
    }
    return null;
  }

  /// 십성 분포 분석 요약
  static String getSipSinSummary(JiJangGanAnalysisResult result) {
    final catDist = result.categoryDistribution;
    final parts = <String>[];

    for (final entry in catDist.entries) {
      if (entry.value > 0) {
        parts.add('${entry.key.korean} ${entry.value}개');
      }
    }

    return parts.join(', ');
  }

  /// 십성별 상세 해석
  static String getSipSinInterpretation(SipSin sipsin) {
    return switch (sipsin) {
      SipSin.bigyeon => '비견: 나와 같은 기운. 독립심, 자존심, 경쟁심이 강함. '
          '형제, 친구, 동료를 의미.',
      SipSin.geopjae => '겁재: 재물을 빼앗는 기운. 적극적이고 승부욕이 강함. '
          '과감한 투자, 도박적 성향 주의.',
      SipSin.siksin => '식신: 먹을 것을 생산하는 기운. 온화하고 여유로움. '
          '의식주, 건강, 수명을 담당.',
      SipSin.sanggwan => '상관: 관을 상하게 하는 기운. 재능이 넘치고 말 잘함. '
          '자유로우나 권위에 반발.',
      SipSin.pyeonjae => '편재: 큰 재물의 기운. 사업 수완, 투자 능력. '
          '아버지, 첩, 투기적 재물.',
      SipSin.jeongjae => '정재: 정당한 재물의 기운. 성실하게 모은 재산. '
          '아내, 정직한 수입, 알뜰함.',
      SipSin.pyeongwan => '편관(칠살): 강한 통제의 기운. 권력, 무관, 돌발상황. '
          '적극적이나 갈등 많음.',
      SipSin.jeonggwan => '정관: 정당한 명예의 기운. 사회적 지위, 직장. '
          '책임감, 도덕성, 남편.',
      SipSin.pyeonin => '편인: 특별한 학문의 기운. 비정통 학문, 종교, 의술. '
          '의붓어머니, 편벽된 사고.',
      SipSin.jeongin => '정인: 정당한 문서의 기운. 학업, 자격증, 어머니. '
          '보호받음, 인자함, 지식.',
    };
  }
}
