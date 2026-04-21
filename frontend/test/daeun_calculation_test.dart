import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/saju_chart/domain/services/daeun_service.dart';
import 'package:frontend/features/saju_chart/domain/services/saju_calculation_service.dart';
import 'package:frontend/features/saju_chart/domain/services/saju_analysis_service.dart';
import 'package:frontend/features/saju_chart/domain/entities/daeun.dart';
import 'package:frontend/features/saju_chart/domain/entities/pillar.dart';
import 'package:frontend/features/saju_chart/domain/entities/saju_chart.dart';
import 'package:frontend/features/saju_chart/data/constants/solar_term_calculator.dart';

void main() {
  late DaeUnService daeunService;
  late SajuCalculationService calcService;

  setUp(() {
    daeunService = DaeUnService();
    calcService = SajuCalculationService();
  });

  group('SolarTermCalculator 절기 날짜 검증', () {
    test('1967년 경칩 = 3월 6일 (베베얌 기준: 3/6 15:42)', () {
      final terms = SolarTermCalculator.calculateYearTerms(1967);
      final gyeongchip = terms['gyeongchip']!;
      print('1967 경칩: ${gyeongchip.month}/${gyeongchip.day} ${gyeongchip.hour}:${gyeongchip.minute.toString().padLeft(2, '0')}');
      expect(gyeongchip.month, 3);
      expect(gyeongchip.day, 6); // 베베얌: 3/6 15:42
    });

    test('1967년 입춘 = 2월 4일 (베베얌 기준: 2/4 21:31)', () {
      final terms = SolarTermCalculator.calculateYearTerms(1967);
      final ipchun = terms['ipchun']!;
      print('1967 입춘: ${ipchun.month}/${ipchun.day} ${ipchun.hour}:${ipchun.minute.toString().padLeft(2, '0')}');
      expect(ipchun.month, 2);
      expect(ipchun.day, 4);
    });

    test('1994년 대설 = 12월 7일 (베베얌 기준: 12/7 17:23)', () {
      final terms = SolarTermCalculator.calculateYearTerms(1994);
      final daeseol = terms['daeseol']!;
      print('1994 대설: ${daeseol.month}/${daeseol.day} ${daeseol.hour}:${daeseol.minute.toString().padLeft(2, '0')}');
      expect(daeseol.month, 12);
      expect(daeseol.day, 7);
    });

    test('1994년 소한(1995년) = 1월 6일경', () {
      final terms = SolarTermCalculator.calculateYearTerms(1995);
      final sohan = terms['sohan']!;
      print('1995 소한: ${sohan.month}/${sohan.day} ${sohan.hour}:${sohan.minute.toString().padLeft(2, '0')}');
      expect(sohan.month, 1);
      expect(sohan.day, inInclusiveRange(5, 6));
    });

    test('여러 연도 절기 날짜가 합리적 범위인지 검증', () {
      // 절입 절기별 합리적 양력 날짜 범위
      final expectedRanges = {
        'ipchun': [2, 3, 5],     // 입춘: 2/3~5
        'gyeongchip': [3, 5, 7], // 경칩: 3/5~7
        'cheongmyeong': [4, 4, 6], // 청명: 4/4~6
        'ipha': [5, 5, 7],      // 입하: 5/5~7
        'mangjong': [6, 5, 7],   // 망종: 6/5~7
        'soseo': [7, 6, 8],     // 소서: 7/6~8
        'ipchu': [8, 7, 9],     // 입추: 8/7~9
        'baekro': [9, 7, 9],    // 백로: 9/7~9
        'hanro': [10, 7, 10],   // 한로: 10/7~10
        'ipdong': [11, 7, 9],   // 입동: 11/7~9
        'daeseol': [12, 6, 8],  // 대설: 12/6~8
        'sohan': [1, 5, 7],     // 소한: 1/5~7
      };

      for (int year = 1950; year <= 2020; year += 10) {
        final terms = SolarTermCalculator.calculateYearTerms(year);
        for (final entry in expectedRanges.entries) {
          final term = terms[entry.key]!;
          final expectedMonth = entry.value[0];
          final minDay = entry.value[1];
          final maxDay = entry.value[2];

          // 소한은 다음 해에 속할 수 있음
          if (entry.key == 'sohan' && term.month == 1) {
            // OK
          } else {
            expect(term.month, expectedMonth,
                reason: '${year}년 ${entry.key}: 월이 $expectedMonth여야 하는데 ${term.month}');
          }
          expect(term.day, inInclusiveRange(minDay, maxDay),
              reason: '${year}년 ${entry.key}: 일이 $minDay~$maxDay여야 하는데 ${term.day}');
        }
      }
      print('1950~2020 모든 절기 날짜 범위 검증 통과');
    });
  });

  group('대운수 계산 버그 수정 검증', () {
    test('[핵심] 음력 1967-01-09 여성 → correctedDateTime 사용 시 대운수 6', () {
      // 음력 1967-01-09 → 양력 1967-02-17
      // 정(丁)미(未)년, 여성 → 음녀 → 순행
      // 다음 절입일: 경칩 3/6 → 약 17일 → 17/3 = 5.67 → 6

      final chart = calcService.calculate(
        birthDateTime: DateTime(1967, 1, 9, 10, 10), // 음력 날짜
        birthCity: '대구광역시',
        isLunarCalendar: true,
      );

      print('입력: 음력 1967-01-09 10:10');
      print('birthDateTime: ${chart.birthDateTime}');
      print('correctedDateTime: ${chart.correctedDateTime}');
      print('사주: ${chart.fullSaju}');

      // 양력 변환 확인
      expect(chart.correctedDateTime.month, 2,
          reason: '양력 변환 후 2월이어야 함');

      // 버그 재현: birthDateTime(음력) 사용 시
      final bugResult = daeunService.calculate(
        chart: chart,
        gender: Gender.female,
        birthDateTime: chart.birthDateTime, // 음력 1월 9일
      );
      print('\n[BUG] birthDateTime 사용: 대운수 ${bugResult.startAge}, 순행: ${bugResult.isForward}');

      // 수정: correctedDateTime(양력) 사용 시
      final fixedResult = daeunService.calculate(
        chart: chart,
        gender: Gender.female,
        birthDateTime: chart.correctedDateTime, // 양력 2월 17일
      );
      print('[FIX] correctedDateTime 사용: 대운수 ${fixedResult.startAge}, 순행: ${fixedResult.isForward}');

      // 순행 확인 (정丁=음간, 여성=음녀=순행)
      expect(fixedResult.isForward, true, reason: '음녀 순행');
      // 대운수 6 확인
      expect(fixedResult.startAge, 6, reason: '포스텔러 기준 대운수 6');
      // 버그 결과는 9 (음력 날짜로 잘못 계산)
      expect(bugResult.startAge, 9, reason: '버그: 음력 날짜 사용 시 9');
    });

    test('양력 입력은 수정 전후 동일해야 함', () {
      // 양력 2006-07-20 → 음력 변환 없으므로 birthDateTime == correctedDateTime (시간보정 제외)
      final chart = calcService.calculate(
        birthDateTime: DateTime(2006, 7, 20, 14, 30),
        birthCity: '서울특별시',
        isLunarCalendar: false,
      );

      print('\n입력: 양력 2006-07-20 14:30');
      print('birthDateTime: ${chart.birthDateTime}');
      print('correctedDateTime: ${chart.correctedDateTime}');
      print('사주: ${chart.fullSaju}');

      // 남자 순행 (병丙=양간, 양남=순행)
      final maleResult = daeunService.calculate(
        chart: chart,
        gender: Gender.male,
        birthDateTime: chart.correctedDateTime,
      );
      print('\n남자 대운수: ${maleResult.startAge}, 순행: ${maleResult.isForward}');
      expect(maleResult.isForward, true, reason: '양남 순행');
      // 동우학당 예제: 7/20→입추 8/8 = 19일, 19/3=6
      expect(maleResult.startAge, inInclusiveRange(5, 7),
          reason: '동우학당 기준 대운수 약 6');

      // 여자 역행 (병丙=양간, 양녀=역행)
      final femaleResult = daeunService.calculate(
        chart: chart,
        gender: Gender.female,
        birthDateTime: chart.correctedDateTime,
      );
      print('여자 대운수: ${femaleResult.startAge}, 순행: ${femaleResult.isForward}');
      expect(femaleResult.isForward, false, reason: '양녀 역행');
      // 동우학당 예제: 7/20→소서 7/7 = 13일, 13/3=4
      expect(femaleResult.startAge, inInclusiveRange(3, 5),
          reason: '동우학당 기준 대운수 약 4');
    });

    test('음력 1994-11-28 오전 9:20 대운수 검증', () {
      final chart = calcService.calculate(
        birthDateTime: DateTime(1994, 11, 28, 9, 20), // 음력
        birthCity: '서울특별시',
        isLunarCalendar: true,
      );

      print('\n입력: 음력 1994-11-28 09:20');
      print('birthDateTime (원본): ${chart.birthDateTime}');
      print('correctedDateTime (양력): ${chart.correctedDateTime}');
      print('사주: ${chart.fullSaju}');

      // 양력 변환 확인: 음력 1994-11-28 → 양력 1994-12-30
      expect(chart.correctedDateTime.year, inInclusiveRange(1994, 1995));
      expect(chart.correctedDateTime.month, greaterThanOrEqualTo(12));

      // 남자 대운수
      final maleResult = daeunService.calculate(
        chart: chart,
        gender: Gender.male,
        birthDateTime: chart.correctedDateTime,
      );
      print('\n남자 대운수: ${maleResult.startAge}, 순행: ${maleResult.isForward}');

      // 여자 대운수
      final femaleResult = daeunService.calculate(
        chart: chart,
        gender: Gender.female,
        birthDateTime: chart.correctedDateTime,
      );
      print('여자 대운수: ${femaleResult.startAge}, 순행: ${femaleResult.isForward}');

      // 버그 비교
      final bugMale = daeunService.calculate(
        chart: chart,
        gender: Gender.male,
        birthDateTime: chart.birthDateTime, // 음력 날짜
      );
      final bugFemale = daeunService.calculate(
        chart: chart,
        gender: Gender.female,
        birthDateTime: chart.birthDateTime,
      );
      print('\n[BUG비교] 음력날짜 남자: ${bugMale.startAge}, 여자: ${bugFemale.startAge}');
      print('[FIX비교] 양력날짜 남자: ${maleResult.startAge}, 여자: ${femaleResult.startAge}');

      if (bugMale.startAge != maleResult.startAge) {
        print('⚠️ 남자 대운수 차이 발견: ${bugMale.startAge} → ${maleResult.startAge}');
      }
      if (bugFemale.startAge != femaleResult.startAge) {
        print('⚠️ 여자 대운수 차이 발견: ${bugFemale.startAge} → ${femaleResult.startAge}');
      }
    });
  });

  group('대운 간지 순서 검증', () {
    test('순행 시 월주에서 +1씩 증가', () {
      // 월주: 임(壬)인(寅) → 순행: 계묘, 갑진, 을사...
      final chart = SajuChart(
        yearPillar: const Pillar(gan: '정', ji: '미'),
        monthPillar: const Pillar(gan: '임', ji: '인'),
        dayPillar: const Pillar(gan: '임', ji: '자'),
        hourPillar: const Pillar(gan: '을', ji: '사'),
        birthDateTime: DateTime(1967, 2, 17),
        correctedDateTime: DateTime(1967, 2, 17),
        birthCity: '대구',
        isLunarCalendar: false,
      );

      final result = daeunService.calculate(
        chart: chart,
        gender: Gender.female,
        birthDateTime: chart.correctedDateTime,
      );

      print('\n순행 대운 간지 순서:');
      for (final daeun in result.daeUnList) {
        print('  ${daeun.order}번째: ${daeun.pillar.gan}${daeun.pillar.ji} (${daeun.startAge}~${daeun.endAge}세)');
      }

      // 첫 대운: 계묘
      expect(result.daeUnList[0].pillar.gan, '계');
      expect(result.daeUnList[0].pillar.ji, '묘');
      // 둘째: 갑진
      expect(result.daeUnList[1].pillar.gan, '갑');
      expect(result.daeUnList[1].pillar.ji, '진');
    });

    test('역행 시 월주에서 -1씩 감소', () {
      // 월주: 임(壬)인(寅) → 역행: 신축, 경자, 기해...
      final chart = SajuChart(
        yearPillar: const Pillar(gan: '정', ji: '미'),
        monthPillar: const Pillar(gan: '임', ji: '인'),
        dayPillar: const Pillar(gan: '임', ji: '자'),
        hourPillar: const Pillar(gan: '을', ji: '사'),
        birthDateTime: DateTime(1967, 2, 17),
        correctedDateTime: DateTime(1967, 2, 17),
        birthCity: '대구',
        isLunarCalendar: false,
      );

      final result = daeunService.calculate(
        chart: chart,
        gender: Gender.male, // 음남 → 역행
        birthDateTime: chart.correctedDateTime,
      );

      print('\n역행 대운 간지 순서:');
      for (final daeun in result.daeUnList) {
        print('  ${daeun.order}번째: ${daeun.pillar.gan}${daeun.pillar.ji} (${daeun.startAge}~${daeun.endAge}세)');
      }

      // 첫 대운: 신축
      expect(result.daeUnList[0].pillar.gan, '신');
      expect(result.daeUnList[0].pillar.ji, '축');
      // 둘째: 경자
      expect(result.daeUnList[1].pillar.gan, '경');
      expect(result.daeUnList[1].pillar.ji, '자');
    });
  });

  group('SajuAnalysisService 통합 검증 (수정 반영)', () {
    test('analyze()에서 correctedDateTime 사용 확인', () {
      final chart = calcService.calculate(
        birthDateTime: DateTime(1967, 1, 9, 10, 10),
        birthCity: '대구광역시',
        isLunarCalendar: true,
      );

      final analysisService = SajuAnalysisService();
      final analysis = analysisService.analyze(
        chart: chart,
        gender: Gender.female,
        currentYear: 2026,
      );

      print('\n[통합 테스트] 음력 1967-01-09 여성');
      print('대운수: ${analysis.daeun?.startAge}');
      print('순행: ${analysis.daeun?.isForward}');
      print('대운 목록:');
      for (final d in analysis.daeun?.daeUnList ?? []) {
        print('  ${d.order}: ${d.pillar.gan}${d.pillar.ji} (${d.startAge}~${d.endAge}세)');
      }

      // 수정 후 대운수 6 확인
      expect(analysis.daeun?.startAge, 6,
          reason: 'SajuAnalysisService가 correctedDateTime을 사용해야 함');
      expect(analysis.daeun?.isForward, true);

      // 대운 시작 나이 연속성 확인
      expect(analysis.daeun?.daeUnList[0].startAge, 6);
      expect(analysis.daeun?.daeUnList[1].startAge, 16);
      expect(analysis.daeun?.daeUnList[2].startAge, 26);
    });
  });
}
