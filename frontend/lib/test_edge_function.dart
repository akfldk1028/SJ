// Edge Function 테스트 코드
// Flutter 앱에서 실행하거나, main.dart에서 호출하여 테스트
//
// 사용법:
// 1. main.dart에서 import 'test_edge_function.dart';
// 2. runApp() 전에 await testEdgeFunction(); 호출

import 'package:flutter/foundation.dart';
import 'core/services/supabase_service.dart';

Future<void> testEdgeFunction() async {
  if (!kDebugMode) return;

  print('========== Edge Function 테스트 시작 ==========');

  try {
    final client = SupabaseService.client;

    // 현재 세션 확인
    final session = client.auth.currentSession;
    print('[테스트] 현재 세션: ${session != null ? "있음" : "없음"}');

    if (session == null) {
      print('[테스트] 익명 로그인 시도...');
      await client.auth.signInAnonymously();
      print('[테스트] 익명 로그인 성공!');
    }

    // Edge Function 호출
    print('[테스트] saju-chat Edge Function 호출...');

    final response = await client.functions.invoke(
      'saju-chat',
      body: {
        'messages': [
          {'role': 'user', 'content': '안녕하세요, 간단하게 자기소개 해주세요'}
        ],
        'profileName': '테스트',
        'birthDate': '1990-01-15',
        'chatType': 'general',
      },
    );

    print('[테스트] 응답 상태: ${response.status}');

    if (response.status == 200) {
      final data = response.data as Map<String, dynamic>;
      print('[테스트] 성공!');
      print('[테스트] AI 응답: ${data['response']?.toString().substring(0, 100)}...');
      if (data['usage'] != null) {
        print('[테스트] 토큰 사용량: ${data['usage']['totalTokens']}');
      }
      print('[테스트] 모델: ${data['model']}');
    } else {
      print('[테스트] 실패: ${response.data}');
    }
  } catch (e, stack) {
    print('[테스트] 에러: $e');
    print('[테스트] 스택: $stack');
  }

  print('========== Edge Function 테스트 종료 ==========');
}
