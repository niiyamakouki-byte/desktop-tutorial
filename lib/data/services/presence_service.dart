import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// ============================================================================
// プレゼンスステータス列挙型
// ユーザーのオンライン状態を表す
// ============================================================================
enum PresenceStatus {
  /// オンライン - ユーザーがアクティブ
  online,

  /// 離席中 - ユーザーが一時的に離れている
  away,

  /// オフライン - ユーザーが接続していない
  offline,
}

// ============================================================================
// UserPresence モデル
// ユーザーのプレゼンス情報を保持するデータクラス
// ============================================================================
class UserPresence {
  /// ユーザーID
  final String id;

  /// 最終確認日時
  final DateTime lastSeenAt;

  /// 現在のステータス
  final PresenceStatus status;

  /// 現在表示中のビュー (例: "gantt:project-123")
  final String? currentView;

  /// デバイス情報
  final String? deviceInfo;

  const UserPresence({
    required this.id,
    required this.lastSeenAt,
    required this.status,
    this.currentView,
    this.deviceInfo,
  });

  /// JSONからUserPresenceを生成
  factory UserPresence.fromJson(Map<String, dynamic> json) {
    return UserPresence(
      id: json['id'] as String,
      lastSeenAt: DateTime.parse(json['lastSeenAt'] as String),
      status: PresenceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PresenceStatus.offline,
      ),
      currentView: json['currentView'] as String?,
      deviceInfo: json['deviceInfo'] as String?,
    );
  }

  /// UserPresenceをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lastSeenAt': lastSeenAt.toIso8601String(),
      'status': status.name,
      if (currentView != null) 'currentView': currentView,
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
    };
  }

  /// ステータスを更新したコピーを作成
  UserPresence copyWith({
    String? id,
    DateTime? lastSeenAt,
    PresenceStatus? status,
    String? currentView,
    String? deviceInfo,
  }) {
    return UserPresence(
      id: id ?? this.id,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      status: status ?? this.status,
      currentView: currentView ?? this.currentView,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }

  /// ステータスの日本語ラベルを取得
  String get statusLabel {
    switch (status) {
      case PresenceStatus.online:
        return 'オンライン';
      case PresenceStatus.away:
        return '離席中';
      case PresenceStatus.offline:
        return 'オフライン';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPresence &&
        other.id == id &&
        other.lastSeenAt == lastSeenAt &&
        other.status == status &&
        other.currentView == currentView &&
        other.deviceInfo == deviceInfo;
  }

  @override
  int get hashCode {
    return Object.hash(id, lastSeenAt, status, currentView, deviceInfo);
  }

  @override
  String toString() {
    return 'UserPresence(id: $id, status: $status, lastSeenAt: $lastSeenAt)';
  }
}

// ============================================================================
// PresenceHeartbeatRequest モデル
// ハートビートリクエストのペイロード
// ============================================================================
class PresenceHeartbeatRequest {
  /// 現在のステータス (online または away)
  final PresenceStatus status;

  /// 現在表示中のビュー
  final String? currentView;

  const PresenceHeartbeatRequest({
    required this.status,
    this.currentView,
  });

  /// リクエストをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      if (currentView != null) 'currentView': currentView,
    };
  }
}

// ============================================================================
// PresenceState モデル
// プレゼンスサービスの全体状態を保持
// ============================================================================
class PresenceState {
  /// 全ユーザーのプレゼンス情報
  final Map<String, UserPresence> presence;

  /// 自分のステータス
  final PresenceStatus myStatus;

  /// 現在表示中のビュー
  final String? currentView;

  /// ハートビートが動作中かどうか
  final bool isHeartbeatActive;

  const PresenceState({
    this.presence = const {},
    this.myStatus = PresenceStatus.online,
    this.currentView,
    this.isHeartbeatActive = false,
  });

  /// 状態を更新したコピーを作成
  PresenceState copyWith({
    Map<String, UserPresence>? presence,
    PresenceStatus? myStatus,
    String? currentView,
    bool? isHeartbeatActive,
  }) {
    return PresenceState(
      presence: presence ?? this.presence,
      myStatus: myStatus ?? this.myStatus,
      currentView: currentView ?? this.currentView,
      isHeartbeatActive: isHeartbeatActive ?? this.isHeartbeatActive,
    );
  }

  /// オンラインユーザー数を取得
  int get onlineUserCount {
    return presence.values
        .where((p) => p.status == PresenceStatus.online)
        .length;
  }

  /// 離席中ユーザー数を取得
  int get awayUserCount {
    return presence.values
        .where((p) => p.status == PresenceStatus.away)
        .length;
  }

  /// オフラインユーザー数を取得
  int get offlineUserCount {
    return presence.values
        .where((p) => p.status == PresenceStatus.offline)
        .length;
  }
}

// ============================================================================
// PresenceService
// TTLベースのハートビートプレゼンス追跡サービス
// シングルトンパターンで実装
// ============================================================================
class PresenceService with WidgetsBindingObserver {
  // シングルトンインスタンス
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  // ============================================================================
  // 定数設定
  // ============================================================================

  /// デフォルトのハートビート間隔（30秒）
  static const Duration defaultHeartbeatInterval = Duration(seconds: 30);

  /// デフォルトのTTL閾値（2分）
  /// この時間を超えると古いユーザーとみなす
  static const Duration defaultStaleThreshold = Duration(minutes: 2);

  /// クリーンアップチェック間隔（30秒）
  static const Duration cleanupInterval = Duration(seconds: 30);

  // ============================================================================
  // 内部状態
  // ============================================================================

  /// 現在のプレゼンス状態
  PresenceState _state = const PresenceState();

  /// ハートビートタイマー
  Timer? _heartbeatTimer;

  /// クリーンアップタイマー
  Timer? _cleanupTimer;

  /// 現在のユーザーID
  String? _currentUserId;

  /// TTL閾値（カスタマイズ可能）
  Duration _staleThreshold = defaultStaleThreshold;

  /// サービスが初期化されているかどうか
  bool _initialized = false;

  /// アプリがバックグラウンドにあるかどうか
  bool _isBackgrounded = false;

  // ============================================================================
  // StreamControllers（UIへのリアクティブ更新用）
  // ============================================================================

  /// 状態変更ストリーム
  final StreamController<PresenceState> _stateController =
      StreamController<PresenceState>.broadcast();

  /// 個別プレゼンス更新ストリーム
  final StreamController<UserPresence> _presenceUpdateController =
      StreamController<UserPresence>.broadcast();

  /// ユーザーオフラインイベントストリーム
  final StreamController<String> _userOfflineController =
      StreamController<String>.broadcast();

  /// ハートビートイベントストリーム（デバッグ用）
  final StreamController<DateTime> _heartbeatController =
      StreamController<DateTime>.broadcast();

  /// エラーストリーム
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // ============================================================================
  // ゲッター
  // ============================================================================

  /// 現在の状態を取得
  PresenceState get state => _state;

  /// 状態ストリーム
  Stream<PresenceState> get stateStream => _stateController.stream;

  /// プレゼンス更新ストリーム
  Stream<UserPresence> get presenceUpdateStream => _presenceUpdateController.stream;

  /// ユーザーオフラインストリーム
  Stream<String> get userOfflineStream => _userOfflineController.stream;

  /// ハートビートストリーム
  Stream<DateTime> get heartbeatStream => _heartbeatController.stream;

  /// エラーストリーム
  Stream<String> get errorStream => _errorController.stream;

  /// 初期化済みかどうか
  bool get isInitialized => _initialized;

  /// ハートビートが動作中かどうか
  bool get isHeartbeatActive => _heartbeatTimer != null;

  /// 現在のユーザーID
  String? get currentUserId => _currentUserId;

  /// 自分のステータス
  PresenceStatus get myStatus => _state.myStatus;

  /// 現在のビュー
  String? get currentView => _state.currentView;

  // ============================================================================
  // 初期化・終了処理
  // ============================================================================

  /// サービスを初期化
  /// [userId] - 現在のユーザーID
  /// [staleThreshold] - カスタムTTL閾値（オプション）
  void initialize({
    required String userId,
    Duration? staleThreshold,
  }) {
    if (_initialized) {
      debugPrint('PresenceService: 既に初期化されています');
      return;
    }

    _currentUserId = userId;
    if (staleThreshold != null) {
      _staleThreshold = staleThreshold;
    }

    // アプリライフサイクル監視を開始
    WidgetsBinding.instance.addObserver(this);

    _initialized = true;
    debugPrint('PresenceService: 初期化完了 (userId: $userId)');
  }

  /// サービスを終了・リソースを解放
  void dispose() {
    stopHeartbeat();
    _stopCleanupTimer();

    // ライフサイクル監視を解除
    WidgetsBinding.instance.removeObserver(this);

    // ストリームをクローズ
    _stateController.close();
    _presenceUpdateController.close();
    _userOfflineController.close();
    _heartbeatController.close();
    _errorController.close();

    _initialized = false;
    debugPrint('PresenceService: リソースを解放しました');
  }

  // ============================================================================
  // アプリライフサイクル処理
  // バックグラウンド時にハートビートを一時停止
  // ============================================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // アプリがフォアグラウンドに復帰
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // アプリがバックグラウンドに移行
        _onAppPaused();
        break;
    }
  }

  /// アプリ復帰時の処理
  void _onAppResumed() {
    if (_isBackgrounded) {
      _isBackgrounded = false;
      debugPrint('PresenceService: アプリがフォアグラウンドに復帰');

      // ステータスをオンラインに戻してハートビートを再開
      if (_currentUserId != null) {
        setMyStatus(PresenceStatus.online);
        startHeartbeat();
      }
    }
  }

  /// アプリ一時停止時の処理
  void _onAppPaused() {
    if (!_isBackgrounded) {
      _isBackgrounded = true;
      debugPrint('PresenceService: アプリがバックグラウンドに移行');

      // ハートビートを停止し、ステータスを離席中に設定
      stopHeartbeat();
      setMyStatus(PresenceStatus.away);
    }
  }

  // ============================================================================
  // ハートビート管理
  // ============================================================================

  /// ハートビートを開始
  /// [interval] - ハートビート間隔（デフォルト: 30秒）
  void startHeartbeat([Duration interval = defaultHeartbeatInterval]) {
    if (!_initialized) {
      debugPrint('PresenceService: 初期化されていません');
      _errorController.add('サービスが初期化されていません');
      return;
    }

    // 既存のタイマーを停止
    _heartbeatTimer?.cancel();

    // 即座に最初のハートビートを送信
    _sendHeartbeat();

    // 定期的なハートビートを開始
    _heartbeatTimer = Timer.periodic(interval, (_) {
      _sendHeartbeat();
    });

    // クリーンアップタイマーも開始
    _startCleanupTimer();

    // 状態を更新
    _updateState(_state.copyWith(isHeartbeatActive: true));

    debugPrint('PresenceService: ハートビート開始 (間隔: ${interval.inSeconds}秒)');
  }

  /// ハートビートを停止
  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    _stopCleanupTimer();

    // 状態を更新
    _updateState(_state.copyWith(isHeartbeatActive: false));

    debugPrint('PresenceService: ハートビート停止');
  }

  /// ハートビートを送信
  Future<void> _sendHeartbeat() async {
    if (_currentUserId == null) return;

    final request = PresenceHeartbeatRequest(
      status: _state.myStatus,
      currentView: _state.currentView,
    );

    try {
      // API呼び出し（実際の実装ではHTTPリクエストを送信）
      await _sendHeartbeatToServer(request);

      // 自分のプレゼンスを更新
      final myPresence = UserPresence(
        id: _currentUserId!,
        lastSeenAt: DateTime.now(),
        status: _state.myStatus,
        currentView: _state.currentView,
        deviceInfo: _getDeviceInfo(),
      );

      updatePresence(_currentUserId!, myPresence);

      // ハートビートイベントを通知
      _heartbeatController.add(DateTime.now());

    } catch (e) {
      debugPrint('PresenceService: ハートビート送信エラー: $e');
      _errorController.add('ハートビートの送信に失敗しました: $e');
    }
  }

  /// サーバーにハートビートを送信（実装プレースホルダー）
  /// 実際のアプリケーションでは、ここでHTTPリクエストを送信
  Future<void> _sendHeartbeatToServer(PresenceHeartbeatRequest request) async {
    // TODO: 実際のAPIエンドポイントに送信
    // 例:
    // await http.post(
    //   Uri.parse('$baseUrl/api/presence/heartbeat'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode(request.toJson()),
    // );

    // デモ用の遅延をシミュレート
    await Future.delayed(const Duration(milliseconds: 50));
  }

  // ============================================================================
  // ステータス管理
  // ============================================================================

  /// 自分のステータスを設定
  void setMyStatus(PresenceStatus status) {
    if (_state.myStatus == status) return;

    _updateState(_state.copyWith(myStatus: status));

    // 自分のプレゼンスを即座に更新
    if (_currentUserId != null) {
      final myPresence = UserPresence(
        id: _currentUserId!,
        lastSeenAt: DateTime.now(),
        status: status,
        currentView: _state.currentView,
        deviceInfo: _getDeviceInfo(),
      );
      updatePresence(_currentUserId!, myPresence);
    }

    debugPrint('PresenceService: ステータス変更 -> ${status.name}');
  }

  /// 現在のビューを設定
  void setCurrentView(String? view) {
    if (_state.currentView == view) return;

    _updateState(_state.copyWith(currentView: view));

    debugPrint('PresenceService: ビュー変更 -> $view');
  }

  // ============================================================================
  // プレゼンス管理
  // ============================================================================

  /// ユーザーのプレゼンスを更新
  void updatePresence(String userId, UserPresence presence) {
    final newPresence = Map<String, UserPresence>.from(_state.presence);
    newPresence[userId] = presence;

    _updateState(_state.copyWith(presence: newPresence));
    _presenceUpdateController.add(presence);
  }

  /// 複数ユーザーのプレゼンスを一括更新
  void updatePresenceBatch(Map<String, UserPresence> updates) {
    final newPresence = Map<String, UserPresence>.from(_state.presence);
    newPresence.addAll(updates);

    _updateState(_state.copyWith(presence: newPresence));

    for (final presence in updates.values) {
      _presenceUpdateController.add(presence);
    }
  }

  /// 特定ユーザーのプレゼンスを取得
  UserPresence? getPresence(String userId) {
    return _state.presence[userId];
  }

  /// 全ユーザーのプレゼンスを取得
  List<UserPresence> getAllPresence() {
    return _state.presence.values.toList();
  }

  /// オンラインユーザーのみ取得
  List<UserPresence> getOnlineUsers() {
    return _state.presence.values
        .where((p) => p.status == PresenceStatus.online)
        .toList();
  }

  /// 特定のビューにいるユーザーを取得
  List<UserPresence> getUsersInView(String view) {
    return _state.presence.values
        .where((p) => p.currentView == view && p.status != PresenceStatus.offline)
        .toList();
  }

  // ============================================================================
  // TTLベースのクリーンアップ
  // ============================================================================

  /// クリーンアップタイマーを開始
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(cleanupInterval, (_) {
      cleanupStalePresence();
    });
  }

  /// クリーンアップタイマーを停止
  void _stopCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  /// 古いプレゼンス情報をクリーンアップ
  /// TTL閾値を超えたユーザーをオフラインに設定
  void cleanupStalePresence() {
    final now = DateTime.now();
    final newPresence = <String, UserPresence>{};
    final offlineUsers = <String>[];

    _state.presence.forEach((userId, presence) {
      final timeSinceLastSeen = now.difference(presence.lastSeenAt);

      if (timeSinceLastSeen < _staleThreshold) {
        // まだアクティブなユーザー
        newPresence[userId] = presence;
      } else if (presence.status != PresenceStatus.offline) {
        // 古くなったユーザー -> オフラインに設定
        newPresence[userId] = presence.copyWith(status: PresenceStatus.offline);
        offlineUsers.add(userId);
        debugPrint('PresenceService: ユーザー $userId をオフラインに設定 (最終確認: ${presence.lastSeenAt})');
      } else {
        // 既にオフラインのユーザー
        newPresence[userId] = presence;
      }
    });

    if (offlineUsers.isNotEmpty) {
      _updateState(_state.copyWith(presence: newPresence));

      // オフラインになったユーザーを通知
      for (final userId in offlineUsers) {
        _userOfflineController.add(userId);
      }
    }
  }

  /// 手動でクリーンアップをトリガー
  void forceCleanup() {
    cleanupStalePresence();
  }

  // ============================================================================
  // ユーティリティ
  // ============================================================================

  /// 状態を更新し、ストリームに通知
  void _updateState(PresenceState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  /// デバイス情報を取得
  String _getDeviceInfo() {
    if (kIsWeb) {
      return 'Web';
    }
    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isLinux) return 'Linux';
    } catch (e) {
      // Platform情報が取得できない場合
    }
    return 'Unknown';
  }

  /// サービスの状態をリセット（テスト用）
  @visibleForTesting
  void reset() {
    stopHeartbeat();
    _state = const PresenceState();
    _currentUserId = null;
    _isBackgrounded = false;
    _staleThreshold = defaultStaleThreshold;
    _initialized = false;
  }
}

// ============================================================================
// PresenceServiceProvider (InheritedWidget)
// ウィジェットツリーでPresenceServiceにアクセスするためのプロバイダー
// ============================================================================
class PresenceServiceProvider extends InheritedWidget {
  final PresenceService service;

  const PresenceServiceProvider({
    super.key,
    required this.service,
    required super.child,
  });

  /// 最も近い祖先からPresenceServiceを取得
  static PresenceService of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<PresenceServiceProvider>();
    assert(provider != null, 'PresenceServiceProviderが見つかりません');
    return provider!.service;
  }

  /// PresenceServiceを取得（nullを許容）
  static PresenceService? maybeOf(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<PresenceServiceProvider>();
    return provider?.service;
  }

  @override
  bool updateShouldNotify(PresenceServiceProvider oldWidget) {
    return service != oldWidget.service;
  }
}

// ============================================================================
// PresenceBuilder
// プレゼンス状態に基づいてUIを構築するためのStreamBuilder
// ============================================================================
class PresenceBuilder extends StatelessWidget {
  final PresenceService service;
  final Widget Function(BuildContext context, PresenceState state) builder;

  const PresenceBuilder({
    super.key,
    required this.service,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PresenceState>(
      stream: service.stateStream,
      initialData: service.state,
      builder: (context, snapshot) {
        return builder(context, snapshot.data ?? const PresenceState());
      },
    );
  }
}

// ============================================================================
// UserPresenceBuilder
// 特定ユーザーのプレゼンス更新を監視するビルダー
// ============================================================================
class UserPresenceBuilder extends StatelessWidget {
  final PresenceService service;
  final String userId;
  final Widget Function(BuildContext context, UserPresence? presence) builder;

  const UserPresenceBuilder({
    super.key,
    required this.service,
    required this.userId,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PresenceState>(
      stream: service.stateStream,
      initialData: service.state,
      builder: (context, snapshot) {
        final presence = snapshot.data?.presence[userId];
        return builder(context, presence);
      },
    );
  }
}
