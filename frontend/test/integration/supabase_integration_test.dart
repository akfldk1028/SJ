// ignore_for_file: avoid_print
/// Supabase 통합 테스트
///
/// 실행 방법:
/// ```bash
/// cd frontend
/// flutter test test/integration/supabase_integration_test.dart
/// ```
///
/// 주의: 실제 Supabase DB에 연결하므로 네트워크 필요
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/supabase/generated/supadart_exports.dart';

void main() {
  late SupabaseClient client;

  setUpAll(() async {
    // Supabase 초기화 (테스트용)
    await Supabase.initialize(
      url: 'https://kfciluyxkomskyxjaeat.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmY2lsdXl4a29tc2t5eGphZWF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyNzQ1ODcsImV4cCI6MjA4MDg1MDU4N30.U6bVMabObQvYLp88ATd_JqxoUEJrZ2LiBCYqh3sUNLk',
    );
    client = Supabase.instance.client;
  });

  group('Supabase Integration Tests', () {
    test('saju_profiles 테이블 조회', () async {
      // Supadart 생성 타입 사용
      final response = await client
          .from(SajuProfiles.table_name)
          .select()
          .limit(3);

      expect(response, isA<List>());
      print('조회된 프로필 수: ${response.length}');

      if (response.isNotEmpty) {
        // Supadart converter 사용
        final profiles = SajuProfiles.converter(
          List<Map<String, dynamic>>.from(response),
        );

        expect(profiles, isA<List<SajuProfiles>>());
        print('첫 번째 프로필: ${profiles.first.displayName}');
        print('생년월일: ${profiles.first.birthDate}');
      }
    });

    test('saju_analyses 테이블 조회', () async {
      final response = await client
          .from(SajuAnalyses.table_name)
          .select()
          .limit(3);

      expect(response, isA<List>());
      print('조회된 분석 수: ${response.length}');

      if (response.isNotEmpty) {
        final analyses = SajuAnalyses.converter(
          List<Map<String, dynamic>>.from(response),
        );

        expect(analyses, isA<List<SajuAnalyses>>());

        final first = analyses.first;
        print('사주: ${first.yearGan}${first.yearJi} ${first.monthGan}${first.monthJi} ${first.dayGan}${first.dayJi}');
        print('오행 분포: ${first.ohengDistribution}');
      }
    });

    test('컬럼명 상수로 필터링', () async {
      // 하드코딩 대신 타입 안전한 컬럼명 사용
      final response = await client
          .from(SajuProfiles.table_name)
          .select()
          .eq(SajuProfiles.c_isPrimary, true)
          .limit(5);

      expect(response, isA<List>());
      print('Primary 프로필 수: ${response.length}');

      if (response.isNotEmpty) {
        final profiles = SajuProfiles.converter(
          List<Map<String, dynamic>>.from(response),
        );

        // 모든 결과가 isPrimary = true인지 확인
        for (final profile in profiles) {
          expect(profile.isPrimary, isTrue);
        }
      }
    });

    test('chat_sessions 테이블 조회', () async {
      final response = await client
          .from(ChatSessions.table_name)
          .select()
          .limit(3);

      expect(response, isA<List>());
      print('조회된 세션 수: ${response.length}');
    });

    test('chat_messages 테이블 조회', () async {
      final response = await client
          .from(ChatMessages.table_name)
          .select()
          .limit(3);

      expect(response, isA<List>());
      print('조회된 메시지 수: ${response.length}');
    });

    test('Join 쿼리 (프로필 + 분석)', () async {
      // 프로필과 사주 분석 조인
      final response = await client
          .from(SajuProfiles.table_name)
          .select('''
            *,
            saju_analyses (
              id,
              year_gan,
              year_ji,
              day_gan,
              day_ji,
              oheng_distribution
            )
          ''')
          .eq(SajuProfiles.c_isPrimary, true)
          .limit(3);

      expect(response, isA<List>());
      print('조인 결과 수: ${response.length}');

      if (response.isNotEmpty) {
        final first = response.first as Map<String, dynamic>;
        print('프로필: ${first['display_name']}');

        final analyses = first['saju_analyses'];
        if (analyses != null && analyses is List && analyses.isNotEmpty) {
          print('사주 분석 있음: ${analyses.first['day_gan']}');
        }
      }
    });
  });
}
