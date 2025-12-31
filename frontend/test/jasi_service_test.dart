import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/saju_chart/domain/services/jasi_service.dart';

/// 야자시/조자시 로직 검증 테스트
///
/// 명리학 이론 기준:
/// - 야자시(夜子時): 자정(00:00) 기준 일주 변경
///   - 23:00-23:59 → 당일 일주 유지
///   - 00:00-00:59 → 익일 일주 적용
///
/// - 정자시(正子時): 자시 시작(23:00) 기준 일주 변경
///   - 23:00-23:59 → 익일 일주 적용
///   - 00:00-00:59 → 익일 일주 (이미 다음 날짜)
void main() {
  group('JasiService', () {
    final service = JasiService();

    group('isJasiHour', () {
      test('23시는 자시이다', () {
        expect(service.isJasiHour(23), true);
      });

      test('0시는 자시이다', () {
        expect(service.isJasiHour(0), true);
      });

      test('22시는 자시가 아니다 (해시)', () {
        expect(service.isJasiHour(22), false);
      });

      test('1시는 자시가 아니다 (축시)', () {
        expect(service.isJasiHour(1), false);
      });

      test('12시는 자시가 아니다 (오시)', () {
        expect(service.isJasiHour(12), false);
      });
    });

    group('adjustForJasi - 야자시 모드', () {
      test('23시에 태어나면 당일 일주 유지 (날짜 변경 없음)', () {
        final birthTime = DateTime(2000, 1, 1, 23, 30); // 2000.1.1 23:30
        final adjusted = service.adjustForJasi(
          dateTime: birthTime,
          mode: JasiMode.yaJasi,
        );

        // 야자시: 23시는 당일 → 날짜 변경 없음
        expect(adjusted.day, 1);
        expect(adjusted.month, 1);
        expect(adjusted.year, 2000);
      });

      test('0시에 태어나면 익일 일주 적용 (날짜 +1)', () {
        final birthTime = DateTime(2000, 1, 1, 0, 30); // 2000.1.1 00:30
        final adjusted = service.adjustForJasi(
          dateTime: birthTime,
          mode: JasiMode.yaJasi,
        );

        // 야자시: 0시는 익일 → 날짜 +1
        expect(adjusted.day, 2);
        expect(adjusted.month, 1);
        expect(adjusted.year, 2000);
      });

      test('자시가 아닌 시간은 변경 없음', () {
        final birthTime = DateTime(2000, 1, 1, 15, 0); // 2000.1.1 15:00
        final adjusted = service.adjustForJasi(
          dateTime: birthTime,
          mode: JasiMode.yaJasi,
        );

        expect(adjusted, birthTime);
      });
    });

    group('adjustForJasi - 정자시(조자시) 모드', () {
      test('23시에 태어나면 익일 일주 적용 (날짜 +1)', () {
        final birthTime = DateTime(2000, 1, 1, 23, 30); // 2000.1.1 23:30
        final adjusted = service.adjustForJasi(
          dateTime: birthTime,
          mode: JasiMode.joJasi,
        );

        // 정자시: 23시는 익일 → 날짜 +1
        expect(adjusted.day, 2);
        expect(adjusted.month, 1);
        expect(adjusted.year, 2000);
      });

      test('0시에 태어나면 날짜 변경 없음 (이미 익일)', () {
        final birthTime = DateTime(2000, 1, 1, 0, 30); // 2000.1.1 00:30
        final adjusted = service.adjustForJasi(
          dateTime: birthTime,
          mode: JasiMode.joJasi,
        );

        // 정자시: 0시는 이미 익일이므로 변경 없음
        expect(adjusted.day, 1);
        expect(adjusted.month, 1);
        expect(adjusted.year, 2000);
      });

      test('자시가 아닌 시간은 변경 없음', () {
        final birthTime = DateTime(2000, 1, 1, 15, 0); // 2000.1.1 15:00
        final adjusted = service.adjustForJasi(
          dateTime: birthTime,
          mode: JasiMode.joJasi,
        );

        expect(adjusted, birthTime);
      });
    });

    group('월/년 경계 테스트', () {
      test('야자시 모드: 월말 0시 → 다음 달로 변경', () {
        final birthTime = DateTime(2000, 1, 31, 0, 30); // 1월 31일 00:30
        final adjusted = service.adjustForJasi(
          dateTime: birthTime,
          mode: JasiMode.yaJasi,
        );

        expect(adjusted.day, 1);
        expect(adjusted.month, 2); // 2월로 변경
      });

      test('정자시 모드: 월말 23시 → 다음 달로 변경', () {
        final birthTime = DateTime(2000, 1, 31, 23, 30); // 1월 31일 23:30
        final adjusted = service.adjustForJasi(
          dateTime: birthTime,
          mode: JasiMode.joJasi,
        );

        expect(adjusted.day, 1);
        expect(adjusted.month, 2); // 2월로 변경
      });

      test('야자시 모드: 연말 0시 → 다음 해로 변경', () {
        final birthTime = DateTime(1999, 12, 31, 0, 30); // 12월 31일 00:30
        final adjusted = service.adjustForJasi(
          dateTime: birthTime,
          mode: JasiMode.yaJasi,
        );

        expect(adjusted.day, 1);
        expect(adjusted.month, 1);
        expect(adjusted.year, 2000); // 2000년으로 변경
      });

      test('정자시 모드: 연말 23시 → 다음 해로 변경', () {
        final birthTime = DateTime(1999, 12, 31, 23, 30); // 12월 31일 23:30
        final adjusted = service.adjustForJasi(
          dateTime: birthTime,
          mode: JasiMode.joJasi,
        );

        expect(adjusted.day, 1);
        expect(adjusted.month, 1);
        expect(adjusted.year, 2000); // 2000년으로 변경
      });
    });

    group('getModeDescription', () {
      test('야자시 설명 반환', () {
        final desc = service.getModeDescription(JasiMode.yaJasi);
        expect(desc, contains('야자시'));
        expect(desc, contains('23시'));
        expect(desc, contains('당일'));
      });

      test('정자시 설명 반환', () {
        final desc = service.getModeDescription(JasiMode.joJasi);
        expect(desc, contains('조자시'));
        expect(desc, contains('23시'));
        expect(desc, contains('익일'));
      });
    });

    group('밀레니엄 베이비 예시 (2000.1.1 00:00)', () {
      // 참고: 나무위키 사주팔자 문서
      // 야자시: 정사(丁巳)일 임자(壬子)시
      // 정자시: 무오(戊午)일 임자(壬子)시

      test('야자시 모드: 1999.12.31 23:30 → 당일(12.31) 일주', () {
        final birthTime = DateTime(1999, 12, 31, 23, 30);
        final adjusted = service.adjustForJasi(
          dateTime: birthTime,
          mode: JasiMode.yaJasi,
        );

        // 야자시: 23시는 당일 → 12월 31일 유지
        expect(adjusted.year, 1999);
        expect(adjusted.month, 12);
        expect(adjusted.day, 31);
      });

      test('정자시 모드: 1999.12.31 23:30 → 익일(2000.1.1) 일주', () {
        final birthTime = DateTime(1999, 12, 31, 23, 30);
        final adjusted = service.adjustForJasi(
          dateTime: birthTime,
          mode: JasiMode.joJasi,
        );

        // 정자시: 23시는 익일 → 2000년 1월 1일
        expect(adjusted.year, 2000);
        expect(adjusted.month, 1);
        expect(adjusted.day, 1);
      });
    });
  });
}
