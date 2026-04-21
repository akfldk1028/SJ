/// In-App Purchase 설정 상수
///
/// RevenueCat 대시보드에서 발급받은 API 키 및
/// 상품/Entitlement ID 정의
import 'dart:io';

abstract class PurchaseConfig {
  // ── RevenueCat API Keys (대시보드에서 발급) ──
  // Android: Google Play Console 연동
  static const String revenueCatApiKeyAndroid = 'goog_DfwxpejDQNZHDxDNdLVPSWZVDvR';

  // iOS: App Store Connect 연동 (SaDam Life - com.clickaround.sadamlife)
  // RevenueCat 대시보드 → iOS App → Public API Key
  static const String revenueCatApiKeyIos = 'appl_mYfDDBjMoxgKYoaZLmTSUpUVxUR';

  // ── Entitlements ──
  /// 단일 통합 entitlement: 프리미엄 (광고 제거 + AI 무제한)
  static const String entitlementPremium = 'premium';

  // ── Product IDs (플랫폼별 분기) ──
  // Android: 기존 sadam_* (Play Store 등록 유지)
  // iOS: sadamlife_* (새 App Store 앱)
  static String get productDayPass =>
      Platform.isIOS ? 'sadamlife_day_pass' : 'sadam_day_pass';

  static String get productWeekPass =>
      Platform.isIOS ? 'sadamlife_week_pass' : 'sadam_week_pass';

  static String get productMonthly =>
      Platform.isIOS ? 'sadamlife_monthly' : 'sadam_monthly';

  // ── Quota ──
  static const int premiumDailyQuota = 1000000000; // 무제한
  static const int freeDailyQuota = 5000;
}
