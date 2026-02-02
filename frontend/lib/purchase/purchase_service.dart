import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/services/supabase_service.dart';
import 'purchase_config.dart';

/// RevenueCat 초기화 및 핵심 메서드
///
/// Singleton 패턴. main.dart에서 initialize() 호출.
class PurchaseService {
  static final PurchaseService instance = PurchaseService._();
  PurchaseService._();

  bool _initialized = false;

  /// RevenueCat SDK 초기화
  ///
  /// 모바일 전용 (Web에서는 호출하지 않음)
  Future<void> initialize() async {
    if (_initialized) return;

    final apiKey = Platform.isIOS
        ? PurchaseConfig.revenueCatApiKeyIos
        : PurchaseConfig.revenueCatApiKeyAndroid;

    await Purchases.configure(PurchasesConfiguration(apiKey));

    // Supabase user ID와 RevenueCat user ID 동기화
    final userId = SupabaseService.currentUserId;
    if (userId != null) {
      await Purchases.logIn(userId);
    }

    _initialized = true;

    if (kDebugMode) {
      print('[PurchaseService] RevenueCat 초기화 완료 (userId: $userId)');
    }
  }

  /// 프리미엄 여부 (day_pass, week_pass, monthly 중 하나 활성)
  Future<bool> get isPremium async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.all[PurchaseConfig.entitlementPremium]?.isActive ==
          true;
    } catch (e) {
      if (kDebugMode) {
        print('[PurchaseService] isPremium 체크 실패: $e');
      }
      return false;
    }
  }

  /// Offerings 조회 (상품 목록)
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      if (kDebugMode) {
        print('[PurchaseService] getOfferings 실패: $e');
      }
      return null;
    }
  }

  /// 구매 실행
  Future<PurchaseResult> purchase(Package package) =>
      Purchases.purchasePackage(package);

  /// 구매 복원
  Future<CustomerInfo> restore() => Purchases.restorePurchases();
}
