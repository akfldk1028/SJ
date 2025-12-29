/// # 파일 로거 서비스
///
/// AI API 호출 결과를 텍스트 파일로 저장합니다.
/// Flutter 웹에서도 동작하도록 JavaScript interop 사용.

import 'dart:convert';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// 파일 로거 (웹 전용)
class FileLogger {
  static final StringBuffer _buffer = StringBuffer();
  static bool _initialized = false;
  static String _currentDate = '';

  /// 초기화
  static void init() {
    if (_initialized) return;

    final now = DateTime.now();
    _currentDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    _buffer.writeln('═' * 80);
    _buffer.writeln('AI API 로그 - $_currentDate');
    _buffer.writeln('═' * 80);
    _buffer.writeln();

    _initialized = true;
    debugPrint('[FileLogger] 초기화 완료');
  }

  /// 로그 추가
  static void log(String content) {
    if (!_initialized) init();

    final now = DateTime.now();
    final timestamp =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    _buffer.writeln('[$timestamp] $content');

    // localStorage에도 저장 (브라우저 새로고침 대비)
    _saveToLocalStorage();
  }

  /// AI API 로그 추가 (구조화된 형식)
  static void logAiApi({
    required String provider,
    required String model,
    required String type,
    required bool success,
    String? requestSummary,
    String? response,
    Map<String, dynamic>? tokens,
    double? costUsd,
    int? processingTimeMs,
    String? error,
  }) {
    if (!_initialized) init();

    final now = DateTime.now();
    final timestamp =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final divider = '─' * 70;

    _buffer.writeln();
    _buffer.writeln('╔$divider╗');
    _buffer.writeln('║ [$timestamp] ${success ? "✅" : "❌"} $provider - $type');
    _buffer.writeln('╠$divider╣');
    _buffer.writeln('║ 모델: $model');

    if (tokens != null) {
      _buffer.writeln(
          '║ 토큰: prompt=${tokens['prompt']}, completion=${tokens['completion']}');
    }
    if (costUsd != null) {
      _buffer.writeln('║ 비용: \$${costUsd.toStringAsFixed(6)}');
    }
    if (processingTimeMs != null) {
      _buffer.writeln('║ 처리시간: ${processingTimeMs}ms');
    }
    if (requestSummary != null) {
      _buffer.writeln('║ 요청: $requestSummary');
    }

    if (success && response != null) {
      _buffer.writeln('╠$divider╣');
      _buffer.writeln('║ 응답:');

      // JSON 포맷팅
      try {
        final jsonData = jsonDecode(response);
        final formatted = const JsonEncoder.withIndent('  ').convert(jsonData);
        for (final line in formatted.split('\n')) {
          _buffer.writeln('║   $line');
        }
      } catch (e) {
        // JSON이 아니면 그냥 출력
        for (final line in response.split('\n')) {
          _buffer.writeln('║   $line');
        }
      }
    } else if (error != null) {
      _buffer.writeln('╠$divider╣');
      _buffer.writeln('║ ❌ 에러: $error');
    }

    _buffer.writeln('╚$divider╝');
    _buffer.writeln();

    // localStorage에 저장
    _saveToLocalStorage();

    debugPrint('[FileLogger] AI 로그 추가: $provider/$type');
  }

  /// localStorage에 저장
  static void _saveToLocalStorage() {
    try {
      html.window.localStorage['ai_log_$_currentDate'] = _buffer.toString();
    } catch (e) {
      debugPrint('[FileLogger] localStorage 저장 실패: $e');
    }
  }

  /// localStorage에서 복원
  static void restoreFromLocalStorage() {
    try {
      final stored = html.window.localStorage['ai_log_$_currentDate'];
      if (stored != null && stored.isNotEmpty) {
        _buffer.clear();
        _buffer.write(stored);
        _initialized = true;
        debugPrint('[FileLogger] localStorage에서 복원 완료');
      }
    } catch (e) {
      debugPrint('[FileLogger] localStorage 복원 실패: $e');
    }
  }

  /// 파일 다운로드 (브라우저에서)
  static void downloadLog() {
    if (_buffer.isEmpty) {
      debugPrint('[FileLogger] 다운로드할 로그 없음');
      return;
    }

    final content = _buffer.toString();
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'ai_log_$_currentDate.txt')
      ..click();

    html.Url.revokeObjectUrl(url);
    debugPrint('[FileLogger] 파일 다운로드 시작: ai_log_$_currentDate.txt');
  }

  /// 현재 로그 내용 반환
  static String getLogContent() {
    return _buffer.toString();
  }

  /// 로그 초기화
  static void clear() {
    _buffer.clear();
    _initialized = false;
    try {
      html.window.localStorage.remove('ai_log_$_currentDate');
    } catch (e) {
      // ignore
    }
    debugPrint('[FileLogger] 로그 초기화 완료');
  }

  /// 콘솔에 전체 로그 출력
  static void printAllLogs() {
    if (_buffer.isEmpty) {
      debugPrint('[FileLogger] 저장된 로그 없음');
      return;
    }

    print('\n' + '=' * 80);
    print('전체 AI API 로그');
    print('=' * 80);
    print(_buffer.toString());
    print('=' * 80 + '\n');
  }
}
