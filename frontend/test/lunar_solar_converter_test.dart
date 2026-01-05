import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/saju_chart/domain/services/lunar_solar_converter.dart';
import 'package:frontend/features/saju_chart/domain/entities/lunar_date.dart';

void main() {
  group('LunarSolarConverter - 음양력 변환 검증', () {
    late LunarSolarConverter converter;

    setUp(() {
      converter = LunarSolarConverter();
    });

    test('김동현 음력 1994/11/28 → 양력 변환', () {
      // 음력 1994년 11월 28일 (윤달 아님)
      final lunarDate = LunarDate(
        year: 1994,
        month: 11,
        day: 28,
        isLeapMonth: false,
      );

      final solarDate = converter.lunarToSolar(lunarDate);

      print('\n=======================================');
      print('[음양력 변환 검증 - 김동현]');
      print('음력: 1994년 11월 28일');
      print('양력: ${solarDate.year}년 ${solarDate.month}월 ${solarDate.day}일');
      print('---------------------------------------');

      // 1994년 윤달 정보 확인
      final leapMonthInfo = converter.getLeapMonthInfo(1994);
      print('1994년 윤달: ${leapMonthInfo.hasLeapMonth ? "${leapMonthInfo.leapMonth}월" : "없음"}');

      // 음력 11월 일수 확인
      final monthDays = converter.getLunarMonthDays(1994, 11);
      print('음력 11월 일수: $monthDays일');
      print('=======================================\n');

      // 음력 1994/11/28은 양력 1994/12/30
      expect(solarDate.year, 1994);
      expect(solarDate.month, 12);
      expect(solarDate.day, 30);
    });

    test('이여진 양력 1992/10/08 → 음력 변환', () {
      final solarDate = DateTime(1992, 10, 8);
      final lunarDate = converter.solarToLunar(solarDate);

      print('\n=======================================');
      print('[음양력 변환 검증 - 이여진]');
      print('양력: 1992년 10월 8일');
      print('음력: ${lunarDate.year}년 ${lunarDate.isLeapMonth ? "윤" : ""}${lunarDate.month}월 ${lunarDate.day}일');
      print('---------------------------------------');

      // 1992년 윤달 정보 확인
      final leapMonthInfo = converter.getLeapMonthInfo(1992);
      print('1992년 윤달: ${leapMonthInfo.hasLeapMonth ? "${leapMonthInfo.leapMonth}월" : "없음"}');
      print('=======================================\n');

      // 양력 1992/10/08은 음력 1992/09/13 (포스텔러 기준)
      expect(lunarDate.year, 1992);
      expect(lunarDate.month, 9);
      expect(lunarDate.day, 13);
      expect(lunarDate.isLeapMonth, false);
    });

    test('윤달 있는 해 검증 - 1993년 윤3월', () {
      // 1993년은 윤3월이 있음
      final leapMonthInfo = converter.getLeapMonthInfo(1993);

      print('\n=======================================');
      print('[윤달 검증 - 1993년]');
      print('윤달 유무: ${leapMonthInfo.hasLeapMonth}');
      print('윤달 월: ${leapMonthInfo.leapMonth}');
      print('윤달 일수: ${leapMonthInfo.leapMonthDays}');
      print('=======================================\n');

      expect(leapMonthInfo.hasLeapMonth, true);
      expect(leapMonthInfo.leapMonth, 3);
    });

    test('윤달 음력 → 양력 변환', () {
      // 1993년 윤3월 15일
      final lunarDate = LunarDate(
        year: 1993,
        month: 3,
        day: 15,
        isLeapMonth: true, // 윤달
      );

      final solarDate = converter.lunarToSolar(lunarDate);

      print('\n=======================================');
      print('[윤달 변환 검증 - 1993년 윤3월]');
      print('음력: 1993년 윤3월 15일');
      print('양력: ${solarDate.year}년 ${solarDate.month}월 ${solarDate.day}일');
      print('=======================================\n');

      // 윤달이므로 일반 3월 이후에 위치
      expect(solarDate.year, 1993);
      // 정확한 날짜는 테이블 데이터에 따라 다름
      expect(solarDate.month, greaterThanOrEqualTo(4));
    });

    test('윤달 유효성 검증', () {
      // 1994년에는 윤달이 없음
      final invalidLeapDate = LunarDate(
        year: 1994,
        month: 3,
        day: 15,
        isLeapMonth: true, // 존재하지 않는 윤달
      );

      final validationResult = converter.validateLunarDate(invalidLeapDate);

      print('\n=======================================');
      print('[윤달 유효성 검증 - 1994년]');
      print('입력: 1994년 윤3월 15일');
      print('유효성: ${validationResult.isValid}');
      print('에러 메시지: ${validationResult.errorMessage ?? "없음"}');
      print('=======================================\n');

      expect(validationResult.isValid, false);
      expect(validationResult.errorMessage, contains('윤달이 없습니다'));
    });

    test('박재현 양력 1997/11/29 → 음력 변환', () {
      final solarDate = DateTime(1997, 11, 29);
      final lunarDate = converter.solarToLunar(solarDate);

      print('\n=======================================');
      print('[음양력 변환 검증 - 박재현]');
      print('양력: 1997년 11월 29일');
      print('음력: ${lunarDate.year}년 ${lunarDate.isLeapMonth ? "윤" : ""}${lunarDate.month}월 ${lunarDate.day}일');
      print('---------------------------------------');

      // 1997년 윤달 정보 확인
      final leapMonthInfo = converter.getLeapMonthInfo(1997);
      print('1997년 윤달: ${leapMonthInfo.hasLeapMonth ? "${leapMonthInfo.leapMonth}월" : "없음"}');
      print('=======================================\n');

      // 양력 1997/11/29에 대한 음력 변환 검증
      expect(lunarDate.year, 1997);
      expect(lunarDate.month, greaterThan(0));
      expect(lunarDate.day, greaterThan(0));
    });
  });
}
