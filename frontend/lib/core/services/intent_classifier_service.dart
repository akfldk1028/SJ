import 'package:flutter/foundation.dart';
import 'ai_summary_service.dart';
import 'supabase_service.dart';

/// 사용자 질문의 의도를 분류하는 서비스
///
/// Supabase Edge Function (ai-gemini v19)를 통해 Gemini Flash로 빠르게 카테고리 판단 (1초 이내)
/// 토큰 최적화를 위해 필요한 AI Summary 섹션만 선택
///
/// ## v3.0: Supabase Edge Function 통합 (보안 강화)
/// - API 키가 서버에만 존재 (클라이언트 노출 없음)
/// - Quota 관리 자동화
/// - 토큰 사용량 DB 기록
///
/// ## 사용 예시
/// ```dart
/// final result = await IntentClassifierService.classifyIntent(
///   userMessage: "요즘 연애가 잘 안 풀리는데 이유가 뭘까?",
///   userId: "user-id",
/// );
/// // result.categories: [SummaryCategory.love]
/// ```
class IntentClassifierService {
  static const String _functionName = 'ai-gemini';

  /// 사용자 질문에서 필요한 카테고리 추출
  ///
  /// [userMessage] - 사용자 질문
  /// [chatHistory] - 최근 대화 내역 (컨텍스트용, 선택)
  /// [userId] - 사용자 ID (Quota 관리용, 선택)
  ///
  /// 반환: 필요한 카테고리 목록 (최대 3개)
  static Future<IntentClassificationResult> classifyIntent({
    required String userMessage,
    List<String>? chatHistory,
    String? userId,
  }) async {
    try {
      // Supabase 클라이언트 확인
      final client = SupabaseService.client;
      if (client == null) {
        if (kDebugMode) {
          print('[IntentClassifier] ⚠️ Supabase 미연결 (오프라인)');
        }
        return const IntentClassificationResult(
          categories: [SummaryCategory.general],
          reason: '오프라인 모드로 전체 정보 제공',
        );
      }

      if (kDebugMode) {
        print('[IntentClassifier] 분류 시작: ${userMessage.length > 30 ? '${userMessage.substring(0, 30)}...' : userMessage}');
      }

      // Edge Function 호출 (ai-gemini v19)
      final response = await client.functions.invoke(
        _functionName,
        body: {
          'action': 'classify-intent',
          'user_message': userMessage,
          'chat_history': chatHistory,
          'user_id': userId,
        },
      );

      if (kDebugMode) {
        print('[IntentClassifier] Edge Function 응답: status=${response.status}');
        print('[IntentClassifier] 응답 데이터: ${response.data}');
      }

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>;

        if (kDebugMode) {
          print('[IntentClassifier] success=${data['success']}, categories=${data['categories']}');
        }

        if (data['success'] == true) {
          final categoryCodes = (data['categories'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              ['GENERAL'];

          final categories = categoryCodes
              .map((code) => SummaryCategory.values.firstWhere(
                    (c) => c.code == code,
                    orElse: () => SummaryCategory.general,
                  ))
              .toList();

          if (kDebugMode) {
            print('[IntentClassifier] ✅ 분류 완료: ${categories.map((c) => c.korean).join(", ")}');
          }

          return IntentClassificationResult(
            categories: categories,
            reason: data['reason'] as String? ?? '',
          );
        } else {
          if (kDebugMode) {
            print('[IntentClassifier] ⚠️ success=false');
          }
        }
      } else {
        // 에러 응답 로그
        if (kDebugMode) {
          print('[IntentClassifier] ⚠️ 응답 실패 (status: ${response.status})');
          print('[IntentClassifier] 에러 응답: ${response.data}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[IntentClassifier] ❌ 분류 실패: $e');
      }
    }

    // 실패 시 전체 반환 (안전장치)
    return const IntentClassificationResult(
      categories: [SummaryCategory.general],
      reason: '분류 실패로 전체 정보 제공',
    );
  }

}
