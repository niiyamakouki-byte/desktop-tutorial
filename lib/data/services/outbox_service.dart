/// Outbox Service
/// オフラインファースト操作のためのOutboxパターン実装
///
/// 設計方針:
/// - オフライン時は操作をローカルキューに保存
/// - オンライン復帰時に自動リトライ
/// - 指数バックオフ＋ジッター（1s→2s→4s...max 30s）
/// - 最大5回リトライ、失敗後はfailed状態

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// 操作タイプ
enum OperationType {
  create('create'),
  update('update'),
  delete('delete');

  final String value;

  const OperationType(this.value);

  static OperationType fromString(String value) {
    return OperationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OperationType.update,
    );
  }
}

/// Outboxアイテムのステータス
enum OutboxStatus {
  /// 送信待ち
  pending('pending'),

  /// 送信中
  processing('processing'),

  /// 失敗（リトライ上限到達）
  failed('failed'),

  /// 完了（送信成功）
  completed('completed');

  final String value;

  const OutboxStatus(this.value);

  static OutboxStatus fromString(String value) {
    return OutboxStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OutboxStatus.pending,
    );
  }
}

/// Outboxアイテム
class OutboxItem {
  /// アイテムID
  final String id;

  /// 操作タイプ
  final OperationType operation;

  /// エンティティタイプ（task, project, phase等）
  final String entityType;

  /// エンティティID
  final String entityId;

  /// ペイロード（送信データ）
  final Map<String, dynamic> payload;

  /// 作成日時
  final DateTime createdAt;

  /// リトライ回数
  final int retryCount;

  /// 最後のエラー
  final String? lastError;

  /// ステータス
  final OutboxStatus status;

  /// 次回リトライ時刻
  final DateTime? nextRetryAt;

  const OutboxItem({
    required this.id,
    required this.operation,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
    this.status = OutboxStatus.pending,
    this.nextRetryAt,
  });

  factory OutboxItem.fromJson(Map<String, dynamic> json) {
    return OutboxItem(
      id: json['id'] as String,
      operation: OperationType.fromString(json['operation'] as String),
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      payload: json['payload'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      lastError: json['lastError'] as String?,
      status: OutboxStatus.fromString(json['status'] as String? ?? 'pending'),
      nextRetryAt: json['nextRetryAt'] != null
          ? DateTime.parse(json['nextRetryAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'operation': operation.value,
        'entityType': entityType,
        'entityId': entityId,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'lastError': lastError,
        'status': status.value,
        'nextRetryAt': nextRetryAt?.toIso8601String(),
      };

  OutboxItem copyWith({
    String? id,
    OperationType? operation,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? retryCount,
    String? lastError,
    OutboxStatus? status,
    DateTime? nextRetryAt,
  }) {
    return OutboxItem(
      id: id ?? this.id,
      operation: operation ?? this.operation,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      status: status ?? this.status,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
    );
  }
}

/// Outboxサービス設定
class OutboxConfig {
  /// 最大リトライ回数
  final int maxRetries;

  /// 基本バックオフ時間（ミリ秒）
  final int baseBackoffMs;

  /// 最大バックオフ時間（ミリ秒）
  final int maxBackoffMs;

  /// 処理間隔（ミリ秒）
  final int processIntervalMs;

  /// APIエンドポイント
  final String apiBaseUrl;

  const OutboxConfig({
    this.maxRetries = 5,
    this.baseBackoffMs = 1000,
    this.maxBackoffMs = 30000,
    this.processIntervalMs = 5000,
    this.apiBaseUrl = '/api',
  });
}

/// Outbox状態
class OutboxState {
  /// 保留中のアイテム
  final List<OutboxItem> items;

  /// 処理中かどうか
  final bool isProcessing;

  /// オンライン状態
  final bool isOnline;

  const OutboxState({
    this.items = const [],
    this.isProcessing = false,
    this.isOnline = true,
  });

  OutboxState copyWith({
    List<OutboxItem>? items,
    bool? isProcessing,
    bool? isOnline,
  }) {
    return OutboxState(
      items: items ?? this.items,
      isProcessing: isProcessing ?? this.isProcessing,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  /// 保留中のアイテム数
  int get pendingCount =>
      items.where((i) => i.status == OutboxStatus.pending).length;

  /// 失敗したアイテム数
  int get failedCount =>
      items.where((i) => i.status == OutboxStatus.failed).length;

  /// 処理可能なアイテムがあるか
  bool get hasReadyItems {
    final now = DateTime.now();
    return items.any((i) =>
        i.status == OutboxStatus.pending &&
        (i.nextRetryAt == null || i.nextRetryAt!.isBefore(now)));
  }
}

/// Outboxサービス
/// Zustand OutboxStore のFlutter版実装
class OutboxService {
  static const String _storageKey = 'outbox_items';

  final OutboxConfig config;
  final http.Client? httpClient;
  final Random _random = Random();

  Timer? _processTimer;
  bool _isRunning = false;

  final _stateController = StreamController<OutboxState>.broadcast();
  OutboxState _state = const OutboxState();

  /// 状態ストリーム（UIバインディング用）
  Stream<OutboxState> get stateStream => _stateController.stream;

  /// 現在の状態
  OutboxState get state => _state;

  OutboxService({
    this.config = const OutboxConfig(),
    this.httpClient,
  });

  /// 状態を更新
  void _updateState(OutboxState newState) {
    _state = newState;
    _stateController.add(newState);
    _persistQueue();
  }

  /// 初期化（キューを読み込み）
  Future<void> initialize() async {
    await _loadQueue();
    startProcessing();
  }

  /// 処理開始
  void startProcessing() {
    if (_isRunning) return;
    _isRunning = true;

    _processTimer = Timer.periodic(
      Duration(milliseconds: config.processIntervalMs),
      (_) => processOutbox(),
    );

    // 初回は即時実行
    processOutbox();
  }

  /// 処理停止
  void stopProcessing() {
    _isRunning = false;
    _processTimer?.cancel();
    _processTimer = null;
  }

  /// オンライン状態を設定
  void setOnline(bool isOnline) {
    _updateState(_state.copyWith(isOnline: isOnline));

    // オンラインになったら処理開始
    if (isOnline && _state.hasReadyItems) {
      processOutbox();
    }
  }

  /// Outboxに追加
  Future<void> enqueue({
    required OperationType operation,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    final item = OutboxItem(
      id: _generateId(),
      operation: operation,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      createdAt: DateTime.now(),
    );

    final newItems = [..._state.items, item];
    _updateState(_state.copyWith(items: newItems));

    // 即時処理を試みる
    if (_state.isOnline) {
      processOutbox();
    }
  }

  /// Outboxを処理
  Future<void> processOutbox() async {
    if (_state.isProcessing || !_state.isOnline) return;

    final readyItems = _peekReady();
    if (readyItems.isEmpty) return;

    _updateState(_state.copyWith(isProcessing: true));

    for (final item in readyItems) {
      try {
        await _executeOperation(item);
        _markDone(item.id);
      } catch (e) {
        _handleError(item, e.toString());
      }
    }

    _updateState(_state.copyWith(isProcessing: false));
  }

  /// 処理可能なアイテムを取得
  List<OutboxItem> _peekReady() {
    final now = DateTime.now();
    return _state.items
        .where((i) =>
            i.status == OutboxStatus.pending &&
            (i.nextRetryAt == null || i.nextRetryAt!.isBefore(now)))
        .toList();
  }

  /// 操作を実行
  Future<void> _executeOperation(OutboxItem item) async {
    final client = httpClient ?? http.Client();

    try {
      final endpoint = '${config.apiBaseUrl}/${item.entityType}';
      late http.Response response;

      switch (item.operation) {
        case OperationType.create:
          response = await client.post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(item.payload),
          );
          break;

        case OperationType.update:
          response = await client.put(
            Uri.parse('$endpoint/${item.entityId}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(item.payload),
          );
          break;

        case OperationType.delete:
          response = await client.delete(
            Uri.parse('$endpoint/${item.entityId}'),
          );
          break;
      }

      if (response.statusCode >= 400) {
        throw Exception('API error: ${response.statusCode}');
      }
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  /// 完了としてマーク
  void _markDone(String itemId) {
    final newItems = _state.items.where((i) => i.id != itemId).toList();
    _updateState(_state.copyWith(items: newItems));
  }

  /// エラー処理
  void _handleError(OutboxItem item, String error) {
    if (item.retryCount >= config.maxRetries) {
      // 最大リトライ到達 → failed
      _markFailed(item.id, error);
    } else {
      // リトライスケジュール
      _scheduleRetry(item, error);
    }
  }

  /// 失敗としてマーク
  void _markFailed(String itemId, String error) {
    final newItems = _state.items.map((i) {
      if (i.id == itemId) {
        return i.copyWith(
          status: OutboxStatus.failed,
          lastError: error,
        );
      }
      return i;
    }).toList();

    _updateState(_state.copyWith(items: newItems));
  }

  /// リトライをスケジュール
  void _scheduleRetry(OutboxItem item, String error) {
    final backoff = _backoffMs(item.retryCount);
    final nextRetry = DateTime.now().add(Duration(milliseconds: backoff));

    final newItems = _state.items.map((i) {
      if (i.id == item.id) {
        return i.copyWith(
          retryCount: item.retryCount + 1,
          lastError: error,
          nextRetryAt: nextRetry,
        );
      }
      return i;
    }).toList();

    _updateState(_state.copyWith(items: newItems));
  }

  /// 指数バックオフ＋ジッター計算
  int _backoffMs(int retryCount) {
    // 2^retryCount * baseBackoff + random jitter
    final exponential = config.baseBackoffMs * pow(2, retryCount).toInt();
    final jitter = _random.nextInt(config.baseBackoffMs);
    return min(exponential + jitter, config.maxBackoffMs);
  }

  /// 失敗したアイテムをリトライ
  void retryFailed(String itemId) {
    final newItems = _state.items.map((i) {
      if (i.id == itemId) {
        return i.copyWith(
          status: OutboxStatus.pending,
          retryCount: 0,
          nextRetryAt: null,
        );
      }
      return i;
    }).toList();

    _updateState(_state.copyWith(items: newItems));
    processOutbox();
  }

  /// 全ての失敗したアイテムをリトライ
  void retryAllFailed() {
    final newItems = _state.items.map((i) {
      if (i.status == OutboxStatus.failed) {
        return i.copyWith(
          status: OutboxStatus.pending,
          retryCount: 0,
          nextRetryAt: null,
        );
      }
      return i;
    }).toList();

    _updateState(_state.copyWith(items: newItems));
    processOutbox();
  }

  /// 失敗したアイテムをクリア
  void clearFailed() {
    final newItems =
        _state.items.where((i) => i.status != OutboxStatus.failed).toList();
    _updateState(_state.copyWith(items: newItems));
  }

  /// 全てクリア
  void clearAll() {
    _updateState(_state.copyWith(items: []));
  }

  /// キューを永続化
  Future<void> _persistQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = _state.items.map((i) => i.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(json));
    } catch (e) {
      if (kDebugMode) {
        print('Persist queue error: $e');
      }
    }
  }

  /// キューを読み込み
  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);

      if (jsonStr != null) {
        final jsonList = jsonDecode(jsonStr) as List<dynamic>;
        final items = jsonList
            .map((j) => OutboxItem.fromJson(j as Map<String, dynamic>))
            .toList();

        _updateState(_state.copyWith(items: items));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Load queue error: $e');
      }
    }
  }

  /// ユニークID生成
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = _random.nextInt(999999);
    return 'outbox_${timestamp}_$random';
  }

  /// リソース解放
  void dispose() {
    stopProcessing();
    _stateController.close();
  }
}

/// Outboxサービスのシングルトンインスタンス
class OutboxServiceProvider {
  static OutboxService? _instance;

  static OutboxService get instance {
    _instance ??= OutboxService();
    return _instance!;
  }

  static Future<void> initialize(OutboxConfig config) async {
    _instance = OutboxService(config: config);
    await _instance!.initialize();
  }

  static void dispose() {
    _instance?.dispose();
    _instance = null;
  }
}
