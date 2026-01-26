/// Current Workers Dashboard Card
/// 現在入場者カードウィジェット

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/services/attendance_service.dart';
import '../../../data/models/person.dart';

/// 現在入場者カード（コックピットダッシュボード用）
class CurrentWorkersCard extends StatefulWidget {
  final String projectId;
  final VoidCallback? onTap;
  final VoidCallback? onKioskButtonPressed;

  const CurrentWorkersCard({
    super.key,
    required this.projectId,
    this.onTap,
    this.onKioskButtonPressed,
  });

  @override
  State<CurrentWorkersCard> createState() => _CurrentWorkersCardState();
}

class _CurrentWorkersCardState extends State<CurrentWorkersCard> {
  final AttendanceService _attendanceService = AttendanceService();
  List<CurrentAttendee> _currentAttendees = [];
  bool _isLoading = true;
  bool _showAllWorkers = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _attendanceService.initialize();
      _currentAttendees = await _attendanceService.getCurrentAttendees(widget.projectId);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface,
                const Color(0xFF4CAF50).withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              _buildHeader(),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // 入場者リスト
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_currentAttendees.isEmpty)
                _buildEmptyState()
              else
                _buildWorkersList(),
              // アクションボタン
              if (widget.onKioskButtonPressed != null) ...[
                const SizedBox(height: 12),
                _buildKioskButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.people,
            color: Color(0xFF4CAF50),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '現在入場者',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${_currentAttendees.length}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const Text(
                    '名',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // リフレッシュボタン
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: AppColors.textSecondary,
          ),
          onPressed: _loadData,
          tooltip: '更新',
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.person_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              '現在入場者はいません',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkersList() {
    final displayCount = _showAllWorkers ? _currentAttendees.length : 5;
    final displayList = _currentAttendees.take(displayCount).toList();

    return Column(
      children: [
        // 会社別カウント
        _buildCompanySummary(),
        const SizedBox(height: 12),
        // 入場者リスト
        ...displayList.map((attendee) => _buildWorkerTile(attendee)),
        // 「もっと見る」ボタン
        if (_currentAttendees.length > 5)
          TextButton(
            onPressed: () {
              setState(() => _showAllWorkers = !_showAllWorkers);
            },
            child: Text(
              _showAllWorkers
                  ? '折りたたむ'
                  : '全${_currentAttendees.length}名を表示',
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildCompanySummary() {
    // 会社別に集計
    final Map<String, int> companyCount = {};
    for (final attendee in _currentAttendees) {
      final companyName = attendee.company?.displayName ?? '不明';
      companyCount[companyName] = (companyCount[companyName] ?? 0) + 1;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: companyCount.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${entry.key}: ${entry.value}名',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkerTile(CurrentAttendee attendee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: attendee.hasWarning
            ? Colors.orange.withOpacity(0.1)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: attendee.hasWarning ? Colors.orange : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          // アバター
          CircleAvatar(
            radius: 18,
            backgroundColor: _getJobTypeColor(attendee.person.jobType),
            child: Text(
              attendee.person.name.substring(0, 1),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 名前・会社
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      attendee.person.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (attendee.hasWarning) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.warning_amber,
                        size: 14,
                        color: Colors.orange,
                      ),
                    ],
                  ],
                ),
                Text(
                  '${attendee.company?.displayName ?? "不明"} / ${attendee.person.jobType.displayName}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // 入場時刻・滞在時間
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${attendee.inTime.hour.toString().padLeft(2, '0')}:${attendee.inTime.minute.toString().padLeft(2, '0')} IN',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4CAF50),
                ),
              ),
              Text(
                attendee.stayDurationString,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKioskButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onKioskButtonPressed,
        icon: const Icon(Icons.qr_code_scanner, size: 20),
        label: const Text('入退場キオスク画面を開く'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Color _getJobTypeColor(JobType jobType) {
    switch (jobType) {
      case JobType.carpenter:
        return const Color(0xFF8D6E63); // 茶色
      case JobType.scaffolder:
        return const Color(0xFF5C6BC0); // 紫
      case JobType.electrician:
        return const Color(0xFFFFB300); // 黄色
      case JobType.plumber:
        return const Color(0xFF00ACC1); // シアン
      case JobType.painter:
        return const Color(0xFFE91E63); // ピンク
      case JobType.plasterer:
        return const Color(0xFF795548); // ブラウン
      case JobType.reinforcer:
        return const Color(0xFF546E7A); // グレー
      case JobType.formworker:
        return const Color(0xFF6D4C41); // ダークブラウン
      case JobType.operator:
        return const Color(0xFFFF7043); // オレンジ
      case JobType.supervisor:
        return const Color(0xFF1A237E); // ダークブルー
      case JobType.clerk:
        return const Color(0xFF7986CB); // ライトブルー
      case JobType.other:
        return const Color(0xFF78909C); // ブルーグレー
    }
  }

  @override
  void dispose() {
    _attendanceService.dispose();
    super.dispose();
  }
}

/// コンパクト版・現在入場者カード（サイドバー用）
class CurrentWorkersCompactCard extends StatelessWidget {
  final int workerCount;
  final VoidCallback? onTap;

  const CurrentWorkersCompactCard({
    super.key,
    required this.workerCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.people,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '現在入場者',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$workerCount名',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
