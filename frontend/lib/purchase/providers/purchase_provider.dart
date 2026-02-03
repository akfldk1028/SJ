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
@Riverpod(keepAlive: true)
class PurchaseNotifier extends _$PurchaseNotifier {
  /// ITEM_ALREADY_OWNED 등 Google Play에서 구매 확인됐지만
  /// RevenueCat에 미반영된 경우 강제 프리미엄 처리
  bool _forcePremium = false;

  @override
  Future<CustomerInfo> build() async {
    final info = await Purchases.getCustomerInfo();
    if (kDebugMode) {
      print('[PurchaseNotifier] build() 초기 로드');
      print('[PurchaseNotifier] entitlements: ${info.entitlements.all.keys.toList()}');
      for (final entry in info.entitlements.all.entries) {
        print('[PurchaseNotifier] "${entry.key}": isActive=${entry.value.isActive}');
      }
      print('[PurchaseNotifier] activeSubscriptions: ${info.activeSubscriptions}');
      print('[PurchaseNotifier] allPurchasedProductIds: ${info.allPurchasedProductIdentifiers}');
    }
    return info;
  }

  // ── Entitlement 체크 ──

  bool get isPremium {
    // 0차: Google Play에서 ITEM_ALREADY_OWNED 확인된 경우
    if (_forcePremium) return true;

    final info = state.valueOrNull;
    if (info == null) return false;

    // 1차: entitlement 체크 (정상 케이스 - RevenueCat 대시보드에서 매핑된 경우)
    final entitlement = info.entitlements.all[PurchaseConfig.entitlementPremium];
    if (entitlement?.isActive == true) return true;

    // 2차: 활성 구독 체크 (월간 구독)
    if (info.activeSubscriptions.contains(PurchaseConfig.productMonthly)) {
      if (kDebugMode) {
        print('[PurchaseNotifier] isPremium: 월간 구독 활성 (fallback)');
      }
      return true;
    }

    // 3차: 비구독 상품 (1일/1주 이용권) - 구매 시점 + 기간으로 직접 체크
    final now = DateTime.now();
    for (final tx in info.nonSubscriptionTransactions) {
      final productId = tx.productIdentifier;
      // purchaseDate는 String ("yyyy-MM-ddTHH:mm:ssZ") → DateTime 파싱
      final purchaseDate = DateTime.tryParse(tx.purchaseDate);
      if (purchaseDate == null) continue;

      Duration? duration;
      if (productId == PurchaseConfig.productDayPass) {
        duration = const Duration(hours: 24);
      } else if (productId == PurchaseConfig.productWeekPass) {
        duration = const Duration(days: 7);
      }

      if (duration != null) {
        final expiresAt = purchaseDate.add(duration);
        if (now.isBefore(expiresAt)) {
          if (kDebugMode) {
            print('[PurchaseNotifier] isPremium: $productId 활성 (만료: $expiresAt) (fallback)');
          }
          return true;
        }
      }
    }

    if (kDebugMode) {
      print('[PurchaseNotifier] isPremium: false');
      print('[PurchaseNotifier] entitlements: ${info.entitlements.all.keys.toList()}');
      print('[PurchaseNotifier] activeSubscriptions: ${info.activeSubscriptions}');
      print('[PurchaseNotifier] nonSubscriptionTx: ${info.nonSubscriptionTransactions.length}개');
    }

    return false;
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

      if (kDebugMode) {
        print('[PurchaseNotifier] ===== 구매 결과 디버그 =====');
        print('[PurchaseNotifier] 구매 상품: ${package.identifier}');
        print('[PurchaseNotifier] 전체 entitlements: ${info.entitlements.all.keys.toList()}');
        for (final entry in info.entitlements.all.entries) {
          print('[PurchaseNotifier] entitlement "${entry.key}": isActive=${entry.value.isActive}, productId=${entry.value.productIdentifier}');
        }
        print('[PurchaseNotifier] activeSubscriptions: ${info.activeSubscriptions}');
        print('[PurchaseNotifier] allPurchasedProductIds: ${info.allPurchasedProductIdentifiers}');
        print('[PurchaseNotifier] premium entitlement: ${info.entitlements.all[PurchaseConfig.entitlementPremium]}');
        print('[PurchaseNotifier] isPremium 결과: ${info.entitlements.all[PurchaseConfig.entitlementPremium]?.isActive == true}');
        print('[PurchaseNotifier] =============================');
      }

      state = AsyncData(info);
      await PurchaseMutations.recordPurchase(info);

      // 구매 직후 entitlement가 반영 안 된 경우 재시도
      if (info.entitlements.all[PurchaseConfig.entitlementPremium]?.isActive != true) {
        if (kDebugMode) {
          print('[PurchaseNotifier] entitlement 미반영 → 1초 후 재조회...');
        }
        await Future.delayed(const Duration(seconds: 1));
        final refreshed = await Purchases.getCustomerInfo();
        if (kDebugMode) {
          print('[PurchaseNotifier] 재조회 entitlements: ${refreshed.entitlements.all.keys.toList()}');
          for (final entry in refreshed.entitlements.all.entries) {
            print('[PurchaseNotifier] 재조회 "${entry.key}": isActive=${entry.value.isActive}');
          }
          print('[PurchaseNotifier] 재조회 isPremium: ${refreshed.entitlements.all[PurchaseConfig.entitlementPremium]?.isActive == true}');
        }
        state = AsyncData(refreshed);
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (kDebugMode) {
        print('[PurchaseNotifier] PlatformException: $e');
        print('[PurchaseNotifier] errorCode: $errorCode');
      }
      if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        // 이미 구매한 상품 → Google Play가 확인함 → 프리미엄 강제 적용
        if (kDebugMode) {
          print('[PurchaseNotifier] ITEM_ALREADY_OWNED → 강제 프리미엄 적용');
        }
        _forcePremium = true;
        try {
          final restored = await Purchases.restorePurchases();
          state = AsyncData(restored);
        } catch (_) {
          state = AsyncData(await Purchases.getCustomerInfo());
        }
      } else if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        // 사용자가 취소한 경우 이전 상태로 복원
        state = AsyncData(await Purchases.getCustomerInfo());
      } else {
        state = AsyncError(e, StackTrace.current);
      }
    } catch (e, st) {
      // PlatformException 외의 모든 에러 캐치
      if (kDebugMode) {
        print('[PurchaseNotifier] 예상치 못한 에러: $e');
        print('[PurchaseNotifier] stackTrace: $st');
      }
      state = AsyncError(e, st);
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
