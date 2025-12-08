import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/saju_chart/domain/services/saju_calculation_service.dart';
import 'package:frontend/features/saju_chart/domain/services/jasi_service.dart'; // JasiMode defined here

void main() {
  group('Saju Logic Verification', () {
    late SajuCalculationService service;

    setUp(() {
      service = SajuCalculationService();
    });

    test('Calculate Saju for 1990-02-15 09:30 (Seoul)', () async {
      final result = service.calculate(
        birthDateTime: DateTime(1990, 2, 15, 9, 30),
        birthCity: '서울',
        isLunarCalendar: false, // 양력
        isLeapMonth: false,
        jasiMode: JasiMode.yaJasi,
      );

      print('\n=======================================');
      print('[만세력 로직 검증 결과]');
      print('입력: 1990년 2월 15일 09시 30분 (양력), 서울');
      print('---------------------------------------');
      print('년주: ${result.yearPillar.fullName} (${result.yearPillar.ganOheng}/${result.yearPillar.jiOheng})');
      print('월주: ${result.monthPillar.fullName} (${result.monthPillar.ganOheng}/${result.monthPillar.jiOheng})');
      print('일주: ${result.dayPillar.fullName} (${result.dayPillar.ganOheng}/${result.dayPillar.jiOheng})');
      print('시주: ${result.hourPillar!.fullName} (${result.hourPillar!.ganOheng}/${result.hourPillar!.jiOheng})');
      print('=======================================\n');

      // 1990.2.15 09:30 (양력) - 포스텔러 검증 완료
      // 정답: 경오년 무인월 신해일 임진시
      expect(result.yearPillar.gan, '경');
      expect(result.yearPillar.ji, '오');
      expect(result.monthPillar.gan, '무');
      expect(result.monthPillar.ji, '인');
      expect(result.dayPillar.gan, '신');
      expect(result.dayPillar.ji, '해'); // 신해(辛亥) - 포스텔러 확인
      expect(result.hourPillar!.gan, '임');
      expect(result.hourPillar!.ji, '진'); // 임진시 - 포스텔러 확인
    });

    test('Calculate Saju for 1997-11-29 08:03 Busan (포스텔러 검증)', () async {
      final result = service.calculate(
        birthDateTime: DateTime(1997, 11, 29, 8, 3),
        birthCity: '부산',
        isLunarCalendar: false, // 양력
        isLeapMonth: false,
        jasiMode: JasiMode.yaJasi,
      );

      print('\n=======================================');
      print('[포스텔러 검증 - 1997/11/29 08:03 부산]');
      print('---------------------------------------');
      print('년주: ${result.yearPillar.fullName}');
      print('월주: ${result.monthPillar.fullName}');
      print('일주: ${result.dayPillar.fullName}');
      print('시주: ${result.hourPillar!.fullName}');
      print('=======================================\n');

      // 포스텔러 기준 정답: 정축년 신해월 을해일 경진시
      expect(result.yearPillar.gan, '정');
      expect(result.yearPillar.ji, '축');
      expect(result.monthPillar.gan, '신');
      expect(result.monthPillar.ji, '해');
      expect(result.dayPillar.gan, '을');
      expect(result.dayPillar.ji, '해');
      expect(result.hourPillar!.gan, '경');
      expect(result.hourPillar!.ji, '진');
    });
  });
}
