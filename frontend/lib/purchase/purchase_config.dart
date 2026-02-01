/// In-App Purchase 설정 상수
///
/// RevenueCat 대시보드에서 발급받은 API 키 및
/// 상품/Entitlement ID 정의
abstract class PurchaseConfig {
  // ── RevenueCat API Keys (대시보드에서 발급) ──
  static const String revenueCatApiKeyAndroid = 'goog_xxx'; // TODO: 실제 키로 교체
  static const String revenueCatApiKeyIos = 'appl_xxx'; // TODO: 실제 키로 교체

  // ── Entitlements ──
  static const String entitlementAdFree = 'ad_free';
  static const String entitlementAiPremium = 'ai_premium';

  // ── Product IDs ──
  static const String productAdRemoval = 'sadam_ad_removal';
  static const String productAiPremium = 'sadam_ai_premium';
  static const String productCombo = 'sadam_combo';

  // ── Quota ──
  static const int premiumDailyQuota = 1000000000; // 무제한
  static const int freeDailyQuota = 20000;
}
