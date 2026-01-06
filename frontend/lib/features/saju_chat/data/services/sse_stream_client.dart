import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// SSE (Server-Sent Events) 스트림 클라이언트
///
/// Gemini Edge Function의 실시간 스트리밍 응답 처리
/// - Web/Mobile 플랫폼별 최적화
/// - 청크 단위 텍스트 yield
/// - 토큰 사용량 추적
///
/// Web 플랫폼 제한사항:
/// Flutter Web에서 Dio는 XMLHttpRequest를 사용하므로 스트리밍이 버퍼링됩니다.
/// [simulateStreamingOnWeb]을 true로 설정하면 버퍼링된 응답을 받은 후
/// 클라이언트 측에서 타이핑 효과를 시뮬레이션합니다.
class SseStreamClient {
  final Dio _dio;

  /// Web 플랫폼에서 시뮬레이션 스트리밍 활성화
  /// true: 버퍼링된 응답을 받은 후 타이핑 효과 적용
  /// false: 원본 스트리밍 그대로 사용 (버퍼링 발생)
  final bool simulateStreamingOnWeb;

  /// 시뮬레이션 스트리밍 지연 시간 (글자당)
  final Duration simulatedCharDelay;

  /// 청크 수신 디버그 콜백 (테스트용)
  void Function(int chunkIndex, String text)? onChunkReceived;

  SseStreamClient(
    this._dio, {
    this.simulateStreamingOnWeb = true,
    this.simulatedCharDelay = const Duration(milliseconds: 8),
  });

  /// SSE 스트림 요청 및 텍스트 청크 yield
  ///
  /// [url] - 요청 URL
  /// [data] - POST body
  /// [headers] - 추가 헤더
  ///
  /// Returns: 누적된 전체 텍스트를 yield하는 스트림
  Stream<SseChunk> streamRequest({
    required String url,
    required Map<String, dynamic> data,
    Map<String, String>? headers,
  }) async* {
    final fullContent = StringBuffer();
    String sseBuffer = '';
    int chunkCount = 0;

    // 토큰 정보 (완료 시)
    int? promptTokens;
    int? completionTokens;
    int? totalTokens;
    String? finishReason;

    try {
      final response = await _dio.post<ResponseBody>(
        url,
        data: data,
        options: Options(
          headers: {
            'Accept': 'text/event-stream',
            // Cache-Control 제거 - CORS preflight에서 차단됨
            // Edge Function 응답에서 Cache-Control: no-cache 설정됨
            ...?headers,
          },
          responseType: ResponseType.stream,
          // 중요: receiveTimeout을 길게 설정 (스트리밍 중 타임아웃 방지)
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      if (response.data == null) {
        throw SseException('스트리밍 응답이 비어있습니다');
      }

      if (kDebugMode) {
        print('[SSE] 스트림 연결 성공, 청크 수신 시작...');
      }

      await for (final chunk in response.data!.stream) {
        final decoded = utf8.decode(chunk);
        sseBuffer += decoded;

        // 디버그: 네트워크 청크 수신 확인
        if (kDebugMode && chunkCount < 3) {
          print('[SSE] 네트워크 청크 #${chunkCount + 1}: ${decoded.length}바이트');
        }

        // 완전한 SSE 이벤트 파싱 (\n\n으로 구분)
        while (sseBuffer.contains('\n\n')) {
          final eventEnd = sseBuffer.indexOf('\n\n');
          final event = sseBuffer.substring(0, eventEnd);
          sseBuffer = sseBuffer.substring(eventEnd + 2);

          // data: 접두사 파싱
          if (event.startsWith('data: ')) {
            final jsonStr = event.substring(6).trim();
            if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

            try {
              final eventData = jsonDecode(jsonStr) as Map<String, dynamic>;

              // 텍스트 청크 처리
              if (eventData.containsKey('text')) {
                final text = eventData['text'] as String;
                if (text.isNotEmpty) {
                  chunkCount++;
                  fullContent.write(text);

                  // 콜백 호출 (테스트용)
                  onChunkReceived?.call(chunkCount, text);

                  if (kDebugMode && chunkCount <= 5) {
                    print('[SSE] 청크 #$chunkCount: +${text.length}자 (총 ${fullContent.length}자)');
                  }

                  yield SseChunk(
                    accumulatedText: fullContent.toString(),
                    deltaText: text,
                    chunkIndex: chunkCount,
                    isDone: false,
                  );
                }
              }

              // 완료 및 토큰 정보
              if (eventData['done'] == true) {
                final usage = eventData['usage'] as Map<String, dynamic>?;
                if (usage != null) {
                  promptTokens = usage['prompt_tokens'] as int?;
                  completionTokens = usage['completion_tokens'] as int?;
                  totalTokens = usage['total_tokens'] as int?;
                }
                finishReason = eventData['finish_reason'] as String?;
              }
            } catch (e) {
              if (kDebugMode) {
                print('[SSE] 파싱 오류: $e');
              }
            }
          }
        }
      }

      // 최종 완료 청크 (토큰 정보 포함)
      yield SseChunk(
        accumulatedText: fullContent.toString(),
        deltaText: '',
        chunkIndex: chunkCount,
        isDone: true,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        totalTokens: totalTokens,
        finishReason: finishReason,
      );

      if (kDebugMode) {
        print('[SSE] 스트림 완료: ${fullContent.length}자, 청크: $chunkCount, 토큰: $totalTokens');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[SSE] Dio 에러: ${e.message}');
      }
      throw SseException('SSE 연결 오류: ${e.message}', original: e);
    }
  }

  /// Web 플랫폼용 시뮬레이션 스트리밍
  ///
  /// 서버 응답을 모두 받은 후 클라이언트에서 타이핑 효과를 시뮬레이션
  /// [streamRequest]가 버퍼링되는 경우 자동으로 이 메서드 사용
  Stream<SseChunk> streamRequestWithSimulation({
    required String url,
    required Map<String, dynamic> data,
    Map<String, String>? headers,
  }) async* {
    // Web 플랫폼에서 시뮬레이션 스트리밍 사용
    if (kIsWeb && simulateStreamingOnWeb) {
      yield* _simulatedStream(url: url, data: data, headers: headers);
      return;
    }

    // 모바일/데스크톱: 기본 스트리밍
    yield* streamRequest(url: url, data: data, headers: headers);
  }

  /// 시뮬레이션 스트리밍 구현 (Web용)
  Stream<SseChunk> _simulatedStream({
    required String url,
    required Map<String, dynamic> data,
    Map<String, String>? headers,
  }) async* {
    if (kDebugMode) {
      print('[SSE] Web 시뮬레이션 모드: 응답 수집 중...');
    }

    // 모든 청크 수집
    final chunks = <SseChunk>[];
    await for (final chunk in streamRequest(url: url, data: data, headers: headers)) {
      chunks.add(chunk);
    }

    if (chunks.isEmpty) return;

    // 마지막 청크 (완료 정보)
    final lastChunk = chunks.last;
    final fullText = lastChunk.accumulatedText;

    if (fullText.isEmpty) {
      yield lastChunk;
      return;
    }

    if (kDebugMode) {
      print('[SSE] Web 시뮬레이션: ${fullText.length}자 타이핑 효과 시작');
    }

    // 타이핑 효과 시뮬레이션 (단어 단위로 속도 향상)
    final words = fullText.split(' ');
    final buffer = StringBuffer();
    int chunkIndex = 0;

    for (int i = 0; i < words.length; i++) {
      if (i > 0) buffer.write(' ');
      buffer.write(words[i]);
      chunkIndex++;

      yield SseChunk(
        accumulatedText: buffer.toString(),
        deltaText: i > 0 ? ' ${words[i]}' : words[i],
        chunkIndex: chunkIndex,
        isDone: false,
      );

      // 단어 단위 지연 (더 빠른 속도)
      await Future.delayed(simulatedCharDelay * 3);
    }

    // 완료 청크 (토큰 정보 포함)
    yield SseChunk(
      accumulatedText: fullText,
      deltaText: '',
      chunkIndex: chunkIndex,
      isDone: true,
      promptTokens: lastChunk.promptTokens,
      completionTokens: lastChunk.completionTokens,
      totalTokens: lastChunk.totalTokens,
      finishReason: lastChunk.finishReason,
    );

    if (kDebugMode) {
      print('[SSE] Web 시뮬레이션 완료');
    }
  }
}

/// SSE 청크 데이터
class SseChunk {
  /// 누적된 전체 텍스트 (UI 표시용)
  final String accumulatedText;

  /// 이번 청크에서 추가된 텍스트 (델타)
  final String deltaText;

  /// 청크 인덱스 (1부터 시작)
  final int chunkIndex;

  /// 스트림 완료 여부
  final bool isDone;

  /// 프롬프트 토큰 (완료 시에만)
  final int? promptTokens;

  /// 완성 토큰 (완료 시에만)
  final int? completionTokens;

  /// 총 토큰 (완료 시에만)
  final int? totalTokens;

  /// 완료 사유
  final String? finishReason;

  const SseChunk({
    required this.accumulatedText,
    required this.deltaText,
    required this.chunkIndex,
    required this.isDone,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.finishReason,
  });
}

/// SSE 예외
class SseException implements Exception {
  final String message;
  final dynamic original;

  SseException(this.message, {this.original});

  @override
  String toString() => 'SseException: $message';
}
