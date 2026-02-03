import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 구독 상태 조회
abstract class PurchaseQueries {
  PurchaseQueries._();

  /// 현재 사용자의 활성 구독 조회
  static Future<List<Map<String, dynamic>>> getActiveSubscriptions(
      String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('[PurchaseQueries] 구독 조회 실패: $e');
      }
      return [];
    }
  }

  /// 특정 상품의 활성 구독 여부 확인
  static Future<bool> hasActiveSubscription(
      String userId, String productId) async {
    try {
      final response = await Supabase.instance.client
          .from('subscriptions')
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .eq('status', 'active')
          .maybeSingle();

      return response != null;
    } catch (e) {
      if (kDebugMode) {
        print('[PurchaseQueries] 구독 확인 실패: $e');
      }
      return false;
    }
  }
}
