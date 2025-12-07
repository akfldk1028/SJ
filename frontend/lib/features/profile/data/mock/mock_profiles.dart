import '../../domain/entities/saju_profile.dart';
import '../../domain/entities/gender.dart';
import '../../domain/entities/relationship_type.dart';

/// 목업 프로필 데이터 (테스트용)
class MockProfiles {
  static List<SajuProfile> get profiles => [
    // 나 (Me)
    SajuProfile(
      id: 'me_001',
      displayName: '홍길동',
      gender: Gender.male,
      birthDate: DateTime(1990, 5, 20),
      isLunar: false,
      birthTimeMinutes: 9 * 60 + 30, // 09:30
      birthTimeUnknown: false,
      useYaJasi: true,
      birthCity: '서울',
      timeCorrection: -30,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      relationType: RelationshipType.me,
      memo: '본인',
    ),

    // 가족
    SajuProfile(
      id: 'family_001',
      displayName: '홍어머니',
      gender: Gender.female,
      birthDate: DateTime(1962, 3, 15),
      isLunar: true,
      birthTimeMinutes: 6 * 60, // 06:00
      birthTimeUnknown: false,
      useYaJasi: true,
      birthCity: '부산',
      timeCorrection: -23,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: false,
      relationType: RelationshipType.family,
      memo: '어머니',
    ),
    SajuProfile(
      id: 'family_002',
      displayName: '홍아버지',
      gender: Gender.male,
      birthDate: DateTime(1960, 8, 8),
      isLunar: false,
      birthTimeMinutes: 14 * 60 + 20, // 14:20
      birthTimeUnknown: false,
      useYaJasi: true,
      birthCity: '대구',
      timeCorrection: -27,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: false,
      relationType: RelationshipType.family,
      memo: '아버지',
    ),
    SajuProfile(
      id: 'family_003',
      displayName: '홍여동생',
      gender: Gender.female,
      birthDate: DateTime(1995, 12, 25),
      isLunar: false,
      birthTimeMinutes: null,
      birthTimeUnknown: true,
      useYaJasi: true,
      birthCity: '서울',
      timeCorrection: -30,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: false,
      relationType: RelationshipType.family,
      memo: '여동생',
    ),

    // 친구
    SajuProfile(
      id: 'friend_001',
      displayName: '김철수',
      gender: Gender.male,
      birthDate: DateTime(1990, 7, 14),
      isLunar: false,
      birthTimeMinutes: 11 * 60 + 45, // 11:45
      birthTimeUnknown: false,
      useYaJasi: true,
      birthCity: '인천',
      timeCorrection: -29,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: false,
      relationType: RelationshipType.friend,
      memo: '대학 동기',
    ),
    SajuProfile(
      id: 'friend_002',
      displayName: '이영희',
      gender: Gender.female,
      birthDate: DateTime(1991, 2, 28),
      isLunar: false,
      birthTimeMinutes: 22 * 60 + 10, // 22:10
      birthTimeUnknown: false,
      useYaJasi: true,
      birthCity: '광주',
      timeCorrection: -33,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: false,
      relationType: RelationshipType.friend,
      memo: '고등학교 친구',
    ),

    // 연인
    SajuProfile(
      id: 'lover_001',
      displayName: '박수진',
      gender: Gender.female,
      birthDate: DateTime(1992, 9, 3),
      isLunar: false,
      birthTimeMinutes: 8 * 60, // 08:00
      birthTimeUnknown: false,
      useYaJasi: true,
      birthCity: '서울',
      timeCorrection: -30,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: false,
      relationType: RelationshipType.lover,
      memo: '여자친구',
    ),

    // 동료
    SajuProfile(
      id: 'work_001',
      displayName: '최팀장',
      gender: Gender.male,
      birthDate: DateTime(1985, 4, 10),
      isLunar: false,
      birthTimeMinutes: 7 * 60 + 30, // 07:30
      birthTimeUnknown: false,
      useYaJasi: true,
      birthCity: '대전',
      timeCorrection: -28,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: false,
      relationType: RelationshipType.work,
      memo: '직장 팀장님',
    ),
    SajuProfile(
      id: 'work_002',
      displayName: '정대리',
      gender: Gender.female,
      birthDate: DateTime(1993, 11, 22),
      isLunar: false,
      birthTimeMinutes: 16 * 60, // 16:00
      birthTimeUnknown: false,
      useYaJasi: true,
      birthCity: '수원',
      timeCorrection: -29,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: false,
      relationType: RelationshipType.work,
      memo: '같은 팀 동료',
    ),
  ];
}
