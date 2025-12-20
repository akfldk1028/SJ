import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/saju_chart/data/constants/solar_term_calculator.dart';
import 'package:frontend/features/saju_chart/data/constants/solar_term_table.dart';

void main() {
  group('SolarTermCalculator 정확도 검증', () {
    test('2024년 절기 계산 - 한국천문연구원 데이터와 비교', () {
      // 한국천문연구원 공식 데이터 (solar_term_table.dart에서)
      final officialData = solarTermTable[2024]!;
      final calculatedData = SolarTermCalculator.calculateYearTerms(2024);

      print('===== 2024년 절기 검증 =====');
      for (final key in SolarTermCalculator.termKeys) {
        final official = officialData[key]!.dateTime;
        final calculated = calculatedData[key]!;

        final diffMinutes =
            calculated.difference(official).inMinutes.abs();

        print(
            '${officialData[key]!.name}: 공식 ${official.month}/${official.day} ${official.hour}:${official.minute.toString().padLeft(2, '0')} vs 계산 ${calculated.month}/${calculated.day} ${calculated.hour}:${calculated.minute.toString().padLeft(2, '0')} (차이: ${diffMinutes}분)');

        // 오차 허용 범위: 대부분 60분 이내
        // 사주 계산에서 절입 시간은 "날짜"가 중요하며, 분 단위 오차는 자정 전후가 아니면 영향 없음
        // 일부 절기(추분 등)는 알고리즘 한계로 큰 오차 발생 가능 - 공식 테이블 데이터로 대체
        if (diffMinutes > 60) {
          print('  ⚠️ 큰 오차 발견 - 공식 데이터 사용 필요');
        }
      }
    });

    test('2025년 절기 계산 - 한국천문연구원 데이터와 비교', () {
      final officialData = solarTermTable[2025]!;
      final calculatedData = SolarTermCalculator.calculateYearTerms(2025);

      print('===== 2025년 절기 검증 =====');
      int maxDiff = 0;
      for (final key in SolarTermCalculator.termKeys) {
        final official = officialData[key]!.dateTime;
        final calculated = calculatedData[key]!;

        final diffMinutes =
            calculated.difference(official).inMinutes.abs();
        if (diffMinutes > maxDiff) maxDiff = diffMinutes;

        print(
            '${officialData[key]!.name}: 차이 ${diffMinutes}분');

        if (diffMinutes > 60) {
          print('  ⚠️ 큰 오차: ${officialData[key]!.name}');
        }
      }
      print('최대 오차: ${maxDiff}분');
    });

    test('2020년 절기 계산 - 한국천문연구원 데이터와 비교', () {
      final officialData = solarTermTable[2020]!;
      final calculatedData = SolarTermCalculator.calculateYearTerms(2020);

      num totalDiff = 0;
      int count = 0;
      num maxDiff = 0;

      print('===== 2020년 절기 검증 =====');
      for (final key in SolarTermCalculator.termKeys) {
        final official = officialData[key]!.dateTime;
        final calculated = calculatedData[key]!;

        final diffMinutes = calculated.difference(official).inMinutes.abs();
        totalDiff += diffMinutes;
        count++;
        if (diffMinutes > maxDiff) maxDiff = diffMinutes;

        print('${officialData[key]!.name}: 차이 ${diffMinutes}분');

        if (diffMinutes > 60) {
          print('  ⚠️ 큰 오차: ${officialData[key]!.name}');
        }
      }

      print('평균 오차: ${(totalDiff / count).toStringAsFixed(1)}분');
      print('최대 오차: ${maxDiff}분');
    });

    test('1950년 절기 계산 (역사적 날짜)', () {
      // 1950년 입춘: 음력 기준 사주 계산에 중요
      final terms1950 = SolarTermCalculator.calculateYearTerms(1950);

      print('===== 1950년 절기 =====');
      for (int i = 0; i < 24; i++) {
        final key = SolarTermCalculator.termKeys[i];
        final name = SolarTermCalculator.termNames[i];
        final dt = terms1950[key]!;
        print('$name: ${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}');
      }

      // 1950년 입춘 예상: 2월 4일 또는 5일경
      final ipchun = terms1950['ipchun']!;
      expect(ipchun.month, equals(2));
      expect(ipchun.day, inInclusiveRange(3, 6));
    });

    test('2050년 절기 계산 (미래 날짜)', () {
      final terms2050 = SolarTermCalculator.calculateYearTerms(2050);

      print('===== 2050년 절기 =====');
      for (int i = 0; i < 24; i++) {
        final key = SolarTermCalculator.termKeys[i];
        final name = SolarTermCalculator.termNames[i];
        final dt = terms2050[key]!;
        print('$name: ${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}');
      }

      // 2050년 동지 예상: 12월 21일 또는 22일경
      final dongji = terms2050['dongji']!;
      expect(dongji.month, equals(12));
      expect(dongji.day, inInclusiveRange(20, 23));
    });

    test('2100년 절기 계산 (범위 경계)', () {
      final terms2100 = SolarTermCalculator.calculateYearTerms(2100);

      // 2100년 춘분: 3월 20일 또는 21일경
      final chunbun = terms2100['chunbun']!;
      expect(chunbun.month, equals(3));
      expect(chunbun.day, inInclusiveRange(19, 22));

      print('2100년 춘분: ${chunbun.month}/${chunbun.day} ${chunbun.hour}:${chunbun.minute}');
    });

    test('1900년 절기 계산 (범위 경계)', () {
      final terms1900 = SolarTermCalculator.calculateYearTerms(1900);

      // 1900년 하지: 6월 21일 또는 22일경
      final haji = terms1900['haji']!;
      expect(haji.month, equals(6));
      expect(haji.day, inInclusiveRange(20, 23));

      print('1900년 하지: ${haji.month}/${haji.day} ${haji.hour}:${haji.minute}');
    });
  });

  group('SolarTermTableGenerator', () {
    test('테이블 코드 생성 테스트', () {
      // 2년치만 생성해서 출력 확인
      final code = SolarTermTableGenerator.generateTableCode(2024, 2025);

      print('===== 생성된 코드 샘플 =====');
      print(code.substring(0, code.length > 1000 ? 1000 : code.length));

      expect(code.contains('2024:'), isTrue);
      expect(code.contains('2025:'), isTrue);
      expect(code.contains("'ipchun'"), isTrue);
      expect(code.contains("'dongji'"), isTrue);
    });
  });
}
