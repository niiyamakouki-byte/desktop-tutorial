import 'dart:html' as html;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/services/attendance_service.dart';
import '../../data/models/attendance_event.dart';

/// 入退場履歴画面
///
/// 機能:
/// - 日別の入退場サマリー表示
/// - 会社別フィルター
/// - CSV/Excelエクスポート
/// - 警告フラグ付きイベントの強調表示
class AttendanceListScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  final VoidCallback? onBack;

  const AttendanceListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    this.onBack,
  });

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  List<DailyAttendanceSummary> _summaries = [];
  String? _selectedCompanyFilter;
  List<String> _companyList = [];

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    await _attendanceService.initialize();
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _summaries = await _attendanceService.getDailySummary(
        widget.projectId,
        _selectedDate,
      );

      // 会社リスト取得
      final companies = await _attendanceService.getAllCompanies();
      _companyList = companies.map((c) => c.id).toList();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<DailyAttendanceSummary> get _filteredSummaries {
    if (_selectedCompanyFilter == null) {
      return _summaries;
    }
    return _summaries.where((s) => s.companyId == _selectedCompanyFilter).toList();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ja'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      await _loadData();
    }
  }

  void _exportCsv() async {
    setState(() => _isLoading = true);
    try {
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final csvContent = await _attendanceService.exportToCsv(
        widget.projectId,
        startOfDay,
        endOfDay,
      );

      // ダウンロードリンク生成
      final bytes = utf8.encode(csvContent);
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final fileName = '入退場記録_${DateFormat('yyyy-MM-dd').format(_selectedDate)}.csv';

      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();

      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fileName をダウンロードしました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エクスポートに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年M月d日(E)', 'ja');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '入退場履歴',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.projectName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          // CSVエクスポートボタン
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportCsv,
            tooltip: 'CSVエクスポート',
          ),
          // 更新ボタン
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '更新',
          ),
        ],
      ),
      body: Column(
        children: [
          // 日付・フィルターバー
          _buildFilterBar(dateFormat),
          // サマリーカード
          _buildSummaryCard(),
          // リスト
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSummaries.isEmpty
                    ? _buildEmptyState()
                    : _buildSummaryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 日付選択
          Expanded(
            child: InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      dateFormat.format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 日付移動ボタン
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  });
                  _loadData();
                },
                tooltip: '前日',
              ),
              IconButton(
                icon: const Icon(Icons.today),
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime.now();
                  });
                  _loadData();
                },
                tooltip: '今日',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _selectedDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))
                    ? () {
                        setState(() {
                          _selectedDate = _selectedDate.add(const Duration(days: 1));
                        });
                        _loadData();
                      }
                    : null,
                tooltip: '翌日',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalWorkers = _filteredSummaries.length;
    final totalHours = _filteredSummaries
        .where((s) => s.workingHours != null)
        .fold<Duration>(Duration.zero, (sum, s) => sum + s.workingHours!);
    final totalManDays = _filteredSummaries
        .fold<double>(0, (sum, s) => sum + s.manDays);
    final warningCount = _filteredSummaries
        .where((s) => s.hasAutoCorrection)
        .length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSummaryItem(
            '入場者数',
            '$totalWorkers名',
            Icons.people,
            const Color(0xFF4CAF50),
          ),
          _buildSummaryItem(
            '合計労働時間',
            '${totalHours.inHours}h ${totalHours.inMinutes % 60}m',
            Icons.access_time,
            const Color(0xFF2196F3),
          ),
          _buildSummaryItem(
            '合計人工',
            '${totalManDays.toStringAsFixed(2)}人工',
            Icons.engineering,
            const Color(0xFF9C27B0),
          ),
          _buildSummaryItem(
            '警告',
            '$warningCount件',
            Icons.warning_amber,
            warningCount > 0 ? Colors.orange : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'この日の入退場記録はありません',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryList() {
    // 会社別にグループ化
    final Map<String, List<DailyAttendanceSummary>> byCompany = {};
    for (final summary in _filteredSummaries) {
      byCompany.putIfAbsent(summary.companyName, () => []).add(summary);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: byCompany.length,
      itemBuilder: (context, index) {
        final companyName = byCompany.keys.elementAt(index);
        final companySummaries = byCompany[companyName]!;

        return _buildCompanySection(companyName, companySummaries);
      },
    );
  }

  Widget _buildCompanySection(String companyName, List<DailyAttendanceSummary> summaries) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 会社名ヘッダー
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E).withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.business,
                  size: 20,
                  color: Color(0xFF1A237E),
                ),
                const SizedBox(width: 8),
                Text(
                  companyName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${summaries.length}名',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 職人リスト
          ...summaries.map((summary) => _buildSummaryTile(summary)),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(DailyAttendanceSummary summary) {
    final timeFormat = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // 名前
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Text(
                  summary.personName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (summary.hasAutoCorrection) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: '17:30自動補正あり',
                    child: Icon(
                      Icons.auto_fix_high,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // IN時刻
          Expanded(
            child: Text(
              summary.firstIn != null ? timeFormat.format(summary.firstIn!) : '-',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // OUT時刻
          Expanded(
            child: Text(
              summary.lastOut != null ? timeFormat.format(summary.lastOut!) : '-',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // 勤務時間
          Expanded(
            child: Text(
              summary.workingHoursDisplay,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // 人工
          Expanded(
            child: Text(
              summary.manDays.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9C27B0),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _attendanceService.dispose();
    super.dispose();
  }
}
