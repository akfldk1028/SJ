/// 광고 트리거 서비스
///
/// 토큰 사용량 및 메시지 수에 따라 광고 표시 시점 결정
/// 순수 함수로 구현하여 테스트 용이성 확보
library;

import '../../../../ad/ad_strategy.dart';
import '../models/conversational_ad_model.dart' show AdTriggerResult, AdMessageType;
import 'conversation_window_manager.dart' show TokenUsageInfo;

/// 광고 트리거 서비스
///
/// 사용 예:
/// ```dart
/// final result = AdTriggerService.checkTrigger(
///   tokenUsage: tokenUsageInfo,
///   messageCount: messages.length,
/// );
///
/// if (result != AdTriggerResult.none) {
///   // 광고 표시
/// }
/// ```
abstract class AdTriggerService {
  AdTriggerService._();

  // ═══════════════════════════════════════════════════════════════════════════
  // 토큰 보상 → AdStrategy에서 관리 (ad_strategy.dart에서 값 조정)
  // ═══════════════════════════════════════════════════════════════════════════

  static int get depletedRewardTokensVideo => AdStrategy.depletedRewardTokensVideo;
  static int get depletedRewardTokensNative => AdStrategy.depletedRewardTokensNative;
  static int get intervalClickRewardTokens => AdStrategy.intervalClickRewardTokens;

  /// 토큰 소진 시 기본 보상 토큰 (하위 호환)
  static int get depletedRewardTokens => AdStrategy.depletedRewardTokensVideo;

  // ═══════════════════════════════════════════════════════════════════════════
  // 트리거 설정 (내부용 - 변경 불필요)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 토큰 소진 임계값 (100% = 소진)
  static const double tokenDepletedThreshold = 1.0;

  /// 80% 경고 비활성화 (warningRewardTokens = 0)
  static const double tokenWarningThreshold = 0.8;
  static const int warningRewardTokens = 0;
  static const int impressionRewardTokens = 0;
  static const int tokenWarningCooldownMessages = 3;

  // ═══════════════════════════════════════════════════════════════════════════
  // 트리거 체크 메서드
  // ═══════════════════════════════════════════════════════════════════════════

  /// 통합 트리거 체크
  ///
  /// 토큰 기반 트리거를 우선 체크하고,
  /// 해당되지 않으면 메시지 간격 트리거 체크
  ///
  /// [tokenWarningOnCooldown]: 토큰 경고 스킵 후 쿨다운 중이면 true → 토큰 경고 억제
  /// [shownAdCount]: 이번 대화에서 이미 보여준 광고 수. maxCount 이상이면 인터벌 광고 차단.
  static AdTriggerResult checkTrigger({
    required TokenUsageInfo tokenUsage,
    required int messageCount,
    bool tokenWarningOnCooldown = false,
    int shownAdCount = 0,
    bool isPremium = false,
  }) {
    // 1. 토큰 기반 트리거 (우선순위 높음)
    final tokenTrigger = checkTokenTrigger(
      tokenUsage: tokenUsage,
      tokenWarningOnCooldown: tokenWarningOnCooldown,
    );
    if (tokenTrigger != AdTriggerResult.none) {
      // 광고 제거 구매자: 토큰 소진(100%) 보상형 광고만 허용
      // → 강제 광고 아님, 유저가 직접 선택해서 시청 → 토큰 충전
      // 토큰 경고(80%)는 차단 (강제성 있는 광고이므로)
      if (isPremium && tokenTrigger != AdTriggerResult.tokenDepleted) {
        return AdTriggerResult.none;
      }
      return tokenTrigger;
    }

    // 광고 제거 구매자 → 인터벌(강제) 광고 차단
    if (isPremium) return AdTriggerResult.none;

    // 2. 인터벌 광고 비활성화 (v28)
    // 인라인 ChatAdWidget이 4메시지마다 표시되므로 인터벌 AdNativeBubble 불필요.
    // 토큰 소진 시에만 AdNativeBubble 사용.
    return AdTriggerResult.none;
  }

  /// 토큰 기반 트리거 체크
  ///
  /// - 100%: tokenDepleted (필수 광고, 항상 발동)
  /// - 80% 이상: tokenNearLimit (선제적 광고 권유)
  ///   → 단, 스킵 후 쿨다운 중이면 억제 (AdMob 정책 준수)
  ///   → 쿨다운 끝나면 다시 발동 (사용자 압박 유지)
  static AdTriggerResult checkTokenTrigger({
    required TokenUsageInfo tokenUsage,
    bool tokenWarningOnCooldown = false,
  }) {
    // 토큰 100% 소진 (필수 - 항상 발동, 쿨다운 무시)
    if (tokenUsage.usageRate >= tokenDepletedThreshold) {
      return AdTriggerResult.tokenDepleted;
    }

    // 토큰 80% 이상 사용 (선제적)
    // warningRewardTokens = 0이면 80% 경고 완전 비활성화
    // → 보상 없는 rewarded ad 표시는 UX 저하 + AdMob 정책 위험
    if (tokenUsage.usageRate >= tokenWarningThreshold) {
      if (warningRewardTokens <= 0) {
        return AdTriggerResult.none;
      }
      if (tokenWarningOnCooldown) {
        return AdTriggerResult.none;
      }
      return AdTriggerResult.tokenNearLimit;
    }

    return AdTriggerResult.none;
  }

  /// 메시지 간격 트리거 체크
  ///
  /// AdStrategy 설정에 따라 N번째 메시지 후 광고 표시
  /// [shownAdCount]: 이번 대화에서 이미 보여준 인터벌 광고 수
  static AdTriggerResult checkIntervalTrigger({
    required int messageCount,
    int shownAdCount = 0,
  }) {
    // 최대 광고 수 도달 시 차단
    if (shownAdCount >= AdStrategy.inlineAdMaxCount) {
      return AdTriggerResult.none;
    }

    // 최소 메시지 수 미만이면 스킵
    if (messageCount < AdStrategy.inlineAdMinMessages) {
      return AdTriggerResult.none;
    }

    // 간격에 해당하면 광고 표시
    if (messageCount % AdStrategy.inlineAdMessageInterval == 0) {
      return AdTriggerResult.intervalAd;
    }

    return AdTriggerResult.none;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 유틸리티 메서드
  // ═══════════════════════════════════════════════════════════════════════════

  /// 트리거 결과를 AdMessageType으로 변환
  static AdMessageType? triggerToAdType(AdTriggerResult trigger) {
    return switch (trigger) {
      AdTriggerResult.tokenNearLimit => AdMessageType.tokenNearLimit,
      AdTriggerResult.tokenDepleted => AdMessageType.tokenDepleted,
      AdTriggerResult.intervalAd => AdMessageType.inlineInterval,
      AdTriggerResult.none => null,
    };
  }

  /// 트리거 결과에 따른 보상 토큰 수
  static int getRewardTokens(AdTriggerResult trigger) {
    return switch (trigger) {
      AdTriggerResult.tokenNearLimit => warningRewardTokens,
      AdTriggerResult.tokenDepleted => depletedRewardTokens,
      AdTriggerResult.intervalAd => impressionRewardTokens,
      AdTriggerResult.none => 0,
    };
  }

  /// 필수 광고 여부 (스킵 불가)
  static bool isRequired(AdTriggerResult trigger) {
    return trigger == AdTriggerResult.tokenDepleted;
  }

  /// 광고 표시 가능 여부
  ///
  /// 쿨다운, 일일 제한 등 고려
  static bool canShowAd({
    required AdTriggerResult trigger,
    required DateTime? lastAdShownAt,
    required int todayAdCount,
  }) {
    // 필수 광고는 항상 표시
    if (isRequired(trigger)) {
      return true;
    }

    // 쿨다운 체크 (인터벌 광고)
    if (lastAdShownAt != null) {
      const cooldown = Duration(seconds: AdStrategy.interstitialCooldownSeconds);
      if (DateTime.now().difference(lastAdShownAt) < cooldown) {
        return false;
      }
    }

    // 일일 제한 체크
    if (todayAdCount >= AdStrategy.interstitialDailyLimit) {
      return false;
    }

    return true;
  }
}
