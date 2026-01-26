import 'package:flutter/foundation.dart';

/// 変更イベントタイプ
/// サーバーから受信する変更フィードのイベント種別
enum ChangeEventType {
  /// 新規作成
  created('created'),

  /// 更新
  updated('updated'),

  /// 削除
  deleted('deleted'),

  /// バッチ更新（複数リソースの一括変更）
  batchUpdate('batch_update'),

  /// 同期リセット（全データ再取得要求）
  syncReset('sync_reset');

  final String value;
  const ChangeEventType(this.value);

  /// 文字列からenumに変換
  static ChangeEventType fromString(String value) {
    return ChangeEventType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ChangeEventType.updated,
    );
  }

  /// 日本語表示名
  String get displayName {
    switch (this) {
      case ChangeEventType.created:
        return '作成';
      case ChangeEventType.updated:
        return '更新';
      case ChangeEventType.deleted:
        return '削除';
      case ChangeEventType.batchUpdate:
        return '一括更新';
      case ChangeEventType.syncReset:
        return 'リセット';
    }
  }
}

/// リソースタイプ
/// 変更対象のリソース種別
enum ResourceType {
  task('task'),
  project('project'),
  message('message'),
  attachment('attachment'),
  user('user'),
  attendance('attendance'),
  material('material'),
  phase('phase'),
  dependency('dependency'),
  unknown('unknown');

  final String value;
  const ResourceType(this.value);

  static ResourceType fromString(String value) {
    return ResourceType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ResourceType.unknown,
    );
  }
}

/// 変更イベントモデル
///
/// サーバーから受信するチェンジフィードの各イベントを表現
/// カーソルベースのポーリングで使用
@immutable
class ChangeEvent {
  /// イベント固有ID
  final String id;

  /// イベントタイプ
  final ChangeEventType type;

  /// リソースタイプ
  final ResourceType resourceType;

  /// 変更対象リソースID
  final String resourceId;

  /// プロジェクトID（スコープ用）
  final String? projectId;

  /// 変更データ（JSON形式）
  /// 作成/更新時は完全なリソースデータ
  /// 削除時はnull
  final Map<String, dynamic>? payload;

  /// イベント発生時刻
  final DateTime timestamp;

  /// 変更を行ったユーザーID
  final String? changedByUserId;

  /// サーバーシーケンス番号（順序保証用）
  final int? sequenceNumber;

  /// メタデータ（追加情報）
  final Map<String, dynamic>? metadata;

  const ChangeEvent({
    required this.id,
    required this.type,
    required this.resourceType,
    required this.resourceId,
    this.projectId,
    this.payload,
    required this.timestamp,
    this.changedByUserId,
    this.sequenceNumber,
    this.metadata,
  });

  /// JSONからモデルを生成
  factory ChangeEvent.fromJson(Map<String, dynamic> json) {
    return ChangeEvent(
      id: json['id'] as String,
      type: ChangeEventType.fromString(json['type'] as String),
      resourceType: ResourceType.fromString(json['resourceType'] as String),
      resourceId: json['resourceId'] as String,
      projectId: json['projectId'] as String?,
      payload: json['payload'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      changedByUserId: json['changedByUserId'] as String?,
      sequenceNumber: json['sequenceNumber'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// モデルをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'resourceType': resourceType.value,
      'resourceId': resourceId,
      'projectId': projectId,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'changedByUserId': changedByUserId,
      'sequenceNumber': sequenceNumber,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChangeEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChangeEvent(id: $id, type: ${type.displayName}, '
        'resource: ${resourceType.value}/$resourceId, at: $timestamp)';
  }
}

/// 変更フィードレスポンスモデル
///
/// サーバーからのポーリングレスポンスを表現
@immutable
class ChangeFeedResponse {
  /// 取得したイベント一覧
  final List<ChangeEvent> events;

  /// 次回ポーリング用カーソル
  /// このカーソル以降のイベントを取得するために使用
  final String? cursor;

  /// さらにイベントがあるか
  final bool hasMore;

  /// サーバータイムスタンプ
  final DateTime serverTime;

  const ChangeFeedResponse({
    required this.events,
    this.cursor,
    this.hasMore = false,
    required this.serverTime,
  });

  /// JSONからモデルを生成
  factory ChangeFeedResponse.fromJson(Map<String, dynamic> json) {
    final eventsJson = json['events'] as List<dynamic>? ?? [];
    return ChangeFeedResponse(
      events: eventsJson
          .map((e) => ChangeEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      cursor: json['cursor'] as String?,
      hasMore: json['hasMore'] as bool? ?? false,
      serverTime: json['serverTime'] != null
          ? DateTime.parse(json['serverTime'] as String)
          : DateTime.now(),
    );
  }

  /// モデルをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'events': events.map((e) => e.toJson()).toList(),
      'cursor': cursor,
      'hasMore': hasMore,
      'serverTime': serverTime.toIso8601String(),
    };
  }

  /// イベントが空かどうか
  bool get isEmpty => events.isEmpty;

  /// イベント数
  int get eventCount => events.length;
}

/// カーソル確認応答モデル
@immutable
class CursorAckResponse {
  /// 確認成功
  final bool success;

  /// 確認したカーソル
  final String cursor;

  /// サーバータイムスタンプ
  final DateTime serverTime;

  const CursorAckResponse({
    required this.success,
    required this.cursor,
    required this.serverTime,
  });

  /// JSONからモデルを生成
  factory CursorAckResponse.fromJson(Map<String, dynamic> json) {
    return CursorAckResponse(
      success: json['success'] as bool? ?? true,
      cursor: json['cursor'] as String,
      serverTime: json['serverTime'] != null
          ? DateTime.parse(json['serverTime'] as String)
          : DateTime.now(),
    );
  }
}

/// 変更フィードのフィルタリングユーティリティ
extension ChangeEventListExtension on List<ChangeEvent> {
  /// タイプでフィルタ
  List<ChangeEvent> filterByType(ChangeEventType type) {
    return where((e) => e.type == type).toList();
  }

  /// リソースタイプでフィルタ
  List<ChangeEvent> filterByResourceType(ResourceType resourceType) {
    return where((e) => e.resourceType == resourceType).toList();
  }

  /// プロジェクトでフィルタ
  List<ChangeEvent> filterByProject(String projectId) {
    return where((e) => e.projectId == projectId).toList();
  }

  /// 時間範囲でフィルタ
  List<ChangeEvent> filterByTimeRange(DateTime from, DateTime to) {
    return where((e) =>
        e.timestamp.isAfter(from) && e.timestamp.isBefore(to)).toList();
  }

  /// 最新N件を取得
  List<ChangeEvent> latest(int count) {
    final sorted = [...this]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(count).toList();
  }
}

/// 表示用拡張
extension ChangeEventDisplayExtension on ChangeEvent {
  /// 何分前の変更か
  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    return '${diff.inDays}日前';
  }

  /// 表示用のサマリーテキスト
  String get displaySummary {
    return '${resourceType.value}が${type.displayName}されました';
  }
}
