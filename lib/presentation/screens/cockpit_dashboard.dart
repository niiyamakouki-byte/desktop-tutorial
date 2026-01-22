import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/models.dart';
import '../../data/models/material_model.dart';
import '../../data/models/project_flow_model.dart';
import '../../data/services/order_service.dart';
import '../../data/services/template_service.dart';
import '../widgets/common/glass_container.dart';

/// Main Cockpit Dashboard - Inspired by Construction DX Cockpit
/// Combines KPIs, AI Insights, Timeline, and Quick Actions
class CockpitDashboard extends StatefulWidget {
  final Project? project;
  final List<Task> tasks;
  final OrderService? orderService;
  final ProjectFlow? projectFlow;
  final Function(String view)? onNavigate;

  const CockpitDashboard({
    super.key,
    this.project,
    required this.tasks,
    this.orderService,
    this.projectFlow,
    this.onNavigate,
  });

  @override
  State<CockpitDashboard> createState() => _CockpitDashboardState();
}

class _CockpitDashboardState extends State<CockpitDashboard> {
  String _timeFilter = 'today';
  String _typeFilter = 'all';
  bool _isLoadingInsight = false;
  String _currentInsight = '';
  final List<ActivityLog> _activityLogs = [];

  @override
  void initState() {
    super.initState();
    _generateInsight();
    _generateMockActivityLogs();
  }

  void _generateInsight() {
    setState(() {
      _isLoadingInsight = true;
    });

    // Simulate AI processing
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoadingInsight = false;
          _currentInsight = _getAIInsight();
        });
      }
    });
  }

  String _getAIInsight() {
    final alerts = widget.orderService?.criticalAlerts ?? [];
    final progress = _calculateOverallProgress();
    final overdueCount = widget.tasks.where((t) => t.isOverdue).length;

    if (alerts.isNotEmpty) {
      return '⚠️ ${alerts.length}件の発注アラートがあります。「${alerts.first.title}」を優先的に対応してください。材料の納期遅延リスクを検知しています。';
    } else if (overdueCount > 0) {
      return '📋 $overdueCount件のタスクが期限を超過しています。工程の見直しと人員配置の調整を推奨します。';
    } else if (progress > 0.8) {
      return '✅ プロジェクトは順調に進行中です（進捗${(progress * 100).toInt()}%）。完工に向けて最終チェックリストの確認を推奨します。';
    } else {
      return '📊 本日の天気は晴れ、コンクリート打設に最適な条件です。午後の資材搬入に備えて搬入経路を確保してください。';
    }
  }

  void _generateMockActivityLogs() {
    final now = DateTime.now();
    _activityLogs.addAll([
      ActivityLog(
        id: '1',
        type: 'AI',
        title: 'AI検知: 発注期限アラート',
        description: 'VVFケーブルの発注期限まであと3日です',
        timestamp: now.subtract(const Duration(minutes: 15)),
        isUrgent: true,
      ),
      ActivityLog(
        id: '2',
        type: 'progress',
        title: '工程完了: 基礎工事',
        description: '基礎工事が100%完了しました',
        timestamp: now.subtract(const Duration(hours: 2)),
        user: '田中監督',
      ),
      ActivityLog(
        id: '3',
        type: 'message',
        title: '連絡: 資材搬入',
        description: '午後14:00にトラック3台到着予定',
        timestamp: now.subtract(const Duration(hours: 4)),
        user: '鈴木',
      ),
      ActivityLog(
        id: '4',
        type: 'AI',
        title: 'AI提案: 天候リスク',
        description: '明日雨予報のため、外装工事の日程調整を推奨',
        timestamp: now.subtract(const Duration(hours: 6)),
      ),
      ActivityLog(
        id: '5',
        type: 'approval',
        title: '承認完了: 追加工事見積',
        description: '追加電気工事 ¥150,000 承認されました',
        timestamp: now.subtract(const Duration(days: 1)),
        user: '本社',
      ),
    ]);
  }

  double _calculateOverallProgress() {
    if (widget.tasks.isEmpty) return 0.0;
    return widget.tasks.map((t) => t.progress).reduce((a, b) => a + b) /
        widget.tasks.length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Cards Row
            _buildKPICards(),
            const SizedBox(height: AppConstants.paddingL),

            // AI Insight Card
            _buildAIInsightCard(),
            const SizedBox(height: AppConstants.paddingL),

            // Main Content Row
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline (Left)
                  Expanded(
                    flex: 2,
                    child: _buildTimelineCard(),
                  ),
                  const SizedBox(width: AppConstants.paddingM),

                  // Right Column
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildSiteStatusCard(),
                        const SizedBox(height: AppConstants.paddingM),
                        _buildQuickActionsCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICards() {
    final progress = _calculateOverallProgress();
    final completedTasks = widget.tasks.where((t) => t.status == 'completed').length;
    final alerts = widget.orderService?.criticalAlerts.length ?? 0;
    final pendingOrders = widget.orderService?.pendingOrders.length ?? 0;

    return Row(
      children: [
        Expanded(
          child: _KPICard(
            title: '全体進捗率',
            value: '${(progress * 100).toInt()}%',
            subtitle: '完了: $completedTasks/${widget.tasks.length}',
            icon: Icons.trending_up,
            color: AppColors.constructionGreen,
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: _KPICard(
            title: '発注状況',
            value: '$pendingOrders件',
            subtitle: '発注待ち',
            icon: Icons.inventory_2_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: _KPICard(
            title: 'リスク検知',
            value: '$alerts件',
            subtitle: alerts > 0 ? '要確認あり' : '問題なし',
            icon: Icons.warning_amber_rounded,
            color: alerts > 0 ? AppColors.industrialOrange : AppColors.textTertiary,
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          child: _KPICard(
            title: 'AIレポート',
            value: '3件',
            subtitle: '本日更新あり',
            icon: Icons.auto_awesome,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildAIInsightCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.purple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.withOpacity(0.2)),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.purple,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'AI現場インサイト',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.purple.withOpacity(0.2)),
                      ),
                      child: const Text(
                        'リアルタイム',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _isLoadingInsight
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _currentInsight,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.paddingM),
          OutlinedButton.icon(
            onPressed: _generateInsight,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('最新分析'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.purple,
              side: BorderSide(color: Colors.purple.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.timeline, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '現場ログ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    // Time filters
                    _buildTimeFilters(),
                  ],
                ),
                const SizedBox(height: 12),
                // Type filters
                _buildTypeFilters(),
              ],
            ),
          ),
          // Timeline list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              itemCount: _getFilteredLogs().length,
              itemBuilder: (context, index) {
                return _ActivityLogItem(log: _getFilteredLogs()[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilters() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimeFilterButton('today', '今日'),
          _buildTimeFilterButton('week', '週間'),
          _buildTimeFilterButton('all', '全期間'),
        ],
      ),
    );
  }

  Widget _buildTimeFilterButton(String value, String label) {
    final isSelected = _timeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _timeFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTypeFilterChip('all', 'すべて', null),
          const SizedBox(width: 8),
          _buildTypeFilterChip('AI', 'AI検知', Icons.auto_awesome),
          const SizedBox(width: 8),
          _buildTypeFilterChip('urgent', '優先', Icons.warning_amber_rounded),
          const SizedBox(width: 8),
          _buildTypeFilterChip('progress', '進捗', Icons.check_circle_outline),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChip(String value, String label, IconData? icon) {
    final isSelected = _typeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _typeFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ActivityLog> _getFilteredLogs() {
    var logs = _activityLogs;

    // Time filter
    final now = DateTime.now();
    if (_timeFilter == 'today') {
      logs = logs.where((l) =>
          l.timestamp.year == now.year &&
          l.timestamp.month == now.month &&
          l.timestamp.day == now.day).toList();
    } else if (_timeFilter == 'week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      logs = logs.where((l) => l.timestamp.isAfter(weekAgo)).toList();
    }

    // Type filter
    if (_typeFilter != 'all') {
      if (_typeFilter == 'urgent') {
        logs = logs.where((l) => l.isUrgent).toList();
      } else {
        logs = logs.where((l) => l.type == _typeFilter).toList();
      }
    }

    return logs;
  }

  Widget _buildSiteStatusCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '現在の現場状況',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Icon(Icons.wb_sunny, color: Colors.white.withOpacity(0.8), size: 32),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '24°C',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '湿度 45% / 風速 2m',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.campaign, color: Colors.yellow.shade300, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '午後から資材搬入トラック3台到着予定',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'クイックアクション',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _QuickActionButton(
            icon: Icons.description_outlined,
            label: '日報作成 (AI)',
            color: Colors.purple,
            onTap: () => _showAIPromptDialog('daily_report'),
          ),
          const SizedBox(height: 8),
          _QuickActionButton(
            icon: Icons.inventory_2_outlined,
            label: '発注リスト確認',
            color: AppColors.industrialOrange,
            onTap: () => widget.onNavigate?.call('orders'),
          ),
          const SizedBox(height: 8),
          _QuickActionButton(
            icon: Icons.camera_alt_outlined,
            label: '図面品番抽出 (AI)',
            color: AppColors.primary,
            onTap: () => _showAIPromptDialog('drawing_extraction'),
          ),
          const SizedBox(height: 8),
          _QuickActionButton(
            icon: Icons.file_download_outlined,
            label: 'CSV出力',
            color: AppColors.constructionGreen,
            onTap: () => _showExportDialog(),
          ),
        ],
      ),
    );
  }

  void _showAIPromptDialog(String promptId) {
    final content = TemplateService.getPromptContent(promptId);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.purple),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'AIプロンプト',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppColors.info, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'このプロンプトをコピーして、ChatGPTやClaudeに貼り付けて使用してください',
                        style: TextStyle(fontSize: 12, color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      content,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('閉じる'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: content));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('プロンプトをコピーしました'),
                          backgroundColor: AppColors.constructionGreen,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('コピー'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エクスポート'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart, color: AppColors.constructionGreen),
              title: const Text('材料リスト CSV'),
              onTap: () {
                Navigator.pop(context);
                final csv = SpreadsheetTemplates.getMaterialListCsv();
                Clipboard.setData(ClipboardData(text: csv));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSVをコピーしました')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: AppColors.primary),
              title: const Text('発注書テンプレート'),
              onTap: () {
                Navigator.pop(context);
                final csv = SpreadsheetTemplates.getOrderSheetCsv();
                Clipboard.setData(ClipboardData(text: csv));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSVをコピーしました')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

// KPI Card Widget
class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KPICard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Activity Log Item
class _ActivityLogItem extends StatelessWidget {
  final ActivityLog log;

  const _ActivityLogItem({required this.log});

  IconData get _icon {
    switch (log.type) {
      case 'AI':
        return Icons.auto_awesome;
      case 'progress':
        return Icons.check_circle;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'approval':
        return Icons.verified;
      default:
        return Icons.info_outline;
    }
  }

  Color get _color {
    switch (log.type) {
      case 'AI':
        return Colors.purple;
      case 'progress':
        return AppColors.constructionGreen;
      case 'message':
        return AppColors.primary;
      case 'approval':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: log.isUrgent
            ? AppColors.industrialOrange.withOpacity(0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: log.isUrgent
              ? AppColors.industrialOrange.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon, color: _color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (log.isUrgent) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.industrialOrange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '優先',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        log.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  log.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _formatTimestamp(log.timestamp),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    if (log.user != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• ${log.user}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}時間前';
    } else {
      return '${diff.inDays}日前';
    }
  }
}

// Quick Action Button
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

// Activity Log Model
class ActivityLog {
  final String id;
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;
  final String? user;
  final bool isUrgent;

  const ActivityLog({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.user,
    this.isUrgent = false,
  });
}
