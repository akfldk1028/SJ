/// 광고 네트워크 공통 인터페이스
///
/// 모든 광고 네트워크(AdMob, Unity, Vungle, AdFit 등)가 구현하는 플러그인 패턴.
/// 새 네트워크 추가 = 이 인터페이스 구현 1개 + AdService 등록. 끝.
abstract class AdNetworkAdapter {
  /// 네트워크 식별자 (로그용)
  String get name;

  /// SDK 초기화 (앱 시작 시 1회)
  Future<void> initialize();

  // ==================== Interstitial ====================

  /// 전면 광고 로드 시작. 로드 완료는 [isInterstitialLoaded]로 확인.
  Future<bool> loadInterstitial();

  /// 전면 광고 표시. [onDismissed]는 광고 닫힌 후 호출.
  Future<bool> showInterstitial({void Function()? onDismissed, String? screen});

  /// 전면 광고 로드 완료 여부
  bool get isInterstitialLoaded;

  // ==================== Rewarded ====================

  /// 보상형 광고 로드 시작. 로드 완료는 [isRewardedLoaded]로 확인.
  Future<bool> loadRewarded();

  /// 보상형 광고 표시. 보상 획득 시 [onRewarded](amount, type) 호출.
  Future<bool> showRewarded({
    required void Function(int amount, String type) onRewarded,
    String? screen,
  });

  /// 보상형 광고 로드 완료 여부
  bool get isRewardedLoaded;

  // ==================== Lifecycle ====================

  /// 리소스 해제
  void dispose();
}
