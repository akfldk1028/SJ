import '../../data/constants/dst_periods.dart';

/// 서머타임(일광절약시간) 보정 서비스
/// 한국의 서머타임 적용 기간 확인 및 시간 보정
class DSTService {
  /// 서머타임 적용 여부 확인
  /// 해당 날짜가 서머타임 기간인지 확인
  bool checkDSTApplied(DateTime dateTime) {
    return dstPeriods.any((period) => period.contains(dateTime));
  }

  /// 서머타임 보정
  /// 서머타임 기간 출생자는 -1시간 보정
  ///
  /// 한국 서머타임 적용 기간:
  /// - 1948-1951년 (일부 기간)
  /// - 1955-1960년 (일부 기간)
  /// - 1987-1988년 (일부 기간)
  ///
  /// 해당 기간에는 시계를 1시간 앞당겼으므로
  /// 실제 태양시 계산을 위해 1시간을 빼야 함
  DateTime adjustForDST(DateTime dateTime) {
    return adjustDST(dateTime);
  }

  /// 서머타임 적용 기간 목록 반환
  List<DateRange> getDSTPeriods() {
    return dstPeriods;
  }

  /// 특정 연도에 서머타임이 적용되었는지 확인
  bool hasAnyDSTInYear(int year) {
    return dstPeriods.any((period) =>
        period.start.year == year || period.end.year == year);
  }

  /// 서머타임 보정 정보 반환 (디버깅/표시용)
  Map<String, dynamic> getDSTInfo(DateTime dateTime) {
    final isApplied = checkDSTApplied(dateTime);
    DateRange? appliedPeriod;

    if (isApplied) {
      appliedPeriod = dstPeriods.firstWhere(
        (period) => period.contains(dateTime),
      );
    }

    return {
      'isApplied': isApplied,
      'periodStart': appliedPeriod?.start.toIso8601String(),
      'periodEnd': appliedPeriod?.end.toIso8601String(),
      'correctionHours': isApplied ? -1 : 0,
    };
  }
}
