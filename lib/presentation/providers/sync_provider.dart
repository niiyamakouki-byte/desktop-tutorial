/// Sync Provider
/// アプリ全体の同期状態を管理するProvider
///
/// React版SyncProviderに基づく実装:
/// - ポーリングループ（setInterval相当）
/// - visibilitychange対応（タブがアクティブな時だけポーリング）
/// - エラー時は黙って次回（現場は落ちる前提）

import 'package:flutter/material.dart';

import '../../data/services/sync_service.dart';
import '../../data/services/presence_service.dart';
import '../../data/services/outbox_service.dart';
import '../../data/models/change_event_model.dart';

/// Sync設定オプション
class SyncOptions {
  /// プロジェクトID
  final String? projectId;

  /// デバイスID
  final String? deviceId;

  /// ユーザーID
  final String? userId;

  /// 変更ポーリング間隔（ミリ秒）
  final int pollChangesMs;

  /// Heartbeat間隔（ミリ秒）
  final int heartbeatMs;

  /// Outbox処理間隔（ミリ秒）
  final int outboxProcessMs;

  /// APIベースURL
  final String apiBaseUrl;

  const SyncOptions({
    this.projectId,
    this.deviceId,
    this.userId,
    this.pollChangesMs = 7000,
    this.heartbeatMs = 20000,
    this.outboxProcessMs = 5000,
    this.apiBaseUrl = '/api',
  });
}

/// Sync状態
class SyncProviderState {
  final SyncState syncState;
  final PresenceState presenceState;
  final OutboxState outboxState;
  final bool isOnline;
  final bool isAppActive;

  const SyncProviderState({
    required this.syncState,
    required this.presenceState,
    required this.outboxState,
    this.isOnline = true,
    this.isAppActive = true,
  });

  /// 未確認の変更数
  int get unackedCount => syncState.unackedCount;

  /// オンラインメンバー数
  int get onlineMembers => presenceState.onlineCount;

  /// 保留中のOutboxアイテム数
  int get pendingOutbox => outboxState.pendingCount;

  /// 同期中かどうか
  bool get isSyncing => syncState.status == SyncStatus.syncing;
}

/// SyncProvider Widget
/// アプリのルートに配置して同期機能を提供
class SyncProvider extends StatefulWidget {
  final SyncOptions options;
  final Widget child;

  /// 変更イベント受信時のコールバック
  final void Function(List<ChangeEvent>)? onChangesReceived;

  /// エラー発生時のコールバック
  final void Function(String error)? onError;

  const SyncProvider({
    super.key,
    required this.options,
    required this.child,
    this.onChangesReceived,
    this.onError,
  });

  /// 現在のSyncProviderStateを取得
  static SyncProviderState of(BuildContext context) {
    final state = context
        .dependOnInheritedWidgetOfExactType<_SyncProviderInherited>()
        ?.state;
    if (state == null) {
      throw FlutterError(
        'SyncProvider.of() called with a context that does not contain a SyncProvider.',
      );
    }
    return state;
  }

  /// SyncServiceを取得
  static SyncService syncService(BuildContext context) {
    return SyncServiceProvider.instance;
  }

  /// PresenceServiceを取得
  static PresenceService presenceService(BuildContext context) {
    return PresenceServiceProvider.instance;
  }

  /// OutboxServiceを取得
  static OutboxService outboxService(BuildContext context) {
    return OutboxServiceProvider.instance;
  }

  @override
  State<SyncProvider> createState() => _SyncProviderState();
}

class _SyncProviderState extends State<SyncProvider> with WidgetsBindingObserver {
  late SyncProviderState _state;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // SyncServiceを初期化
    SyncServiceProvider.initialize(SyncConfig(
      pollingIntervalMs: widget.options.pollChangesMs,
      apiBaseUrl: widget.options.apiBaseUrl,
    ));

    // PresenceServiceを初期化
    PresenceServiceProvider.initialize(
      PresenceConfig(
        heartbeatIntervalMs: widget.options.heartbeatMs,
        apiBaseUrl: widget.options.apiBaseUrl,
      ),
      userId: widget.options.userId,
    );

    // OutboxServiceを初期化
    await OutboxServiceProvider.initialize(OutboxConfig(
      processIntervalMs: widget.options.outboxProcessMs,
      apiBaseUrl: widget.options.apiBaseUrl,
    ));

    // 初期状態を設定
    _state = SyncProviderState(
      syncState: SyncServiceProvider.instance.state,
      presenceState: PresenceServiceProvider.instance.state,
      outboxState: OutboxServiceProvider.instance.state,
    );

    // 状態変更をリッスン
    SyncServiceProvider.instance.stateStream.listen((syncState) {
      if (mounted) {
        setState(() {
          _state = SyncProviderState(
            syncState: syncState,
            presenceState: _state.presenceState,
            outboxState: _state.outboxState,
            isOnline: _state.isOnline,
            isAppActive: _state.isAppActive,
          );
        });
      }
    });

    PresenceServiceProvider.instance.stateStream.listen((presenceState) {
      if (mounted) {
        setState(() {
          _state = SyncProviderState(
            syncState: _state.syncState,
            presenceState: presenceState,
            outboxState: _state.outboxState,
            isOnline: _state.isOnline,
            isAppActive: _state.isAppActive,
          );
        });
      }
    });

    OutboxServiceProvider.instance.stateStream.listen((outboxState) {
      if (mounted) {
        setState(() {
          _state = SyncProviderState(
            syncState: _state.syncState,
            presenceState: _state.presenceState,
            outboxState: outboxState,
            isOnline: _state.isOnline,
            isAppActive: _state.isAppActive,
          );
        });
      }
    });

    // 変更イベントコールバックを設定
    if (widget.onChangesReceived != null) {
      SyncServiceProvider.instance.addEventListener(widget.onChangesReceived!);
    }

    // ポーリング開始
    SyncServiceProvider.instance.startPolling();
    PresenceServiceProvider.instance.startHeartbeat();

    setState(() {
      _initialized = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // アプリがバックグラウンドに移行した場合
    final isActive = state == AppLifecycleState.resumed;

    setState(() {
      _state = SyncProviderState(
        syncState: _state.syncState,
        presenceState: _state.presenceState,
        outboxState: _state.outboxState,
        isOnline: _state.isOnline,
        isAppActive: isActive,
      );
    });

    // サービスに通知
    SyncServiceProvider.instance.setAppActive(isActive);

    if (isActive) {
      // フォアグラウンド復帰時
      PresenceServiceProvider.instance.startHeartbeat();
      OutboxServiceProvider.instance.processOutbox();
    } else {
      // バックグラウンド移行時
      PresenceServiceProvider.instance.stopHeartbeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // コールバックを解除
    if (widget.onChangesReceived != null) {
      SyncServiceProvider.instance.removeEventListener(widget.onChangesReceived!);
    }

    // サービスを停止（破棄はしない - シングルトンなので）
    SyncServiceProvider.instance.stopPolling();
    PresenceServiceProvider.instance.stopHeartbeat();
    OutboxServiceProvider.instance.stopProcessing();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return _SyncProviderInherited(
      state: _state,
      child: widget.child,
    );
  }
}

/// InheritedWidget for SyncProvider
class _SyncProviderInherited extends InheritedWidget {
  final SyncProviderState state;

  const _SyncProviderInherited({
    required this.state,
    required super.child,
  });

  @override
  bool updateShouldNotify(_SyncProviderInherited oldWidget) {
    return state != oldWidget.state;
  }
}

/// 同期ステータスインジケーター
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SyncProvider.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(state).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.isSyncing)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getStatusColor(state),
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            _getStatusText(state),
            style: TextStyle(
              fontSize: 11,
              color: _getStatusColor(state),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(SyncProviderState state) {
    if (!state.isOnline) {
      return const Color(0xFF9E9E9E);
    }
    if (state.isSyncing) {
      return const Color(0xFF2196F3);
    }
    if (state.syncState.status == SyncStatus.error) {
      return const Color(0xFFF44336);
    }
    return const Color(0xFF4CAF50);
  }

  String _getStatusText(SyncProviderState state) {
    if (!state.isOnline) return 'オフライン';
    if (state.isSyncing) return '同期中...';
    if (state.syncState.status == SyncStatus.error) return 'エラー';
    return '同期済み';
  }
}

/// オンラインメンバー数バッジ
class OnlineMembersBadge extends StatelessWidget {
  const OnlineMembersBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SyncProvider.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${state.onlineMembers}人オンライン',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF4CAF50),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 未確認変更バッジ
class UnackedChangesBadge extends StatelessWidget {
  final VoidCallback? onTap;

  const UnackedChangesBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final state = SyncProvider.of(context);

    if (state.unackedCount == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF44336),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sync,
              size: 12,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              '${state.unackedCount}件の変更',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
