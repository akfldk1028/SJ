import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/entities/chat_message.dart';
import '../models/chat_message_model.dart';

/// 대기 중인 메시지 상태
enum QueuedMessageStatus {
  pending,   // 전송 대기
  sending,   // 전송 중
  failed,    // 실패 (재시도 필요)
  maxRetried // 최대 재시도 횟수 초과
}

/// 대기 중인 메시지
class QueuedMessage {
  final ChatMessage message;
  final DateTime queuedAt;
  final int retryCount;
  final QueuedMessageStatus status;
  final String? lastError;

  const QueuedMessage({
    required this.message,
    required this.queuedAt,
    this.retryCount = 0,
    this.status = QueuedMessageStatus.pending,
    this.lastError,
  });

  QueuedMessage copyWith({
    ChatMessage? message,
    DateTime? queuedAt,
    int? retryCount,
    QueuedMessageStatus? status,
    String? lastError,
  }) {
    return QueuedMessage(
      message: message ?? this.message,
      queuedAt: queuedAt ?? this.queuedAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toHiveMap() {
    return {
      'message': ChatMessageModel.fromEntity(message).toHiveMap(),
      'queuedAt': queuedAt.toIso8601String(),
      'retryCount': retryCount,
      'status': status.name,
      'lastError': lastError,
    };
  }

  factory QueuedMessage.fromHiveMap(Map<dynamic, dynamic> map) {
    final messageMap = Map<dynamic, dynamic>.from(map['message'] as Map);
    return QueuedMessage(
      message: ChatMessageModel.fromHiveMap(messageMap).toEntity(),
      queuedAt: DateTime.parse(map['queuedAt'] as String),
      retryCount: map['retryCount'] as int? ?? 0,
      status: QueuedMessageStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String?),
        orElse: () => QueuedMessageStatus.pending,
      ),
      lastError: map['lastError'] as String?,
    );
  }
}

/// 메시지 큐 서비스
///
/// 오프라인 상태에서 실패한 메시지를 큐에 저장하고
/// 네트워크가 복구되면 자동으로 재전송
class MessageQueueService {
  static MessageQueueService? _instance;
  static MessageQueueService get instance => _instance ??= MessageQueueService._();

  static const String _boxName = 'message_queue';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);

  MessageQueueService._();

  Box<Map<dynamic, dynamic>>? _box;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _retryTimer;

  /// 큐 변경 알림
  final _queueController = StreamController<List<QueuedMessage>>.broadcast();
  Stream<List<QueuedMessage>> get onQueueChanged => _queueController.stream;

  /// 메시지 전송 콜백 (Provider에서 설정)
  Future<bool> Function(ChatMessage message)? onSendMessage;

  /// 초기화
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box<Map<dynamic, dynamic>>(_boxName);
      } else {
        _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
      }
    }

    // 네트워크 상태 감시
    _startConnectivityMonitoring();

    // 초기 큐 상태 알림
    _notifyQueueChanged();

    if (kDebugMode) {
      print('[MessageQueue] 초기화 완료, 대기 메시지: ${await getPendingCount()}개');
    }
  }

  /// 네트워크 상태 감시 시작
  void _startConnectivityMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      final hasConnection = !result.contains(ConnectivityResult.none);
      if (hasConnection) {
        if (kDebugMode) {
          print('[MessageQueue] 네트워크 복구됨, 재전송 시작');
        }
        _processQueue();
      }
    });
  }

  /// 메시지 큐에 추가
  Future<void> enqueue(ChatMessage message) async {
    await init();

    final queuedMessage = QueuedMessage(
      message: message,
      queuedAt: DateTime.now(),
    );

    await _box!.put(message.id, queuedMessage.toHiveMap());
    _notifyQueueChanged();

    if (kDebugMode) {
      print('[MessageQueue] 메시지 큐 추가: ${message.id}');
    }

    // 즉시 전송 시도
    _processQueue();
  }

  /// 큐에서 메시지 제거
  Future<void> dequeue(String messageId) async {
    await init();
    await _box!.delete(messageId);
    _notifyQueueChanged();

    if (kDebugMode) {
      print('[MessageQueue] 메시지 큐 제거: $messageId');
    }
  }

  /// 대기 중인 메시지 수 조회
  Future<int> getPendingCount() async {
    await init();
    return _box!.length;
  }

  /// 모든 대기 메시지 조회
  Future<List<QueuedMessage>> getAllQueued() async {
    await init();

    final messages = <QueuedMessage>[];
    for (var key in _box!.keys) {
      final raw = _box!.get(key);
      if (raw != null) {
        messages.add(QueuedMessage.fromHiveMap(raw));
      }
    }

    // 큐에 추가된 시간순 정렬
    messages.sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
    return messages;
  }

  /// 큐 처리 (재전송 시도)
  Future<void> _processQueue() async {
    if (onSendMessage == null) {
      if (kDebugMode) {
        print('[MessageQueue] 전송 콜백 없음');
      }
      return;
    }

    // 네트워크 확인
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      if (kDebugMode) {
        print('[MessageQueue] 오프라인 상태, 재전송 연기');
      }
      return;
    }

    final allQueued = await getAllQueued();
    for (final queued in allQueued) {
      if (queued.status == QueuedMessageStatus.maxRetried) {
        continue; // 최대 재시도 초과 메시지 스킵
      }

      // 전송 중 상태로 업데이트
      await _updateStatus(queued.message.id, QueuedMessageStatus.sending);

      try {
        final success = await onSendMessage!(queued.message);

        if (success) {
          // 성공 시 큐에서 제거
          await dequeue(queued.message.id);
        } else {
          // 실패 시 재시도 카운트 증가
          await _handleRetry(queued, '전송 실패');
        }
      } catch (e) {
        await _handleRetry(queued, e.toString());
      }
    }
  }

  /// 재시도 처리
  Future<void> _handleRetry(QueuedMessage queued, String error) async {
    final newRetryCount = queued.retryCount + 1;

    if (newRetryCount >= _maxRetries) {
      // 최대 재시도 초과
      await _updateStatus(
        queued.message.id,
        QueuedMessageStatus.maxRetried,
        retryCount: newRetryCount,
        error: error,
      );

      if (kDebugMode) {
        print('[MessageQueue] 최대 재시도 초과: ${queued.message.id}');
      }
    } else {
      // 재시도 예약
      await _updateStatus(
        queued.message.id,
        QueuedMessageStatus.failed,
        retryCount: newRetryCount,
        error: error,
      );

      // 지연 후 재시도
      _retryTimer?.cancel();
      _retryTimer = Timer(_retryDelay, () => _processQueue());

      if (kDebugMode) {
        print('[MessageQueue] 재시도 예약: ${queued.message.id} (${newRetryCount}/$_maxRetries)');
      }
    }
  }

  /// 메시지 상태 업데이트
  Future<void> _updateStatus(
    String messageId,
    QueuedMessageStatus status, {
    int? retryCount,
    String? error,
  }) async {
    await init();

    final raw = _box!.get(messageId);
    if (raw == null) return;

    final queued = QueuedMessage.fromHiveMap(raw);

    final updated = queued.copyWith(
      status: status,
      retryCount: retryCount ?? queued.retryCount,
      lastError: error ?? queued.lastError,
    );

    await _box!.put(messageId, updated.toHiveMap());
    _notifyQueueChanged();
  }

  /// 큐 변경 알림
  void _notifyQueueChanged() {
    getAllQueued().then((messages) {
      _queueController.add(messages);
    });
  }

  /// 실패한 메시지 수동 재전송
  Future<void> retryFailed(String messageId) async {
    await _updateStatus(messageId, QueuedMessageStatus.pending, retryCount: 0);
    await _processQueue();
  }

  /// 실패한 메시지 모두 삭제
  Future<void> clearFailed() async {
    await init();

    final toRemove = <String>[];
    for (var key in _box!.keys) {
      final raw = _box!.get(key);
      if (raw != null) {
        final queued = QueuedMessage.fromHiveMap(raw);
        if (queued.status == QueuedMessageStatus.maxRetried) {
          toRemove.add(key as String);
        }
      }
    }

    for (final id in toRemove) {
      await _box!.delete(id);
    }

    _notifyQueueChanged();
  }

  /// 리소스 해제
  void dispose() {
    _connectivitySubscription?.cancel();
    _retryTimer?.cancel();
    _queueController.close();
  }
}
