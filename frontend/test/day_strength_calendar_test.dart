import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/saju_chart/domain/entities/saju_chart.dart';
import 'package:frontend/features/saju_chart/domain/entities/pillar.dart';
import 'package:frontend/features/saju_chart/domain/services/day_strength_service.dart';

void main() {
  group('신강/신약 - 음력/양력/시간모름 영향 분석', () {
    late DayStrengthService service;

    setUp(() {
      service = DayStrengthService();
    });

    test('이여진 - 시간 있음 vs 시간 없음 비교', () {
      // 임신년 기유월 정사일 계묘시
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

      final withoutTime = SajuChart(
        yearPillar: const Pillar(gan: '임', ji: '신'),
        monthPillar: const Pillar(gan: '기', ji: '유'),
        dayPillar: const Pillar(gan: '정', ji: '사'),
        hourPillar: null, // 시간 모름
        birthDateTime: DateTime(1992, 10, 8),
        correctedDateTime: DateTime(1992, 10, 8),
        birthCity: '서울',
        isLunarCalendar: false,
      );

      final resultWithTime = service.analyze(withTime);
      final resultWithoutTime = service.analyze(withoutTime);

      print('\n=======================================');
      print('[시간 유무에 따른 신강/신약 비교 - 이여진]');
      print('---------------------------------------');
      print('시간 있음 (계묘시):');
      print('  - 점수: ${resultWithTime.score}점');
      print('  - 등급: ${resultWithTime.level.korean}');
      print('  - 득령: ${resultWithTime.deukryeong}, 득지: ${resultWithTime.deukji}');
      print('  - 득시: ${resultWithTime.deuksi}, 득세: ${resultWithTime.deukse}');
      print('---------------------------------------');
      print('시간 없음:');
      print('  - 점수: ${resultWithoutTime.score}점 (75점 만점 → 100점 환산)');
      print('  - 등급: ${resultWithoutTime.level.korean}');
      print('  - 득령: ${resultWithoutTime.deukryeong}, 득지: ${resultWithoutTime.deukji}');
      print('  - 득시: ${resultWithoutTime.deuksi} (N/A), 득세: ${resultWithoutTime.deukse}');
      print('=======================================\n');

      // 시간 있을 때: 일지(15) + 시지(15) = 30점 → 신약
      expect(resultWithTime.level.korean, '신약');

      // 시간 없을 때: 일지(15) / 75 * 100 = 20점 → 태약?
      // 또는 년지도 확인해야 함
    });

    test('김동현 - 시간 모름 케이스', () {
      // 갑술년 을해월 기축일 (시간 모름)
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
      print('[시간 모름 케이스 - 김동현]');
      print('사주: 갑술년 을해월 기축일 (시간 모름)');
      print('일간: 기(己) = 토(土)');
      print('---------------------------------------');
      print('75점 만점 기준 계산:');
      print('  - 년간 갑(甲) → 목 → 관성 → 0점');
      print('  - 월간 을(乙) → 목 → 관성 → 0점');
      print('  - 년지 술(戌) → 정기 무(戊) → 토 → 비겁 → 10점');
      print('  - 월지 해(亥) → 정기 임(壬) → 수 → 재성 → 0점');
      print('  - 일지 축(丑) → 정기 기(己) → 토 → 비겁 → 15점');
      print('  - 총: 25점 / 75점 = ${(25/75*100).round()}점');
      print('---------------------------------------');
      print('실제 결과:');
      print('  - 점수: ${result.score}점');
      print('  - 등급: ${result.level.korean}');
      print('=======================================\n');

      expect(result.score, 33); // 25/75*100 = 33.3 → 33점
      expect(result.level.korean, '신약');
    });

    test('동일 사주 - 음력 표시 vs 양력 표시 (사주 자체는 동일)', () {
      // 음력/양력은 입력 방식만 다르고, 사주팔자가 계산된 후에는 동일해야 함
      // 사주팔자가 같으면 신강/신약도 같아야 함

      // 이여진 사주 (양력 입력이든 음력 입력이든 사주가 같으면 결과 동일)
      final lunarInput = SajuChart(
        yearPillar: const Pillar(gan: '임', ji: '신'),
        monthPillar: const Pillar(gan: '기', ji: '유'),
        dayPillar: const Pillar(gan: '정', ji: '사'),
        hourPillar: const Pillar(gan: '계', ji: '묘'),
        birthDateTime: DateTime(1992, 10, 8, 5, 40),
        correctedDateTime: DateTime(1992, 10, 8, 5, 40),
        birthCity: '서울',
        isLunarCalendar: true, // 음력으로 표시
      );

      final solarInput = SajuChart(
        yearPillar: const Pillar(gan: '임', ji: '신'),
        monthPillar: const Pillar(gan: '기', ji: '유'),
        dayPillar: const Pillar(gan: '정', ji: '사'),
        hourPillar: const Pillar(gan: '계', ji: '묘'),
        birthDateTime: DateTime(1992, 10, 8, 5, 40),
        correctedDateTime: DateTime(1992, 10, 8, 5, 40),
        birthCity: '서울',
        isLunarCalendar: false, // 양력으로 표시
      );

      final lunarResult = service.analyze(lunarInput);
      final solarResult = service.analyze(solarInput);

      print('\n=======================================');
      print('[음력/양력 표시에 따른 신강/신약 비교]');
      print('---------------------------------------');
      print('핵심: 사주팔자(임신년 기유월 정사일 계묘시)가 같으면');
      print('      음력/양력 표시와 무관하게 결과 동일');
      print('---------------------------------------');
      print('음력 표시: ${lunarResult.score}점, ${lunarResult.level.korean}');
      print('양력 표시: ${solarResult.score}점, ${solarResult.level.korean}');
      print('=======================================\n');

      // 사주가 같으면 결과도 같아야 함
      expect(lunarResult.score, solarResult.score);
      expect(lunarResult.level, solarResult.level);
    });

    test('시간에 따른 점수 차이 시뮬레이션', () {
      // 같은 년월일이지만 시간이 다르면 시주가 달라짐
      final times = [
        ('자시', '갑', '자', 0),  // 23:30-01:30
        ('묘시', '계', '묘', 6),  // 05:30-07:30
        ('오시', '병', '오', 12), // 11:30-13:30
        ('유시', '기', '유', 18), // 17:30-19:30
      ];

      print('\n=======================================');
      print('[시간대별 신강/신약 시뮬레이션 - 이여진 기준]');
      print('년월일 고정: 임신년 기유월 정사일');
      print('일간: 정(丁) = 화(火)');
      print('---------------------------------------');

      for (final (name, hourGan, hourJi, hour) in times) {
        final chart = SajuChart(
          yearPillar: const Pillar(gan: '임', ji: '신'),
          monthPillar: const Pillar(gan: '기', ji: '유'),
          dayPillar: const Pillar(gan: '정', ji: '사'),
          hourPillar: Pillar(gan: hourGan, ji: hourJi),
          birthDateTime: DateTime(1992, 10, 8, hour, 30),
          correctedDateTime: DateTime(1992, 10, 8, hour, 30),
          birthCity: '서울',
          isLunarCalendar: false,
        );

        final result = service.analyze(chart);
        final hourJiOheng = _getJiOheng(hourJi);

        print('$name($hourGan$hourJi) - $hourJiOheng:');
        print('  점수: ${result.score}점, 등급: ${result.level.korean}');
        print('  득시: ${result.deuksi} (시지 정기가 화를 생하거나 같은 오행?)');
      }
      print('=======================================\n');
    });
  });
}

String _getJiOheng(String ji) {
  const map = {
    '자': '수', '축': '토', '인': '목', '묘': '목',
    '진': '토', '사': '화', '오': '화', '미': '토',
    '신': '금', '유': '금', '술': '토', '해': '수',
  };
  return map[ji] ?? '?';
}
