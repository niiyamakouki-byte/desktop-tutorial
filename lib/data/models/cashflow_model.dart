import 'package:flutter/foundation.dart';

/// 支払いサイト（支払い条件）
enum PaymentTerms {
  /// 即払い
  immediate('即払い', 0, 0),

  /// 月末締め翌月払い
  endOfMonthNext('月末締め翌月払い', 0, 1),

  /// 月末締め翌々月払い
  endOfMonthNextNext('月末締め翌々月払い', 0, 2),

  /// 20日締め翌月末払い
  day20NextEnd('20日締め翌月末払い', 20, 1),

  /// 完工後30日
  completion30('完工後30日', 0, 0),

  /// 完工後60日
  completion60('完工後60日', 0, 0);

  const PaymentTerms(this.label, this.cutoffDay, this.monthsDelay);

  final String label;
  final int cutoffDay; // 0 = 月末
  final int monthsDelay;

  /// 支払い予定日を計算
  DateTime calculatePaymentDate(DateTime baseDate) {
    switch (this) {
      case PaymentTerms.immediate:
        return baseDate;

      case PaymentTerms.completion30:
        return baseDate.add(const Duration(days: 30));

      case PaymentTerms.completion60:
        return baseDate.add(const Duration(days: 60));

      case PaymentTerms.endOfMonthNext:
        // 月末締め → 翌月末
        final nextMonth = DateTime(baseDate.year, baseDate.month + 2, 0);
        return nextMonth;

      case PaymentTerms.endOfMonthNextNext:
        // 月末締め → 翌々月末
        final nextNextMonth = DateTime(baseDate.year, baseDate.month + 3, 0);
        return nextNextMonth;

      case PaymentTerms.day20NextEnd:
        // 20日締め → 翌月末
        if (baseDate.day <= 20) {
          return DateTime(baseDate.year, baseDate.month + 1, 0);
        } else {
          return DateTime(baseDate.year, baseDate.month + 2, 0);
        }
    }
  }
}

/// 入金種別
enum IncomeType {
  /// 着手金
  downPayment('着手金', 0.3),

  /// 中間金
  progressPayment('中間金', 0.3),

  /// 完工金
  finalPayment('完工金', 0.4),

  /// その他
  other('その他', 0.0);

  const IncomeType(this.label, this.typicalRatio);

  final String label;
  final double typicalRatio; // 典型的な割合
}

/// 出金種別
enum ExpenseType {
  /// 材料費
  material('材料費'),

  /// 外注費（職人）
  subcontractor('外注費'),

  /// 設備費
  equipment('設備費'),

  /// 諸経費
  overhead('諸経費'),

  /// その他
  other('その他');

  const ExpenseType(this.label);

  final String label;
}

/// 入金予定
@immutable
class IncomeEntry {
  final String id;
  final String projectId;
  final String projectName;
  final IncomeType type;
  final double amount;
  final DateTime expectedDate;
  final DateTime? actualDate;
  final bool isConfirmed;
  final String? note;

  const IncomeEntry({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.type,
    required this.amount,
    required this.expectedDate,
    this.actualDate,
    this.isConfirmed = false,
    this.note,
  });

  bool get isPaid => actualDate != null;

  bool get isOverdue =>
      !isPaid && expectedDate.isBefore(DateTime.now());

  IncomeEntry copyWith({
    String? id,
    String? projectId,
    String? projectName,
    IncomeType? type,
    double? amount,
    DateTime? expectedDate,
    DateTime? actualDate,
    bool? isConfirmed,
    String? note,
  }) {
    return IncomeEntry(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      expectedDate: expectedDate ?? this.expectedDate,
      actualDate: actualDate ?? this.actualDate,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'projectName': projectName,
        'type': type.name,
        'amount': amount,
        'expectedDate': expectedDate.toIso8601String(),
        'actualDate': actualDate?.toIso8601String(),
        'isConfirmed': isConfirmed,
        'note': note,
      };

  factory IncomeEntry.fromJson(Map<String, dynamic> json) => IncomeEntry(
        id: json['id'] as String,
        projectId: json['projectId'] as String,
        projectName: json['projectName'] as String,
        type: IncomeType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => IncomeType.other,
        ),
        amount: (json['amount'] as num).toDouble(),
        expectedDate: DateTime.parse(json['expectedDate'] as String),
        actualDate: json['actualDate'] != null
            ? DateTime.parse(json['actualDate'] as String)
            : null,
        isConfirmed: json['isConfirmed'] as bool? ?? false,
        note: json['note'] as String?,
      );
}

/// 出金予定
@immutable
class ExpenseEntry {
  final String id;
  final String? projectId;
  final String? vendorId;
  final String vendorName;
  final ExpenseType type;
  final double amount;
  final DateTime expectedDate;
  final DateTime? actualDate;
  final PaymentTerms paymentTerms;
  final String? invoiceNumber;
  final String? note;

  const ExpenseEntry({
    required this.id,
    this.projectId,
    this.vendorId,
    required this.vendorName,
    required this.type,
    required this.amount,
    required this.expectedDate,
    this.actualDate,
    this.paymentTerms = PaymentTerms.endOfMonthNext,
    this.invoiceNumber,
    this.note,
  });

  bool get isPaid => actualDate != null;

  bool get isDueSoon {
    if (isPaid) return false;
    final daysUntilDue = expectedDate.difference(DateTime.now()).inDays;
    return daysUntilDue <= 7 && daysUntilDue >= 0;
  }

  ExpenseEntry copyWith({
    String? id,
    String? projectId,
    String? vendorId,
    String? vendorName,
    ExpenseType? type,
    double? amount,
    DateTime? expectedDate,
    DateTime? actualDate,
    PaymentTerms? paymentTerms,
    String? invoiceNumber,
    String? note,
  }) {
    return ExpenseEntry(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      expectedDate: expectedDate ?? this.expectedDate,
      actualDate: actualDate ?? this.actualDate,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'vendorId': vendorId,
        'vendorName': vendorName,
        'type': type.name,
        'amount': amount,
        'expectedDate': expectedDate.toIso8601String(),
        'actualDate': actualDate?.toIso8601String(),
        'paymentTerms': paymentTerms.name,
        'invoiceNumber': invoiceNumber,
        'note': note,
      };

  factory ExpenseEntry.fromJson(Map<String, dynamic> json) => ExpenseEntry(
        id: json['id'] as String,
        projectId: json['projectId'] as String?,
        vendorId: json['vendorId'] as String?,
        vendorName: json['vendorName'] as String,
        type: ExpenseType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ExpenseType.other,
        ),
        amount: (json['amount'] as num).toDouble(),
        expectedDate: DateTime.parse(json['expectedDate'] as String),
        actualDate: json['actualDate'] != null
            ? DateTime.parse(json['actualDate'] as String)
            : null,
        paymentTerms: PaymentTerms.values.firstWhere(
          (e) => e.name == json['paymentTerms'],
          orElse: () => PaymentTerms.endOfMonthNext,
        ),
        invoiceNumber: json['invoiceNumber'] as String?,
        note: json['note'] as String?,
      );
}

/// キャッシュフロー予測
@immutable
class CashflowProjection {
  final DateTime date;
  final double openingBalance;
  final double totalIncome;
  final double totalExpense;
  final double closingBalance;
  final List<IncomeEntry> incomes;
  final List<ExpenseEntry> expenses;

  const CashflowProjection({
    required this.date,
    required this.openingBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.closingBalance,
    this.incomes = const [],
    this.expenses = const [],
  });

  double get netCashflow => totalIncome - totalExpense;

  bool get isNegative => closingBalance < 0;

  bool get isWarning => closingBalance < 1000000; // 100万円以下で警告

  /// 資金ショートリスクレベル
  CashflowRiskLevel get riskLevel {
    if (closingBalance < 0) return CashflowRiskLevel.critical;
    if (closingBalance < 500000) return CashflowRiskLevel.high;
    if (closingBalance < 1000000) return CashflowRiskLevel.medium;
    return CashflowRiskLevel.low;
  }
}

/// 資金ショートリスクレベル
enum CashflowRiskLevel {
  low('安全', '緑'),
  medium('注意', '黄'),
  high('警告', '橙'),
  critical('危険', '赤');

  const CashflowRiskLevel(this.label, this.colorName);

  final String label;
  final String colorName;
}

/// 月次キャッシュフローサマリー
@immutable
class MonthlyCashflowSummary {
  final int year;
  final int month;
  final double totalIncome;
  final double totalExpense;
  final double netCashflow;
  final double projectedEndBalance;
  final CashflowRiskLevel riskLevel;
  final List<CashflowProjection> dailyProjections;

  const MonthlyCashflowSummary({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.netCashflow,
    required this.projectedEndBalance,
    required this.riskLevel,
    this.dailyProjections = const [],
  });

  String get monthLabel => '$year年$month月';

  /// 最初に資金ショートが発生する日（なければnull）
  DateTime? get firstNegativeDate {
    for (final p in dailyProjections) {
      if (p.closingBalance < 0) return p.date;
    }
    return null;
  }
}

/// ゴースト予約（仮押さえ）のステータス
enum GhostBookingStatus {
  /// ゴースト（仮押さえ中）
  ghost('仮押さえ', '打診中'),

  /// 打診済み
  requested('打診済み', '返答待ち'),

  /// 確定
  confirmed('確定', '予約確定'),

  /// キャンセル
  cancelled('キャンセル', '見送り');

  const GhostBookingStatus(this.label, this.vendorView);

  final String label;
  final String vendorView; // 業者側に見せるラベル
}

/// ゴースト予約（業者の仮押さえ）
@immutable
class GhostBooking {
  final String id;
  final String projectId;
  final String vendorId;
  final String vendorName;
  final String taskId;
  final String taskName;
  final DateTime startDate;
  final DateTime endDate;
  final GhostBookingStatus status;
  final String? note;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? confirmedAt;

  const GhostBooking({
    required this.id,
    required this.projectId,
    required this.vendorId,
    required this.vendorName,
    required this.taskId,
    required this.taskName,
    required this.startDate,
    required this.endDate,
    this.status = GhostBookingStatus.ghost,
    this.note,
    required this.createdAt,
    required this.createdBy,
    this.confirmedAt,
  });

  int get durationDays => endDate.difference(startDate).inDays + 1;

  bool get isActive =>
      status == GhostBookingStatus.ghost ||
      status == GhostBookingStatus.requested;

  bool get isConfirmed => status == GhostBookingStatus.confirmed;

  GhostBooking copyWith({
    String? id,
    String? projectId,
    String? vendorId,
    String? vendorName,
    String? taskId,
    String? taskName,
    DateTime? startDate,
    DateTime? endDate,
    GhostBookingStatus? status,
    String? note,
    DateTime? createdAt,
    String? createdBy,
    DateTime? confirmedAt,
  }) {
    return GhostBooking(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      taskId: taskId ?? this.taskId,
      taskName: taskName ?? this.taskName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'vendorId': vendorId,
        'vendorName': vendorName,
        'taskId': taskId,
        'taskName': taskName,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'status': status.name,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy,
        'confirmedAt': confirmedAt?.toIso8601String(),
      };

  factory GhostBooking.fromJson(Map<String, dynamic> json) => GhostBooking(
        id: json['id'] as String,
        projectId: json['projectId'] as String,
        vendorId: json['vendorId'] as String,
        vendorName: json['vendorName'] as String,
        taskId: json['taskId'] as String,
        taskName: json['taskName'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        status: GhostBookingStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => GhostBookingStatus.ghost,
        ),
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        createdBy: json['createdBy'] as String,
        confirmedAt: json['confirmedAt'] != null
            ? DateTime.parse(json['confirmedAt'] as String)
            : null,
      );
}

/// 業者の空き状況
enum VendorAvailabilityStatus {
  /// 空き
  available('◯', '空き'),

  /// 相談可
  maybe('△', '相談可'),

  /// 埋まり
  busy('✕', '埋まり'),

  /// 未回答
  unknown('?', '未回答');

  const VendorAvailabilityStatus(this.symbol, this.label);

  final String symbol;
  final String label;
}

/// 業者の週次空き状況
@immutable
class VendorAvailability {
  final String vendorId;
  final String vendorName;
  final DateTime weekStart;
  final Map<int, VendorAvailabilityStatus> dailyStatus; // 0=月, 6=日
  final DateTime? updatedAt;

  const VendorAvailability({
    required this.vendorId,
    required this.vendorName,
    required this.weekStart,
    this.dailyStatus = const {},
    this.updatedAt,
  });

  /// 指定日の空き状況を取得
  VendorAvailabilityStatus getStatusForDate(DateTime date) {
    final dayOfWeek = date.weekday - 1; // 0=月曜
    return dailyStatus[dayOfWeek] ?? VendorAvailabilityStatus.unknown;
  }

  /// 週全体が空いているか
  bool get isFullyAvailable =>
      dailyStatus.values.every((s) => s == VendorAvailabilityStatus.available);

  /// 週全体が埋まっているか
  bool get isFullyBusy =>
      dailyStatus.values.every((s) => s == VendorAvailabilityStatus.busy);

  VendorAvailability copyWith({
    String? vendorId,
    String? vendorName,
    DateTime? weekStart,
    Map<int, VendorAvailabilityStatus>? dailyStatus,
    DateTime? updatedAt,
  }) {
    return VendorAvailability(
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      weekStart: weekStart ?? this.weekStart,
      dailyStatus: dailyStatus ?? this.dailyStatus,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'vendorId': vendorId,
        'vendorName': vendorName,
        'weekStart': weekStart.toIso8601String(),
        'dailyStatus': dailyStatus.map(
          (k, v) => MapEntry(k.toString(), v.name),
        ),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory VendorAvailability.fromJson(Map<String, dynamic> json) {
    final statusMap = (json['dailyStatus'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(
            int.parse(k),
            VendorAvailabilityStatus.values.firstWhere(
              (e) => e.name == v,
              orElse: () => VendorAvailabilityStatus.unknown,
            ),
          ),
        ) ??
        {};

    return VendorAvailability(
      vendorId: json['vendorId'] as String,
      vendorName: json['vendorName'] as String,
      weekStart: DateTime.parse(json['weekStart'] as String),
      dailyStatus: statusMap,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}
