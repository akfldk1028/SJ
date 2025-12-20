import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/saju_chart/data/constants/solar_term_table_extended.dart';

void main() {
  setUp(() {
    clearSolarTermCache();
  });

  group('getSolarTermsForYear', () {
    test('2024년 공식 데이터 조회', () {
      final terms = getSolarTermsForYear(2024);

      expect(terms.length, equals(24));
      expect(terms['ipchun']?.name, equals('입춘'));
      expect(terms['ipchun']?.dateTime.month, equals(2));
      expect(terms['ipchun']?.dateTime.day, equals(4));

      print('2024년 입춘: ${terms['ipchun']?.dateTime}');
    });

    test('1950년 계산 데이터 조회', () {
      final terms = getSolarTermsForYear(1950);

      expect(terms.length, equals(24));
      expect(terms['ipchun']?.name, equals('입춘'));
      expect(terms['ipchun']?.dateTime.month, equals(2));
      expect(terms['ipchun']?.dateTime.day, inInclusiveRange(3, 6));

      print('1950년 입춘: ${terms['ipchun']?.dateTime}');
    });

    test('2050년 계산 데이터 조회', () {
      final terms = getSolarTermsForYear(2050);

      expect(terms.length, equals(24));
      expect(terms['dongji']?.name, equals('동지'));
      expect(terms['dongji']?.dateTime.month, equals(12));
      expect(terms['dongji']?.dateTime.day, inInclusiveRange(20, 23));

      print('2050년 동지: ${terms['dongji']?.dateTime}');
    });

    test('캐싱 동작 확인', () {
      // 첫 번째 호출 (계산)
      final terms1 = getSolarTermsForYear(1980);
      // 두 번째 호출 (캐시)
      final terms2 = getSolarTermsForYear(1980);

      expect(identical(terms1, terms2), isTrue);
    });

    test('범위 외 연도 오류', () {
      expect(
        () => getSolarTermsForYear(1899),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => getSolarTermsForYear(2101),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('경계 연도 처리', () {
      final terms1900 = getSolarTermsForYear(1900);
      expect(terms1900.length, equals(24));
      print('1900년 입춘: ${terms1900['ipchun']?.dateTime}');

      final terms2100 = getSolarTermsForYear(2100);
      expect(terms2100.length, equals(24));
      print('2100년 입춘: ${terms2100['ipchun']?.dateTime}');
    });
  });

  group('findSolarTermForDate', () {
    test('특정 날짜의 절기 찾기 - 2024년 입춘 이후', () {
      final result = findSolarTermForDate(DateTime(2024, 2, 10));

      expect(result, isNotNull);
      expect(result!.$1, equals('ipchun'));
      expect(result.$2.name, equals('입춘'));

      print('2024-02-10은 ${result.$2.name} 이후');
    });

    test('특정 날짜의 절기 찾기 - 2024년 입춘 당일', () {
      final result = findSolarTermForDate(DateTime(2024, 2, 4, 18, 0));

      expect(result, isNotNull);
      expect(result!.$1, equals('ipchun'));
    });

    test('특정 날짜의 절기 찾기 - 연초(이전 연도 절기)', () {
      final result = findSolarTermForDate(DateTime(2024, 1, 1));

      expect(result, isNotNull);
      // 1월 1일은 아직 소한(1/6) 전이므로 이전 연도 동지
      expect(result!.$1, equals('dongji'));
      print('2024-01-01은 ${result.$2.name} (${result.$2.dateTime.year}년) 이후');
    });
  });

  group('하위 호환성', () {
    test('solarTermTable deprecated getter 동작', () {
      // ignore: deprecated_member_use_from_same_package
      final table = solarTermTable;

      expect(table.containsKey(2024), isTrue);
      expect(table[2024]?['ipchun']?.name, equals('입춘'));
    });
  });

  group('전체 연도 범위 테스트', () {
    test('1900-2100년 모든 연도 절기 생성 가능', () {
      for (int year = 1900; year <= 2100; year++) {
        final terms = getSolarTermsForYear(year);
        expect(terms.length, equals(24), reason: '$year년 절기 개수 오류');

        // 입춘이 항상 2월에 있는지 확인
        final ipchun = terms['ipchun'];
        expect(ipchun?.dateTime.month, equals(2),
            reason: '$year년 입춘 월 오류: ${ipchun?.dateTime.month}');

        // 동지가 항상 12월에 있는지 확인
        final dongji = terms['dongji'];
        expect(dongji?.dateTime.month, equals(12),
            reason: '$year년 동지 월 오류: ${dongji?.dateTime.month}');
      }

      print('1900-2100년 (201년) 모든 절기 생성 성공');
    });
  });
}
