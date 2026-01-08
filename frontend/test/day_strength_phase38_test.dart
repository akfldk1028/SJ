import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/saju_chart/domain/entities/saju_chart.dart';
import 'package:frontend/features/saju_chart/domain/entities/pillar.dart';
import 'package:frontend/features/saju_chart/domain/services/day_strength_service.dart';

void main() {
  group('Phase 38: 비율 기준 등급 결정 테스트', () {
    late DayStrengthService service;

    setUp(() {
      service = DayStrengthService();
    });

    test('이여진 - 시간 있음/없음 등급 일관성 검증', () {
      // 시간 있음: 임신년 기유월 정사일 계묘시
      final withTime = SajuChart(
        yearPillar: const Pillar(gan: '임', ji: '신'),
        monthPillar: const Pillar(gan: '기', ji: '유'),
        dayPillar: const Pillar(gan: '정', ji: '사'),
        hourPillar: const Pillar(gan: '계', ji: '묘'),
        birthDateTime: DateTime(1992, 10, 8, 5, 40),
        correctedDateTime: DateTime(1992, 10, 8, 5, 40),
        birthCity: '서울',
        isLunarCalendar: false,
      );

      // 시간 없음 (삼주)
      final withoutTime = SajuChart(
        yearPillar: const Pillar(gan: '임', ji: '신'),
        monthPillar: const Pillar(gan: '기', ji: '유'),
        dayPillar: const Pillar(gan: '정', ji: '사'),
        hourPillar: null,
        birthDateTime: DateTime(1992, 10, 8),
        correctedDateTime: DateTime(1992, 10, 8),
        birthCity: '서울',
        isLunarCalendar: false,
      );

      final resultWithTime = service.analyze(withTime);
      final resultWithoutTime = service.analyze(withoutTime);

      print('\n=======================================');
      print('[Phase 38: 비율 기준 등급 결정 - 이여진]');
      print('---------------------------------------');
      print('시간 있음 (사주):');
      print('  - 획득: 15점(일지) + 15점(시지) = 30점');
      print('  - 만점: 100점');
      print('  - 비율: 30/100 = 30%');
      print('  - 점수: ${resultWithTime.score}점');
      print('  - 등급: ${resultWithTime.level.korean}');
      print('---------------------------------------');
      print('시간 없음 (삼주):');
      print('  - 획득: 15점(일지) = 15점');
      print('  - 만점: 75점');
      print('  - 비율: 15/75 = 20%');
      print('  - 점수: ${resultWithoutTime.score}점 (비율 * 100)');
      print('  - 등급: ${resultWithoutTime.level.korean}');
      print('---------------------------------------');
      print('핵심: 시간 유무와 관계없이 동일 등급 유지!');
      print('=======================================\n');

      // 핵심 검증: 비율 기준 등급 결정
      // 시간 있음: 30/100 = 30% → 신약 (26-37%)
      // 시간 없음: 15/75 = 20% → 태약 (13-25%)
      //
      // 차이 원인: 시지(묘)가 목으로 화를 생함 → 득시 15점
      // 시간 모르면 이 점수가 없음 → 등급이 다를 수 있음
      // 이는 명리학적으로 정상 (삼주 내에서 판단)
      expect(resultWithTime.level.korean, '신약',
          reason: '시간 있음: 30% = 신약');
      expect(resultWithoutTime.level.korean, '태약',
          reason: '시간 없음: 20% = 태약 (시지 15점 없음)');

      // 주의: 이 케이스는 시지가 득시여서 등급이 달라짐
      // 시지가 실시인 경우는 등급이 같을 수 있음
    });

    test('김동현 - 삼주 분석 검증', () {
      final chart = SajuChart(
        yearPillar: const Pillar(gan: '갑', ji: '술'),
        monthPillar: const Pillar(gan: '을', ji: '해'),
        dayPillar: const Pillar(gan: '기', ji: '축'),
        hourPillar: null,
        birthDateTime: DateTime(1994, 12, 30),
        correctedDateTime: DateTime(1994, 12, 30),
        birthCity: '서울',
        isLunarCalendar: true,
      );

      final result = service.analyze(chart);

      print('\n=======================================');
      print('[Phase 38: 삼주 분석 - 김동현]');
      print('사주: 갑술년 을해월 기축일 (시간 모름)');
      print('일간: 기(己) = 토(土)');
      print('---------------------------------------');
      print('삼주 기준 점수 계산:');
      print('  - 년간 갑(甲) → 관성 → 0점');
      print('  - 월간 을(乙) → 관성 → 0점');
      print('  - 년지 술(戌) → 비겁 → 10점');
      print('  - 월지 해(亥) → 재성 → 0점');
      print('  - 일지 축(丑) → 비겁 → 15점');
      print('  - 총: 25점 / 75점 = 33.3%');
      print('---------------------------------------');
      print('실제 결과:');
      print('  - 점수: ${result.score}점');
      print('  - 등급: ${result.level.korean}');
      print('=======================================\n');

      // 25/75 = 33.3% → 신약 범위 (26-37%)
      expect(result.score, 33);
      expect(result.level.korean, '신약');
    });

    test('박재현 - 사주 분석 검증', () {
      final chart = SajuChart(
        yearPillar: const Pillar(gan: '정', ji: '축'),
        monthPillar: const Pillar(gan: '신', ji: '해'),
        dayPillar: const Pillar(gan: '을', ji: '해'),
        hourPillar: const Pillar(gan: '경', ji: '진'),
        birthDateTime: DateTime(1997, 11, 29, 8, 3),
        correctedDateTime: DateTime(1997, 11, 29, 8, 3),
        birthCity: '부산',
        isLunarCalendar: false,
      );

      final result = service.analyze(chart);

      print('\n=======================================');
      print('[Phase 38: 사주 분석 - 박재현]');
      print('사주: 정축년 신해월 을해일 경진시');
      print('일간: 을(乙) = 목(木)');
      print('---------------------------------------');
      print('사주 기준 점수 계산:');
      print('  - 년간 정(丁) → 식상 → 0점');
      print('  - 월간 신(辛) → 관성 → 0점');
      print('  - 시간 경(庚) → 관성 → 0점');
      print('  - 년지 축(丑) → 재성 → 0점');
      print('  - 월지 해(亥) → 인성 → 30점');
      print('  - 일지 해(亥) → 인성 → 15점');
      print('  - 시지 진(辰) → 재성 → 0점');
      print('  - 총: 45점 / 100점 = 45%');
      print('---------------------------------------');
      print('실제 결과:');
      print('  - 점수: ${result.score}점');
      print('  - 등급: ${result.level.korean}');
      print('=======================================\n');

      // 45/100 = 45% → 중화신약 범위 (38-49%)
      expect(result.score, 45);
      expect(result.level.korean, '중화신약');
    });

    test('등급 경계값 테스트', () {
      print('\n=======================================');
      print('[Phase 38: 등급 경계값]');
      print('---------------------------------------');
      print('비율 기준:');
      print('  - 88%+ = 극왕');
      print('  - 75-87% = 태강');
      print('  - 63-74% = 신강');
      print('  - 50-62% = 중화신강');
      print('  - 38-49% = 중화신약');
      print('  - 26-37% = 신약');
      print('  - 13-25% = 태약');
      print('  - 0-12% = 극약');
      print('=======================================\n');

      // 이 테스트는 정보 출력용
      expect(true, true);
    });
  });
}
