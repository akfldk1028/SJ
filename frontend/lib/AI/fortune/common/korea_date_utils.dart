/// # 한국 날짜 유틸리티
///
/// ## 개요
/// 한국 시간대(KST, UTC+9) 기준 날짜/시간 처리
/// 운세 분석의 월/년 전환 기준점 명확화
///
/// ## 파일 위치
/// `frontend/lib/AI/fortune/common/korea_date_utils.dart`
///
/// ## 사용 이유
/// - DateTime.now()는 시스템 로컬 시간 사용
/// - 서버/기기 timezone이 다르면 한국 날짜와 불일치
/// - 운세 분석은 반드시 한국 시간 기준이어야 함

/// 한국 시간대 오프셋 (UTC+9)
const int _koreaTimeZoneOffsetHours = 9;

/// 한국 날짜 유틸리티 클래스
class KoreaDateUtils {
  KoreaDateUtils._();

  /// 현재 한국 시간 반환
  ///
  /// UTC 기준으로 +9시간 적용
  static DateTime nowKorea() {
    final utcNow = DateTime.now().toUtc();
    return utcNow.add(const Duration(hours: _koreaTimeZoneOffsetHours));
  }

  /// 현재 한국 연도
  static int get currentYear => nowKorea().year;

  /// 현재 한국 월
  static int get currentMonth => nowKorea().month;

  /// 현재 한국 일
  static int get currentDay => nowKorea().day;

  /// 현재 한국 날짜 (시간 정보 제외)
  static DateTime get today {
    final now = nowKorea();
    return DateTime(now.year, now.month, now.day);
  }

  /// 이번달 1일 (한국 시간)
  static DateTime get firstDayOfMonth {
    final now = nowKorea();
    return DateTime(now.year, now.month, 1);
  }

  /// 이번달 마지막 날 (한국 시간)
  static DateTime get lastDayOfMonth {
    final now = nowKorea();
    return DateTime(now.year, now.month + 1, 0);
  }

  /// 특정 월의 첫날
  static DateTime firstDayOf(int year, int month) {
    return DateTime(year, month, 1);
  }

  /// 특정 월의 마지막 날
  static DateTime lastDayOf(int year, int month) {
    return DateTime(year, month + 1, 0);
  }

  /// 월 변경 여부 확인
  ///
  /// [cachedYear] 캐시된 연도
  /// [cachedMonth] 캐시된 월
  /// 반환: 현재 한국 시간 기준으로 월이 변경되었는지
  static bool isMonthChanged(int cachedYear, int cachedMonth) {
    return currentYear != cachedYear || currentMonth != cachedMonth;
  }

  /// 연 변경 여부 확인
  ///
  /// [cachedYear] 캐시된 연도
  /// 반환: 현재 한국 시간 기준으로 연이 변경되었는지
  static bool isYearChanged(int cachedYear) {
    return currentYear != cachedYear;
  }

  /// 만료 시간 계산 (한국 시간 기준)
  ///
  /// [duration] 만료까지의 기간
  /// 반환: 만료 DateTime (UTC)
  static DateTime calculateExpiry(Duration duration) {
    return nowKorea().add(duration);
  }

  /// 이번달 남은 일수
  static int get daysLeftInMonth {
    final now = nowKorea();
    final lastDay = lastDayOfMonth;
    return lastDay.day - now.day;
  }

  /// 다음달 1일까지 남은 시간
  static Duration get durationUntilNextMonth {
    final now = nowKorea();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    return nextMonth.difference(now);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 운세 캐시 만료 시간 계산
  // ═══════════════════════════════════════════════════════════════════════════

  /// 특정 월 말일 23:59:59 (한국 시간)
  ///
  /// [year] 연도
  /// [month] 월
  /// 반환: 해당 월의 마지막 순간
  ///
  /// 예: 2026년 1월 → 2026-01-31 23:59:59 KST
  static DateTime endOfMonth(int year, int month) {
    // month+1의 0일 = month의 마지막 날
    final lastDay = DateTime(year, month + 1, 0);
    return DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
  }

  /// 특정 연도 말일 23:59:59 (한국 시간)
  ///
  /// [year] 연도
  /// 반환: 해당 연도의 마지막 순간 (12월 31일 23:59:59)
  ///
  /// 예: 2026 → 2026-12-31 23:59:59 KST
  static DateTime endOfYear(int year) {
    return DateTime(year, 12, 31, 23, 59, 59);
  }

  /// 이번달 말일 23:59:59 만료 시간 (Supabase용 ISO8601)
  ///
  /// 월운 캐시에 사용
  static String expiryEndOfCurrentMonth() {
    return toIso8601(endOfMonth(currentYear, currentMonth));
  }

  /// 특정 월 말일 만료 시간 (Supabase용 ISO8601)
  ///
  /// [year] 연도
  /// [month] 월
  static String expiryEndOfMonth(int year, int month) {
    return toIso8601(endOfMonth(year, month));
  }

  /// 특정 연도 말일 만료 시간 (Supabase용 ISO8601)
  ///
  /// [year] 연도
  /// 신년운세 캐시에 사용
  static String expiryEndOfYear(int year) {
    return toIso8601(endOfYear(year));
  }

  /// 연도-월 문자열 (캐시 키용)
  ///
  /// 반환: 'YYYY-MM' 형식
  static String get currentYearMonthKey {
    final year = currentYear.toString();
    final month = currentMonth.toString().padLeft(2, '0');
    return '$year-$month';
  }

  /// 특정 연월의 키 생성
  static String yearMonthKey(int year, int month) {
    final y = year.toString();
    final m = month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  /// ISO8601 문자열로 변환 (Supabase용)
  static String toIso8601(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  /// 현재 한국 시간 ISO8601 문자열
  static String get nowKoreaIso8601 {
    return toIso8601(nowKorea());
  }
}

/// 확장 메서드: DateTime에 한국 시간 변환 추가
extension KoreaTimeExtension on DateTime {
  /// UTC를 한국 시간으로 변환
  DateTime toKoreaTime() {
    if (isUtc) {
      return add(const Duration(hours: _koreaTimeZoneOffsetHours));
    }
    // 이미 로컬 시간인 경우 UTC로 변환 후 한국 시간 적용
    return toUtc().add(const Duration(hours: _koreaTimeZoneOffsetHours));
  }

  /// 한국 시간을 UTC로 변환
  DateTime fromKoreaTimeToUtc() {
    return subtract(const Duration(hours: _koreaTimeZoneOffsetHours)).toUtc();
  }
}
