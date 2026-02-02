import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/mutations/purchase_mutations.dart';
import '../purchase_config.dart';

part 'purchase_provider.g.dart';

/// 구매 상태 관리 Provider
///
/// RevenueCat CustomerInfo 기반으로 entitlement 체크
/// 광고/quota 시스템과 연동
@riverpod
class PurchaseNotifier extends _$PurchaseNotifier {
  @override
  Future<CustomerInfo> build() async {
    return await Purchases.getCustomerInfo();
  }

  // ── Entitlement 체크 ──

  bool get isPremium {
    return state.valueOrNull?.entitlements
            .all[PurchaseConfig.entitlementPremium]?.isActive ==
        true;
  }

  // ── 파생 상태 ──

  int get dailyQuota => isPremium
      ? PurchaseConfig.premiumDailyQuota
      : PurchaseConfig.freeDailyQuota;

  bool get showAds => !isPremium;

  // ── 액션 ──

  /// 구매 실행
  Future<void> purchasePackage(Package package) async {
    state = const AsyncLoading();
    try {
      final result = await Purchases.purchasePackage(package);
      final info = result.customerInfo;
      state = AsyncData(info);
      await PurchaseMutations.recordPurchase(info);

      if (kDebugMode) {
        print('[PurchaseNotifier] 구매 성공: ${package.identifier}');
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        state = AsyncError(e, StackTrace.current);
        if (kDebugMode) {
          print('[PurchaseNotifier] 구매 실패: $e');
        }
      } else {
        // 사용자가 취소한 경우 이전 상태로 복원
        state = AsyncData(await Purchases.getCustomerInfo());
      }
    }
  }

  /// 구매 복원
  Future<void> restore() async {
    state = const AsyncLoading();
    try {
      final info = await Purchases.restorePurchases();
      state = AsyncData(info);

      if (kDebugMode) {
        print('[PurchaseNotifier] 구매 복원 완료');
      }
    } catch (e, st) {
      state = AsyncError(e, st);
      if (kDebugMode) {
        print('[PurchaseNotifier] 구매 복원 실패: $e');
      }
    }
  }

  /// 상태 새로고침
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final info = await Purchases.getCustomerInfo();
      state = AsyncData(info);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Offerings 조회 Provider
@riverpod
// ignore: deprecated_member_use_from_same_package
Future<Offerings?> offerings(OfferingsRef ref) async {
  try {
    return await Purchases.getOfferings();
  } catch (e) {
    if (kDebugMode) {
      print('[offerings] 조회 실패: $e');
    }
    return null;
  }
}
