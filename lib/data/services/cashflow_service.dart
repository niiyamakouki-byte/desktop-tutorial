import '../models/cashflow_model.dart';
import '../models/models.dart';

/// キャッシュフロー予測サービス
///
/// 工程表と連動した「未来の通帳」を計算
class CashflowService {
  static final CashflowService _instance = CashflowService._internal();
  factory CashflowService() => _instance;
  CashflowService._internal();

  // === データストア（実際はDBやAPIから取得） ===
  final List<IncomeEntry> _incomes = [];
  final List<ExpenseEntry> _expenses = [];
  final List<GhostBooking> _ghostBookings = [];
  final Map<String, VendorAvailability> _vendorAvailabilities = {};

  double _currentBalance = 5000000; // 初期残高（デモ用）

  // === 入出金管理 ===

  /// 入金予定を追加
  void addIncome(IncomeEntry income) {
    _incomes.add(income);
  }

  /// 出金予定を追加
  void addExpense(ExpenseEntry expense) {
    _expenses.add(expense);
  }

  /// 現在残高を設定
  void setCurrentBalance(double balance) {
    _currentBalance = balance;
  }

  /// 入金予定一覧を取得
  List<IncomeEntry> getIncomes({String? projectId, bool unpaidOnly = false}) {
    var result = _incomes.toList();
    if (projectId != null) {
      result = result.where((e) => e.projectId == projectId).toList();
    }
    if (unpaidOnly) {
      result = result.where((e) => !e.isPaid).toList();
    }
    return result..sort((a, b) => a.expectedDate.compareTo(b.expectedDate));
  }

  /// 出金予定一覧を取得
  List<ExpenseEntry> getExpenses({String? projectId, bool unpaidOnly = false}) {
    var result = _expenses.toList();
    if (projectId != null) {
      result = result.where((e) => e.projectId == projectId).toList();
    }
    if (unpaidOnly) {
      result = result.where((e) => !e.isPaid).toList();
    }
    return result..sort((a, b) => a.expectedDate.compareTo(b.expectedDate));
  }

  // === キャッシュフロー予測 ===

  /// 日次キャッシュフロー予測を計算
  List<CashflowProjection> calculateDailyProjection({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final projections = <CashflowProjection>[];
    var currentBalance = _currentBalance;

    // 期間内の入出金を日付別に集計
    final incomesByDate = <DateTime, List<IncomeEntry>>{};
    final expensesByDate = <DateTime, List<ExpenseEntry>>{};

    for (final income in _incomes.where((e) => !e.isPaid)) {
      final date = DateTime(
        income.expectedDate.year,
        income.expectedDate.month,
        income.expectedDate.day,
      );
      incomesByDate.putIfAbsent(date, () => []).add(income);
    }

    for (final expense in _expenses.where((e) => !e.isPaid)) {
      final date = DateTime(
        expense.expectedDate.year,
        expense.expectedDate.month,
        expense.expectedDate.day,
      );
      expensesByDate.putIfAbsent(date, () => []).add(expense);
    }

    // 日ごとに計算
    var date = startDate;
    while (!date.isAfter(endDate)) {
      final dateKey = DateTime(date.year, date.month, date.day);
      final dayIncomes = incomesByDate[dateKey] ?? [];
      final dayExpenses = expensesByDate[dateKey] ?? [];

      final totalIncome = dayIncomes.fold<double>(
        0,
        (sum, e) => sum + e.amount,
      );
      final totalExpense = dayExpenses.fold<double>(
        0,
        (sum, e) => sum + e.amount,
      );

      final openingBalance = currentBalance;
      currentBalance = openingBalance + totalIncome - totalExpense;

      projections.add(CashflowProjection(
        date: dateKey,
        openingBalance: openingBalance,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        closingBalance: currentBalance,
        incomes: dayIncomes,
        expenses: dayExpenses,
      ));

      date = date.add(const Duration(days: 1));
    }

    return projections;
  }

  /// 月次キャッシュフローサマリーを計算
  List<MonthlyCashflowSummary> calculateMonthlySummary({
    int monthsAhead = 6,
  }) {
    final now = DateTime.now();
    final summaries = <MonthlyCashflowSummary>[];

    var runningBalance = _currentBalance;

    for (var i = 0; i < monthsAhead; i++) {
      final targetMonth = DateTime(now.year, now.month + i, 1);
      final monthEnd = DateTime(targetMonth.year, targetMonth.month + 1, 0);

      // この月の入金
      final monthIncomes = _incomes.where((e) {
        final d = e.expectedDate;
        return !e.isPaid &&
            d.year == targetMonth.year &&
            d.month == targetMonth.month;
      }).toList();

      // この月の出金
      final monthExpenses = _expenses.where((e) {
        final d = e.expectedDate;
        return !e.isPaid &&
            d.year == targetMonth.year &&
            d.month == targetMonth.month;
      }).toList();

      final totalIncome = monthIncomes.fold<double>(
        0,
        (sum, e) => sum + e.amount,
      );
      final totalExpense = monthExpenses.fold<double>(
        0,
        (sum, e) => sum + e.amount,
      );
      final netCashflow = totalIncome - totalExpense;
      final projectedEndBalance = runningBalance + netCashflow;

      // リスクレベル判定
      CashflowRiskLevel riskLevel;
      if (projectedEndBalance < 0) {
        riskLevel = CashflowRiskLevel.critical;
      } else if (projectedEndBalance < 500000) {
        riskLevel = CashflowRiskLevel.high;
      } else if (projectedEndBalance < 1000000) {
        riskLevel = CashflowRiskLevel.medium;
      } else {
        riskLevel = CashflowRiskLevel.low;
      }

      // 日次予測
      final dailyProjections = calculateDailyProjection(
        startDate: targetMonth,
        endDate: monthEnd,
      );

      summaries.add(MonthlyCashflowSummary(
        year: targetMonth.year,
        month: targetMonth.month,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netCashflow: netCashflow,
        projectedEndBalance: projectedEndBalance,
        riskLevel: riskLevel,
        dailyProjections: dailyProjections,
      ));

      runningBalance = projectedEndBalance;
    }

    return summaries;
  }

  /// 資金ショートアラートを取得
  List<CashflowAlert> getAlerts() {
    final alerts = <CashflowAlert>[];
    final summaries = calculateMonthlySummary();

    for (final summary in summaries) {
      if (summary.riskLevel == CashflowRiskLevel.critical) {
        alerts.add(CashflowAlert(
          type: CashflowAlertType.shortage,
          severity: AlertSeverity.critical,
          title: '⚠️ ${summary.monthLabel}に資金ショートの可能性',
          description:
              '予測残高: ${_formatCurrency(summary.projectedEndBalance)}',
          date: summary.firstNegativeDate ??
              DateTime(summary.year, summary.month, 1),
          suggestedActions: [
            '入金の前倒し交渉',
            '支払いサイトの延長依頼',
            '追加融資の検討',
          ],
        ));
      } else if (summary.riskLevel == CashflowRiskLevel.high) {
        alerts.add(CashflowAlert(
          type: CashflowAlertType.lowBalance,
          severity: AlertSeverity.high,
          title: '⚡ ${summary.monthLabel}は資金繰り注意',
          description:
              '予測残高: ${_formatCurrency(summary.projectedEndBalance)}',
          date: DateTime(summary.year, summary.month, 1),
        ));
      }
    }

    return alerts;
  }

  // === ゴースト予約（仮押さえ） ===

  /// ゴースト予約を追加
  void addGhostBooking(GhostBooking booking) {
    _ghostBookings.add(booking);
  }

  /// ゴースト予約のステータスを更新
  void updateGhostBookingStatus(String bookingId, GhostBookingStatus status) {
    final index = _ghostBookings.indexWhere((b) => b.id == bookingId);
    if (index >= 0) {
      _ghostBookings[index] = _ghostBookings[index].copyWith(
        status: status,
        confirmedAt: status == GhostBookingStatus.confirmed
            ? DateTime.now()
            : _ghostBookings[index].confirmedAt,
      );
    }
  }

  /// 業者のゴースト予約を取得
  List<GhostBooking> getGhostBookingsForVendor(String vendorId) {
    return _ghostBookings
        .where((b) => b.vendorId == vendorId && b.isActive)
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  /// プロジェクトのゴースト予約を取得
  List<GhostBooking> getGhostBookingsForProject(String projectId) {
    return _ghostBookings.where((b) => b.projectId == projectId).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  /// 期間内のゴースト予約競合をチェック
  List<GhostBooking> checkConflicts({
    required String vendorId,
    required DateTime startDate,
    required DateTime endDate,
    String? excludeBookingId,
  }) {
    return _ghostBookings.where((b) {
      if (b.vendorId != vendorId) return false;
      if (b.id == excludeBookingId) return false;
      if (!b.isActive) return false;

      // 期間の重複チェック
      return !(endDate.isBefore(b.startDate) ||
          startDate.isAfter(b.endDate));
    }).toList();
  }

  // === 業者空き状況 ===

  /// 業者の空き状況を更新
  void updateVendorAvailability(VendorAvailability availability) {
    final key = '${availability.vendorId}_${availability.weekStart.toIso8601String()}';
    _vendorAvailabilities[key] = availability;
  }

  /// 業者の空き状況を取得
  VendorAvailability? getVendorAvailability(String vendorId, DateTime weekStart) {
    final normalizedWeekStart = _getWeekStart(weekStart);
    final key = '${vendorId}_${normalizedWeekStart.toIso8601String()}';
    return _vendorAvailabilities[key];
  }

  /// 業者が指定日に空いているか
  VendorAvailabilityStatus getVendorStatusForDate(
    String vendorId,
    DateTime date,
  ) {
    final weekStart = _getWeekStart(date);
    final availability = getVendorAvailability(vendorId, weekStart);
    return availability?.getStatusForDate(date) ??
        VendorAvailabilityStatus.unknown;
  }

  // === 工程表連動 ===

  /// 工程表の日付変更に連動して入金予定を更新
  void updateIncomeFromTaskChange({
    required String projectId,
    required DateTime newCompletionDate,
  }) {
    // 完工金の予定日を更新
    final completionIncomes = _incomes
        .where((e) =>
            e.projectId == projectId && e.type == IncomeType.finalPayment)
        .toList();

    for (final income in completionIncomes) {
      final index = _incomes.indexOf(income);
      if (index >= 0) {
        // 完工後30日など、条件に応じて計算
        final newExpectedDate = newCompletionDate.add(const Duration(days: 30));
        _incomes[index] = income.copyWith(expectedDate: newExpectedDate);
      }
    }
  }

  // === ヘルパー ===

  DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  String _formatCurrency(double amount) {
    if (amount >= 0) {
      return '¥${amount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          )}';
    } else {
      return '-¥${(-amount).toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          )}';
    }
  }

  // === デモデータ生成 ===

  void loadDemoData() {
    final now = DateTime.now();

    // 入金予定（デモ）
    _incomes.addAll([
      IncomeEntry(
        id: 'inc_1',
        projectId: 'proj_1',
        projectName: '山田邸新築工事',
        type: IncomeType.downPayment,
        amount: 3000000,
        expectedDate: now.subtract(const Duration(days: 30)),
        actualDate: now.subtract(const Duration(days: 28)),
        isConfirmed: true,
      ),
      IncomeEntry(
        id: 'inc_2',
        projectId: 'proj_1',
        projectName: '山田邸新築工事',
        type: IncomeType.progressPayment,
        amount: 5000000,
        expectedDate: now.add(const Duration(days: 15)),
        isConfirmed: true,
      ),
      IncomeEntry(
        id: 'inc_3',
        projectId: 'proj_1',
        projectName: '山田邸新築工事',
        type: IncomeType.finalPayment,
        amount: 7000000,
        expectedDate: now.add(const Duration(days: 60)),
      ),
      IncomeEntry(
        id: 'inc_4',
        projectId: 'proj_2',
        projectName: '佐藤邸リフォーム',
        type: IncomeType.downPayment,
        amount: 1500000,
        expectedDate: now.add(const Duration(days: 7)),
        isConfirmed: true,
      ),
    ]);

    // 出金予定（デモ）
    _expenses.addAll([
      ExpenseEntry(
        id: 'exp_1',
        projectId: 'proj_1',
        vendorId: 'vendor_1',
        vendorName: 'A基礎工業',
        type: ExpenseType.subcontractor,
        amount: 2000000,
        expectedDate: now.add(const Duration(days: 5)),
        paymentTerms: PaymentTerms.endOfMonthNext,
      ),
      ExpenseEntry(
        id: 'exp_2',
        projectId: 'proj_1',
        vendorId: 'vendor_2',
        vendorName: 'B材木店',
        type: ExpenseType.material,
        amount: 3500000,
        expectedDate: now.add(const Duration(days: 10)),
        paymentTerms: PaymentTerms.endOfMonthNext,
      ),
      ExpenseEntry(
        id: 'exp_3',
        projectId: 'proj_1',
        vendorId: 'vendor_3',
        vendorName: 'C電気',
        type: ExpenseType.subcontractor,
        amount: 1200000,
        expectedDate: now.add(const Duration(days: 25)),
        paymentTerms: PaymentTerms.endOfMonthNextNext,
      ),
      ExpenseEntry(
        id: 'exp_4',
        projectId: 'proj_1',
        vendorId: 'vendor_4',
        vendorName: 'D塗装',
        type: ExpenseType.subcontractor,
        amount: 800000,
        expectedDate: now.add(const Duration(days: 45)),
        paymentTerms: PaymentTerms.endOfMonthNext,
      ),
    ]);

    // ゴースト予約（デモ）
    _ghostBookings.addAll([
      GhostBooking(
        id: 'ghost_1',
        projectId: 'proj_1',
        vendorId: 'vendor_4',
        vendorName: 'D塗装',
        taskId: 'task_paint',
        taskName: '外壁塗装',
        startDate: now.add(const Duration(days: 30)),
        endDate: now.add(const Duration(days: 37)),
        status: GhostBookingStatus.ghost,
        createdAt: now.subtract(const Duration(days: 3)),
        createdBy: '新山光輝',
      ),
      GhostBooking(
        id: 'ghost_2',
        projectId: 'proj_2',
        vendorId: 'vendor_3',
        vendorName: 'C電気',
        taskId: 'task_elec',
        taskName: '電気配線工事',
        startDate: now.add(const Duration(days: 14)),
        endDate: now.add(const Duration(days: 16)),
        status: GhostBookingStatus.requested,
        createdAt: now.subtract(const Duration(days: 5)),
        createdBy: '新山光輝',
      ),
    ]);
  }
}

/// キャッシュフローアラート種別
enum CashflowAlertType {
  shortage, // 資金ショート
  lowBalance, // 残高低下
  overdueIncome, // 入金遅延
  largePayout, // 大口支払い
}

/// アラート重要度
enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}

/// キャッシュフローアラート
class CashflowAlert {
  final CashflowAlertType type;
  final AlertSeverity severity;
  final String title;
  final String description;
  final DateTime date;
  final List<String> suggestedActions;

  const CashflowAlert({
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.date,
    this.suggestedActions = const [],
  });
}
