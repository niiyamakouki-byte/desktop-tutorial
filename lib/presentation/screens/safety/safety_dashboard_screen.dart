/// Safety Dashboard Screen
/// 安全管理ダッシュボード画面

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/safety_models.dart';
import '../../../data/services/safety_service.dart';
import 'ky_activity_screen.dart';
import 'near_miss_screen.dart';
import 'safety_patrol_screen.dart';

/// 安全管理ダッシュボード
class SafetyDashboardScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  final VoidCallback? onBack;

  const SafetyDashboardScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    this.onBack,
  });

  @override
  State<SafetyDashboardScreen> createState() => _SafetyDashboardScreenState();
}

class _SafetyDashboardScreenState extends State<SafetyDashboardScreen> {
  final SafetyService _safetyService = SafetyService();
  bool _isLoading = true;
  SafetySummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _safetyService.initialize();
    _summary = _safetyService.getSafetySummary(widget.projectId);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
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
              '安全管理',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.projectName,
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '更新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // サマリーカード
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    // メニューカード
                    _buildMenuCards(),
                    const SizedBox(height: 24),
                    // 最近のアクティビティ
                    _buildRecentActivity(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '安全活動状況',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'KY活動',
                '${_summary?.kyActivityCount ?? 0}',
                '件',
                Icons.psychology,
                const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'ヒヤリハット',
                '${_summary?.nearMissCount ?? 0}',
                '件',
                Icons.warning_amber,
                const Color(0xFFFF9800),
                badge: _summary?.unresolvedNearMissCount ?? 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'パトロール',
                '${_summary?.patrolCount ?? 0}',
                '回',
                Icons.checklist,
                const Color(0xFF2196F3),
                badge: _summary?.pendingCorrectionCount ?? 0,
              ),
            ),
          ],
        ),
        // 警告表示
        if (_summary?.hasWarnings == true) ...[
          const SizedBox(height: 12),
          _buildWarningBanner(),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color, {
    int badge = 0,
  }) {
    return Container(
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (badge > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
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

  Widget _buildWarningBanner() {
    final warnings = <String>[];
    if ((_summary?.unresolvedNearMissCount ?? 0) > 0) {
      warnings.add('未対応ヒヤリハット ${_summary?.unresolvedNearMissCount}件');
    }
    if ((_summary?.pendingCorrectionCount ?? 0) > 0) {
      warnings.add('未是正 ${_summary?.pendingCorrectionCount}件');
    }
    if ((_summary?.highSeverityCount ?? 0) > 0) {
      warnings.add('重要度「高」${_summary?.highSeverityCount}件');
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              warnings.join(' / '),
              style: TextStyle(
                fontSize: 13,
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '安全管理メニュー',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          title: 'KY（危険予知）活動',
          subtitle: '日々の作業開始前に危険を予測し対策を立てる',
          icon: Icons.psychology,
          color: const Color(0xFF4CAF50),
          features: ['作業内容記録', '危険予測・対策', '参加者チェック', '写真添付'],
          onTap: () => _navigateToKYActivity(),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          title: 'ヒヤリハット報告',
          subtitle: '危険な出来事を報告し再発防止につなげる',
          icon: Icons.warning_amber,
          color: const Color(0xFFFF9800),
          features: ['発生状況記録', '原因分析', '対策立案', '重要度設定'],
          onTap: () => _navigateToNearMiss(),
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          title: '安全パトロール',
          subtitle: '定期的な現場点検でリスクを早期発見',
          icon: Icons.checklist,
          color: const Color(0xFF2196F3),
          features: ['チェックリスト', '不適合記録', '写真撮影', '是正確認'],
          onTap: () => _navigateToSafetyPatrol(),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: features.map((f) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final kyRecords = _safetyService.getKYRecordsByProject(widget.projectId);
    final nearMissReports = _safetyService.getNearMissReportsByProject(widget.projectId);
    final patrolRecords = _safetyService.getPatrolRecordsByProject(widget.projectId);

    // 最近のアクティビティを時系列でマージ
    final activities = <_ActivityItem>[];

    for (final ky in kyRecords.take(3)) {
      activities.add(_ActivityItem(
        type: 'ky',
        title: 'KY活動: ${ky.workContent}',
        subtitle: ky.location ?? '',
        date: ky.date,
        color: const Color(0xFF4CAF50),
        icon: Icons.psychology,
      ));
    }

    for (final nm in nearMissReports.take(3)) {
      activities.add(_ActivityItem(
        type: 'near_miss',
        title: 'ヒヤリハット: ${nm.description}',
        subtitle: nm.location,
        date: nm.occurredAt,
        color: const Color(0xFFFF9800),
        icon: Icons.warning_amber,
        severity: nm.severity,
      ));
    }

    for (final patrol in patrolRecords.take(3)) {
      activities.add(_ActivityItem(
        type: 'patrol',
        title: '安全パトロール',
        subtitle: '適合率: ${patrol.conformanceRate.toStringAsFixed(0)}%',
        date: patrol.patrolDate,
        color: const Color(0xFF2196F3),
        icon: Icons.checklist,
      ));
    }

    activities.sort((a, b) => b.date.compareTo(a.date));

    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '最近のアクティビティ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.take(5).length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _buildActivityTile(activity);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTile(_ActivityItem activity) {
    final dateFormat = DateFormat('M/d HH:mm', 'ja');

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: activity.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(activity.icon, color: activity.color, size: 20),
      ),
      title: Text(
        activity.title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Text(
            activity.subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          if (activity.severity != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getSeverityColor(activity.severity!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                activity.severity!.displayName,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: Text(
        dateFormat.format(activity.date),
        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
      ),
    );
  }

  Color _getSeverityColor(NearMissSeverity severity) {
    switch (severity) {
      case NearMissSeverity.high:
        return Colors.red;
      case NearMissSeverity.medium:
        return Colors.orange;
      case NearMissSeverity.low:
        return Colors.amber;
    }
  }

  void _navigateToKYActivity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KYActivityScreen(
          projectId: widget.projectId,
          projectName: widget.projectName,
          safetyService: _safetyService,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToNearMiss() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NearMissScreen(
          projectId: widget.projectId,
          projectName: widget.projectName,
          safetyService: _safetyService,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToSafetyPatrol() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SafetyPatrolScreen(
          projectId: widget.projectId,
          projectName: widget.projectName,
          safetyService: _safetyService,
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  void dispose() {
    _safetyService.dispose();
    super.dispose();
  }
}

class _ActivityItem {
  final String type;
  final String title;
  final String subtitle;
  final DateTime date;
  final Color color;
  final IconData icon;
  final NearMissSeverity? severity;

  _ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.color,
    required this.icon,
    this.severity,
  });
}
