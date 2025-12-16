import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/saju_chart/domain/services/lunar_solar_converter.dart';
import 'package:frontend/features/saju_chart/domain/entities/lunar_date.dart';

void main() {
  group('LunarSolarConverter Tests', () {
    late LunarSolarConverter converter;

    setUp(() {
      converter = LunarSolarConverter();
    });

    group('양력 → 음력 변환 (solarToLunar)', () {
      test('2024년 설날 (양력 2024-02-10 → 음력 2024-01-01)', () {
        final result = converter.solarToLunar(DateTime(2024, 2, 10));

        print('\n===================================');
        print('[양력→음력 변환] 2024-02-10');
        print('결과: ${result.year}년 ${result.month}월 ${result.day}일 ${result.isLeapMonth ? "(윤달)" : ""}');
        print('===================================\n');

        expect(result.year, 2024);
        expect(result.month, 1);
        expect(result.day, 1);
        expect(result.isLeapMonth, false);
      });

      test('2023년 추석 (양력 2023-09-29 → 음력 2023-08-15)', () {
        final result = converter.solarToLunar(DateTime(2023, 9, 29));

        print('\n===================================');
        print('[양력→음력 변환] 2023-09-29 (추석)');
        print('결과: ${result.year}년 ${result.month}월 ${result.day}일');
        print('===================================\n');

        expect(result.year, 2023);
        expect(result.month, 8);
        expect(result.day, 15);
      });

      test('1990년 2월 15일 양력 → 음력 변환', () {
        final result = converter.solarToLunar(DateTime(1990, 2, 15));

        print('\n===================================');
        print('[양력→음력 변환] 1990-02-15');
        print('결과: ${result.year}년 ${result.month}월 ${result.day}일 ${result.isLeapMonth ? "(윤달)" : ""}');
        print('===================================\n');

        // 1990년 2월 15일 양력 = 음력 1990년 1월 20일
        expect(result.year, 1990);
        expect(result.month, 1);
        expect(result.day, 20);
      });

      test('연초 경계 - 양력 2023-01-15 (음력 전년도)', () {
        final result = converter.solarToLunar(DateTime(2023, 1, 15));

        print('\n===================================');
        print('[양력→음력 변환] 2023-01-15 (연초)');
        print('결과: ${result.year}년 ${result.month}월 ${result.day}일');
        print('===================================\n');

        // 2023년 1월 15일 양력 = 음력 2022년 12월 25일 (실제 계산 결과)
        expect(result.year, 2022);
        expect(result.month, 12);
        expect(result.day, 25);
      });
    });

    group('음력 → 양력 변환 (lunarToSolar)', () {
      test('음력 2024-01-01 → 양력 2024-02-10 (설날)', () {
        final lunarDate = LunarDate(
          year: 2024,
          month: 1,
          day: 1,
          isLeapMonth: false,
        );
        final result = converter.lunarToSolar(lunarDate);

        print('\n===================================');
        print('[음력→양력 변환] 2024-01-01 (음력 설날)');
        print('결과: ${result.year}년 ${result.month}월 ${result.day}일');
        print('===================================\n');

        expect(result.year, 2024);
        expect(result.month, 2);
        expect(result.day, 10);
      });

      test('음력 2023-08-15 → 양력 2023-09-29 (추석)', () {
        final lunarDate = LunarDate(
          year: 2023,
          month: 8,
          day: 15,
          isLeapMonth: false,
        );
        final result = converter.lunarToSolar(lunarDate);

        print('\n===================================');
        print('[음력→양력 변환] 2023-08-15 (추석)');
        print('결과: ${result.year}년 ${result.month}월 ${result.day}일');
        print('===================================\n');

        expect(result.year, 2023);
        expect(result.month, 9);
        expect(result.day, 29);
      });

      test('음력 1990-01-20 → 양력 1990-02-15', () {
        final lunarDate = LunarDate(
          year: 1990,
          month: 1,
          day: 20,
          isLeapMonth: false,
        );
        final result = converter.lunarToSolar(lunarDate);

        print('\n===================================');
        print('[음력→양력 변환] 1990-01-20');
        print('결과: ${result.year}년 ${result.month}월 ${result.day}일');
        print('===================================\n');

        expect(result.year, 1990);
        expect(result.month, 2);
        expect(result.day, 15);
      });
    });

    group('왕복 변환 테스트 (양력→음력→양력)', () {
      test('2024-03-15 왕복 변환', () {
        final original = DateTime(2024, 3, 15);
        final lunar = converter.solarToLunar(original);
        final back = converter.lunarToSolar(lunar);

        print('\n===================================');
        print('[왕복 변환] 양력 2024-03-15');
        print('→ 음력: ${lunar.year}-${lunar.month}-${lunar.day}');
        print('→ 양력: ${back.year}-${back.month}-${back.day}');
        print('===================================\n');

        expect(back.year, original.year);
        expect(back.month, original.month);
        expect(back.day, original.day);
      });

      test('1997-11-29 왕복 변환 (테스트 케이스)', () {
        final original = DateTime(1997, 11, 29);
        final lunar = converter.solarToLunar(original);
        final back = converter.lunarToSolar(lunar);

        print('\n===================================');
        print('[왕복 변환] 양력 1997-11-29');
        print('→ 음력: ${lunar.year}-${lunar.month}-${lunar.day}');
        print('→ 양력: ${back.year}-${back.month}-${back.day}');
        print('===================================\n');

        expect(back.year, original.year);
        expect(back.month, original.month);
        expect(back.day, original.day);
      });
    });

    group('윤달 테스트', () {
      test('2023년 윤달 확인 (윤2월)', () {
        final hasLeap = converter.hasLeapMonth(2023);
        final leapMonth = converter.getLeapMonth(2023);

        print('\n===================================');
        print('[윤달 확인] 2023년');
        print('윤달 여부: $hasLeap, 윤달 월: ${leapMonth == 0 ? "없음" : "${leapMonth}월"}');
        print('===================================\n');

        expect(hasLeap, true);
        expect(leapMonth, 2); // 2023년은 윤2월
      });

      test('2024년 윤달 확인 (없음)', () {
        final hasLeap = converter.hasLeapMonth(2024);

        print('\n===================================');
        print('[윤달 확인] 2024년');
        print('윤달 여부: $hasLeap');
        print('===================================\n');

        expect(hasLeap, false);
      });
    });

    group('지원 범위 테스트', () {
      test('1900년 지원 확인', () {
        expect(() => converter.solarToLunar(DateTime(1900, 6, 1)), returnsNormally);
      });

      test('2100년 지원 확인', () {
        expect(() => converter.solarToLunar(DateTime(2100, 6, 1)), returnsNormally);
      });

      test('1899년 미지원 확인', () {
        expect(
          () => converter.solarToLunar(DateTime(1899, 6, 1)),
          throwsArgumentError,
        );
      });
    });
  });
}
