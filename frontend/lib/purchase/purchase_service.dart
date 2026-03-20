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
  bool _available = false; // IAP 사용 가능 여부

  /// IAP 사용 가능 여부 (API 키가 설정되어 있고 초기화 성공)
  bool get isAvailable => _initialized && _available;

  /// RevenueCat SDK 초기화
  ///
  /// 모바일 전용 (Web에서는 호출하지 않음)
  /// API 키가 없으면 초기화 스킵 (iOS 빌드 시 키 미설정 대응)
  Future<void> initialize() async {
    if (_initialized) return;

    final apiKey = Platform.isIOS
        ? PurchaseConfig.revenueCatApiKeyIos
        : PurchaseConfig.revenueCatApiKeyAndroid;

    // API 키가 없거나 더미값이면 초기화 스킵
    if (apiKey.isEmpty || apiKey.startsWith('appl_xxx') || apiKey.startsWith('goog_xxx')) {
      _initialized = true;
      _available = false;
      if (kDebugMode) {
        print('[PurchaseService] API 키 미설정 → IAP 비활성화 (${Platform.isIOS ? 'iOS' : 'Android'})');
      }
      return;
    }

    try {
      await Purchases.configure(PurchasesConfiguration(apiKey));

      // Supabase user ID와 RevenueCat user ID 동기화
      // 첫 설치 시 여기서는 userId가 null일 수 있음
      // → splash의 ensureAuthenticated() 후 syncUserId() 재호출
      final userId = SupabaseService.currentUserId;
      if (userId != null) {
        await Purchases.logIn(userId);
      }

      _initialized = true;
      _available = true;

      if (kDebugMode) {
        print('[PurchaseService] RevenueCat 초기화 완료 (userId: $userId)');
      }
    } catch (e) {
      _initialized = true;
      _available = false;
      if (kDebugMode) {
        print('[PurchaseService] RevenueCat 초기화 실패 → IAP 비활성화: $e');
      }
    }
  }

  /// Supabase 인증 후 RevenueCat user ID 동기화
  ///
  /// splash에서 ensureAuthenticated() 성공 후 호출.
  /// 첫 설치 시 initialize()에서 userId=null로 스킵된 경우 여기서 보정.
  Future<void> syncUserId() async {
    if (!_available) return;

    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    try {
      final info = await Purchases.getCustomerInfo();
      final currentId = info.originalAppUserId;

      // 이미 동기화됨 (anonymous가 아님)
      if (!currentId.startsWith('\$RCAnonymousID')) return;

      await Purchases.logIn(userId);
      if (kDebugMode) {
        print('[PurchaseService] syncUserId: $currentId → $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[PurchaseService] syncUserId 실패: $e');
      }
    }
  }
}
