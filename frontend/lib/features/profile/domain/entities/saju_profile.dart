import 'package:freezed_annotation/freezed_annotation.dart';
import 'gender.dart';

part 'saju_profile.freezed.dart';

/// 사주 프로필 엔티티
///
/// 사용자의 생년월일시 정보를 담는 도메인 모델
/// 만세력 계산 및 AI 사주 상담의 기본 데이터
@freezed
class SajuProfile with _$SajuProfile {
  const factory SajuProfile({
    /// 프로필 고유 ID
    required String id,

    /// 표시 이름 (최대 12자)
    required String displayName,

    /// 성별
    required Gender gender,

    /// 생년월일 (양력 기준으로 저장)
    required DateTime birthDate,

    /// 음력 여부
    required bool isLunar,

    /// 음력 윤달 여부 (음력일 때만 의미)
    @Default(false) bool isLeapMonth,

    /// 출생시간 (분 단위, 0~1439)
    /// null이면 시간을 모르는 경우
    int? birthTimeMinutes,

    /// 시간 모름 여부
    @Default(false) bool birthTimeUnknown,

    /// 야자시/조자시 설정
    /// true: 야자시 (23:00-01:00을 다음날 자시로 계산)
    /// false: 조자시 (23:00-01:00을 당일 자시로 계산)
    @Default(true) bool useYaJasi,

    /// 출생 도시 (진태양시 계산용)
    required String birthCity,

    /// 진태양시 보정값 (분 단위)
    /// 자동으로 계산되어 저장됨
    @Default(0) int timeCorrection,

    /// 생성 일시
    required DateTime createdAt,

    /// 수정 일시
    required DateTime updatedAt,

    /// 현재 활성 프로필 여부
    /// 한 번에 하나의 프로필만 활성화 가능
    @Default(false) bool isActive,
  }) = _SajuProfile;

  const SajuProfile._();

  /// 출생시간을 시:분 형식으로 변환
  String? get birthTimeFormatted {
    if (birthTimeMinutes == null || birthTimeUnknown) return null;

    final hours = birthTimeMinutes! ~/ 60;
    final minutes = birthTimeMinutes! % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  /// 생년월일 표시 형식 (YYYY.MM.DD)
  String get birthDateFormatted {
    return '${birthDate.year}.${birthDate.month.toString().padLeft(2, '0')}.${birthDate.day.toString().padLeft(2, '0')}';
  }

  /// 음양력 표시 (양력/음력)
  String get calendarTypeLabel => isLunar ? '음력' : '양력';

  /// 진태양시 보정 표시 문자열
  String get timeCorrectionLabel {
    if (timeCorrection == 0) return '보정 없음';
    if (timeCorrection > 0) {
      return '+${timeCorrection}분';
    }
    return '$timeCorrection분';
  }

  /// 유효성 검증
  bool get isValid {
    // 필수 필드 체크
    if (displayName.isEmpty || displayName.length > 12) return false;
    if (birthCity.isEmpty) return false;

    // 생년월일 범위 체크 (1900년 ~ 현재)
    final now = DateTime.now();
    if (birthDate.year < 1900 || birthDate.isAfter(now)) return false;

    // 출생시간 범위 체크
    if (birthTimeMinutes != null) {
      if (birthTimeMinutes! < 0 || birthTimeMinutes! > 1439) return false;
    }

    return true;
  }
}
