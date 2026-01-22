/// Safety Management Models
/// 安全管理関連のモデル定義

import 'package:flutter/foundation.dart';

// ===========================================
// KY（危険予知）活動記録
// ===========================================

/// KY活動記録
@immutable
class KYActivityRecord {
  final String id;
  final String projectId;
  final DateTime date;
  final String workContent; // 作業内容
  final List<HazardItem> hazardItems; // 予測される危険と対策
  final List<String> participantIds; // 参加者ID
  final List<String> photoUrls; // 添付写真
  final String? weatherCondition; // 天候
  final String? location; // 作業場所
  final String createdById;
  final DateTime createdAt;
  final DateTime updatedAt;

  const KYActivityRecord({
    required this.id,
    required this.projectId,
    required this.date,
    required this.workContent,
    required this.hazardItems,
    required this.participantIds,
    this.photoUrls = const [],
    this.weatherCondition,
    this.location,
    required this.createdById,
    required this.createdAt,
    required this.updatedAt,
  });

  KYActivityRecord copyWith({
    String? id,
    String? projectId,
    DateTime? date,
    String? workContent,
    List<HazardItem>? hazardItems,
    List<String>? participantIds,
    List<String>? photoUrls,
    String? weatherCondition,
    String? location,
    String? createdById,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KYActivityRecord(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      workContent: workContent ?? this.workContent,
      hazardItems: hazardItems ?? this.hazardItems,
      participantIds: participantIds ?? this.participantIds,
      photoUrls: photoUrls ?? this.photoUrls,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      location: location ?? this.location,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'date': date.toIso8601String(),
        'workContent': workContent,
        'hazardItems': hazardItems.map((h) => h.toJson()).toList(),
        'participantIds': participantIds,
        'photoUrls': photoUrls,
        'weatherCondition': weatherCondition,
        'location': location,
        'createdById': createdById,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory KYActivityRecord.fromJson(Map<String, dynamic> json) {
    return KYActivityRecord(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      date: DateTime.parse(json['date'] as String),
      workContent: json['workContent'] as String,
      hazardItems: (json['hazardItems'] as List)
          .map((h) => HazardItem.fromJson(h as Map<String, dynamic>))
          .toList(),
      participantIds: (json['participantIds'] as List).cast<String>(),
      photoUrls: (json['photoUrls'] as List?)?.cast<String>() ?? [],
      weatherCondition: json['weatherCondition'] as String?,
      location: json['location'] as String?,
      createdById: json['createdById'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// 危険予測項目
@immutable
class HazardItem {
  final String id;
  final String hazardDescription; // 予測される危険
  final String countermeasure; // 対策
  final HazardCategory category; // カテゴリ

  const HazardItem({
    required this.id,
    required this.hazardDescription,
    required this.countermeasure,
    this.category = HazardCategory.other,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'hazardDescription': hazardDescription,
        'countermeasure': countermeasure,
        'category': category.value,
      };

  factory HazardItem.fromJson(Map<String, dynamic> json) {
    return HazardItem(
      id: json['id'] as String,
      hazardDescription: json['hazardDescription'] as String,
      countermeasure: json['countermeasure'] as String,
      category: HazardCategory.fromString(json['category'] as String? ?? 'other'),
    );
  }
}

/// 危険カテゴリ
enum HazardCategory {
  falling('falling', '墜落・転落', '🪜'),
  collapse('collapse', '崩壊・倒壊', '🏚️'),
  collision('collision', '飛来・落下', '⚠️'),
  caught('caught', '挟まれ・巻き込まれ', '⚙️'),
  electric('electric', '感電', '⚡'),
  fire('fire', '火災', '🔥'),
  heatstroke('heatstroke', '熱中症', '☀️'),
  traffic('traffic', '交通事故', '🚗'),
  other('other', 'その他', '📋');

  final String value;
  final String displayName;
  final String icon;

  const HazardCategory(this.value, this.displayName, this.icon);

  static HazardCategory fromString(String value) {
    return HazardCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => HazardCategory.other,
    );
  }
}

// ===========================================
// ヒヤリハット報告
// ===========================================

/// ヒヤリハット報告
@immutable
class NearMissReport {
  final String id;
  final String projectId;
  final DateTime occurredAt; // 発生日時
  final String location; // 発生場所
  final String description; // 内容
  final String causeAnalysis; // 原因分析
  final String countermeasure; // 対策
  final NearMissSeverity severity; // 重要度
  final NearMissCategory category; // カテゴリ
  final List<String> photoUrls; // 写真
  final String reporterId; // 報告者
  final NearMissStatus status; // ステータス
  final String? reviewedById; // 確認者
  final DateTime? reviewedAt; // 確認日時
  final String? reviewComment; // 確認コメント
  final DateTime createdAt;
  final DateTime updatedAt;

  const NearMissReport({
    required this.id,
    required this.projectId,
    required this.occurredAt,
    required this.location,
    required this.description,
    required this.causeAnalysis,
    required this.countermeasure,
    required this.severity,
    this.category = NearMissCategory.other,
    this.photoUrls = const [],
    required this.reporterId,
    this.status = NearMissStatus.reported,
    this.reviewedById,
    this.reviewedAt,
    this.reviewComment,
    required this.createdAt,
    required this.updatedAt,
  });

  NearMissReport copyWith({
    String? id,
    String? projectId,
    DateTime? occurredAt,
    String? location,
    String? description,
    String? causeAnalysis,
    String? countermeasure,
    NearMissSeverity? severity,
    NearMissCategory? category,
    List<String>? photoUrls,
    String? reporterId,
    NearMissStatus? status,
    String? reviewedById,
    DateTime? reviewedAt,
    String? reviewComment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NearMissReport(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      occurredAt: occurredAt ?? this.occurredAt,
      location: location ?? this.location,
      description: description ?? this.description,
      causeAnalysis: causeAnalysis ?? this.causeAnalysis,
      countermeasure: countermeasure ?? this.countermeasure,
      severity: severity ?? this.severity,
      category: category ?? this.category,
      photoUrls: photoUrls ?? this.photoUrls,
      reporterId: reporterId ?? this.reporterId,
      status: status ?? this.status,
      reviewedById: reviewedById ?? this.reviewedById,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewComment: reviewComment ?? this.reviewComment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'occurredAt': occurredAt.toIso8601String(),
        'location': location,
        'description': description,
        'causeAnalysis': causeAnalysis,
        'countermeasure': countermeasure,
        'severity': severity.value,
        'category': category.value,
        'photoUrls': photoUrls,
        'reporterId': reporterId,
        'status': status.value,
        'reviewedById': reviewedById,
        'reviewedAt': reviewedAt?.toIso8601String(),
        'reviewComment': reviewComment,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory NearMissReport.fromJson(Map<String, dynamic> json) {
    return NearMissReport(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      location: json['location'] as String,
      description: json['description'] as String,
      causeAnalysis: json['causeAnalysis'] as String,
      countermeasure: json['countermeasure'] as String,
      severity: NearMissSeverity.fromString(json['severity'] as String),
      category: NearMissCategory.fromString(json['category'] as String? ?? 'other'),
      photoUrls: (json['photoUrls'] as List?)?.cast<String>() ?? [],
      reporterId: json['reporterId'] as String,
      status: NearMissStatus.fromString(json['status'] as String? ?? 'reported'),
      reviewedById: json['reviewedById'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      reviewComment: json['reviewComment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// ヒヤリハット重要度
enum NearMissSeverity {
  high('high', '高', SafetyColors.red),
  medium('medium', '中', SafetyColors.orange),
  low('low', '低', SafetyColors.yellow);

  final String value;
  final String displayName;
  final dynamic color;

  const NearMissSeverity(this.value, this.displayName, this.color);

  static NearMissSeverity fromString(String value) {
    return NearMissSeverity.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NearMissSeverity.medium,
    );
  }
}

/// Safety colors placeholder for enum
class SafetyColors {
  static const red = 0xFFE53935;
  static const orange = 0xFFFF9800;
  static const yellow = 0xFFFFC107;
}

/// ヒヤリハットカテゴリ
enum NearMissCategory {
  falling('falling', '墜落・転落'),
  collapse('collapse', '崩壊・倒壊'),
  collision('collision', '飛来・落下'),
  caught('caught', '挟まれ・巻き込まれ'),
  electric('electric', '感電'),
  fire('fire', '火災'),
  vehicle('vehicle', '車両系'),
  crane('crane', 'クレーン'),
  scaffold('scaffold', '足場'),
  excavation('excavation', '掘削'),
  other('other', 'その他');

  final String value;
  final String displayName;

  const NearMissCategory(this.value, this.displayName);

  static NearMissCategory fromString(String value) {
    return NearMissCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NearMissCategory.other,
    );
  }
}

/// ヒヤリハットステータス
enum NearMissStatus {
  reported('reported', '報告済'),
  reviewing('reviewing', '確認中'),
  resolved('resolved', '対策完了'),
  closed('closed', '完了');

  final String value;
  final String displayName;

  const NearMissStatus(this.value, this.displayName);

  static NearMissStatus fromString(String value) {
    return NearMissStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NearMissStatus.reported,
    );
  }
}

// ===========================================
// 安全パトロールチェックリスト
// ===========================================

/// 安全パトロール記録
@immutable
class SafetyPatrolRecord {
  final String id;
  final String projectId;
  final DateTime patrolDate; // パトロール日
  final String patrollerName; // パトロール者
  final String patrollerId;
  final List<PatrolCheckItem> checkItems; // チェック項目
  final List<NonConformanceItem> nonConformances; // 不適合箇所
  final String? overallComment; // 総合コメント
  final PatrolResult overallResult; // 総合結果
  final DateTime createdAt;
  final DateTime updatedAt;

  const SafetyPatrolRecord({
    required this.id,
    required this.projectId,
    required this.patrolDate,
    required this.patrollerName,
    required this.patrollerId,
    required this.checkItems,
    this.nonConformances = const [],
    this.overallComment,
    this.overallResult = PatrolResult.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  SafetyPatrolRecord copyWith({
    String? id,
    String? projectId,
    DateTime? patrolDate,
    String? patrollerName,
    String? patrollerId,
    List<PatrolCheckItem>? checkItems,
    List<NonConformanceItem>? nonConformances,
    String? overallComment,
    PatrolResult? overallResult,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SafetyPatrolRecord(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      patrolDate: patrolDate ?? this.patrolDate,
      patrollerName: patrollerName ?? this.patrollerName,
      patrollerId: patrollerId ?? this.patrollerId,
      checkItems: checkItems ?? this.checkItems,
      nonConformances: nonConformances ?? this.nonConformances,
      overallComment: overallComment ?? this.overallComment,
      overallResult: overallResult ?? this.overallResult,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 適合率を計算
  double get conformanceRate {
    if (checkItems.isEmpty) return 0;
    final conformCount = checkItems.where((c) => c.result == CheckResult.conform).length;
    return conformCount / checkItems.length * 100;
  }

  /// 不適合項目数
  int get nonConformCount =>
      checkItems.where((c) => c.result == CheckResult.nonConform).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'patrolDate': patrolDate.toIso8601String(),
        'patrollerName': patrollerName,
        'patrollerId': patrollerId,
        'checkItems': checkItems.map((c) => c.toJson()).toList(),
        'nonConformances': nonConformances.map((n) => n.toJson()).toList(),
        'overallComment': overallComment,
        'overallResult': overallResult.value,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SafetyPatrolRecord.fromJson(Map<String, dynamic> json) {
    return SafetyPatrolRecord(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      patrolDate: DateTime.parse(json['patrolDate'] as String),
      patrollerName: json['patrollerName'] as String,
      patrollerId: json['patrollerId'] as String,
      checkItems: (json['checkItems'] as List)
          .map((c) => PatrolCheckItem.fromJson(c as Map<String, dynamic>))
          .toList(),
      nonConformances: (json['nonConformances'] as List?)
              ?.map((n) => NonConformanceItem.fromJson(n as Map<String, dynamic>))
              .toList() ??
          [],
      overallComment: json['overallComment'] as String?,
      overallResult: PatrolResult.fromString(json['overallResult'] as String? ?? 'pending'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// パトロールチェック項目
@immutable
class PatrolCheckItem {
  final String id;
  final String category; // カテゴリ
  final String checkContent; // チェック内容
  final CheckResult result; // 結果
  final String? comment; // コメント

  const PatrolCheckItem({
    required this.id,
    required this.category,
    required this.checkContent,
    this.result = CheckResult.notChecked,
    this.comment,
  });

  PatrolCheckItem copyWith({
    String? id,
    String? category,
    String? checkContent,
    CheckResult? result,
    String? comment,
  }) {
    return PatrolCheckItem(
      id: id ?? this.id,
      category: category ?? this.category,
      checkContent: checkContent ?? this.checkContent,
      result: result ?? this.result,
      comment: comment ?? this.comment,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'checkContent': checkContent,
        'result': result.value,
        'comment': comment,
      };

  factory PatrolCheckItem.fromJson(Map<String, dynamic> json) {
    return PatrolCheckItem(
      id: json['id'] as String,
      category: json['category'] as String,
      checkContent: json['checkContent'] as String,
      result: CheckResult.fromString(json['result'] as String? ?? 'not_checked'),
      comment: json['comment'] as String?,
    );
  }
}

/// チェック結果
enum CheckResult {
  notChecked('not_checked', '未確認', '⬜'),
  conform('conform', '適合', '✅'),
  nonConform('non_conform', '不適合', '❌'),
  notApplicable('not_applicable', '該当なし', '➖');

  final String value;
  final String displayName;
  final String icon;

  const CheckResult(this.value, this.displayName, this.icon);

  static CheckResult fromString(String value) {
    return CheckResult.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CheckResult.notChecked,
    );
  }
}

/// 不適合箇所
@immutable
class NonConformanceItem {
  final String id;
  final String location; // 場所
  final String description; // 内容
  final List<String> photoUrls; // 写真
  final String? correctiveAction; // 是正措置
  final CorrectionStatus correctionStatus; // 是正状況
  final DateTime? correctedAt; // 是正日時
  final String? correctedById; // 是正確認者
  final List<String>? correctionPhotoUrls; // 是正後写真

  const NonConformanceItem({
    required this.id,
    required this.location,
    required this.description,
    this.photoUrls = const [],
    this.correctiveAction,
    this.correctionStatus = CorrectionStatus.pending,
    this.correctedAt,
    this.correctedById,
    this.correctionPhotoUrls,
  });

  NonConformanceItem copyWith({
    String? id,
    String? location,
    String? description,
    List<String>? photoUrls,
    String? correctiveAction,
    CorrectionStatus? correctionStatus,
    DateTime? correctedAt,
    String? correctedById,
    List<String>? correctionPhotoUrls,
  }) {
    return NonConformanceItem(
      id: id ?? this.id,
      location: location ?? this.location,
      description: description ?? this.description,
      photoUrls: photoUrls ?? this.photoUrls,
      correctiveAction: correctiveAction ?? this.correctiveAction,
      correctionStatus: correctionStatus ?? this.correctionStatus,
      correctedAt: correctedAt ?? this.correctedAt,
      correctedById: correctedById ?? this.correctedById,
      correctionPhotoUrls: correctionPhotoUrls ?? this.correctionPhotoUrls,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'location': location,
        'description': description,
        'photoUrls': photoUrls,
        'correctiveAction': correctiveAction,
        'correctionStatus': correctionStatus.value,
        'correctedAt': correctedAt?.toIso8601String(),
        'correctedById': correctedById,
        'correctionPhotoUrls': correctionPhotoUrls,
      };

  factory NonConformanceItem.fromJson(Map<String, dynamic> json) {
    return NonConformanceItem(
      id: json['id'] as String,
      location: json['location'] as String,
      description: json['description'] as String,
      photoUrls: (json['photoUrls'] as List?)?.cast<String>() ?? [],
      correctiveAction: json['correctiveAction'] as String?,
      correctionStatus:
          CorrectionStatus.fromString(json['correctionStatus'] as String? ?? 'pending'),
      correctedAt: json['correctedAt'] != null
          ? DateTime.parse(json['correctedAt'] as String)
          : null,
      correctedById: json['correctedById'] as String?,
      correctionPhotoUrls: (json['correctionPhotoUrls'] as List?)?.cast<String>(),
    );
  }
}

/// 是正状況
enum CorrectionStatus {
  pending('pending', '未対応'),
  inProgress('in_progress', '対応中'),
  corrected('corrected', '是正済'),
  verified('verified', '確認完了');

  final String value;
  final String displayName;

  const CorrectionStatus(this.value, this.displayName);

  static CorrectionStatus fromString(String value) {
    return CorrectionStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CorrectionStatus.pending,
    );
  }
}

/// パトロール結果
enum PatrolResult {
  pending('pending', '未完了'),
  pass('pass', '合格'),
  conditionalPass('conditional_pass', '条件付合格'),
  fail('fail', '不合格');

  final String value;
  final String displayName;

  const PatrolResult(this.value, this.displayName);

  static PatrolResult fromString(String value) {
    return PatrolResult.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PatrolResult.pending,
    );
  }
}

// ===========================================
// チェックリストテンプレート
// ===========================================

/// 標準安全パトロールチェック項目テンプレート
class SafetyChecklistTemplates {
  static List<PatrolCheckItem> getStandardChecklist() {
    int itemId = 0;
    String nextId() => 'template_${++itemId}';

    return [
      // 保護具
      PatrolCheckItem(id: nextId(), category: '保護具', checkContent: 'ヘルメットの正しい着用'),
      PatrolCheckItem(id: nextId(), category: '保護具', checkContent: '安全靴の着用'),
      PatrolCheckItem(id: nextId(), category: '保護具', checkContent: '安全帯（フルハーネス）の着用'),
      PatrolCheckItem(id: nextId(), category: '保護具', checkContent: '保護メガネの着用（必要箇所）'),
      PatrolCheckItem(id: nextId(), category: '保護具', checkContent: '手袋の着用'),

      // 足場・通路
      PatrolCheckItem(id: nextId(), category: '足場・通路', checkContent: '足場の固定状態'),
      PatrolCheckItem(id: nextId(), category: '足場・通路', checkContent: '手すり・中さん・巾木の設置'),
      PatrolCheckItem(id: nextId(), category: '足場・通路', checkContent: '昇降設備の安全性'),
      PatrolCheckItem(id: nextId(), category: '足場・通路', checkContent: '通路の確保・障害物なし'),
      PatrolCheckItem(id: nextId(), category: '足場・通路', checkContent: '開口部の養生'),

      // 重機・車両
      PatrolCheckItem(id: nextId(), category: '重機・車両', checkContent: '重機の日常点検実施'),
      PatrolCheckItem(id: nextId(), category: '重機・車両', checkContent: '誘導員の配置'),
      PatrolCheckItem(id: nextId(), category: '重機・車両', checkContent: '立入禁止区域の設定'),
      PatrolCheckItem(id: nextId(), category: '重機・車両', checkContent: 'アウトリガーの張出し'),

      // クレーン作業
      PatrolCheckItem(id: nextId(), category: 'クレーン作業', checkContent: '吊り荷の玉掛け状態'),
      PatrolCheckItem(id: nextId(), category: 'クレーン作業', checkContent: '合図者の配置'),
      PatrolCheckItem(id: nextId(), category: 'クレーン作業', checkContent: '吊り荷下の立入禁止'),

      // 電気作業
      PatrolCheckItem(id: nextId(), category: '電気作業', checkContent: '仮設電気設備の点検'),
      PatrolCheckItem(id: nextId(), category: '電気作業', checkContent: 'コード類の損傷確認'),
      PatrolCheckItem(id: nextId(), category: '電気作業', checkContent: 'アース接続の確認'),

      // 整理整頓
      PatrolCheckItem(id: nextId(), category: '整理整頓', checkContent: '資材の整理整頓'),
      PatrolCheckItem(id: nextId(), category: '整理整頓', checkContent: '廃材の適正処理'),
      PatrolCheckItem(id: nextId(), category: '整理整頓', checkContent: '可燃物の管理'),

      // 掲示・表示
      PatrolCheckItem(id: nextId(), category: '掲示・表示', checkContent: '安全標識の掲示'),
      PatrolCheckItem(id: nextId(), category: '掲示・表示', checkContent: '作業主任者の表示'),
      PatrolCheckItem(id: nextId(), category: '掲示・表示', checkContent: '緊急連絡先の掲示'),

      // 熱中症対策（夏季）
      PatrolCheckItem(id: nextId(), category: '熱中症対策', checkContent: '休憩所・日陰の確保'),
      PatrolCheckItem(id: nextId(), category: '熱中症対策', checkContent: '飲料水・塩分の準備'),
      PatrolCheckItem(id: nextId(), category: '熱中症対策', checkContent: 'WBGT計の設置・確認'),
    ];
  }

  /// カテゴリー一覧を取得
  static List<String> getCategories() {
    return [
      '保護具',
      '足場・通路',
      '重機・車両',
      'クレーン作業',
      '電気作業',
      '整理整頓',
      '掲示・表示',
      '熱中症対策',
    ];
  }
}
