import '../entities/sinsal.dart';
import '../entities/saju_chart.dart';

/// 신살(神煞) 탐지 서비스
/// fortuneteller 로직 참고
///
/// ⚠️ 12신살 기준: 년지 + 일지 병행 사용 (포스텔러 동일 기준)
/// - 전통: 년지만 사용
/// - 현대: 일지만 사용
/// - 권장 (포스텔러): 년지 OR 일지 둘 중 하나라도 해당되면 인정
class SinSalService {
  /// 사주에서 신살 탐지
  List<SinSalResult> findSinSals(SajuChart chart) {
    final results = <SinSalResult>[];
    final dayMaster = chart.dayPillar.gan;
    final yearJi = chart.yearPillar.ji; // 년지 추가
    final dayJi = chart.dayPillar.ji;
    final jis = _getAllJis(chart);

    // 1. 천을귀인
    results.addAll(_findCheonEulGwiIn(dayMaster, jis));

    // 2. 도화살 (년지+일지 병행 기준)
    results.addAll(_findDoHwaSal(yearJi, dayJi, jis));

    // 3. 역마 (년지+일지 병행 기준)
    results.addAll(_findYeokMa(yearJi, dayJi, jis));

    // 4. 화개살 (년지+일지 병행 기준)
    results.addAll(_findHwaGaeSal(yearJi, dayJi, jis));

    // 5. 양인살
    results.addAll(_findYangInSal(dayMaster, jis));

    // 6. 공망
    results.addAll(_findGongMang(chart));

    // 7. 원진살
    results.addAll(_findWonJinSal(jis));

    // 8. 귀문관살
    results.addAll(_findGwiMunGwanSal(jis));

    return results;
  }

  /// 모든 지지 추출
  List<_JiWithLocation> _getAllJis(SajuChart chart) {
    return [
      _JiWithLocation(chart.yearPillar.ji, '년지'),
      _JiWithLocation(chart.monthPillar.ji, '월지'),
      _JiWithLocation(chart.dayPillar.ji, '일지'),
      if (chart.hourPillar != null)
        _JiWithLocation(chart.hourPillar!.ji, '시지'),
    ];
  }

  /// 천을귀인 탐지
  /// 일간별 천을귀인 지지
  List<SinSalResult> _findCheonEulGwiIn(
    String dayMaster,
    List<_JiWithLocation> jis,
  ) {
    final results = <SinSalResult>[];

    // 일간별 천을귀인 지지 테이블
    const table = {
      '갑': ['축', '미'],
      '을': ['자', '신'],
      '병': ['해', '유'],
      '정': ['해', '유'],
      '무': ['축', '미'],
      '기': ['자', '신'],
      '경': ['축', '미'],
      '신': ['인', '오'],
      '임': ['묘', '사'],
      '계': ['묘', '사'],
    };

    final gwiInJis = table[dayMaster] ?? [];

    for (final ji in jis) {
      if (gwiInJis.contains(ji.ji)) {
        results.add(SinSalResult(
          sinsal: SinSal.cheonEulGwiIn,
          location: ji.location,
          relatedJi: ji.ji,
          description: '${ji.location}에 천을귀인 - 귀인의 도움이 있음',
        ));
      }
    }

    return results;
  }

  /// 도화살 탐지
  /// ⚠️ 년지 + 일지 병행 기준 (포스텔러 동일)
  /// 년지 기준 도화살 OR 일지 기준 도화살 중 하나라도 해당되면 인정
  List<SinSalResult> _findDoHwaSal(
    String yearJi,
    String dayJi,
    List<_JiWithLocation> jis,
  ) {
    final results = <SinSalResult>[];

    // 삼합 기준 도화살
    const table = {
      '인': '묘',
      '오': '묘',
      '술': '묘', // 인오술 → 묘
      '사': '오',
      '유': '오',
      '축': '오', // 사유축 → 오
      '신': '유',
      '자': '유',
      '진': '유', // 신자진 → 유
      '해': '자',
      '묘': '자',
      '미': '자', // 해묘미 → 자
    };

    // 년지 기준 도화살과 일지 기준 도화살 모두 계산
    final yearDoHwaJi = table[yearJi];
    final dayDoHwaJi = table[dayJi];

    for (final ji in jis) {
      // 년지 기준 OR 일지 기준 중 하나라도 해당되면 인정
      final isYearBasis = yearDoHwaJi != null && ji.ji == yearDoHwaJi;
      final isDayBasis = dayDoHwaJi != null && ji.ji == dayDoHwaJi;

      if (isYearBasis || isDayBasis) {
        // 중복 방지
        final basisInfo = <String>[];
        if (isYearBasis) basisInfo.add('년지 기준');
        if (isDayBasis) basisInfo.add('일지 기준');

        results.add(SinSalResult(
          sinsal: SinSal.doHwaSal,
          location: ji.location,
          relatedJi: ji.ji,
          description: '${ji.location}에 도화살 (${basisInfo.join(', ')}) - 이성 매력이 강함',
        ));
      }
    }

    return results;
  }

  /// 역마 탐지
  /// ⚠️ 년지 + 일지 병행 기준 (포스텔러 동일)
  /// 년지 기준 역마 OR 일지 기준 역마 중 하나라도 해당되면 인정
  List<SinSalResult> _findYeokMa(
    String yearJi,
    String dayJi,
    List<_JiWithLocation> jis,
  ) {
    final results = <SinSalResult>[];

    // 삼합 기준 역마
    const table = {
      '인': '신',
      '오': '신',
      '술': '신', // 인오술 → 신
      '사': '해',
      '유': '해',
      '축': '해', // 사유축 → 해
      '신': '인',
      '자': '인',
      '진': '인', // 신자진 → 인
      '해': '사',
      '묘': '사',
      '미': '사', // 해묘미 → 사
    };

    // 년지 기준 역마와 일지 기준 역마 모두 계산
    final yearYeokMaJi = table[yearJi];
    final dayYeokMaJi = table[dayJi];

    for (final ji in jis) {
      // 년지 기준 OR 일지 기준 중 하나라도 해당되면 인정
      final isYearBasis = yearYeokMaJi != null && ji.ji == yearYeokMaJi;
      final isDayBasis = dayYeokMaJi != null && ji.ji == dayYeokMaJi;

      if (isYearBasis || isDayBasis) {
        final basisInfo = <String>[];
        if (isYearBasis) basisInfo.add('년지 기준');
        if (isDayBasis) basisInfo.add('일지 기준');

        results.add(SinSalResult(
          sinsal: SinSal.yeokMa,
          location: ji.location,
          relatedJi: ji.ji,
          description: '${ji.location}에 역마 (${basisInfo.join(', ')}) - 이동과 변화가 많음',
        ));
      }
    }

    return results;
  }

  /// 화개살 탐지
  /// ⚠️ 년지 + 일지 병행 기준 (포스텔러 동일)
  /// 년지 기준 화개살 OR 일지 기준 화개살 중 하나라도 해당되면 인정
  List<SinSalResult> _findHwaGaeSal(
    String yearJi,
    String dayJi,
    List<_JiWithLocation> jis,
  ) {
    final results = <SinSalResult>[];

    // 삼합 기준 화개
    const table = {
      '인': '술',
      '오': '술',
      '술': '술', // 인오술 → 술
      '사': '축',
      '유': '축',
      '축': '축', // 사유축 → 축
      '신': '진',
      '자': '진',
      '진': '진', // 신자진 → 진
      '해': '미',
      '묘': '미',
      '미': '미', // 해묘미 → 미
    };

    // 년지 기준 화개살과 일지 기준 화개살 모두 계산
    final yearHwaGaeJi = table[yearJi];
    final dayHwaGaeJi = table[dayJi];

    for (final ji in jis) {
      // 년지 기준 OR 일지 기준 중 하나라도 해당되면 인정
      final isYearBasis = yearHwaGaeJi != null && ji.ji == yearHwaGaeJi;
      final isDayBasis = dayHwaGaeJi != null && ji.ji == dayHwaGaeJi;

      if (isYearBasis || isDayBasis) {
        final basisInfo = <String>[];
        if (isYearBasis) basisInfo.add('년지 기준');
        if (isDayBasis) basisInfo.add('일지 기준');

        results.add(SinSalResult(
          sinsal: SinSal.hwaGaeSal,
          location: ji.location,
          relatedJi: ji.ji,
          description: '${ji.location}에 화개살 (${basisInfo.join(', ')}) - 예술성과 영성이 강함',
        ));
      }
    }

    return results;
  }

  /// 양인살 탐지
  List<SinSalResult> _findYangInSal(
    String dayMaster,
    List<_JiWithLocation> jis,
  ) {
    final results = <SinSalResult>[];

    // 일간별 양인 지지
    const table = {
      '갑': '묘',
      '을': '진', // 일설에는 없음
      '병': '오',
      '정': '미',
      '무': '오',
      '기': '미',
      '경': '유',
      '신': '술',
      '임': '자',
      '계': '축',
    };

    final yangInJi = table[dayMaster];
    if (yangInJi == null) return results;

    for (final ji in jis) {
      if (ji.ji == yangInJi) {
        results.add(SinSalResult(
          sinsal: SinSal.yangInSal,
          location: ji.location,
          relatedJi: ji.ji,
          description: '${ji.location}에 양인살 - 강한 추진력, 주의 필요',
        ));
      }
    }

    return results;
  }

  /// 공망 탐지
  List<SinSalResult> _findGongMang(SajuChart chart) {
    final results = <SinSalResult>[];

    // 일주 기준 공망 계산
    // 60갑자에서 일주의 순(旬)을 찾아 공망 지지 결정
    final dayGan = chart.dayPillar.gan;
    final dayJi = chart.dayPillar.ji;

    // 일간 인덱스
    const gans = ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'];
    const jis = ['자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해'];

    final ganIndex = gans.indexOf(dayGan);
    final jiIndex = jis.indexOf(dayJi);

    if (ganIndex < 0 || jiIndex < 0) return results;

    // 순(旬)의 시작 지지 인덱스 계산
    // 갑자순, 갑술순, 갑신순, 갑오순, 갑진순, 갑인순
    final sunStartJiIndex = (jiIndex - ganIndex + 12) % 12;

    // 공망은 순에서 10개 이후 2개
    // 예: 갑자순 → 술해 공망
    final gongMang1 = jis[(sunStartJiIndex + 10) % 12];
    final gongMang2 = jis[(sunStartJiIndex + 11) % 12];

    final allJis = [
      _JiWithLocation(chart.yearPillar.ji, '년지'),
      _JiWithLocation(chart.monthPillar.ji, '월지'),
      if (chart.hourPillar != null)
        _JiWithLocation(chart.hourPillar!.ji, '시지'),
    ];

    for (final ji in allJis) {
      if (ji.ji == gongMang1 || ji.ji == gongMang2) {
        results.add(SinSalResult(
          sinsal: SinSal.gongMang,
          location: ji.location,
          relatedJi: ji.ji,
          description: '${ji.location}에 공망 - 해당 궁이 약화됨',
        ));
      }
    }

    return results;
  }

  /// 원진살 탐지 (충 관계)
  List<SinSalResult> _findWonJinSal(List<_JiWithLocation> jis) {
    final results = <SinSalResult>[];

    // 원진살 조합 (6충)
    const chungPairs = [
      ['자', '오'],
      ['축', '미'],
      ['인', '신'],
      ['묘', '유'],
      ['진', '술'],
      ['사', '해'],
    ];

    final jiList = jis.map((j) => j.ji).toList();

    for (final pair in chungPairs) {
      if (jiList.contains(pair[0]) && jiList.contains(pair[1])) {
        results.add(SinSalResult(
          sinsal: SinSal.wonJinSal,
          location: '사주 전체',
          relatedJi: '${pair[0]}-${pair[1]}',
          description: '${pair[0]}${pair[1]} 충 - 대인 관계 마찰 주의',
        ));
      }
    }

    return results;
  }

  /// 귀문관살 탐지
  List<SinSalResult> _findGwiMunGwanSal(List<_JiWithLocation> jis) {
    final results = <SinSalResult>[];

    // 귀문관살: 인신사해 중 2개 이상
    const gwiMunJis = ['인', '신', '사', '해'];
    int count = 0;

    for (final ji in jis) {
      if (gwiMunJis.contains(ji.ji)) {
        count++;
      }
    }

    if (count >= 2) {
      results.add(SinSalResult(
        sinsal: SinSal.gwiMunGwanSal,
        location: '사주 전체',
        relatedJi: '인신사해 중 $count개',
        description: '귀문관살 - 영적 민감성, 신비 체험 가능',
      ));
    }

    return results;
  }
}

/// 지지와 위치 정보
class _JiWithLocation {
  final String ji;
  final String location;

  _JiWithLocation(this.ji, this.location);
}
