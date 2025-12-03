import 'gender.dart';

/// 사주 프로필 Entity
///
/// 주의: 순수 Dart만 사용!
/// - Flutter import 금지!
/// - Supabase import 금지!
/// - 외부 패키지 import 금지! (equatable 등 순수 Dart 패키지만 허용)
class SajuProfile {
  final String id;
  final String? userId;
  final String displayName;
  final DateTime birthDate;
  final int? birthTimeMinutes; // 0~1439 (분 단위)
  final bool birthTimeUnknown;
  final bool isLunar;
  final Gender gender;
  final String? birthPlace;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SajuProfile({
    required this.id,
    this.userId,
    required this.displayName,
    required this.birthDate,
    this.birthTimeMinutes,
    this.birthTimeUnknown = false,
    this.isLunar = false,
    required this.gender,
    this.birthPlace,
    this.isActive = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 출생 시간 문자열 (HH:mm 형식)
  String? get birthTimeString {
    if (birthTimeUnknown || birthTimeMinutes == null) return null;
    final hours = birthTimeMinutes! ~/ 60;
    final minutes = birthTimeMinutes! % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  /// 출생일 문자열 (yyyy.MM.dd 형식)
  String get birthDateString {
    return '${birthDate.year}.${birthDate.month.toString().padLeft(2, '0')}.${birthDate.day.toString().padLeft(2, '0')}';
  }

  /// 음양력 문자열
  String get calendarTypeString => isLunar ? '음력' : '양력';

  /// 전체 출생 정보 문자열
  String get fullBirthInfo {
    final timeStr = birthTimeUnknown
        ? '시간모름'
        : (birthTimeString ?? '시간모름');
    return '$birthDateString ($calendarTypeString) $timeStr';
  }

  /// copyWith 메서드
  SajuProfile copyWith({
    String? id,
    String? userId,
    String? displayName,
    DateTime? birthDate,
    int? birthTimeMinutes,
    bool? birthTimeUnknown,
    bool? isLunar,
    Gender? gender,
    String? birthPlace,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SajuProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      birthDate: birthDate ?? this.birthDate,
      birthTimeMinutes: birthTimeMinutes ?? this.birthTimeMinutes,
      birthTimeUnknown: birthTimeUnknown ?? this.birthTimeUnknown,
      isLunar: isLunar ?? this.isLunar,
      gender: gender ?? this.gender,
      birthPlace: birthPlace ?? this.birthPlace,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SajuProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SajuProfile(id: $id, displayName: $displayName, birthDate: $birthDateString)';
  }
}
