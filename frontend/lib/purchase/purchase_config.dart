/// In-App Purchase 설정 상수
///
/// RevenueCat 대시보드에서 발급받은 API 키 및
/// 상품/Entitlement ID 정의
abstract class PurchaseConfig {
  // ── RevenueCat API Keys (대시보드에서 발급) ──
  // Android: Google Play Console 연동
  static const String revenueCatApiKeyAndroid = 'goog_DfwxpejDQNZHDxDNdLVPSWZVDvR';

  // iOS: App Store Connect 연동
  // RevenueCat 대시보드 → iOS App → Public API Key
  static const String revenueCatApiKeyIos = 'appl_XVHtNdLmfGXiACGixJipPUkiAmf';

  // ── Entitlements ──
  /// 단일 통합 entitlement: 프리미엄 (광고 제거 + AI 무제한)
  static const String entitlementPremium = 'premium';

  // ── Product IDs ──
  /// 1일 이용권 (소모성/Consumable, 24시간)
  static const String productDayPass = 'sadam_day_pass';

  /// 1주일 이용권 (소모성/Consumable, 7일)
  static const String productWeekPass = 'sadam_week_pass';

  /// 월간 구독 (자동 갱신)
  static const String productMonthly = 'sadam_monthly';

  // ── Quota ──
  static const int premiumDailyQuota = 1000000000; // 무제한
  static const int freeDailyQuota = 20000;
}
