/// 광고 채팅 메시지 엔티티
///
/// 일반 ChatMessage를 확장하여 광고 정보 포함
/// AI 페르소나가 자연스럽게 전환하는 광고 메시지
///
/// 위젯 트리 최적화:
/// - immutable 객체로 불필요한 리빌드 방지
/// - copyWith으로 상태 변경 시 새 인스턴스 생성
library;

import '../../data/models/conversational_ad_model.dart';
import 'chat_message.dart';

/// 광고 채팅 메시지
///
/// 사용 예:
/// ```dart
/// final adMessage = AdChatMessage(
///   id: uuid.v4(),
///   sessionId: sessionId,
///   content: '광고 전환 메시지',
///   role: MessageRole.assistant,
///   createdAt: DateTime.now(),
///   adType: AdMessageType.tokenNearLimit,
///   transitionText: '허허, 말이 나온 김에...',
/// );
/// ```
class AdChatMessage extends ChatMessage {
  /// 광고 유형
  final AdMessageType adType;

  /// 페르소나 전환 텍스트 (AI가 생성한 자연스러운 문구)
  final String? transitionText;

  /// 광고 후 CTA 텍스트
  final String? ctaText;

  /// 보상형 광고 시 제공되는 토큰 수
  final int? rewardTokens;

  /// 광고 시청 완료 여부
  final bool adWatched;

  /// 광고 스킵 가능 여부
  final bool canSkip;

  const AdChatMessage({
    required super.id,
    required super.sessionId,
    required super.content,
    required super.role,
    required super.createdAt,
    super.status,
    super.tokensUsed,
    super.suggestedQuestions,
    required this.adType,
    this.transitionText,
    this.ctaText,
    this.rewardTokens,
    this.adWatched = false,
    this.canSkip = true,
  });

  /// 광고 메시지 여부
  bool get isAdMessage => true;

  /// 필수 광고 여부 (스킵 불가)
  bool get isRequired => adType == AdMessageType.tokenDepleted;

  /// 토큰 관련 광고 여부
  bool get isTokenRelated =>
      adType == AdMessageType.tokenNearLimit ||
      adType == AdMessageType.tokenDepleted;

  /// 보상형 광고 여부
  bool get isRewarded =>
      adType == AdMessageType.rewarded || rewardTokens != null && rewardTokens! > 0;

  @override
  AdChatMessage copyWith({
    String? id,
    String? sessionId,
    String? content,
    MessageRole? role,
    DateTime? createdAt,
    MessageStatus? status,
    int? tokensUsed,
    List<String>? suggestedQuestions,
    AdMessageType? adType,
    String? transitionText,
    String? ctaText,
    int? rewardTokens,
    bool? adWatched,
    bool? canSkip,
  }) {
    return AdChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      content: content ?? this.content,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      suggestedQuestions: suggestedQuestions ?? this.suggestedQuestions,
      adType: adType ?? this.adType,
      transitionText: transitionText ?? this.transitionText,
      ctaText: ctaText ?? this.ctaText,
      rewardTokens: rewardTokens ?? this.rewardTokens,
      adWatched: adWatched ?? this.adWatched,
      canSkip: canSkip ?? this.canSkip,
    );
  }

  /// 광고 시청 완료 처리
  AdChatMessage markAsWatched() {
    return copyWith(adWatched: true);
  }

  /// 일반 ChatMessage에서 광고 메시지 생성 (팩토리)
  factory AdChatMessage.fromChatMessage(
    ChatMessage message, {
    required AdMessageType adType,
    String? transitionText,
    String? ctaText,
    int? rewardTokens,
  }) {
    return AdChatMessage(
      id: message.id,
      sessionId: message.sessionId,
      content: message.content,
      role: message.role,
      createdAt: message.createdAt,
      status: message.status,
      tokensUsed: message.tokensUsed,
      suggestedQuestions: message.suggestedQuestions,
      adType: adType,
      transitionText: transitionText,
      ctaText: ctaText,
      rewardTokens: rewardTokens,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          adType == other.adType;

  @override
  int get hashCode => Object.hash(id, adType);
}

/// ChatMessage 확장: 광고 메시지 여부 체크
extension ChatMessageAdExtension on ChatMessage {
  /// 광고 메시지인지 확인
  bool get isAdMessage => this is AdChatMessage;

  /// AdChatMessage로 캐스팅 (안전)
  AdChatMessage? get asAdMessage => this is AdChatMessage ? this as AdChatMessage : null;
}
