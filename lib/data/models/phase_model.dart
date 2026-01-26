/// Phase Model for Construction Project Management
/// 工程フェーズモデル - バトンパス方式の工程管理

import 'package:flutter/material.dart';

/// 工程フェーズ
///
/// フェーズは「バトンパスの区切り」を表す。
/// 同じフェーズ内のタスクは並行作業可能。
/// 異なるフェーズ間は直列（前のフェーズが終わらないと次が始まらない）。
class Phase {
  final String id;
  final String projectId;
  final String name;
  final int order; // 同一プロジェクト内での順序（1, 2, 3...）
  final String? dependencyGroup; // 並列フェーズグループID（1F/2Fなど）
  final String? contractorId; // 主担当業者ID
  final String? contractorName; // 主担当業者名
  final PhaseType type; // フェーズ種別
  final DateTime createdAt;
  final DateTime updatedAt;

  const Phase({
    required this.id,
    required this.projectId,
    required this.name,
    required this.order,
    this.dependencyGroup,
    this.contractorId,
    this.contractorName,
    this.type = PhaseType.construction,
    required this.createdAt,
    required this.updatedAt,
  });

  Phase copyWith({
    String? id,
    String? projectId,
    String? name,
    int? order,
    String? dependencyGroup,
    String? contractorId,
    String? contractorName,
    PhaseType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Phase(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      order: order ?? this.order,
      dependencyGroup: dependencyGroup ?? this.dependencyGroup,
      contractorId: contractorId ?? this.contractorId,
      contractorName: contractorName ?? this.contractorName,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'name': name,
        'order': order,
        'dependencyGroup': dependencyGroup,
        'contractorId': contractorId,
        'contractorName': contractorName,
        'type': type.value,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Phase.fromJson(Map<String, dynamic> json) {
    return Phase(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      order: json['order'] as int,
      dependencyGroup: json['dependencyGroup'] as String?,
      contractorId: json['contractorId'] as String?,
      contractorName: json['contractorName'] as String?,
      type: PhaseType.fromString(json['type'] as String? ?? 'construction'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// フェーズの表示色を取得
  Color get color => type.color;

  /// フェーズの短縮名（Phase 1 → P1）
  String get shortName => 'P$order';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Phase && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Phase($name, order: $order)';
}

/// フェーズ種別
enum PhaseType {
  preparation('preparation', '準備', Color(0xFF9E9E9E)),
  foundation('foundation', '基礎', Color(0xFF795548)),
  structure('structure', '躯体', Color(0xFF2196F3)),
  construction('construction', '施工', Color(0xFF4CAF50)),
  finishing('finishing', '仕上げ', Color(0xFF9C27B0)),
  inspection('inspection', '検査', Color(0xFFFF9800)),
  handover('handover', '引渡し', Color(0xFFE91E63));

  final String value;
  final String displayName;
  final Color color;

  const PhaseType(this.value, this.displayName, this.color);

  static PhaseType fromString(String value) {
    return PhaseType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PhaseType.construction,
    );
  }
}

/// フェーズプリセット（一式工事向け）
class PhasePresets {
  /// 住宅工事の標準フェーズ
  static List<PhaseTemplate> residentialConstruction() {
    return [
      PhaseTemplate(order: 1, name: '下地工事', type: PhaseType.construction),
      PhaseTemplate(order: 2, name: '設備工事', type: PhaseType.construction),
      PhaseTemplate(order: 3, name: '仕上げ工事', type: PhaseType.finishing),
      PhaseTemplate(order: 4, name: 'クリーニング・検査', type: PhaseType.inspection),
      PhaseTemplate(order: 5, name: '引渡し', type: PhaseType.handover),
    ];
  }

  /// リフォーム工事の標準フェーズ
  static List<PhaseTemplate> renovationConstruction() {
    return [
      PhaseTemplate(order: 1, name: '解体・撤去', type: PhaseType.preparation),
      PhaseTemplate(order: 2, name: '下地・造作', type: PhaseType.construction),
      PhaseTemplate(order: 3, name: '設備更新', type: PhaseType.construction),
      PhaseTemplate(order: 4, name: '内装仕上げ', type: PhaseType.finishing),
      PhaseTemplate(order: 5, name: '完了検査', type: PhaseType.inspection),
    ];
  }

  /// 商業施設の標準フェーズ
  static List<PhaseTemplate> commercialConstruction() {
    return [
      PhaseTemplate(order: 1, name: '躯体工事', type: PhaseType.structure),
      PhaseTemplate(order: 2, name: '電気・空調', type: PhaseType.construction),
      PhaseTemplate(order: 3, name: '内装工事', type: PhaseType.finishing),
      PhaseTemplate(order: 4, name: '什器設置', type: PhaseType.finishing),
      PhaseTemplate(order: 5, name: '検査・引渡し', type: PhaseType.handover),
    ];
  }
}

/// フェーズテンプレート
class PhaseTemplate {
  final int order;
  final String name;
  final PhaseType type;

  const PhaseTemplate({
    required this.order,
    required this.name,
    required this.type,
  });
}

/// フェーズ日程計算結果
class PhaseSchedule {
  final String phaseId;
  final DateTime startDate; // フェーズ内の最早開始日
  final DateTime endDate; // フェーズ内の最遅終了日
  final int taskCount; // タスク数
  final bool hasOverlap; // 前のフェーズとの重複があるか

  const PhaseSchedule({
    required this.phaseId,
    required this.startDate,
    required this.endDate,
    required this.taskCount,
    this.hasOverlap = false,
  });

  int get durationDays => endDate.difference(startDate).inDays + 1;
}

/// フェーズ色の一覧（フェーズ順序に基づく色分け）
class PhaseColors {
  static const List<Color> orderColors = [
    Color(0xFF2196F3), // Phase 1 - 青
    Color(0xFF4CAF50), // Phase 2 - 緑
    Color(0xFFFF9800), // Phase 3 - オレンジ
    Color(0xFF9C27B0), // Phase 4 - 紫
    Color(0xFFE91E63), // Phase 5 - ピンク
    Color(0xFF00BCD4), // Phase 6 - シアン
    Color(0xFF795548), // Phase 7 - 茶
    Color(0xFF607D8B), // Phase 8 - グレー
  ];

  /// フェーズ順序から色を取得
  static Color getColorForOrder(int order) {
    if (order < 1) return orderColors[0];
    return orderColors[(order - 1) % orderColors.length];
  }

  /// 淡い背景色を取得
  static Color getLightColorForOrder(int order) {
    return getColorForOrder(order).withOpacity(0.15);
  }
}
