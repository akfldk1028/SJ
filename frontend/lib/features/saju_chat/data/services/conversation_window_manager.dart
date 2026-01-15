import 'package:flutter/foundation.dart';
import 'token_counter.dart';

/// 대화 윈도우 관리 결과
class WindowedConversation {
  /// 토큰 제한에 맞게 트리밍된 메시지
  final List<Map<String, dynamic>> messages;

  /// 제거된 메시지 수
  final int removedCount;

  /// 현재 총 토큰 수 (추정)
  final int estimatedTokens;

  /// 트리밍 발생 여부
  final bool wasTrimmed;

  /// 요약된 컨텍스트 (있는 경우)
  final String? summarizedContext;

  const WindowedConversation({
    required this.messages,
    required this.removedCount,
    required this.estimatedTokens,
    required this.wasTrimmed,
    this.summarizedContext,
  });
}

/// 대화 윈도우 관리자
///
/// 토큰 제한에 맞게 대화 히스토리를 관리
/// - 슬라이딩 윈도우: 최근 메시지 우선 유지
/// - 시스템 프롬프트는 항상 포함
/// - 오래된 메시지는 제거 (추후 요약 기능 추가 가능)
class ConversationWindowManager {
  /// 최대 입력 토큰 (기본값)
  final int maxInputTokens;

  /// 최소 유지 메시지 수 (user + assistant 쌍)
  final int minMessagePairs;

  /// 시스템 프롬프트
  String? _systemPrompt;
  int _systemPromptTokens = 0;

  ConversationWindowManager({
    this.maxInputTokens = TokenCounter.defaultMaxInputTokens,
    this.minMessagePairs = 3, // 최소 3쌍 (6개 메시지) 유지
  });

  /// 시스템 프롬프트 설정
  void setSystemPrompt(String? prompt) {
    _systemPrompt = prompt;
    _systemPromptTokens = TokenCounter.estimateSystemPromptTokens(prompt);

    if (kDebugMode) {
      print('[ConversationWindow] 시스템 프롬프트 토큰: $_systemPromptTokens');
    }
  }

  /// 대화 히스토리를 토큰 제한에 맞게 윈도우잉
  ///
  /// [messages]: 전체 대화 히스토리 (user/model 교대)
  /// [newMessageTokens]: 새로 추가될 메시지의 토큰 수 (추정)
  ///
  /// 반환: 토큰 제한에 맞게 트리밍된 메시지 리스트
  WindowedConversation windowMessages(
    List<Map<String, dynamic>> messages, {
    int newMessageTokens = 0,
  }) {
    if (messages.isEmpty) {
      return WindowedConversation(
        messages: messages,
        removedCount: 0,
        estimatedTokens: _systemPromptTokens + newMessageTokens,
        wasTrimmed: false,
      );
    }

    // 사용 가능한 토큰 계산
    final availableTokens = maxInputTokens -
        TokenCounter.safetyMargin -
        _systemPromptTokens -
        newMessageTokens;

    if (availableTokens <= 0) {
      // 시스템 프롬프트 + 새 메시지만으로도 초과
      if (kDebugMode) {
        print('[ConversationWindow] 경고: 토큰 한도 매우 부족');
      }
      return WindowedConversation(
        messages: [],
        removedCount: messages.length,
        estimatedTokens: _systemPromptTokens + newMessageTokens,
        wasTrimmed: true,
      );
    }

    // 뒤에서부터 (최신 메시지부터) 토큰 계산하며 포함
    final resultMessages = <Map<String, dynamic>>[];
    int currentTokens = 0;
    int includedCount = 0;

    // 역순으로 순회 (최신 → 오래된 순)
    for (int i = messages.length - 1; i >= 0; i--) {
      final message = messages[i];
      final messageTokens = _estimateMessageTokens(message);

      // 토큰 한도 체크
      if (currentTokens + messageTokens > availableTokens) {
        // 최소 메시지 수 확보 못했으면 계속 포함
        if (includedCount < minMessagePairs * 2) {
          resultMessages.insert(0, message);
          currentTokens += messageTokens;
          includedCount++;
          continue;
        }
        // 한도 초과, 여기서 중단
        break;
      }

      resultMessages.insert(0, message);
      currentTokens += messageTokens;
      includedCount++;
    }

    final removedCount = messages.length - resultMessages.length;
    final wasTrimmed = removedCount > 0;

    if (kDebugMode && wasTrimmed) {
      print('[ConversationWindow] 트리밍: $removedCount개 메시지 제거');
      print('[ConversationWindow] 유지: ${resultMessages.length}개, 토큰: $currentTokens');
    }

    return WindowedConversation(
      messages: resultMessages,
      removedCount: removedCount,
      estimatedTokens: currentTokens + _systemPromptTokens + newMessageTokens,
      wasTrimmed: wasTrimmed,
    );
  }

  /// 개별 메시지 토큰 추정
  int _estimateMessageTokens(Map<String, dynamic> message) {
    int tokens = 4; // role 오버헤드

    final parts = message['parts'] as List?;
    if (parts != null) {
      for (final part in parts) {
        if (part is Map && part['text'] != null) {
          tokens += TokenCounter.estimateTokens(part['text'] as String);
        }
      }
    }

    return tokens;
  }

  /// 현재 대화의 토큰 상태 정보
  TokenUsageInfo getTokenUsageInfo(List<Map<String, dynamic>> messages) {
    final historyTokens = TokenCounter.estimateMessagesTokens(messages);
    final totalUsed = _systemPromptTokens + historyTokens;
    final remaining = maxInputTokens - totalUsed - TokenCounter.safetyMargin;

    return TokenUsageInfo(
      systemPromptTokens: _systemPromptTokens,
      historyTokens: historyTokens,
      totalUsed: totalUsed,
      maxTokens: maxInputTokens,
      remaining: remaining,
      usagePercent: (totalUsed / maxInputTokens * 100).round(),
    );
  }
}

/// 토큰 사용량 정보
class TokenUsageInfo {
  final int systemPromptTokens;
  final int historyTokens;
  final int totalUsed;
  final int maxTokens;
  final int remaining;
  final int usagePercent;

  const TokenUsageInfo({
    required this.systemPromptTokens,
    required this.historyTokens,
    required this.totalUsed,
    required this.maxTokens,
    required this.remaining,
    required this.usagePercent,
  });

  /// 사용률 (0.0 ~ 1.0) - ad_trigger_service 호환용
  double get usageRate => maxTokens > 0 ? totalUsed / maxTokens : 0.0;

  bool get isNearLimit => usagePercent >= 80;
  bool get isOverLimit => remaining <= 0;
  bool get isDepleted => usageRate >= 1.0;

  @override
  String toString() {
    return 'TokenUsage: $totalUsed/$maxTokens ($usagePercent%), remaining: $remaining';
  }
}
