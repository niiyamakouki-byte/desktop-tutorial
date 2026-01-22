/// Sync Service
/// cursor-based polling による変更フィード同期サービス
///
/// 設計方針（ChatGPT/Gemini議論より）:
/// - Phase1はポーリング＋差分同期、WebSocketはチャットだけ後から
/// - サーバ時刻が正: deviceCapturedAtとserverReceivedAtを分けて持つ
/// - visibilitychange対応（タブがアクティブな時だけポーリング）
/// - エラー時は黙って次回（現場は落ちる前提）

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../models/change_event_model.dart';

/// 同期ステータス
enum SyncStatus {
  /// 初期状態
  idle,

  /// 同期中
  syncing,

  /// 同期完了
  synced,

  /// エラー（次回リトライ）
  error,

  /// オフライン
  offline,
}

/// 同期サービス設定
class SyncConfig {
  /// ポーリング間隔（ミリ秒）
  final int pollingIntervalMs;

  /// アクティブ時のポーリング間隔（ミリ秒）
  final int activePollingIntervalMs;

  /// バックグラウンド時のポーリング間隔（ミリ秒）
  final int backgroundPollingIntervalMs;

  /// 最大リトライ回数
  final int maxRetries;

  /// APIエンドポイント
  final String apiBaseUrl;

  const SyncConfig({
    this.pollingIntervalMs = 3000,
    this.activePollingIntervalMs = 3000,
    this.backgroundPollingIntervalMs = 30000,
    this.maxRetries = 3,
    this.apiBaseUrl = '/api',
  });
}

/// 同期状態
class SyncState {
  /// 現在のカーソル
  final String? cursor;

  /// 取得した変更イベント
  final List<ChangeEvent> events;

  /// 未確認数
  final int unackedCount;

  /// 最終同期時刻
  final DateTime? lastSyncAt;

  /// 同期ステータス
  final SyncStatus status;

  /// エラーメッセージ
  final String? errorMessage;

  const SyncState({
    this.cursor,
    this.events = const [],
    this.unackedCount = 0,
    this.lastSyncAt,
    this.status = SyncStatus.idle,
    this.errorMessage,
  });

  SyncState copyWith({
    String? cursor,
    List<ChangeEvent>? events,
    int? unackedCount,
    DateTime? lastSyncAt,
    SyncStatus? status,
    String? errorMessage,
  }) {
    return SyncState(
      cursor: cursor ?? this.cursor,
      events: events ?? this.events,
      unackedCount: unackedCount ?? this.unackedCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 変更フィード同期サービス
/// Zustand ChangeFeedStore のFlutter版実装
class SyncService {
  static const String _cursorKey = 'sync_cursor';
  static const String _lastSyncKey = 'sync_last_sync';

  final SyncConfig config;
  final http.Client? httpClient;

  Timer? _pollingTimer;
  bool _isPolling = false;
  bool _isAppActive = true;

  final _stateController = StreamController<SyncState>.broadcast();
  SyncState _state = const SyncState();

  /// 状態ストリーム（UIバインディング用）
  Stream<SyncState> get stateStream => _stateController.stream;

  /// 現在の状態
  SyncState get state => _state;

  /// 変更イベントコールバック
  final List<void Function(List<ChangeEvent>)> _eventListeners = [];

  SyncService({
    this.config = const SyncConfig(),
    this.httpClient,
  });

  /// 状態を更新
  void _updateState(SyncState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// ポーリング開始
  Future<void> startPolling() async {
    if (_isPolling) return;
    _isPolling = true;

    // 初回は即時実行
    await _poll();

    // 定期ポーリング開始
    final interval = _isAppActive
        ? config.activePollingIntervalMs
        : config.backgroundPollingIntervalMs;

    _pollingTimer = Timer.periodic(
      Duration(milliseconds: interval),
      (_) => _poll(),
    );
  }

  /// ポーリング停止
  void stopPolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// アプリのアクティブ状態を設定（AppLifecycleState対応）
  void setAppActive(bool isActive) {
    if (_isAppActive == isActive) return;
    _isAppActive = isActive;

    // ポーリング間隔を調整
    if (_isPolling) {
      stopPolling();
      startPolling();
    }
  }

  /// ポーリング実行
  Future<void> _poll() async {
    if (!_isPolling) return;

    try {
      _updateState(_state.copyWith(status: SyncStatus.syncing));

      final cursor = _state.cursor ?? await _loadCursor();
      final response = await _fetchChanges(cursor);

      if (response.events.isNotEmpty) {
        // 新しいイベントをマージ（upsert）
        final mergedEvents = _upsertEvents(_state.events, response.events);

        _updateState(_state.copyWith(
          events: mergedEvents,
          cursor: response.cursor ?? _state.cursor,
          unackedCount: _state.unackedCount + response.events.length,
          lastSyncAt: DateTime.now(),
          status: SyncStatus.synced,
        ));

        // カーソルを保存
        if (response.cursor != null) {
          await _saveCursor(response.cursor!);
        }

        // リスナーに通知
        for (final listener in _eventListeners) {
          listener(response.events);
        }

        // まだデータがある場合は続けてフェッチ
        if (response.hasMore) {
          await _poll();
        }
      } else {
        _updateState(_state.copyWith(
          lastSyncAt: DateTime.now(),
          status: SyncStatus.synced,
        ));
      }
    } catch (e) {
      // エラー時は黙って次回（現場は落ちる前提）
      if (kDebugMode) {
        print('Sync error: $e');
      }
      _updateState(_state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// 変更をフェッチ
  Future<ChangeFeedResponse> _fetchChanges(String? cursor) async {
    // TODO: 実際のAPIエンドポイントに接続
    // 現在はモック実装
    final client = httpClient ?? http.Client();

    try {
      final url = Uri.parse('${config.apiBaseUrl}/changes')
          .replace(queryParameters: cursor != null ? {'since': cursor} : null);

      final response = await client.get(url).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ChangeFeedResponse.fromJson(json);
      }

      throw Exception('API error: ${response.statusCode}');
    } catch (e) {
      // ネットワークエラー時は空のレスポンスを返す
      if (kDebugMode) {
        print('Fetch changes error: $e');
      }
      return ChangeFeedResponse(
        events: [],
        cursor: null,
        hasMore: false,
        serverTime: DateTime.now(),
      );
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  /// 確認（ack）を送信
  Future<bool> acknowledge({String? cursor, List<String>? changeIds}) async {
    try {
      final client = httpClient ?? http.Client();

      try {
        final response = await client.post(
          Uri.parse('${config.apiBaseUrl}/changes/ack'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'cursor': cursor ?? _state.cursor ?? '',
            if (changeIds != null) 'changeIds': changeIds,
          }),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final ackResponse = CursorAckResponse.fromJson(json);

          _updateState(_state.copyWith(
            unackedCount: 0, // Reset unacked count on successful ack
          ));

          return ackResponse.success;
        }
      } finally {
        if (httpClient == null) {
          client.close();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Acknowledge error: $e');
      }
    }

    return false;
  }

  /// イベントをupsert（IDで重複排除）
  List<ChangeEvent> _upsertEvents(
    List<ChangeEvent> existing,
    List<ChangeEvent> newEvents,
  ) {
    final eventMap = <String, ChangeEvent>{};

    for (final event in existing) {
      eventMap[event.id] = event;
    }
    for (final event in newEvents) {
      eventMap[event.id] = event;
    }

    final result = eventMap.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return result;
  }

  /// カーソルを読み込み
  Future<String?> _loadCursor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_cursorKey);
    } catch (e) {
      return null;
    }
  }

  /// カーソルを保存
  Future<void> _saveCursor(String cursor) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cursorKey, cursor);
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      if (kDebugMode) {
        print('Save cursor error: $e');
      }
    }
  }

  /// イベントリスナーを追加
  void addEventListener(void Function(List<ChangeEvent>) listener) {
    _eventListeners.add(listener);
  }

  /// イベントリスナーを削除
  void removeEventListener(void Function(List<ChangeEvent>) listener) {
    _eventListeners.remove(listener);
  }

  /// 特定のプロジェクトの変更を取得
  List<ChangeEvent> getEventsForProject(String projectId) {
    return _state.events.filterByProject(projectId);
  }

  /// 最新N件の変更を取得
  List<ChangeEvent> getLatestEvents(int count) {
    return _state.events.latest(count);
  }

  /// 全ての変更を確認済みにする
  Future<void> acknowledgeAll() async {
    await acknowledge(cursor: _state.cursor);
    _updateState(_state.copyWith(unackedCount: 0));
  }

  /// リソース解放
  void dispose() {
    stopPolling();
    _stateController.close();
    _eventListeners.clear();
  }
}

/// 同期サービスのシングルトンインスタンス
class SyncServiceProvider {
  static SyncService? _instance;

  static SyncService get instance {
    _instance ??= SyncService();
    return _instance!;
  }

  static void initialize(SyncConfig config) {
    _instance = SyncService(config: config);
  }

  static void dispose() {
    _instance?.dispose();
    _instance = null;
  }
}
