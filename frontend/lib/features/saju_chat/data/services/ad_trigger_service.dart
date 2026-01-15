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
  // 토큰 기반 트리거 설정
  // ═══════════════════════════════════════════════════════════════════════════

  /// 토큰 경고 임계값 (80%)
  static const double tokenWarningThreshold = 0.8;

  /// 토큰 소진 임계값 (100%)
  static const double tokenDepletedThreshold = 1.0;

  /// 토큰 경고 시 제공되는 보상 토큰 (광고 시청 시)
  static const int warningRewardTokens = 5000;

  /// 토큰 소진 시 제공되는 보상 토큰 (광고 시청 시)
  static const int depletedRewardTokens = 10000;

  // ═══════════════════════════════════════════════════════════════════════════
  // 트리거 체크 메서드
  // ═══════════════════════════════════════════════════════════════════════════

  /// 통합 트리거 체크
  ///
  /// 토큰 기반 트리거를 우선 체크하고,
  /// 해당되지 않으면 메시지 간격 트리거 체크
  static AdTriggerResult checkTrigger({
    required TokenUsageInfo tokenUsage,
    required int messageCount,
  }) {
    // 1. 토큰 기반 트리거 (우선순위 높음)
    final tokenTrigger = checkTokenTrigger(tokenUsage: tokenUsage);
    if (tokenTrigger != AdTriggerResult.none) {
      return tokenTrigger;
    }

    // 2. 메시지 간격 트리거
    return checkIntervalTrigger(messageCount: messageCount);
  }

  /// 토큰 기반 트리거 체크
  ///
  /// - 80% 이상: tokenNearLimit (선제적 광고 권유)
  /// - 100%: tokenDepleted (필수 광고)
  static AdTriggerResult checkTokenTrigger({
    required TokenUsageInfo tokenUsage,
  }) {
    // 토큰 100% 소진 (필수)
    if (tokenUsage.usageRate >= tokenDepletedThreshold) {
      return AdTriggerResult.tokenDepleted;
    }

    // 토큰 80% 이상 사용 (선제적)
    if (tokenUsage.usageRate >= tokenWarningThreshold) {
      return AdTriggerResult.tokenNearLimit;
    }

    return AdTriggerResult.none;
  }

  /// 메시지 간격 트리거 체크
  ///
  /// AdStrategy 설정에 따라 N번째 메시지 후 광고 표시
  static AdTriggerResult checkIntervalTrigger({
    required int messageCount,
  }) {
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
      AdTriggerResult.intervalAd => 0,
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
