import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/saju_chart/domain/entities/saju_chart.dart';
import 'package:frontend/features/saju_chart/domain/entities/pillar.dart';
import 'package:frontend/features/saju_chart/domain/services/day_strength_service.dart';

void main() {
  group('DayStrengthService - 박재현 테스트케이스', () {
    late DayStrengthService service;

    setUp(() {
      service = DayStrengthService();
    });

    test('1997-11-29 08:03 부산 - 포스텔러 중화신강 기대', () {
      // 정축년 신해월 을해일 경진시
      final birthDateTime = DateTime(1997, 11, 29, 8, 3);
      final chart = SajuChart(
        yearPillar: const Pillar(gan: '정', ji: '축'),
        monthPillar: const Pillar(gan: '신', ji: '해'),
        dayPillar: const Pillar(gan: '을', ji: '해'),
        hourPillar: const Pillar(gan: '경', ji: '진'),
        birthDateTime: birthDateTime,
        correctedDateTime: birthDateTime,
        birthCity: '부산',
        isLunarCalendar: false,
      );

      final result = service.analyze(chart);

      print('\n=======================================');
      print('[신강/신약 분석 - 박재현]');
      print('일간: 을(乙) = 목(木)');
      print('---------------------------------------');
      print('득령: ${result.deukryeong} (월지 해의 정기 임수가 을목을 생함)');
      print('득지: ${result.deukji} (일지 해의 정기 임수가 을목을 생함)');
      print('득시: ${result.deuksi} (시지 진의 정기 무토 - 을목이 극함)');
      print('득세: ${result.deukse} (천간 비겁/인성 개수)');
      print('---------------------------------------');
      print('점수: ${result.score}');
      print('등급: ${result.level.korean} (${result.level.hanja})');
      print('---------------------------------------');
      print('비겁 수: ${result.details.bigeopCount}');
      print('인성 수: ${result.details.inseongCount}');
      print('재성 수: ${result.details.jaeseongCount}');
      print('관성 수: ${result.details.gwanseongCount}');
      print('식상 수: ${result.details.siksangCount}');
      print('=======================================\n');

      // 포스텔러 기준: 중화신강 (50-62점)
      expect(result.level.korean, '중화신강',
          reason: '포스텔러와 일치해야 함. 현재: ${result.level.korean}, 점수: ${result.score}');
    });
  });
}
