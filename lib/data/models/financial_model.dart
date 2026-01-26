import 'package:flutter/material.dart';

/// 予算カテゴリ
enum BudgetCategory {
  labor('labor', '人件費', Icons.people, Color(0xFF2196F3)),
  material('material', '資材費', Icons.inventory, Color(0xFF4CAF50)),
  equipment('equipment', '機材費', Icons.construction, Color(0xFFFF9800)),
  subcontract('subcontract', '外注費', Icons.business, Color(0xFF9C27B0)),
  overhead('overhead', '諸経費', Icons.receipt_long, Color(0xFF607D8B)),
  other('other', 'その他', Icons.more_horiz, Color(0xFF795548));

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const BudgetCategory(this.value, this.label, this.icon, this.color);

  static BudgetCategory fromString(String value) {
    return BudgetCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BudgetCategory.other,
    );
  }
}

/// 予算アイテム
class BudgetItem {
  /// アイテムID
  final String id;

  /// プロジェクトID
  final String projectId;

  /// カテゴリ
  final BudgetCategory category;

  /// 項目名
  final String name;

  /// 予算金額
  final double budgetAmount;

  /// 実績金額
  final double actualAmount;

  /// 関連タスクID
  final String? relatedTaskId;

  /// 関連業者ID
  final String? vendorId;

  /// 備考
  final String? notes;

  /// 作成日
  final DateTime createdAt;

  /// 更新日
  final DateTime updatedAt;

  const BudgetItem({
    required this.id,
    required this.projectId,
    required this.category,
    required this.name,
    required this.budgetAmount,
    this.actualAmount = 0,
    this.relatedTaskId,
    this.vendorId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BudgetItem.fromJson(Map<String, dynamic> json) {
    return BudgetItem(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      category: BudgetCategory.fromString(json['category'] as String),
      name: json['name'] as String,
      budgetAmount: (json['budgetAmount'] as num).toDouble(),
      actualAmount: (json['actualAmount'] as num?)?.toDouble() ?? 0,
      relatedTaskId: json['relatedTaskId'] as String?,
      vendorId: json['vendorId'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'category': category.value,
        'name': name,
        'budgetAmount': budgetAmount,
        'actualAmount': actualAmount,
        'relatedTaskId': relatedTaskId,
        'vendorId': vendorId,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// 差額（予算 - 実績）
  double get variance => budgetAmount - actualAmount;

  /// 消化率（%）
  double get consumptionRate =>
      budgetAmount > 0 ? (actualAmount / budgetAmount) * 100 : 0;

  /// 予算超過か
  bool get isOverBudget => actualAmount > budgetAmount;

  /// 超過率（%）
  double get overageRate =>
      budgetAmount > 0 ? ((actualAmount - budgetAmount) / budgetAmount) * 100 : 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 請求書ステータス
enum InvoiceStatus {
  pending('pending', '処理待ち', Color(0xFFFF9800)),
  approved('approved', '承認済', Color(0xFF4CAF50)),
  rejected('rejected', '却下', Color(0xFFF44336)),
  paid('paid', '支払済', Color(0xFF2196F3));

  final String value;
  final String label;
  final Color color;

  const InvoiceStatus(this.value, this.label, this.color);

  static InvoiceStatus fromString(String value) {
    return InvoiceStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InvoiceStatus.pending,
    );
  }
}

/// 請求書モデル
class Invoice {
  /// 請求書ID
  final String id;

  /// プロジェクトID
  final String projectId;

  /// 請求元業者ID
  final String vendorId;

  /// 請求元業者名（キャッシュ）
  final String vendorName;

  /// 請求書番号
  final String? invoiceNumber;

  /// 請求日
  final DateTime invoiceDate;

  /// 支払期限
  final DateTime? dueDate;

  /// 合計金額
  final double totalAmount;

  /// 税額
  final double? taxAmount;

  /// 明細
  final List<InvoiceLineItem> lineItems;

  /// ステータス
  final InvoiceStatus status;

  /// カテゴリ
  final BudgetCategory category;

  /// 関連タスクID
  final String? relatedTaskId;

  /// 元画像URL（OCR元）
  final String? originalImageUrl;

  /// OCR信頼度（0-100）
  final double? ocrConfidence;

  /// OCRで抽出された生データ
  final Map<String, dynamic>? ocrRawData;

  /// 承認者ID
  final String? approvedById;

  /// 承認日
  final DateTime? approvedAt;

  /// 備考
  final String? notes;

  /// 作成日
  final DateTime createdAt;

  /// 更新日
  final DateTime updatedAt;

  const Invoice({
    required this.id,
    required this.projectId,
    required this.vendorId,
    required this.vendorName,
    this.invoiceNumber,
    required this.invoiceDate,
    this.dueDate,
    required this.totalAmount,
    this.taxAmount,
    this.lineItems = const [],
    this.status = InvoiceStatus.pending,
    this.category = BudgetCategory.other,
    this.relatedTaskId,
    this.originalImageUrl,
    this.ocrConfidence,
    this.ocrRawData,
    this.approvedById,
    this.approvedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      vendorId: json['vendorId'] as String,
      vendorName: json['vendorName'] as String,
      invoiceNumber: json['invoiceNumber'] as String?,
      invoiceDate: DateTime.parse(json['invoiceDate'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      taxAmount: (json['taxAmount'] as num?)?.toDouble(),
      lineItems: (json['lineItems'] as List<dynamic>?)
              ?.map((e) => InvoiceLineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: InvoiceStatus.fromString(json['status'] as String? ?? 'pending'),
      category:
          BudgetCategory.fromString(json['category'] as String? ?? 'other'),
      relatedTaskId: json['relatedTaskId'] as String?,
      originalImageUrl: json['originalImageUrl'] as String?,
      ocrConfidence: (json['ocrConfidence'] as num?)?.toDouble(),
      ocrRawData: json['ocrRawData'] as Map<String, dynamic>?,
      approvedById: json['approvedById'] as String?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'vendorId': vendorId,
        'vendorName': vendorName,
        'invoiceNumber': invoiceNumber,
        'invoiceDate': invoiceDate.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'totalAmount': totalAmount,
        'taxAmount': taxAmount,
        'lineItems': lineItems.map((e) => e.toJson()).toList(),
        'status': status.value,
        'category': category.value,
        'relatedTaskId': relatedTaskId,
        'originalImageUrl': originalImageUrl,
        'ocrConfidence': ocrConfidence,
        'ocrRawData': ocrRawData,
        'approvedById': approvedById,
        'approvedAt': approvedAt?.toIso8601String(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// OCRからの自動生成か
  bool get isFromOcr => originalImageUrl != null;

  /// 高信頼度のOCR結果か
  bool get isHighConfidenceOcr => ocrConfidence != null && ocrConfidence! >= 80;

  /// 支払期限切れか
  bool get isOverdue =>
      dueDate != null &&
      DateTime.now().isAfter(dueDate!) &&
      status == InvoiceStatus.pending;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Invoice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 請求書明細
class InvoiceLineItem {
  /// 明細ID
  final String id;

  /// 品名/内容
  final String description;

  /// 数量
  final double quantity;

  /// 単位
  final String unit;

  /// 単価
  final double unitPrice;

  /// 金額
  final double amount;

  const InvoiceLineItem({
    required this.id,
    required this.description,
    this.quantity = 1,
    this.unit = '式',
    required this.unitPrice,
    required this.amount,
  });

  factory InvoiceLineItem.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItem(
      id: json['id'] as String,
      description: json['description'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unit: json['unit'] as String? ?? '式',
      unitPrice: (json['unitPrice'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'quantity': quantity,
        'unit': unit,
        'unitPrice': unitPrice,
        'amount': amount,
      };
}

/// プロジェクト予算サマリー
class ProjectBudgetSummary {
  /// プロジェクトID
  final String projectId;

  /// 総予算
  final double totalBudget;

  /// 実績合計
  final double totalActual;

  /// カテゴリ別内訳
  final Map<BudgetCategory, BudgetCategorySummary> categoryBreakdown;

  /// 未払請求書合計
  final double pendingInvoicesTotal;

  /// 更新日時
  final DateTime calculatedAt;

  const ProjectBudgetSummary({
    required this.projectId,
    required this.totalBudget,
    required this.totalActual,
    required this.categoryBreakdown,
    this.pendingInvoicesTotal = 0,
    required this.calculatedAt,
  });

  /// 残予算
  double get remainingBudget => totalBudget - totalActual;

  /// 消化率（%）
  double get consumptionRate =>
      totalBudget > 0 ? (totalActual / totalBudget) * 100 : 0;

  /// 予算超過か
  bool get isOverBudget => totalActual > totalBudget;

  /// 超過額
  double get overage => totalActual > totalBudget ? totalActual - totalBudget : 0;

  /// 予測最終コスト（未払を含む）
  double get projectedFinalCost => totalActual + pendingInvoicesTotal;

  /// 今日の利益見込み
  double get todayProfitForecast => totalBudget - projectedFinalCost;
}

/// カテゴリ別予算サマリー
class BudgetCategorySummary {
  /// カテゴリ
  final BudgetCategory category;

  /// 予算
  final double budget;

  /// 実績
  final double actual;

  const BudgetCategorySummary({
    required this.category,
    required this.budget,
    required this.actual,
  });

  /// 差額
  double get variance => budget - actual;

  /// 消化率（%）
  double get consumptionRate => budget > 0 ? (actual / budget) * 100 : 0;

  /// 予算超過か
  bool get isOverBudget => actual > budget;
}

/// OCR結果モデル
class OCRResult {
  /// 成功か
  final bool success;

  /// 抽出された業者名
  final String? vendorName;

  /// 抽出された合計金額
  final double? totalAmount;

  /// 抽出された税額
  final double? taxAmount;

  /// 抽出された請求書番号
  final String? invoiceNumber;

  /// 抽出された請求日
  final DateTime? invoiceDate;

  /// 抽出された明細
  final List<InvoiceLineItem> lineItems;

  /// 信頼度（0-100）
  final double confidence;

  /// 生のOCRテキスト
  final String? rawText;

  /// エラーメッセージ
  final String? errorMessage;

  const OCRResult({
    required this.success,
    this.vendorName,
    this.totalAmount,
    this.taxAmount,
    this.invoiceNumber,
    this.invoiceDate,
    this.lineItems = const [],
    this.confidence = 0,
    this.rawText,
    this.errorMessage,
  });

  factory OCRResult.fromJson(Map<String, dynamic> json) {
    return OCRResult(
      success: json['success'] as bool? ?? false,
      vendorName: json['vendorName'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      taxAmount: (json['taxAmount'] as num?)?.toDouble(),
      invoiceNumber: json['invoiceNumber'] as String?,
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.parse(json['invoiceDate'] as String)
          : null,
      lineItems: (json['lineItems'] as List<dynamic>?)
              ?.map((e) => InvoiceLineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      rawText: json['rawText'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'vendorName': vendorName,
        'totalAmount': totalAmount,
        'taxAmount': taxAmount,
        'invoiceNumber': invoiceNumber,
        'invoiceDate': invoiceDate?.toIso8601String(),
        'lineItems': lineItems.map((e) => e.toJson()).toList(),
        'confidence': confidence,
        'rawText': rawText,
        'errorMessage': errorMessage,
      };

  /// 高信頼度か
  bool get isHighConfidence => confidence >= 80;

  /// 必要な情報が揃っているか
  bool get hasRequiredFields =>
      vendorName != null && totalAmount != null && totalAmount! > 0;
}
