import 'package:flutter/foundation.dart';

/// 入退場イベントタイプ
enum AttendanceEventType {
  /// 入場
  inEvent('IN'),
  /// 退場
  outEvent('OUT'),
  /// 修正（監督・事務のみ）
  edit('EDIT'),
  /// 取消（監督・事務のみ）
  void_('VOID');

  final String value;
  const AttendanceEventType(this.value);

  static AttendanceEventType fromString(String value) {
    return AttendanceEventType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AttendanceEventType.inEvent,
    );
  }

  String get displayName {
    switch (this) {
      case AttendanceEventType.inEvent:
        return '入場';
      case AttendanceEventType.outEvent:
        return '退場';
      case AttendanceEventType.edit:
        return '修正';
      case AttendanceEventType.void_:
        return '取消';
    }
  }

  String get icon {
    switch (this) {
      case AttendanceEventType.inEvent:
        return '🟢';
      case AttendanceEventType.outEvent:
        return '🔴';
      case AttendanceEventType.edit:
        return '✏️';
      case AttendanceEventType.void_:
        return '🚫';
    }
  }
}

/// 同期状態
enum SyncState {
  /// 未同期（ローカルのみ）
  pending('pending'),
  /// 同期済み
  synced('synced'),
  /// 同期失敗
  failed('failed');

  final String value;
  const SyncState(this.value);

  static SyncState fromString(String value) {
    return SyncState.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SyncState.pending,
    );
  }
}

/// 入退場イベントモデル
///
/// 重要: このモデルは追記専用。既存イベントの上書きは禁止。
/// 修正が必要な場合は EDIT/VOID イベントを新規作成。
@immutable
class AttendanceEvent {
  /// ユニークID（UUID）
  final String id;

  /// プロジェクトID
  final String projectId;

  /// 職人ID
  final String personId;

  /// 会社ID
  final String companyId;

  /// イベントタイプ
  final AttendanceEventType type;

  /// イベント発生時刻（端末時刻）
  /// サーバ時刻とズレる可能性あり
  final DateTime occurredAt;

  /// サーバ同期時刻
  final DateTime? syncedAt;

  /// デバイスID（キオスク端末識別）
  final String deviceId;

  /// 作成者ユーザーID
  final String createdByUserId;

  /// GPS緯度（取得できた場合のみ）
  final double? lat;

  /// GPS経度（取得できた場合のみ）
  final double? lng;

  /// 同期状態
  final SyncState syncState;

  /// 修正/取消対象のイベントID
  /// EDIT/VOIDの場合に使用
  final String? editTargetEventId;

  /// 修正メモ（EDIT/VOIDの場合）
  final String? editNote;

  /// 警告フラグ（連続IN/OUT等）
  final bool hasWarning;

  /// 警告メッセージ
  final String? warningMessage;

  const AttendanceEvent({
    required this.id,
    required this.projectId,
    required this.personId,
    required this.companyId,
    required this.type,
    required this.occurredAt,
    this.syncedAt,
    required this.deviceId,
    required this.createdByUserId,
    this.lat,
    this.lng,
    this.syncState = SyncState.pending,
    this.editTargetEventId,
    this.editNote,
    this.hasWarning = false,
    this.warningMessage,
  });

  /// JSONからモデルを生成
  factory AttendanceEvent.fromJson(Map<String, dynamic> json) {
    return AttendanceEvent(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      personId: json['personId'] as String,
      companyId: json['companyId'] as String,
      type: AttendanceEventType.fromString(json['type'] as String),
      occurredAt: DateTime.tryParse(json['occurredAt'] as String? ?? '') ?? DateTime.now(),
      syncedAt: json['syncedAt'] != null
          ? DateTime.tryParse(json['syncedAt'] as String? ?? '')
          : null,
      deviceId: json['deviceId'] as String,
      createdByUserId: json['createdByUserId'] as String,
      lat: json['lat'] as double?,
      lng: json['lng'] as double?,
      syncState: SyncState.fromString(json['syncState'] as String? ?? 'pending'),
      editTargetEventId: json['editTargetEventId'] as String?,
      editNote: json['editNote'] as String?,
      hasWarning: json['hasWarning'] as bool? ?? false,
      warningMessage: json['warningMessage'] as String?,
    );
  }

  /// モデルをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'personId': personId,
      'companyId': companyId,
      'type': type.value,
      'occurredAt': occurredAt.toIso8601String(),
      'syncedAt': syncedAt?.toIso8601String(),
      'deviceId': deviceId,
      'createdByUserId': createdByUserId,
      'lat': lat,
      'lng': lng,
      'syncState': syncState.value,
      'editTargetEventId': editTargetEventId,
      'editNote': editNote,
      'hasWarning': hasWarning,
      'warningMessage': warningMessage,
    };
  }

  /// 同期済みとしてマーク
  AttendanceEvent markAsSynced(DateTime syncTime) {
    return AttendanceEvent(
      id: id,
      projectId: projectId,
      personId: personId,
      companyId: companyId,
      type: type,
      occurredAt: occurredAt,
      syncedAt: syncTime,
      deviceId: deviceId,
      createdByUserId: createdByUserId,
      lat: lat,
      lng: lng,
      syncState: SyncState.synced,
      editTargetEventId: editTargetEventId,
      editNote: editNote,
      hasWarning: hasWarning,
      warningMessage: warningMessage,
    );
  }

  /// 同期失敗としてマーク
  AttendanceEvent markAsFailed() {
    return AttendanceEvent(
      id: id,
      projectId: projectId,
      personId: personId,
      companyId: companyId,
      type: type,
      occurredAt: occurredAt,
      syncedAt: syncedAt,
      deviceId: deviceId,
      createdByUserId: createdByUserId,
      lat: lat,
      lng: lng,
      syncState: SyncState.failed,
      editTargetEventId: editTargetEventId,
      editNote: editNote,
      hasWarning: hasWarning,
      warningMessage: warningMessage,
    );
  }

  /// CSV行として出力
  String toCsvRow(String personName, String companyName) {
    return [
      occurredAt.toIso8601String(),
      type.displayName,
      personName,
      companyName,
      lat?.toString() ?? '',
      lng?.toString() ?? '',
      syncState.value,
      hasWarning ? warningMessage ?? '警告' : '',
    ].join(',');
  }

  /// CSVヘッダー
  static String get csvHeader {
    return '日時,種別,氏名,会社,緯度,経度,同期状態,警告';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttendanceEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AttendanceEvent(id: $id, type: ${type.displayName}, person: $personId, at: $occurredAt)';
  }
}

/// 日次集計モデル
class DailyAttendanceSummary {
  final DateTime date;
  final String personId;
  final String personName;
  final String companyId;
  final String companyName;
  final DateTime? firstIn;
  final DateTime? lastOut;
  final Duration? workingHours;
  final bool hasAutoCorrection;
  final List<AttendanceEvent> events;

  const DailyAttendanceSummary({
    required this.date,
    required this.personId,
    required this.personName,
    required this.companyId,
    required this.companyName,
    this.firstIn,
    this.lastOut,
    this.workingHours,
    this.hasAutoCorrection = false,
    this.events = const [],
  });

  /// 人工（8時間=1人工として計算）
  double get manDays {
    if (workingHours == null) return 0;
    return workingHours!.inMinutes / 480; // 8時間 = 480分
  }

  /// 勤務時間を文字列で表示
  String get workingHoursDisplay {
    if (workingHours == null) return '-';
    final hours = workingHours!.inHours;
    final minutes = workingHours!.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
