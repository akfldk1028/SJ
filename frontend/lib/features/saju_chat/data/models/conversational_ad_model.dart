/// 대화형 광고 모델
///
/// AI 페르소나가 자연스럽게 전환하는 광고 데이터 모델
/// 위젯 트리 최적화: immutable, copyWith 패턴
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversational_ad_model.freezed.dart';
part 'conversational_ad_model.g.dart';

/// 광고 메시지 유형
enum AdMessageType {
  /// 토큰 80% 도달 - 선제적 광고 권유
  tokenNearLimit('token_near_limit'),

  /// 토큰 100% 소진 - 필수 광고
  tokenDepleted('token_depleted'),

  /// N개 메시지 후 인라인 광고
  inlineInterval('inline_interval'),

  /// 보상형 광고 (토큰 충전)
  rewarded('rewarded'),

  /// 프리미엄 기능 해제용
  premiumUnlock('premium_unlock');

  final String value;
  const AdMessageType(this.value);

  static AdMessageType fromString(String value) {
    return AdMessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AdMessageType.inlineInterval,
    );
  }
}

/// 광고 트리거 결과
enum AdTriggerResult {
  /// 트리거 없음
  none,

  /// 토큰 80% 도달 (선제적 광고 권유)
  tokenNearLimit,

  /// 토큰 100% 소진 (필수 광고)
  tokenDepleted,

  /// 메시지 간격 광고
  intervalAd,
}

/// 대화형 광고 상태 모델
@freezed
abstract class ConversationalAdModel with _$ConversationalAdModel {
  const ConversationalAdModel._();

  const factory ConversationalAdModel({
    /// 광고 모드 활성화 여부
    @Default(false) bool isAdMode,

    /// 현재 토큰 사용률 (0.0 ~ 1.0)
    @Default(0.0) double tokenUsageRate,

    /// 광고 유형
    AdMessageType? adType,

    /// 페르소나 전환 문구 (AI 생성)
    String? transitionText,

    /// CTA(Call-to-Action) 문구
    String? ctaText,

    /// 광고 시청 완료 여부
    @Default(false) bool adWatched,

    /// 보상 토큰 수 (시청 완료 시)
    int? rewardedTokens,

    /// 광고 로드 상태
    @Default(AdLoadState.idle) AdLoadState loadState,

    /// 에러 메시지
    String? errorMessage,
  }) = _ConversationalAdModel;

  factory ConversationalAdModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationalAdModelFromJson(json);
}

/// 광고 로드 상태
enum AdLoadState {
  /// 대기 중
  idle,

  /// 로딩 중
  loading,

  /// 로드 완료
  loaded,

  /// 로드 실패
  failed,
}

// Note: TokenUsageInfo는 conversation_window_manager.dart에서 정의됨
// import '../../data/services/conversation_window_manager.dart' show TokenUsageInfo;
