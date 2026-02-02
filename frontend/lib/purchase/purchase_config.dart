/// In-App Purchase 설정 상수
///
/// RevenueCat 대시보드에서 발급받은 API 키 및
/// 상품/Entitlement ID 정의
abstract class PurchaseConfig {
  // ── RevenueCat API Keys (대시보드에서 발급) ──
  static const String revenueCatApiKeyAndroid = 'goog_xxx'; // TODO: 실제 키로 교체
  static const String revenueCatApiKeyIos = 'appl_xxx'; // TODO: 실제 키로 교체

  // ── Entitlements ──
  /// 단일 통합 entitlement: 프리미엄 (광고 제거 + AI 무제한)
  static const String entitlementPremium = 'premium';

  // ── Product IDs ──
  /// 1일 이용권 (비소모성, 24시간)
  static const String productDayPass = 'sadam_day_pass';

  /// 1주일 이용권 (비소모성, 7일)
  static const String productWeekPass = 'sadam_week_pass';

  /// 월간 구독 (자동 갱신)
  static const String productMonthly = 'sadam_monthly';

  // ── Quota ──
  static const int premiumDailyQuota = 1000000000; // 무제한
  static const int freeDailyQuota = 20000;
}
