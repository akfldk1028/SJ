// ignore_for_file: avoid_print
/// Supabase DB 연결 테스트 스크립트
///
/// 실행 방법:
/// ```bash
/// cd frontend
/// dart run test/integration/db_test_script.dart
/// ```
import 'package:supabase/supabase.dart';

// Supadart 생성 타입 import
import '../../lib/core/supabase/generated/saju_analyses.dart';
import '../../lib/core/supabase/generated/saju_profiles.dart';
import '../../lib/core/supabase/generated/chat_sessions.dart';
import '../../lib/core/supabase/generated/chat_messages.dart';

const supabaseUrl = 'https://kfciluyxkomskyxjaeat.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmY2lsdXl4a29tc2t5eGphZWF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyNzQ1ODcsImV4cCI6MjA4MDg1MDU4N30.U6bVMabObQvYLp88ATd_JqxoUEJrZ2LiBCYqh3sUNLk';

void main() async {
  print('=== Supabase DB 연결 테스트 ===\n');

  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  try {
    // 1. saju_profiles 조회
    print('1. saju_profiles 테이블 조회');
    print('   테이블명: ${SajuProfiles.table_name}');

    final profilesResponse = await client
        .from(SajuProfiles.table_name)
        .select()
        .limit(3);

    print('   조회 결과: ${profilesResponse.length}건');

    if (profilesResponse.isNotEmpty) {
      final profiles = SajuProfiles.converter(
        List<Map<String, dynamic>>.from(profilesResponse),
      );

      for (final p in profiles) {
        print('   - ${p.displayName} (${p.birthDate})');
      }
    }
    print('   ✅ 성공\n');

    // 2. saju_analyses 조회
    print('2. saju_analyses 테이블 조회');
    print('   테이블명: ${SajuAnalyses.table_name}');

    final analysesResponse = await client
        .from(SajuAnalyses.table_name)
        .select()
        .limit(3);

    print('   조회 결과: ${analysesResponse.length}건');

    if (analysesResponse.isNotEmpty) {
      final analyses = SajuAnalyses.converter(
        List<Map<String, dynamic>>.from(analysesResponse),
      );

      for (final a in analyses) {
        print('   - 사주: ${a.yearGan}${a.yearJi} ${a.monthGan}${a.monthJi} ${a.dayGan}${a.dayJi}');
        print('     오행: ${a.ohengDistribution}');
      }
    }
    print('   ✅ 성공\n');

    // 3. 컬럼명 상수 테스트
    print('3. 컬럼명 상수로 필터링');
    print('   필터: ${SajuProfiles.c_isPrimary} = true');

    final primaryResponse = await client
        .from(SajuProfiles.table_name)
        .select()
        .eq(SajuProfiles.c_isPrimary, true)
        .limit(3);

    print('   Primary 프로필: ${primaryResponse.length}건');
    print('   ✅ 성공\n');

    // 4. chat_sessions 조회
    print('4. chat_sessions 테이블 조회');
    print('   테이블명: ${ChatSessions.table_name}');

    final sessionsResponse = await client
        .from(ChatSessions.table_name)
        .select()
        .limit(3);

    print('   조회 결과: ${sessionsResponse.length}건');
    print('   ✅ 성공\n');

    // 5. chat_messages 조회
    print('5. chat_messages 테이블 조회');
    print('   테이블명: ${ChatMessages.table_name}');

    final messagesResponse = await client
        .from(ChatMessages.table_name)
        .select()
        .limit(3);

    print('   조회 결과: ${messagesResponse.length}건');
    print('   ✅ 성공\n');

    // 6. Join 테스트
    print('6. Join 쿼리 (프로필 + 분석)');

    final joinResponse = await client
        .from(SajuProfiles.table_name)
        .select('''
          ${SajuProfiles.c_id},
          ${SajuProfiles.c_displayName},
          saju_analyses (
            ${SajuAnalyses.c_dayGan},
            ${SajuAnalyses.c_dayJi}
          )
        ''')
        .eq(SajuProfiles.c_isPrimary, true)
        .limit(3);

    print('   조인 결과: ${joinResponse.length}건');

    for (final row in joinResponse) {
      final name = row['display_name'];
      final analyses = row['saju_analyses'] as List?;
      if (analyses != null && analyses.isNotEmpty) {
        final dayGan = analyses.first['day_gan'];
        final dayJi = analyses.first['day_ji'];
        print('   - $name: 일주 $dayGan$dayJi');
      }
    }
    print('   ✅ 성공\n');

    print('=== 모든 테스트 통과! ===');
  } catch (e, st) {
    print('❌ 에러 발생: $e');
    print(st);
  } finally {
    client.dispose();
  }
}
