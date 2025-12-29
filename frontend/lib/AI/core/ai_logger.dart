/// # AI 로그 서비스
///
/// ## 개요
/// GPT/Gemini API 호출 결과를 로컬에 저장하고 조회합니다.
/// Supabase 없이 로컬에서 바로 확인 가능!
///
/// ## 파일 위치
/// `frontend/lib/AI/core/ai_logger.dart`
///
/// ## 저장 방식
/// 1. **콘솔 출력**: 터미널/Chrome DevTools에서 바로 확인
/// 2. **Hive 저장**: 앱 내에서 조회 가능
///
/// ## 사용 예시
/// ```dart
/// // 초기화 (main.dart에서 한 번)
/// await AiLogger.init();
///
/// // 로그 저장 (ai_api_service에서)
/// await AiLogger.log(
///   provider: 'openai',
///   model: 'gpt-5.2',
///   type: 'saju_base',
///   request: {'messages': [...], 'temperature': 0.7},
///   response: response.content,
///   tokens: {'prompt': 1200, 'completion': 800},
///   costUsd: 0.032,
///   success: true,
/// );
///
/// // 최근 로그 조회
/// final logs = await AiLogger.getRecentLogs(10);
/// ```

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'file_logger.dart';

/// AI API 로그 데이터
class AiLogEntry {
  final String id;
  final DateTime timestamp;
  final String provider; // 'openai' | 'gemini'
  final String model;
  final String type; // 'saju_base' | 'daily_fortune' | 'chat'
  final Map<String, dynamic> request;
  final Map<String, dynamic>? response;
  final Map<String, dynamic>? tokens;
  final double? costUsd;
  final bool success;
  final String? error;

  AiLogEntry({
    required this.id,
    required this.timestamp,
    required this.provider,
    required this.model,
    required this.type,
    required this.request,
    this.response,
    this.tokens,
    this.costUsd,
    required this.success,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'provider': provider,
        'model': model,
        'type': type,
        'request': request,
        'response': response,
        'tokens': tokens,
        'cost_usd': costUsd,
        'success': success,
        'error': error,
      };

  factory AiLogEntry.fromJson(Map<String, dynamic> json) => AiLogEntry(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        provider: json['provider'] as String,
        model: json['model'] as String,
        type: json['type'] as String,
        request: json['request'] as Map<String, dynamic>,
        response: json['response'] as Map<String, dynamic>?,
        tokens: json['tokens'] as Map<String, dynamic>?,
        costUsd: (json['cost_usd'] as num?)?.toDouble(),
        success: json['success'] as bool,
        error: json['error'] as String?,
      );

  /// 콘솔 출력용 포맷
  String toPrettyString() {
    final buffer = StringBuffer();
    final divider = '═' * 60;
    final subDivider = '─' * 60;

    buffer.writeln();
    buffer.writeln(divider);
    buffer.writeln('🤖 AI API LOG [${success ? "✅ SUCCESS" : "❌ FAILED"}]');
    buffer.writeln(divider);
    buffer.writeln('📅 Time: $timestamp');
    buffer.writeln('🏷️  Provider: ${provider.toUpperCase()}');
    buffer.writeln('🔧 Model: $model');
    buffer.writeln('📝 Type: $type');
    buffer.writeln(subDivider);

    // Tokens & Cost
    if (tokens != null) {
      buffer.writeln(
          '📊 Tokens: prompt=${tokens!['prompt']}, completion=${tokens!['completion']}');
    }
    if (costUsd != null) {
      buffer.writeln('💰 Cost: \$${costUsd!.toStringAsFixed(6)}');
    }
    buffer.writeln(subDivider);

    // Request (messages 요약)
    buffer.writeln('📤 REQUEST:');
    final messages = request['messages'] as List?;
    if (messages != null && messages.isNotEmpty) {
      for (final msg in messages) {
        final role = msg['role'] as String?;
        final content = msg['content'] as String?;
        if (content != null) {
          final preview =
              content.length > 200 ? '${content.substring(0, 200)}...' : content;
          buffer.writeln('   [$role] $preview');
        }
      }
    }
    buffer.writeln(subDivider);

    // Response
    buffer.writeln('📥 RESPONSE:');
    if (success && response != null) {
      final jsonStr = const JsonEncoder.withIndent('  ').convert(response);
      // 너무 길면 자르기
      if (jsonStr.length > 2000) {
        buffer.writeln('${jsonStr.substring(0, 2000)}...');
        buffer.writeln('   (truncated, full response saved to Hive)');
      } else {
        buffer.writeln(jsonStr);
      }
    } else if (error != null) {
      buffer.writeln('   ❌ Error: $error');
    }

    buffer.writeln(divider);
    buffer.writeln();

    return buffer.toString();
  }
}

/// AI 로그 서비스 (싱글톤)
class AiLogger {
  static const String _boxName = 'ai_logs';
  static Box<String>? _box;

  /// 로그 레벨
  static const int _logLevelNone = 0;
  static const int _logLevelBasic = 1;
  static const int _logLevelDetail = 2;
  static const int _logLevelFull = 3;

  /// 현재 로그 레벨 (기본: 상세)
  static int _currentLogLevel = _logLevelDetail;

  /// 로그 레벨 설정
  static void setLogLevel(int level) {
    _currentLogLevel = level;
  }

  /// Hive Box 초기화 (main.dart에서 호출)
  static Future<void> init() async {
    if (_box != null && _box!.isOpen) return;

    try {
      _box = await Hive.openBox<String>(_boxName);
      debugPrint('[AiLogger] 초기화 완료. 저장된 로그: ${_box!.length}개');

      // FileLogger도 초기화
      if (kIsWeb) {
        FileLogger.init();
        FileLogger.restoreFromLocalStorage();
      }
    } catch (e) {
      debugPrint('[AiLogger] 초기화 실패: $e');
    }
  }

  /// 로그 저장 + 콘솔 출력
  static Future<void> log({
    required String provider,
    required String model,
    required String type,
    required Map<String, dynamic> request,
    Map<String, dynamic>? response,
    Map<String, dynamic>? tokens,
    double? costUsd,
    required bool success,
    String? error,
  }) async {
    final entry = AiLogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      provider: provider,
      model: model,
      type: type,
      request: request,
      response: response,
      tokens: tokens,
      costUsd: costUsd,
      success: success,
      error: error,
    );

    // 1. 콘솔 출력 (개발 모드에서만)
    if (kDebugMode) {
      debugPrint(entry.toPrettyString());
    }

    // 2. Hive 저장
    await _saveToHive(entry);

    // 3. 파일 로그 (웹에서만)
    if (kIsWeb) {
      FileLogger.logAiApi(
        provider: provider,
        model: model,
        type: type,
        success: success,
        requestSummary: _summarizeRequest(request),
        response: response != null ? jsonEncode(response) : null,
        tokens: tokens,
        costUsd: costUsd,
        error: error,
      );
    }
  }

  /// 요청 요약 생성
  static String _summarizeRequest(Map<String, dynamic> request) {
    final messages = request['messages'] as List?;
    if (messages == null || messages.isEmpty) {
      return '(empty request)';
    }

    final lastMessage = messages.last;
    final content = lastMessage['content'] as String? ?? '';
    if (content.length > 100) {
      return '${content.substring(0, 100)}...';
    }
    return content;
  }

  /// Hive에 저장
  static Future<void> _saveToHive(AiLogEntry entry) async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }

    try {
      // 키: timestamp_provider_type (정렬용)
      final key =
          '${entry.timestamp.toIso8601String()}_${entry.provider}_${entry.type}';
      await _box!.put(key, jsonEncode(entry.toJson()));
    } catch (e) {
      debugPrint('[AiLogger] 저장 실패: $e');
    }
  }

  /// 최근 로그 조회
  static Future<List<AiLogEntry>> getRecentLogs([int limit = 20]) async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }

    try {
      final keys = _box!.keys.toList()
        ..sort((a, b) => b.toString().compareTo(a.toString()));

      final logs = <AiLogEntry>[];
      for (final key in keys.take(limit)) {
        final json = _box!.get(key);
        if (json != null) {
          logs.add(AiLogEntry.fromJson(jsonDecode(json)));
        }
      }
      return logs;
    } catch (e) {
      debugPrint('[AiLogger] 조회 실패: $e');
      return [];
    }
  }

  /// 날짜별 로그 조회
  static Future<List<AiLogEntry>> getLogsByDate(DateTime date) async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }

    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final logs = <AiLogEntry>[];
      for (final key in _box!.keys) {
        if (key.toString().startsWith(dateStr)) {
          final json = _box!.get(key);
          if (json != null) {
            logs.add(AiLogEntry.fromJson(jsonDecode(json)));
          }
        }
      }
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return logs;
    } catch (e) {
      debugPrint('[AiLogger] 날짜별 조회 실패: $e');
      return [];
    }
  }

  /// Provider별 로그 조회
  static Future<List<AiLogEntry>> getLogsByProvider(String provider,
      [int limit = 20]) async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }

    try {
      final logs = <AiLogEntry>[];
      final keys = _box!.keys.toList()
        ..sort((a, b) => b.toString().compareTo(a.toString()));

      for (final key in keys) {
        if (key.toString().contains('_${provider}_')) {
          final json = _box!.get(key);
          if (json != null) {
            logs.add(AiLogEntry.fromJson(jsonDecode(json)));
            if (logs.length >= limit) break;
          }
        }
      }
      return logs;
    } catch (e) {
      debugPrint('[AiLogger] Provider별 조회 실패: $e');
      return [];
    }
  }

  /// 오래된 로그 삭제 (기본 7일)
  static Future<int> clearOldLogs([int daysToKeep = 7]) async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }

    final cutoff = DateTime.now().subtract(Duration(days: daysToKeep));
    int deleted = 0;

    try {
      final keysToDelete = <String>[];
      for (final key in _box!.keys) {
        final json = _box!.get(key);
        if (json != null) {
          final entry = AiLogEntry.fromJson(jsonDecode(json));
          if (entry.timestamp.isBefore(cutoff)) {
            keysToDelete.add(key.toString());
          }
        }
      }

      for (final key in keysToDelete) {
        await _box!.delete(key);
        deleted++;
      }

      debugPrint('[AiLogger] $deleted개 오래된 로그 삭제 완료');
      return deleted;
    } catch (e) {
      debugPrint('[AiLogger] 삭제 실패: $e');
      return 0;
    }
  }

  /// 모든 로그 삭제
  static Future<void> clearAllLogs() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }

    try {
      await _box!.clear();
      debugPrint('[AiLogger] 모든 로그 삭제 완료');
    } catch (e) {
      debugPrint('[AiLogger] 전체 삭제 실패: $e');
    }
  }

  /// 로그 개수 조회
  static int get logCount => _box?.length ?? 0;

  /// 특정 로그 상세 출력 (디버깅용)
  static Future<void> printLog(String id) async {
    final logs = await getRecentLogs(100);
    final log = logs.firstWhere(
      (l) => l.id == id,
      orElse: () => throw Exception('Log not found: $id'),
    );
    debugPrint(log.toPrettyString());
  }

  /// 모든 로그를 JSON 문자열로 내보내기
  static Future<String> exportAllLogs() async {
    final logs = await getRecentLogs(1000);
    return const JsonEncoder.withIndent('  ')
        .convert(logs.map((l) => l.toJson()).toList());
  }

  /// 모든 로그를 TEXT 형식으로 내보내기
  static Future<String> exportAllLogsAsText() async {
    final logs = await getRecentLogs(1000);
    final buffer = StringBuffer();

    buffer.writeln('═' * 80);
    buffer.writeln('AI API 로그 내보내기');
    buffer.writeln('생성 시각: ${DateTime.now().toIso8601String()}');
    buffer.writeln('총 로그 수: ${logs.length}개');
    buffer.writeln('═' * 80);
    buffer.writeln();

    for (final log in logs) {
      buffer.writeln(log.toPrettyString());
    }

    return buffer.toString();
  }

  /// 프로필 분석 전용 로그 (더 상세한 출력)
  static Future<void> logProfileAnalysis({
    required String profileId,
    required String profileName,
    required String analysisType, // 'saju_base' | 'daily_fortune' | 'ai_summary'
    required String provider,
    required String model,
    required bool success,
    String? content,
    Map<String, dynamic>? tokens,
    double? costUsd,
    int? processingTimeMs,
    String? error,
  }) async {
    final divider = '━' * 60;
    final now = DateTime.now();

    // 콘솔에 상세 출력
    if (kDebugMode && _currentLogLevel >= _logLevelBasic) {
      print('');
      print('┏$divider┓');
      print('┃ 🔮 프로필 사주 분석 로그                                      ┃');
      print('┣$divider┫');
      print('┃ 📅 시각: ${now.toIso8601String()}');
      print('┃ 👤 프로필: $profileName ($profileId)');
      print('┃ 📝 분석 유형: $analysisType');
      print('┃ 🏷️  제공자: $provider');
      print('┃ 🔧 모델: $model');
      print('┃ ${success ? "✅ 성공" : "❌ 실패"}');

      if (tokens != null) {
        print('┃ 📊 토큰: prompt=${tokens['prompt']}, completion=${tokens['completion']}');
      }
      if (costUsd != null) {
        print('┃ 💰 비용: \$${costUsd.toStringAsFixed(6)}');
      }
      if (processingTimeMs != null) {
        print('┃ ⏱️  처리시간: ${processingTimeMs}ms');
      }
      if (error != null) {
        print('┃ ❌ 에러: $error');
      }

      // 상세 레벨이면 응답 내용도 출력
      if (_currentLogLevel >= _logLevelDetail && content != null) {
        print('┣$divider┫');
        print('┃ 📥 응답 내용:');
        final lines = content.split('\n');
        for (final line in lines.take(20)) {
          final truncated = line.length > 55 ? '${line.substring(0, 55)}...' : line;
          print('┃   $truncated');
        }
        if (lines.length > 20) {
          print('┃   ... (${lines.length - 20}줄 더)');
        }
      }

      print('┗$divider┛');
      print('');
    }

    // Hive에도 저장
    await log(
      provider: provider,
      model: model,
      type: 'profile_$analysisType',
      request: {
        'profile_id': profileId,
        'profile_name': profileName,
        'analysis_type': analysisType,
      },
      response: content != null ? {'content': content} : null,
      tokens: tokens,
      costUsd: costUsd,
      success: success,
      error: error,
    );

    // Supabase에도 저장 (SQL로 바로 조회 가능)
    await _saveToSupabase(
      profileId: profileId,
      provider: provider,
      model: model,
      logType: analysisType,
      promptTokens: tokens?['prompt'] as int?,
      completionTokens: tokens?['completion'] as int?,
      cachedTokens: tokens?['cached'] as int?,
      totalCostUsd: costUsd,
      success: success,
      processingTimeMs: processingTimeMs,
      errorMessage: error,
      requestPreview: '$profileName ($analysisType)',
      responsePreview: content?.substring(0, content.length > 1000 ? 1000 : content.length),
    );
  }

  /// Supabase ai_api_logs 테이블에 저장
  static Future<void> _saveToSupabase({
    required String profileId,
    required String provider,
    required String model,
    required String logType,
    int? promptTokens,
    int? completionTokens,
    int? cachedTokens,
    double? totalCostUsd,
    required bool success,
    int? processingTimeMs,
    String? errorMessage,
    String? requestPreview,
    String? responsePreview,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('[AiLogger] Supabase 저장 스킵: 로그인 필요');
        return;
      }

      await Supabase.instance.client.from('ai_api_logs').insert({
        'user_id': user.id,
        'profile_id': profileId,
        'provider': provider,
        'model': model,
        'log_type': logType,
        'prompt_tokens': promptTokens,
        'completion_tokens': completionTokens,
        'cached_tokens': cachedTokens,
        'total_cost_usd': totalCostUsd,
        'success': success,
        'processing_time_ms': processingTimeMs,
        'error_message': errorMessage,
        'request_preview': requestPreview,
        'response_preview': responsePreview,
      });

      debugPrint('[AiLogger] Supabase 저장 완료: $logType');
    } catch (e) {
      debugPrint('[AiLogger] Supabase 저장 실패: $e');
    }
  }

  /// 오늘 로그 요약 출력
  static Future<void> printTodaySummary() async {
    final todayLogs = await getLogsByDate(DateTime.now());

    if (todayLogs.isEmpty) {
      debugPrint('[AiLogger] 오늘 로그 없음');
      return;
    }

    int totalRequests = todayLogs.length;
    int successCount = todayLogs.where((l) => l.success).length;
    double totalCost = todayLogs
        .map((l) => l.costUsd ?? 0)
        .fold(0.0, (a, b) => a + b);

    // Provider별 통계
    final providerStats = <String, int>{};
    for (final log in todayLogs) {
      providerStats[log.provider] = (providerStats[log.provider] ?? 0) + 1;
    }

    print('');
    print('┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓');
    print('┃ 📊 오늘의 AI API 로그 요약                                      ┃');
    print('┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫');
    print('┃ 총 요청: $totalRequests회');
    print('┃ 성공: $successCount회, 실패: ${totalRequests - successCount}회');
    print('┃ 총 비용: \$${totalCost.toStringAsFixed(6)}');
    print('┃ Provider별:');
    for (final entry in providerStats.entries) {
      print('┃   - ${entry.key}: ${entry.value}회');
    }
    print('┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛');
    print('');
  }
}
