import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/services/error_logging_service.dart';
import '../data/mutations/purchase_mutations.dart';
import '../purchase_config.dart';
import '../purchase_service.dart';

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
    // IAP 비활성화 상태면 에러 던져서 isPremium = false 처리
    if (!PurchaseService.instance.isAvailable) {
      if (kDebugMode) {
        print('[PurchaseNotifier] IAP 비활성화 상태 → isPremium = false');
      }
      throw Exception('IAP not available');
    }

    try {
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
    } catch (e) {
      if (kDebugMode) {
        print('[PurchaseNotifier] build() 실패: $e');
      }
      rethrow; // AsyncError 상태로 전환
    }
  }

  // ── Entitlement 체크 ──

  bool get isPremium {
    final info = state.valueOrNull;
    if (info == null) return _forcePremium; // 로딩 중이면 _forcePremium 따름

    // 1차: entitlement 체크 (구독 상품만 신뢰)
    // ⚠️ 비구독 시간제 상품(day_pass, week_pass)은 RevenueCat이
    //    만료 시점을 모르므로 entitlement.isActive를 신뢰하면 안 됨
    //    → 구매일+기간 계산으로만 판단 (3차 로직)
    final entitlement = info.entitlements.all[PurchaseConfig.entitlementPremium];
    if (entitlement?.isActive == true) {
      final pid = entitlement!.productIdentifier;
      // 비구독 시간제 상품이면 entitlement만으로 판단하지 않음
      final isTimeLimited = pid == PurchaseConfig.productDayPass ||
          pid == PurchaseConfig.productWeekPass;
      if (!isTimeLimited) {
        return true; // 월간 구독 등 → entitlement 신뢰
      }
      // 시간제 상품은 아래 3차 로직에서 구매일 기반으로 판단
    }

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
            print('[PurchaseNotifier] isPremium: $productId 활성 (만료: $expiresAt)');
          }
          return true;
        }
      }
    }

    // isPremium=false 로그는 build()에서 이미 출력하므로 여기선 생략
    return false;
  }

  // ── 파생 상태 ──

  /// 현재 활성 플랜의 만료 시각 (null = 프리미엄 아님 or 만료 정보 없음)
  DateTime? get expiresAt {
    final info = state.valueOrNull;
    if (info == null) return null;

    // 1차: entitlement 만료일 (월간 구독만 신뢰)
    // ⚠️ 시간제 상품은 isPremium과 동일하게 entitlement 무시
    final entitlement = info.entitlements.all[PurchaseConfig.entitlementPremium];
    if (entitlement?.isActive == true && entitlement!.expirationDate != null) {
      final pid = entitlement.productIdentifier;
      final isTimeLimited = pid == PurchaseConfig.productDayPass ||
          pid == PurchaseConfig.productWeekPass;
      if (!isTimeLimited) {
        return DateTime.tryParse(entitlement.expirationDate!);
      }
    }

    // 2차: 비구독 상품 (1일/1주 이용권) 만료 계산
    // entitlement가 active이지만 expirationDate가 없는 경우 (비구독 상품)
    // → 가장 최근 구매의 만료일 표시 (만료됐더라도 - sandbox 환경 대응)
    DateTime? latestExpiry;
    for (final tx in info.nonSubscriptionTransactions) {
      final productId = tx.productIdentifier;
      final purchaseDate = DateTime.tryParse(tx.purchaseDate);
      if (purchaseDate == null) continue;

      Duration? duration;
      if (productId == PurchaseConfig.productDayPass) {
        duration = const Duration(hours: 24);
      } else if (productId == PurchaseConfig.productWeekPass) {
        duration = const Duration(days: 7);
      }

      if (duration != null) {
        final expiry = purchaseDate.add(duration);
        // 아직 유효한 만료일 우선, 없으면 가장 최근 만료일이라도 사용
        if (latestExpiry == null || expiry.isAfter(latestExpiry)) {
          latestExpiry = expiry;
        }
      }
    }
    return latestExpiry;
  }

  /// 현재 활성 플랜 이름
  String? get activePlanName {
    if (!isPremium) return null;

    final info = state.valueOrNull;
    if (info == null) return null;

    // 월간 구독 체크
    final entitlement = info.entitlements.all[PurchaseConfig.entitlementPremium];
    if (entitlement?.isActive == true) {
      final pid = entitlement!.productIdentifier;
      if (pid == PurchaseConfig.productMonthly) return '월간 구독';
      if (pid == PurchaseConfig.productWeekPass) return '1주일 이용권';
      if (pid == PurchaseConfig.productDayPass) return '1일 이용권';
      return '프리미엄';
    }

    if (info.activeSubscriptions.contains(PurchaseConfig.productMonthly)) {
      return '월간 구독';
    }

    // 비구독 상품 체크
    final now = DateTime.now();
    for (final tx in info.nonSubscriptionTransactions) {
      final productId = tx.productIdentifier;
      final purchaseDate = DateTime.tryParse(tx.purchaseDate);
      if (purchaseDate == null) continue;

      Duration? duration;
      String? name;
      if (productId == PurchaseConfig.productDayPass) {
        duration = const Duration(hours: 24);
        name = '1일 이용권';
      } else if (productId == PurchaseConfig.productWeekPass) {
        duration = const Duration(days: 7);
        name = '1주일 이용권';
      }

      if (duration != null && now.isBefore(purchaseDate.add(duration))) {
        return name;
      }
    }

    if (_forcePremium) return '프리미엄';
    return null;
  }

  /// 만료 임박 여부 (24시간 이내, 아직 만료되지 않은 경우만)
  bool get isExpiringSoon {
    final expiry = expiresAt;
    if (expiry == null) return false;
    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative) return false; // 이미 만료됨
    return remaining.inHours < 24;
  }

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

      // 구매 직후 entitlement가 반영 안 된 경우 재시도 (최대 3회)
      if (info.entitlements.all[PurchaseConfig.entitlementPremium]?.isActive != true) {
        CustomerInfo? latestInfo;
        for (int i = 1; i <= 3; i++) {
          if (kDebugMode) {
            print('[PurchaseNotifier] entitlement 미반영 → ${i}초 후 재조회 ($i/3)...');
          }
          await Future.delayed(Duration(seconds: i));
          latestInfo = await Purchases.getCustomerInfo();

          if (latestInfo.entitlements.all[PurchaseConfig.entitlementPremium]?.isActive == true) {
            if (kDebugMode) {
              print('[PurchaseNotifier] 재조회 성공! entitlement 반영됨');
            }
            break;
          }
        }

        if (latestInfo != null) {
          state = AsyncData(latestInfo);

          // 3회 재시도 후에도 entitlement 미반영이면 구매 상품 ID로 강제 처리
          if (latestInfo.entitlements.all[PurchaseConfig.entitlementPremium]?.isActive != true) {
            final purchasedIds = latestInfo.allPurchasedProductIdentifiers;
            final hasPurchasedProduct = purchasedIds.contains(PurchaseConfig.productDayPass) ||
                purchasedIds.contains(PurchaseConfig.productWeekPass) ||
                purchasedIds.contains(PurchaseConfig.productMonthly);

            if (hasPurchasedProduct) {
              if (kDebugMode) {
                print('[PurchaseNotifier] entitlement 미반영이지만 구매 상품 확인됨 → 강제 프리미엄');
              }
              _forcePremium = true;

              // Supabase 로깅 - RevenueCat 설정 문제 추적용
              ErrorLoggingService.logError(
                operation: 'purchase_entitlement_mismatch',
                errorMessage: 'Entitlement 미반영 - 강제 프리미엄 적용됨',
                errorType: 'purchase_warning',
                sourceFile: 'purchase_provider.dart',
                extraData: {
                  'package_id': package.identifier,
                  'product_id': package.storeProduct.identifier,
                  'purchased_ids': purchasedIds.toList(),
                  'entitlements': latestInfo.entitlements.all.keys.toList(),
                },
              );
            }
          }
        }
      }
    } on PlatformException catch (e, st) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (kDebugMode) {
        print('[PurchaseNotifier] PlatformException: $e');
        print('[PurchaseNotifier] errorCode: $errorCode');
      }

      // Supabase 에러 로깅 (취소 제외)
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        ErrorLoggingService.logError(
          operation: 'purchase_package',
          errorMessage: e.toString(),
          errorType: 'purchase',
          errorCode: errorCode.name,
          sourceFile: 'purchase_provider.dart',
          extraData: {
            'package_id': package.identifier,
            'product_id': package.storeProduct.identifier,
          },
        );
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

      // Supabase 에러 로깅
      ErrorLoggingService.logError(
        operation: 'purchase_package',
        errorMessage: e.toString(),
        errorType: 'purchase_unknown',
        sourceFile: 'purchase_provider.dart',
        stackTrace: st.toString(),
        extraData: {
          'package_id': package.identifier,
        },
      );

      state = AsyncError(e, st);
    }
  }

  /// 구매 복원 (이전 상태 유지하며 복원)
  Future<void> restore() async {
    // 이전 상태 보존 (깜빡임 방지)
    final previousValue = state.valueOrNull;

    try {
      final info = await Purchases.restorePurchases();
      state = AsyncData(info);

      if (kDebugMode) {
        print('[PurchaseNotifier] 구매 복원 완료');
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('[PurchaseNotifier] 구매 복원 실패: $e');
      }

      // Supabase 에러 로깅
      ErrorLoggingService.logError(
        operation: 'restore_purchase',
        errorMessage: e.toString(),
        errorType: 'purchase_restore',
        sourceFile: 'purchase_provider.dart',
        stackTrace: st.toString(),
      );

      // 에러 시 이전 상태가 있으면 유지, 없으면 에러 상태
      if (previousValue != null) {
        state = AsyncData(previousValue);
      } else {
        state = AsyncError(e, st);
      }
    }
  }

  /// 상태 새로고침 (이전 상태 유지하며 백그라운드 갱신)
  Future<void> refresh() async {
    // IAP 비활성화 상태면 스킵
    if (!PurchaseService.instance.isAvailable) return;

    // 이전 상태 보존 (깜빡임 방지)
    final previousValue = state.valueOrNull;

    try {
      final info = await Purchases.getCustomerInfo();
      state = AsyncData(info);
      if (kDebugMode) {
        print('[PurchaseNotifier] refresh() 완료');
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('[PurchaseNotifier] refresh() 실패: $e');
      }
      // 에러 시 이전 상태가 있으면 유지, 없으면 에러 상태
      if (previousValue != null) {
        state = AsyncData(previousValue);
      } else {
        state = AsyncError(e, st);
      }
    }
  }

  /// IAP 사용 가능 여부 (외부에서 체크용)
  bool get isIapAvailable => PurchaseService.instance.isAvailable;
}

/// Offerings 조회 Provider
@riverpod
// ignore: deprecated_member_use_from_same_package
Future<Offerings?> offerings(OfferingsRef ref) async {
  // IAP 비활성화 상태면 null 반환
  if (!PurchaseService.instance.isAvailable) {
    if (kDebugMode) {
      print('[offerings] IAP 비활성화 → null 반환');
    }
    return null;
  }

  try {
    final result = await Purchases.getOfferings();
    if (kDebugMode) {
      final current = result.current;
      print('[offerings] current: ${current?.identifier}');
      print('[offerings] packages: ${current?.availablePackages.length}');
      for (final pkg in current?.availablePackages ?? []) {
        print('[offerings]   - ${pkg.identifier}: ${pkg.storeProduct.identifier} (${pkg.storeProduct.priceString})');
      }
    }
    return result;
  } catch (e) {
    if (kDebugMode) {
      print('[offerings] 조회 실패: $e');
    }
    return null;
  }
}
