import 'package:flutter/foundation.dart';

/// 職種タイプ
enum JobType {
  /// 大工
  carpenter('carpenter', '大工', '🔨'),
  /// 電気工
  electrician('electrician', '電気工', '⚡'),
  /// 配管工
  plumber('plumber', '配管工', '🔧'),
  /// 塗装工
  painter('painter', '塗装工', '🎨'),
  /// 左官
  plasterer('plasterer', '左官', '🧱'),
  /// 鳶
  scaffolder('scaffolder', '鳶', '🏗️'),
  /// 鉄筋工
  reinforcer('reinforcer', '鉄筋工', '🔩'),
  /// 型枠大工
  formworker('formworker', '型枠大工', '📐'),
  /// 重機オペレーター
  operator('operator', '重機オペ', '🚜'),
  /// 現場監督
  supervisor('supervisor', '監督', '👷'),
  /// 事務
  clerk('clerk', '事務', '📋'),
  /// その他
  other('other', 'その他', '👤');

  final String value;
  final String displayName;
  final String icon;

  const JobType(this.value, this.displayName, this.icon);

  static JobType fromString(String value) {
    return JobType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => JobType.other,
    );
  }
}

/// 職人ステータス
enum PersonStatus {
  /// アクティブ
  active('active', 'アクティブ'),
  /// 非アクティブ
  inactive('inactive', '非アクティブ'),
  /// 退職
  retired('retired', '退職');

  final String value;
  final String displayName;

  const PersonStatus(this.value, this.displayName);

  static PersonStatus fromString(String value) {
    return PersonStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PersonStatus.active,
    );
  }
}

/// 職人モデル
@immutable
class Person {
  /// ユニークID
  final String id;

  /// プロジェクトID
  final String projectId;

  /// 会社ID
  final String companyId;

  /// 氏名
  final String name;

  /// フリガナ
  final String? nameKana;

  /// 職種
  final JobType jobType;

  /// ステータス
  final PersonStatus status;

  /// QRコード識別子（固定QR用）
  final String? qrCode;

  /// 電話番号
  final String? phone;

  /// メモ
  final String? note;

  /// 作成日時
  final DateTime createdAt;

  /// 更新日時
  final DateTime updatedAt;

  const Person({
    required this.id,
    required this.projectId,
    required this.companyId,
    required this.name,
    this.nameKana,
    required this.jobType,
    this.status = PersonStatus.active,
    this.qrCode,
    this.phone,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  /// JSONからモデルを生成
  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      companyId: json['companyId'] as String,
      name: json['name'] as String,
      nameKana: json['nameKana'] as String?,
      jobType: JobType.fromString(json['jobType'] as String),
      status: PersonStatus.fromString(json['status'] as String? ?? 'active'),
      qrCode: json['qrCode'] as String?,
      phone: json['phone'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// モデルをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'companyId': companyId,
      'name': name,
      'nameKana': nameKana,
      'jobType': jobType.value,
      'status': status.value,
      'qrCode': qrCode,
      'phone': phone,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// コピーを作成
  Person copyWith({
    String? id,
    String? projectId,
    String? companyId,
    String? name,
    String? nameKana,
    JobType? jobType,
    PersonStatus? status,
    String? qrCode,
    String? phone,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Person(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      nameKana: nameKana ?? this.nameKana,
      jobType: jobType ?? this.jobType,
      status: status ?? this.status,
      qrCode: qrCode ?? this.qrCode,
      phone: phone ?? this.phone,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 表示名（職種アイコン付き）
  String get displayName => '${jobType.icon} $name';

  /// イニシャル
  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return name.length >= 2 ? name.substring(0, 2) : name;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Person && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Person(id: $id, name: $name, job: ${jobType.displayName})';
  }
}
