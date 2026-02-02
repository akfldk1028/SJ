import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../purchase_config.dart';

/// Supabase 구매 이벤트 기록
///
/// 클라이언트에서 구매 성공 후 subscriptions 테이블에 기록
/// 주: 메인 구독 관리는 RevenueCat webhook → purchase-webhook Edge Function이 담당
/// 여기서는 보조적으로 클라이언트 측 기록만 수행
abstract class PurchaseMutations {
  PurchaseMutations._();

  /// 구매 성공 후 구독 정보 기록
  static Future<void> recordPurchase(CustomerInfo customerInfo) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // 활성 entitlement 확인 후 기록
      final premium =
          customerInfo.entitlements.all[PurchaseConfig.entitlementPremium];

      if (premium?.isActive == true) {
        await _upsertSubscription(
          userId: userId,
          productId: premium!.productIdentifier,
          isLifetime: false,
          expiresAt: premium.expirationDate,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[PurchaseMutations] 구매 기록 실패: $e');
      }
    }
  }

  static Future<void> _upsertSubscription({
    required String userId,
    required String productId,
    required bool isLifetime,
    String? expiresAt,
  }) async {
    try {
      await Supabase.instance.client.from('subscriptions').upsert(
        {
          'user_id': userId,
          'product_id': productId,
          'platform': defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
          'status': 'active',
          'is_lifetime': isLifetime,
          'expires_at': expiresAt,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,product_id',
      );
    } catch (e) {
      if (kDebugMode) {
        print('[PurchaseMutations] 구독 upsert 실패: $e');
      }
    }
  }
}
