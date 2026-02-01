import 'package:flutter/foundation.dart';

/// 대화 히스토리 요약 관리
/// 담당: Jina
///
/// 트리밍된 메시지에서 로컬로 핵심 내용을 추출하여
/// AI가 이전 대화 맥락을 유지할 수 있도록 요약 생성
///
/// - API 호출 없이 로컬에서 처리 (지연시간 0, 비용 0)
/// - user 메시지 → 질문/주제 추출
/// - model 메시지 → 사주 키워드 포함 문장 우선 추출
/// - 요약 최대 ~600자 (약 500토큰)
class ChatHistoryManager {
  /// 누적 요약 (이전 대화의 핵심 내용)
  String? _currentSummary;

  /// 최대 요약 길이 (자)
  static const int _maxSummaryLength = 600;

  /// 사주 관련 키워드 (우선 추출 대상)
  static const List<String> _sajuKeywords = [
    '운', '용신', '재물', '재운', '직장', '이직', '건강', '연애', '결혼',
    '정관', '편관', '정재', '편재', '정인', '편인', '식신', '상관',
    '비견', '겁재', '목', '화', '토', '금', '수',
    '일주', '일간', '월주', '년주', '시주', '대운', '세운',
    '궁합', '합', '충', '형', '파', '해',
  ];

  /// 현재 요약 내용
  String? get currentSummary => _currentSummary;

  /// 요약이 존재하는지 여부
  bool get hasSummary => _currentSummary != null && _currentSummary!.isNotEmpty;

  /// 트리밍된 메시지에서 요약 생성
  ///
  /// [removedMessages]: 윈도우 매니저가 제거한 메시지 리스트
  /// Gemini 포맷: {'role': 'user'/'model', 'parts': [{'text': '...'}]}
  void generateSummary(List<Map<String, dynamic>> removedMessages) {
    if (removedMessages.isEmpty) return;

    final userTopics = <String>[];
    final modelHighlights = <String>[];

    for (final msg in removedMessages) {
      final role = msg['role'] as String?;
      final text = _extractText(msg);
      if (text == null || text.isEmpty) continue;

      if (role == 'user') {
        final topic = _extractUserTopic(text);
        if (topic.isNotEmpty) {
          userTopics.add(topic);
        }
      } else if (role == 'model') {
        final highlight = _extractModelHighlight(text);
        if (highlight.isNotEmpty) {
          modelHighlights.add(highlight);
        }
      }
    }

    if (userTopics.isEmpty && modelHighlights.isEmpty) return;

    // 새 요약 구성
    final buffer = StringBuffer();

    if (userTopics.isNotEmpty) {
      buffer.write('사용자 질문: ');
      buffer.write(userTopics.join(', '));
    }

    if (modelHighlights.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write('주요 답변: ');
      buffer.write(modelHighlights.join(', '));
    }

    final newPart = buffer.toString();

    // 기존 요약과 합치기
    if (_currentSummary != null && _currentSummary!.isNotEmpty) {
      _currentSummary = '${_currentSummary!}\n$newPart';
    } else {
      _currentSummary = newPart;
    }

    // 길이 제한 트리밍
    _trimSummary();

    if (kDebugMode) {
      print('[ChatHistoryManager] 요약 생성: ${_currentSummary!.length}자');
    }
  }

  /// 세션 리셋 (새 세션 시작 시)
  void reset() {
    _currentSummary = null;
    if (kDebugMode) {
      print('[ChatHistoryManager] 요약 리셋');
    }
  }

  /// 세션 복원 시 기존 요약 복원
  void restoreSummary(String? summary) {
    _currentSummary = summary;
    if (kDebugMode && summary != null) {
      print('[ChatHistoryManager] 요약 복원: ${summary.length}자');
    }
  }

  /// 복원된 메시지가 많을 때 미리 요약 생성
  ///
  /// [messages]: 복원된 전체 메시지 리스트
  /// [windowSize]: 윈도우에 유지할 메시지 수
  void preGenerateSummaryIfNeeded(
    List<Map<String, dynamic>> messages, {
    int windowSize = 12,
  }) {
    if (messages.length <= windowSize) return;

    final removedPart = messages.sublist(0, messages.length - windowSize);
    generateSummary(removedPart);

    if (kDebugMode) {
      print('[ChatHistoryManager] 복원 시 사전 요약: ${messages.length}개 중 ${removedPart.length}개 요약');
    }
  }

  // --- Private helpers ---

  /// 메시지에서 텍스트 추출
  String? _extractText(Map<String, dynamic> msg) {
    final parts = msg['parts'] as List?;
    if (parts == null || parts.isEmpty) return null;
    final first = parts.first;
    if (first is Map) return first['text'] as String?;
    return null;
  }

  /// user 메시지에서 질문/주제 추출 (첫 문장 또는 80자)
  String _extractUserTopic(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return '';

    // 첫 문장 추출 (마침표, 물음표, 느낌표 기준)
    final sentenceEnd = RegExp(r'[.?!。？！]');
    final match = sentenceEnd.firstMatch(cleaned);

    String topic;
    if (match != null && match.end <= 80) {
      topic = cleaned.substring(0, match.end).trim();
    } else {
      // 80자 이내로 자르기
      topic = cleaned.length <= 80 ? cleaned : '${cleaned.substring(0, 77)}...';
    }

    return topic;
  }

  /// model 메시지에서 사주 키워드 포함 핵심 문장 추출
  String _extractModelHighlight(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return '';

    // 문장 단위로 분리
    final sentences = cleaned.split(RegExp(r'[.!?\n]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 5)
        .toList();

    if (sentences.isEmpty) {
      // 문장 분리 실패 시 앞 100자
      return cleaned.length <= 100 ? cleaned : '${cleaned.substring(0, 97)}...';
    }

    // 사주 키워드가 포함된 문장 우선
    final keywordSentences = <String>[];
    for (final sentence in sentences) {
      final hasKeyword = _sajuKeywords.any((kw) => sentence.contains(kw));
      if (hasKeyword) {
        keywordSentences.add(sentence);
      }
    }

    // 키워드 문장이 있으면 최대 2개, 없으면 첫 문장
    final selected = keywordSentences.isNotEmpty
        ? keywordSentences.take(2).toList()
        : [sentences.first];

    final result = selected.join(', ');
    return result.length <= 150 ? result : '${result.substring(0, 147)}...';
  }

  /// 요약 길이 제한 트리밍 (오래된 내용부터 제거)
  void _trimSummary() {
    if (_currentSummary == null) return;
    if (_currentSummary!.length <= _maxSummaryLength) return;

    // 줄 단위로 분리하여 최신 내용 유지
    final lines = _currentSummary!.split('\n');

    while (lines.join('\n').length > _maxSummaryLength && lines.length > 2) {
      lines.removeAt(0);
    }

    _currentSummary = lines.join('\n');

    // 그래도 길면 앞에서 자르기
    if (_currentSummary!.length > _maxSummaryLength) {
      _currentSummary = _currentSummary!.substring(
        _currentSummary!.length - _maxSummaryLength,
      );
    }
  }
}
