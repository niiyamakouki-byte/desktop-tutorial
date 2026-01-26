import 'package:flutter/foundation.dart';

/// 協力会社モデル
@immutable
class Company {
  /// ユニークID
  final String id;

  /// 会社名
  final String name;

  /// 会社名（正式名称）
  final String? formalName;

  /// 略称
  final String? shortName;

  /// 仮登録フラグ（名前の揺れ対応で後から正式登録）
  final bool isPending;

  /// 統合先会社ID（会社統合時に設定）
  final String? mergedIntoId;

  /// 代表者名
  final String? representativeName;

  /// 電話番号
  final String? phone;

  /// メールアドレス
  final String? email;

  /// 住所
  final String? address;

  /// メモ
  final String? note;

  /// 作成日時
  final DateTime createdAt;

  /// 更新日時
  final DateTime updatedAt;

  const Company({
    required this.id,
    required this.name,
    this.formalName,
    this.shortName,
    this.isPending = false,
    this.mergedIntoId,
    this.representativeName,
    this.phone,
    this.email,
    this.address,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  /// JSONからモデルを生成
  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String,
      name: json['name'] as String,
      formalName: json['formalName'] as String?,
      shortName: json['shortName'] as String?,
      isPending: json['isPending'] as bool? ?? false,
      mergedIntoId: json['mergedIntoId'] as String?,
      representativeName: json['representativeName'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// モデルをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'formalName': formalName,
      'shortName': shortName,
      'isPending': isPending,
      'mergedIntoId': mergedIntoId,
      'representativeName': representativeName,
      'phone': phone,
      'email': email,
      'address': address,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// コピーを作成
  Company copyWith({
    String? id,
    String? name,
    String? formalName,
    String? shortName,
    bool? isPending,
    String? mergedIntoId,
    String? representativeName,
    String? phone,
    String? email,
    String? address,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      formalName: formalName ?? this.formalName,
      shortName: shortName ?? this.shortName,
      isPending: isPending ?? this.isPending,
      mergedIntoId: mergedIntoId ?? this.mergedIntoId,
      representativeName: representativeName ?? this.representativeName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 表示名（仮登録の場合はマーク付き）
  String get displayName {
    if (isPending) {
      return '$name (仮)';
    }
    return shortName ?? name;
  }

  /// 統合済みかどうか
  bool get isMerged => mergedIntoId != null;

  /// この会社を別の会社に統合
  Company mergeInto(String targetCompanyId) {
    return copyWith(
      mergedIntoId: targetCompanyId,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Company && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Company(id: $id, name: $name, isPending: $isPending)';
  }
}

/// 会社名の揺れを検出するためのユーティリティ
class CompanyNameMatcher {
  /// 類似度を計算（0.0〜1.0）
  static double similarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    // 正規化
    final normA = _normalize(a);
    final normB = _normalize(b);

    if (normA == normB) return 1.0;

    // レーベンシュタイン距離で計算
    final distance = _levenshteinDistance(normA, normB);
    final maxLength = [normA.length, normB.length].reduce((a, b) => a > b ? a : b);

    return 1.0 - (distance / maxLength);
  }

  /// 文字列を正規化
  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('株式会社', '')
        .replaceAll('有限会社', '')
        .replaceAll('合同会社', '')
        .replaceAll('(株)', '')
        .replaceAll('（株）', '')
        .replaceAll(' ', '')
        .replaceAll('　', '')
        .trim();
  }

  /// レーベンシュタイン距離
  static int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> previousRow = List<int>.generate(b.length + 1, (i) => i);
    List<int> currentRow = List<int>.filled(b.length + 1, 0);

    for (int i = 0; i < a.length; i++) {
      currentRow[0] = i + 1;

      for (int j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        currentRow[j + 1] = [
          previousRow[j + 1] + 1,
          currentRow[j] + 1,
          previousRow[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }

      final temp = previousRow;
      previousRow = currentRow;
      currentRow = temp;
    }

    return previousRow[b.length];
  }

  /// 類似会社を検索
  static List<Company> findSimilar(Company target, List<Company> companies, {double threshold = 0.7}) {
    return companies
        .where((c) => c.id != target.id && !c.isMerged)
        .where((c) => similarity(target.name, c.name) >= threshold)
        .toList();
  }
}
