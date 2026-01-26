import 'package:flutter/material.dart';

/// 工種カテゴリ
enum TradeCategory {
  foundation('foundation', '基礎工事', Icons.foundation),
  framing('framing', '躯体工事', Icons.home_work),
  electrical('electrical', '電気設備', Icons.electrical_services),
  plumbing('plumbing', '給排水設備', Icons.water_drop),
  hvac('hvac', '空調設備', Icons.ac_unit),
  roofing('roofing', '屋根工事', Icons.roofing),
  exterior('exterior', '外装工事', Icons.wall),
  interior('interior', '内装工事', Icons.format_paint),
  painting('painting', '塗装工事', Icons.brush),
  flooring('flooring', '床工事', Icons.grid_on),
  landscaping('landscaping', '外構工事', Icons.park),
  general('general', 'その他', Icons.construction);

  final String value;
  final String label;
  final IconData icon;

  const TradeCategory(this.value, this.label, this.icon);

  static TradeCategory fromString(String value) {
    return TradeCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TradeCategory.general,
    );
  }
}

/// 業者の評価レベル
enum VendorRating {
  excellent('excellent', '優良', 5, Color(0xFF4CAF50)),
  good('good', '良好', 4, Color(0xFF8BC34A)),
  average('average', '標準', 3, Color(0xFFFFC107)),
  belowAverage('below_average', '要改善', 2, Color(0xFFFF9800)),
  poor('poor', '不良', 1, Color(0xFFF44336));

  final String value;
  final String label;
  final int stars;
  final Color color;

  const VendorRating(this.value, this.label, this.stars, this.color);

  static VendorRating fromString(String value) {
    return VendorRating.values.firstWhere(
      (e) => e.value == value,
      orElse: () => VendorRating.average,
    );
  }
}

/// 業者モデル
///
/// 協力会社の情報を管理
class Vendor {
  /// 業者ID
  final String id;

  /// 会社名
  final String companyName;

  /// 代表者名
  final String? representativeName;

  /// 担当者名
  final String? contactName;

  /// 電話番号
  final String? phone;

  /// メールアドレス
  final String? email;

  /// LINE ID（連絡用）
  final String? lineId;

  /// 住所
  final String? address;

  /// 工種カテゴリ（複数可）
  final List<TradeCategory> tradeCategories;

  /// 評価
  final VendorRating rating;

  /// 過去の取引回数
  final int transactionCount;

  /// 平均レスポンス時間（時間）
  final double? averageResponseTime;

  /// 工期遵守率（%）
  final double? onTimeDeliveryRate;

  /// メモ
  final String? notes;

  /// アクティブか
  final bool isActive;

  /// 登録日
  final DateTime createdAt;

  /// 更新日
  final DateTime updatedAt;

  const Vendor({
    required this.id,
    required this.companyName,
    this.representativeName,
    this.contactName,
    this.phone,
    this.email,
    this.lineId,
    this.address,
    this.tradeCategories = const [],
    this.rating = VendorRating.average,
    this.transactionCount = 0,
    this.averageResponseTime,
    this.onTimeDeliveryRate,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] as String,
      companyName: json['companyName'] as String,
      representativeName: json['representativeName'] as String?,
      contactName: json['contactName'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      lineId: json['lineId'] as String?,
      address: json['address'] as String?,
      tradeCategories: (json['tradeCategories'] as List<dynamic>?)
              ?.map((e) => TradeCategory.fromString(e as String))
              .toList() ??
          [],
      rating: VendorRating.fromString(json['rating'] as String? ?? 'average'),
      transactionCount: json['transactionCount'] as int? ?? 0,
      averageResponseTime: (json['averageResponseTime'] as num?)?.toDouble(),
      onTimeDeliveryRate: (json['onTimeDeliveryRate'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'companyName': companyName,
        'representativeName': representativeName,
        'contactName': contactName,
        'phone': phone,
        'email': email,
        'lineId': lineId,
        'address': address,
        'tradeCategories': tradeCategories.map((e) => e.value).toList(),
        'rating': rating.value,
        'transactionCount': transactionCount,
        'averageResponseTime': averageResponseTime,
        'onTimeDeliveryRate': onTimeDeliveryRate,
        'notes': notes,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  Vendor copyWith({
    String? id,
    String? companyName,
    String? representativeName,
    String? contactName,
    String? phone,
    String? email,
    String? lineId,
    String? address,
    List<TradeCategory>? tradeCategories,
    VendorRating? rating,
    int? transactionCount,
    double? averageResponseTime,
    double? onTimeDeliveryRate,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vendor(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      representativeName: representativeName ?? this.representativeName,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      lineId: lineId ?? this.lineId,
      address: address ?? this.address,
      tradeCategories: tradeCategories ?? this.tradeCategories,
      rating: rating ?? this.rating,
      transactionCount: transactionCount ?? this.transactionCount,
      averageResponseTime: averageResponseTime ?? this.averageResponseTime,
      onTimeDeliveryRate: onTimeDeliveryRate ?? this.onTimeDeliveryRate,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 表示名（会社名 + 担当者）
  String get displayName {
    if (contactName != null) {
      return '$companyName / $contactName';
    }
    return companyName;
  }

  /// 工種のラベル一覧
  String get tradeCategoriesLabel {
    return tradeCategories.map((e) => e.label).join(', ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vendor && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 見積依頼（RFQ）のステータス
enum RFQStatus {
  draft('draft', '下書き', Color(0xFF9E9E9E)),
  sent('sent', '送信済', Color(0xFF2196F3)),
  viewed('viewed', '閲覧済', Color(0xFF00BCD4)),
  responded('responded', '回答済', Color(0xFF4CAF50)),
  expired('expired', '期限切れ', Color(0xFFFF9800)),
  cancelled('cancelled', 'キャンセル', Color(0xFFF44336));

  final String value;
  final String label;
  final Color color;

  const RFQStatus(this.value, this.label, this.color);

  static RFQStatus fromString(String value) {
    return RFQStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RFQStatus.draft,
    );
  }
}

/// 見積依頼（RFQ）モデル
///
/// 複数業者への見積依頼を管理
class RFQRequest {
  /// RFQ ID
  final String id;

  /// プロジェクトID
  final String projectId;

  /// 関連タスクID
  final String? relatedTaskId;

  /// タイトル
  final String title;

  /// 説明
  final String description;

  /// 工種カテゴリ
  final TradeCategory tradeCategory;

  /// 必要資材リスト
  final List<RFQItem> items;

  /// 送信先業者リスト
  final List<RFQRecipient> recipients;

  /// 希望納期
  final DateTime? desiredDeliveryDate;

  /// 回答期限
  final DateTime responseDeadline;

  /// ステータス
  final RFQStatus status;

  /// 作成日
  final DateTime createdAt;

  /// 作成者ID
  final String createdById;

  /// 備考
  final String? notes;

  const RFQRequest({
    required this.id,
    required this.projectId,
    this.relatedTaskId,
    required this.title,
    required this.description,
    required this.tradeCategory,
    this.items = const [],
    this.recipients = const [],
    this.desiredDeliveryDate,
    required this.responseDeadline,
    this.status = RFQStatus.draft,
    required this.createdAt,
    required this.createdById,
    this.notes,
  });

  factory RFQRequest.fromJson(Map<String, dynamic> json) {
    return RFQRequest(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      relatedTaskId: json['relatedTaskId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      tradeCategory:
          TradeCategory.fromString(json['tradeCategory'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => RFQItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recipients: (json['recipients'] as List<dynamic>?)
              ?.map((e) => RFQRecipient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      desiredDeliveryDate: json['desiredDeliveryDate'] != null
          ? DateTime.parse(json['desiredDeliveryDate'] as String)
          : null,
      responseDeadline: DateTime.parse(json['responseDeadline'] as String),
      status: RFQStatus.fromString(json['status'] as String? ?? 'draft'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdById: json['createdById'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'relatedTaskId': relatedTaskId,
        'title': title,
        'description': description,
        'tradeCategory': tradeCategory.value,
        'items': items.map((e) => e.toJson()).toList(),
        'recipients': recipients.map((e) => e.toJson()).toList(),
        'desiredDeliveryDate': desiredDeliveryDate?.toIso8601String(),
        'responseDeadline': responseDeadline.toIso8601String(),
        'status': status.value,
        'createdAt': createdAt.toIso8601String(),
        'createdById': createdById,
        'notes': notes,
      };

  /// 回答済み件数
  int get responseCount =>
      recipients.where((r) => r.response != null).length;

  /// 最低金額の回答
  RFQRecipient? get lowestBidder {
    final responded =
        recipients.where((r) => r.response?.totalAmount != null).toList();
    if (responded.isEmpty) return null;
    responded.sort(
        (a, b) => a.response!.totalAmount!.compareTo(b.response!.totalAmount!));
    return responded.first;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RFQRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// RFQ明細アイテム
class RFQItem {
  /// アイテムID
  final String id;

  /// 品名
  final String name;

  /// 仕様
  final String? specification;

  /// 数量
  final double quantity;

  /// 単位
  final String unit;

  /// 備考
  final String? notes;

  const RFQItem({
    required this.id,
    required this.name,
    this.specification,
    required this.quantity,
    this.unit = '式',
    this.notes,
  });

  factory RFQItem.fromJson(Map<String, dynamic> json) {
    return RFQItem(
      id: json['id'] as String,
      name: json['name'] as String,
      specification: json['specification'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? '式',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'specification': specification,
        'quantity': quantity,
        'unit': unit,
        'notes': notes,
      };
}

/// RFQ送信先（業者）
class RFQRecipient {
  /// 業者ID
  final String vendorId;

  /// 業者名（キャッシュ）
  final String vendorName;

  /// 送信日時
  final DateTime? sentAt;

  /// 閲覧日時
  final DateTime? viewedAt;

  /// 回答
  final RFQResponse? response;

  const RFQRecipient({
    required this.vendorId,
    required this.vendorName,
    this.sentAt,
    this.viewedAt,
    this.response,
  });

  factory RFQRecipient.fromJson(Map<String, dynamic> json) {
    return RFQRecipient(
      vendorId: json['vendorId'] as String,
      vendorName: json['vendorName'] as String,
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'] as String)
          : null,
      viewedAt: json['viewedAt'] != null
          ? DateTime.parse(json['viewedAt'] as String)
          : null,
      response: json['response'] != null
          ? RFQResponse.fromJson(json['response'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'vendorId': vendorId,
        'vendorName': vendorName,
        'sentAt': sentAt?.toIso8601String(),
        'viewedAt': viewedAt?.toIso8601String(),
        'response': response?.toJson(),
      };
}

/// RFQ回答
class RFQResponse {
  /// 回答日時
  final DateTime respondedAt;

  /// 合計金額
  final double? totalAmount;

  /// 明細
  final List<RFQResponseItem> items;

  /// 見積有効期限
  final DateTime? validUntil;

  /// 納期
  final DateTime? deliveryDate;

  /// コメント
  final String? comment;

  /// 添付ファイルURL
  final String? attachmentUrl;

  const RFQResponse({
    required this.respondedAt,
    this.totalAmount,
    this.items = const [],
    this.validUntil,
    this.deliveryDate,
    this.comment,
    this.attachmentUrl,
  });

  factory RFQResponse.fromJson(Map<String, dynamic> json) {
    return RFQResponse(
      respondedAt: DateTime.parse(json['respondedAt'] as String),
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => RFQResponseItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'] as String)
          : null,
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.parse(json['deliveryDate'] as String)
          : null,
      comment: json['comment'] as String?,
      attachmentUrl: json['attachmentUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'respondedAt': respondedAt.toIso8601String(),
        'totalAmount': totalAmount,
        'items': items.map((e) => e.toJson()).toList(),
        'validUntil': validUntil?.toIso8601String(),
        'deliveryDate': deliveryDate?.toIso8601String(),
        'comment': comment,
        'attachmentUrl': attachmentUrl,
      };
}

/// RFQ回答明細
class RFQResponseItem {
  /// 対象アイテムID
  final String itemId;

  /// 単価
  final double unitPrice;

  /// 金額
  final double amount;

  /// 備考
  final String? notes;

  const RFQResponseItem({
    required this.itemId,
    required this.unitPrice,
    required this.amount,
    this.notes,
  });

  factory RFQResponseItem.fromJson(Map<String, dynamic> json) {
    return RFQResponseItem(
      itemId: json['itemId'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'unitPrice': unitPrice,
        'amount': amount,
        'notes': notes,
      };
}
