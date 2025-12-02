/// 자시 처리 모드
/// 23:00-01:00 자시 시간대의 날짜 처리 방식
enum JasiMode {
  /// 야자시 (夜子時): 전통 방식
  /// - 23:00-24:00 → 당일 자시
  /// - 00:00-01:00 → 익일 자시 (일주 변경)
  yaJasi,

  /// 조자시 (早子時): 현대 방식
  /// - 23:00-24:00 → 익일로 간주 (일주 변경)
  /// - 00:00-01:00 → 당일 자시
  joJasi,
}

/// 자시 처리 서비스
/// 23:00-01:00 자시 시간대의 특수한 날짜 처리
class JasiService {
  /// 자시 시간대 판단 (23:00-01:00)
  bool isJasiHour(int hour) {
    return hour == 23 || hour == 0;
  }

  /// 야자시/조자시 모드에 따른 날짜 조정
  ///
  /// 야자시 모드 (전통):
  /// - 23:00-24:00 → 당일 자시 (날짜 변경 없음)
  /// - 00:00-01:00 → 익일 자시 (일주 변경 = 다음 날로 계산)
  ///
  /// 조자시 모드 (현대):
  /// - 23:00-24:00 → 익일로 간주 (일주 변경 = 다음 날로 계산)
  /// - 00:00-01:00 → 당일 자시 (날짜 변경 없음)
  ///
  /// [dateTime] 보정할 날짜시간
  /// [mode] 자시 처리 모드 (기본: 야자시)
  DateTime adjustForJasi({
    required DateTime dateTime,
    JasiMode mode = JasiMode.yaJasi,
  }) {
    final hour = dateTime.hour;

    if (!isJasiHour(hour)) {
      return dateTime; // 자시 아니면 그대로 반환
    }

    if (mode == JasiMode.yaJasi) {
      // 야자시: 0시대는 익일 처리
      if (hour == 0) {
        return dateTime.add(const Duration(days: 1));
      }
    } else {
      // 조자시: 23시대를 익일로 처리
      if (hour == 23) {
        return dateTime.add(const Duration(days: 1));
      }
    }

    return dateTime;
  }

  /// 자시 모드 설명 반환
  String getModeDescription(JasiMode mode) {
    switch (mode) {
      case JasiMode.yaJasi:
        return '야자시 (전통): 23시대는 당일, 0시대는 익일로 계산';
      case JasiMode.joJasi:
        return '조자시 (현대): 23시대는 익일, 0시대는 당일로 계산';
    }
  }

  /// 자시 보정 정보 반환 (디버깅/표시용)
  Map<String, dynamic> getJasiInfo({
    required DateTime dateTime,
    required JasiMode mode,
  }) {
    final hour = dateTime.hour;
    final isJasi = isJasiHour(hour);

    DateTime adjustedDate = dateTime;
    bool dateChanged = false;

    if (isJasi) {
      adjustedDate = adjustForJasi(dateTime: dateTime, mode: mode);
      dateChanged = adjustedDate.day != dateTime.day;
    }

    return {
      'isJasiHour': isJasi,
      'hour': hour,
      'mode': mode.toString().split('.').last,
      'originalDate': dateTime.toIso8601String(),
      'adjustedDate': adjustedDate.toIso8601String(),
      'dateChanged': dateChanged,
      'description': getModeDescription(mode),
    };
  }

  /// 자시 시간대의 시주 인덱스 (0-11)
  /// 자시 = 0, 축시 = 1, ...
  int getJasiJiIndex() {
    return 0; // 자(子)
  }
}
