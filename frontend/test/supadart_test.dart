import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/supabase/generated/supadart_exports.dart';

void main() {
  group('Supadart Generated Types', () {
    group('SajuAnalyses', () {
      test('table_name should return correct value', () {
        expect(SajuAnalyses.table_name, 'saju_analyses');
      });

      test('column constants should return snake_case names', () {
        expect(SajuAnalyses.c_id, 'id');
        expect(SajuAnalyses.c_profileId, 'profile_id');
        expect(SajuAnalyses.c_yearGan, 'year_gan');
        expect(SajuAnalyses.c_yearJi, 'year_ji');
        expect(SajuAnalyses.c_monthGan, 'month_gan');
        expect(SajuAnalyses.c_monthJi, 'month_ji');
        expect(SajuAnalyses.c_dayGan, 'day_gan');
        expect(SajuAnalyses.c_dayJi, 'day_ji');
        expect(SajuAnalyses.c_hourGan, 'hour_gan');
        expect(SajuAnalyses.c_hourJi, 'hour_ji');
        expect(SajuAnalyses.c_ohengDistribution, 'oheng_distribution');
        expect(SajuAnalyses.c_dayStrength, 'day_strength');
        expect(SajuAnalyses.c_yongsin, 'yongsin');
        expect(SajuAnalyses.c_gilseong, 'gilseong');
      });

      test('fromJson should parse correctly', () {
        final json = {
          'id': 'test-id',
          'profile_id': 'profile-123',
          'year_gan': '갑',
          'year_ji': '자',
          'month_gan': '을',
          'month_ji': '축',
          'day_gan': '병',
          'day_ji': '인',
          'hour_gan': '정',
          'hour_ji': '묘',
          'oheng_distribution': {'wood': 2, 'fire': 3, 'earth': 1, 'metal': 1, 'water': 1},
          'day_strength': {'score': 45, 'is_singang': false},
          'yongsin': {'yongsin': '금', 'huisin': '토'},
          'gilseong': {'items': []},
        };

        final analysis = SajuAnalyses.fromJson(json);

        expect(analysis.id, 'test-id');
        expect(analysis.profileId, 'profile-123');
        expect(analysis.yearGan, '갑');
        expect(analysis.yearJi, '자');
        expect(analysis.monthGan, '을');
        expect(analysis.monthJi, '축');
        expect(analysis.dayGan, '병');
        expect(analysis.dayJi, '인');
        expect(analysis.hourGan, '정');
        expect(analysis.hourJi, '묘');
        expect(analysis.ohengDistribution['wood'], 2);
        expect(analysis.dayStrength?['score'], 45);
        expect(analysis.yongsin?['yongsin'], '금');
        expect(analysis.gilseong?['items'], []);
      });

      test('toJson should serialize correctly', () {
        final analysis = SajuAnalyses(
          id: 'test-id',
          profileId: 'profile-123',
          yearGan: '갑',
          yearJi: '자',
          monthGan: '을',
          monthJi: '축',
          dayGan: '병',
          dayJi: '인',
          hourGan: '정',
          hourJi: '묘',
          ohengDistribution: {'wood': 2, 'fire': 3},
        );

        final json = analysis.toJson();

        expect(json['id'], 'test-id');
        expect(json['profile_id'], 'profile-123');
        expect(json['year_gan'], '갑');
        expect(json['oheng_distribution'], {'wood': 2, 'fire': 3});
      });

      test('insert should generate correct map with required fields', () {
        final insertMap = SajuAnalyses.insert(
          profileId: 'profile-123',
          yearGan: '갑',
          yearJi: '자',
          monthGan: '을',
          monthJi: '축',
          dayGan: '병',
          dayJi: '인',
          ohengDistribution: {'wood': 2},
        );

        expect(insertMap['profile_id'], 'profile-123');
        expect(insertMap['year_gan'], '갑');
        expect(insertMap['oheng_distribution'], {'wood': 2});
        expect(insertMap.containsKey('id'), false); // optional field not included
      });

      test('copyWith should create new instance with updated values', () {
        final original = SajuAnalyses(
          id: 'test-id',
          profileId: 'profile-123',
          yearGan: '갑',
          yearJi: '자',
          monthGan: '을',
          monthJi: '축',
          dayGan: '병',
          dayJi: '인',
          ohengDistribution: {'wood': 2},
        );

        final updated = original.copyWith(yearGan: '을');

        expect(updated.yearGan, '을');
        expect(updated.id, 'test-id'); // unchanged
        expect(original.yearGan, '갑'); // original unchanged
      });
    });

    group('SajuProfiles', () {
      test('table_name should return correct value', () {
        expect(SajuProfiles.table_name, 'saju_profiles');
      });

      test('column constants should return snake_case names', () {
        expect(SajuProfiles.c_id, 'id');
        expect(SajuProfiles.c_userId, 'user_id');
        expect(SajuProfiles.c_displayName, 'display_name');
        expect(SajuProfiles.c_birthDate, 'birth_date');
        expect(SajuProfiles.c_birthTimeMinutes, 'birth_time_minutes');
        expect(SajuProfiles.c_isPrimary, 'is_primary');
      });

      test('fromJson should parse correctly', () {
        final json = {
          'id': 'profile-id',
          'user_id': 'user-123',
          'display_name': '홍길동',
          'birth_date': '1990-01-15',
          'birth_time_minutes': 480,
          'gender': 'male',
          'birth_city': '서울',
          'is_primary': true,
        };

        final profile = SajuProfiles.fromJson(json);

        expect(profile.id, 'profile-id');
        expect(profile.userId, 'user-123');
        expect(profile.displayName, '홍길동');
        expect(profile.birthTimeMinutes, 480);
        expect(profile.isPrimary, true);
      });
    });

    group('ChatSessions', () {
      test('table_name should return correct value', () {
        expect(ChatSessions.table_name, 'chat_sessions');
      });
    });

    group('ChatMessages', () {
      test('table_name should return correct value', () {
        expect(ChatMessages.table_name, 'chat_messages');
      });
    });
  });
}
