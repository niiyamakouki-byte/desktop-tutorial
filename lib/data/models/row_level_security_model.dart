/// Row Level Security Model
/// 行レベルセキュリティモデル
///
/// Geminiセキュリティレビューに基づく設計:
/// - LINE UID + 本名 + 電話番号がセットで漏れると致命的
/// - 対策：行レベルセキュリティ（現場監督ごとに閲覧権限）
/// - 10社を超えたらPostgreSQL（Supabase等）へ移行必須

import 'package:flutter/foundation.dart';

/// 権限レベル
enum PermissionLevel {
  /// なし
  none('none', 0),

  /// 閲覧のみ
  read('read', 1),

  /// 編集可能
  write('write', 2),

  /// 管理者（削除可能）
  admin('admin', 3),

  /// オーナー（全権限）
  owner('owner', 4);

  final String value;
  final int level;

  const PermissionLevel(this.value, this.level);

  static PermissionLevel fromString(String value) {
    return PermissionLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PermissionLevel.none,
    );
  }

  /// この権限レベル以上か
  bool isAtLeast(PermissionLevel required) {
    return level >= required.level;
  }
}

/// リソースタイプ
enum SecurityResourceType {
  /// プロジェクト
  project('project'),

  /// タスク
  task('task'),

  /// フェーズ
  phase('phase'),

  /// ワーカー（職人）
  worker('worker'),

  /// ドキュメント
  document('document'),

  /// レポート
  report('report'),

  /// 組織
  organization('organization');

  final String value;

  const SecurityResourceType(this.value);

  static SecurityResourceType fromString(String value) {
    return SecurityResourceType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SecurityResourceType.project,
    );
  }
}

/// アクセス許可ポリシー
class AccessPolicy {
  /// ポリシーID
  final String id;

  /// ポリシー名
  final String name;

  /// 対象リソースタイプ
  final SecurityResourceType resourceType;

  /// 条件（SQLライクな条件式）
  final String? condition;

  /// 付与する権限
  final PermissionLevel permission;

  /// 説明
  final String? description;

  const AccessPolicy({
    required this.id,
    required this.name,
    required this.resourceType,
    this.condition,
    required this.permission,
    this.description,
  });

  factory AccessPolicy.fromJson(Map<String, dynamic> json) {
    return AccessPolicy(
      id: json['id'] as String,
      name: json['name'] as String,
      resourceType: SecurityResourceType.fromString(json['resourceType'] as String),
      condition: json['condition'] as String?,
      permission: PermissionLevel.fromString(json['permission'] as String),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'resourceType': resourceType.value,
        'condition': condition,
        'permission': permission.value,
        'description': description,
      };
}

/// ロール（役割）
class Role {
  /// ロールID
  final String id;

  /// ロール名
  final String name;

  /// 説明
  final String? description;

  /// 付与されたポリシー
  final List<String> policyIds;

  /// システムロールか
  final bool isSystem;

  const Role({
    required this.id,
    required this.name,
    this.description,
    this.policyIds = const [],
    this.isSystem = false,
  });

  /// システムデフォルトロール
  static const Role supervisor = Role(
    id: 'role_supervisor',
    name: '現場監督',
    description: '担当プロジェクトの全権限',
    policyIds: ['policy_project_admin'],
    isSystem: true,
  );

  static const Role worker = Role(
    id: 'role_worker',
    name: '職人',
    description: '割り当てタスクの閲覧のみ',
    policyIds: ['policy_task_read'],
    isSystem: true,
  );

  static const Role viewer = Role(
    id: 'role_viewer',
    name: '閲覧者',
    description: '全プロジェクトの閲覧のみ',
    policyIds: ['policy_project_read'],
    isSystem: true,
  );

  static const Role admin = Role(
    id: 'role_admin',
    name: '管理者',
    description: '組織の全権限',
    policyIds: ['policy_all_admin'],
    isSystem: true,
  );

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      policyIds: (json['policyIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isSystem: json['isSystem'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'policyIds': policyIds,
        'isSystem': isSystem,
      };
}

/// ユーザーのリソースアクセス権限
class UserResourceAccess {
  /// ユーザーID
  final String userId;

  /// リソースタイプ
  final SecurityResourceType resourceType;

  /// リソースID
  final String resourceId;

  /// 権限レベル
  final PermissionLevel permission;

  /// 付与元ロールID
  final String? grantedByRoleId;

  /// 付与日時
  final DateTime grantedAt;

  /// 期限（nullの場合は無期限）
  final DateTime? expiresAt;

  const UserResourceAccess({
    required this.userId,
    required this.resourceType,
    required this.resourceId,
    required this.permission,
    this.grantedByRoleId,
    required this.grantedAt,
    this.expiresAt,
  });

  /// 有効期限内か
  bool get isValid {
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  factory UserResourceAccess.fromJson(Map<String, dynamic> json) {
    return UserResourceAccess(
      userId: json['userId'] as String,
      resourceType: SecurityResourceType.fromString(json['resourceType'] as String),
      resourceId: json['resourceId'] as String,
      permission: PermissionLevel.fromString(json['permission'] as String),
      grantedByRoleId: json['grantedByRoleId'] as String?,
      grantedAt: DateTime.parse(json['grantedAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'resourceType': resourceType.value,
        'resourceId': resourceId,
        'permission': permission.value,
        'grantedByRoleId': grantedByRoleId,
        'grantedAt': grantedAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
      };
}

/// 行レベルセキュリティマネージャー
class RowLevelSecurityManager {
  final Map<String, List<UserResourceAccess>> _accessCache = {};
  final Map<String, Role> _userRoles = {};

  /// ユーザーの権限を確認
  bool hasPermission({
    required String userId,
    required SecurityResourceType resourceType,
    required String resourceId,
    required PermissionLevel requiredLevel,
  }) {
    // キャッシュから権限を取得
    final accessList = _accessCache[userId] ?? [];

    // 直接付与された権限を確認
    final directAccess = accessList.where((a) =>
        a.resourceType == resourceType &&
        a.resourceId == resourceId &&
        a.isValid);

    for (final access in directAccess) {
      if (access.permission.isAtLeast(requiredLevel)) {
        return true;
      }
    }

    // ロールによる権限を確認
    final userRole = _userRoles[userId];
    if (userRole != null) {
      // TODO: ポリシーを評価して権限を判定
      if (userRole.id == Role.admin.id) {
        return true;
      }
    }

    return false;
  }

  /// ユーザーがアクセスできるリソースIDリストを取得
  List<String> getAccessibleResourceIds({
    required String userId,
    required SecurityResourceType resourceType,
    PermissionLevel? minimumLevel,
  }) {
    final accessList = _accessCache[userId] ?? [];

    return accessList
        .where((a) =>
            a.resourceType == resourceType &&
            a.isValid &&
            (minimumLevel == null || a.permission.isAtLeast(minimumLevel)))
        .map((a) => a.resourceId)
        .toList();
  }

  /// 権限を付与
  void grantAccess({
    required String userId,
    required SecurityResourceType resourceType,
    required String resourceId,
    required PermissionLevel permission,
    String? grantedByRoleId,
    DateTime? expiresAt,
  }) {
    final access = UserResourceAccess(
      userId: userId,
      resourceType: resourceType,
      resourceId: resourceId,
      permission: permission,
      grantedByRoleId: grantedByRoleId,
      grantedAt: DateTime.now(),
      expiresAt: expiresAt,
    );

    _accessCache.putIfAbsent(userId, () => []).add(access);
  }

  /// 権限を取り消し
  void revokeAccess({
    required String userId,
    required SecurityResourceType resourceType,
    required String resourceId,
  }) {
    final accessList = _accessCache[userId];
    if (accessList != null) {
      accessList.removeWhere((a) =>
          a.resourceType == resourceType && a.resourceId == resourceId);
    }
  }

  /// ロールを割り当て
  void assignRole(String userId, Role role) {
    _userRoles[userId] = role;
  }

  /// ロールを解除
  void unassignRole(String userId) {
    _userRoles.remove(userId);
  }

  /// キャッシュをクリア
  void clearCache() {
    _accessCache.clear();
  }

  /// デバッグ: ユーザーの権限一覧を出力
  void debugPrintUserPermissions(String userId) {
    if (!kDebugMode) return;

    print('=== Permissions for user: $userId ===');
    print('Role: ${_userRoles[userId]?.name ?? 'None'}');

    final accessList = _accessCache[userId] ?? [];
    for (final access in accessList) {
      print(
          '  ${access.resourceType.value}/${access.resourceId}: ${access.permission.value}');
    }
  }
}

/// セキュリティ監査ログ
class SecurityAuditLog {
  /// ログID
  final String id;

  /// アクション
  final SecurityAction action;

  /// ユーザーID
  final String userId;

  /// リソースタイプ
  final SecurityResourceType? resourceType;

  /// リソースID
  final String? resourceId;

  /// 結果（成功/失敗）
  final bool success;

  /// 詳細
  final String? details;

  /// IPアドレス
  final String? ipAddress;

  /// タイムスタンプ
  final DateTime timestamp;

  const SecurityAuditLog({
    required this.id,
    required this.action,
    required this.userId,
    this.resourceType,
    this.resourceId,
    required this.success,
    this.details,
    this.ipAddress,
    required this.timestamp,
  });

  factory SecurityAuditLog.fromJson(Map<String, dynamic> json) {
    return SecurityAuditLog(
      id: json['id'] as String,
      action: SecurityAction.fromString(json['action'] as String),
      userId: json['userId'] as String,
      resourceType: json['resourceType'] != null
          ? SecurityResourceType.fromString(json['resourceType'] as String)
          : null,
      resourceId: json['resourceId'] as String?,
      success: json['success'] as bool,
      details: json['details'] as String?,
      ipAddress: json['ipAddress'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action.value,
        'userId': userId,
        'resourceType': resourceType?.value,
        'resourceId': resourceId,
        'success': success,
        'details': details,
        'ipAddress': ipAddress,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// セキュリティアクション
enum SecurityAction {
  /// ログイン
  login('login'),

  /// ログアウト
  logout('logout'),

  /// リソースアクセス
  access('access'),

  /// リソース作成
  create('create'),

  /// リソース更新
  update('update'),

  /// リソース削除
  delete('delete'),

  /// 権限変更
  permissionChange('permission_change'),

  /// エクスポート
  export('export');

  final String value;

  const SecurityAction(this.value);

  static SecurityAction fromString(String value) {
    return SecurityAction.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SecurityAction.access,
    );
  }
}

/// 機密データマスキング
class DataMasking {
  /// 電話番号をマスク（例: 090-****-5678）
  static String maskPhoneNumber(String phone) {
    if (phone.length < 8) return '****';

    // ハイフンを除去
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-****-${digits.substring(7)}';
    } else if (digits.length == 10) {
      return '${digits.substring(0, 3)}-***-${digits.substring(6)}';
    }

    return '****';
  }

  /// メールアドレスをマスク（例: t***@example.com）
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***@***';

    final localPart = parts[0];
    final domain = parts[1];

    if (localPart.length <= 1) {
      return '*@$domain';
    }

    return '${localPart[0]}***@$domain';
  }

  /// LINE UIDをマスク（例: U1234***）
  static String maskLineUid(String uid) {
    if (uid.length <= 5) return '***';
    return '${uid.substring(0, 5)}***';
  }

  /// 名前をマスク（例: 山田 *）
  static String maskName(String name) {
    if (name.isEmpty) return '*';

    // スペースで分割
    final parts = name.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      // 苗字のみ
      return '${name[0]}${'*' * (name.length - 1)}';
    }

    // 苗字 + 名前の最初の文字
    return '${parts[0]} ${parts.sublist(1).map((p) => p.isNotEmpty ? p[0] : '').join()}*';
  }
}
