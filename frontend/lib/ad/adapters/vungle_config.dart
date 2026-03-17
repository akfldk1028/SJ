/// Vungle (Liftoff Monetize) 설정
///
/// Liftoff Dashboard에서 발급받은 App ID 및 Placement Ref IDs
/// 현재 stub 상태 — 네이티브 SDK 브릿지 구현 후 활성화
library;

abstract class VungleConfig {
  // App ID
  static const String appId = '69b12ed23e8180318ca50c01';

  // Placement Ref IDs
  static const String interstitial = 'SADAM_INTERSTITIAL-8431750';
  static const String rewarded = 'SADAM_REWARDED-6562858';
  static const String banner = 'SADAM_BANNER-2556829';
  static const String native = 'SADAM_NATIVE-4930348';
}
