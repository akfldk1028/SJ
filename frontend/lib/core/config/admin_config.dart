import 'package:flutter/foundation.dart';

/// Admin 계정 설정
///
/// 개발 환경에서만 사용되는 관리자 프로필 정보
/// 배포 시에는 kDebugMode가 false가 되어 Admin 버튼이 숨겨짐
class AdminConfig {
  AdminConfig._();

  /// Admin 모드 활성화 여부 (개발 환경에서만 true)
  static bool get isAdminModeAvailable => kDebugMode;

  /// Admin 프로필 고정 정보
  static const String displayName = '이지나';
  static const int birthYear = 1999;
  static const int birthMonth = 7;
  static const int birthDay = 27;
  static const String birthCity = '서울특별시';
  static const String gender = 'female';
  static const bool birthTimeUnknown = true;
  static const bool isLunar = false;
  static const bool isLeapMonth = false;

  /// Admin 프로필 생년월일
  static DateTime get birthDate => DateTime(birthYear, birthMonth, birthDay);

  /// Admin 일일 토큰 quota (10억)
  static const int dailyQuota = 1000000000;
}
