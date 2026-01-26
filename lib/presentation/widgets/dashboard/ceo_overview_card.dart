/// CEO Overview Dashboard Card
/// 経営者向け全現場俯瞰ダッシュボードカード
///
/// 全現場の「予定通り / 遅延 / 職人確認待ち」を
/// 1画面で俯瞰できるダッシュボード

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../data/models/notification_feedback_model.dart';

/// プロジェクトの健全性ステータス
enum ProjectHealthStatus {
  /// 順調（予定通り）
  onTrack('on_track', '順調', Color(0xFF4CAF50), Icons.check_circle),

  /// 軽微な遅延
  minorDelay('minor_delay', '軽遅延', Color(0xFFFF9800), Icons.warning),

  /// 重大な遅延
  majorDelay('major_delay', '遅延', Color(0xFFF44336), Icons.error),

  /// 確認待ち（職人返信待ち）
  pendingConfirmation('pending', '確認待ち', Color(0xFF2196F3), Icons.schedule),

  /// 中断中
  paused('paused', '中断', Color(0xFF9E9E9E), Icons.pause_circle);

  final String value;
  final String displayName;
  final Color color;
  final IconData icon;

  const ProjectHealthStatus(this.value, this.displayName, this.color, this.icon);
}

/// プロジェクトサマリデータ
class ProjectSummaryData {
  final String projectId;
  final String projectName;
  final String? location;
  final ProjectHealthStatus status;
  final double progress; // 0.0 - 1.0
  final int totalTasks;
  final int completedTasks;
  final int delayedTasks;
  final int pendingConfirmations; // 職人確認待ち数
  final DateTime? expectedCompletion;
  final int? delayDays; // 遅延日数（マイナスは前倒し）
  final String? currentPhaseName;
  final String? nextMilestone;
  final DateTime? nextMilestoneDate;

  const ProjectSummaryData({
    required this.projectId,
    required this.projectName,
    this.location,
    required this.status,
    required this.progress,
    required this.totalTasks,
    required this.completedTasks,
    required this.delayedTasks,
    required this.pendingConfirmations,
    this.expectedCompletion,
    this.delayDays,
    this.currentPhaseName,
    this.nextMilestone,
    this.nextMilestoneDate,
  });

  /// 残りタスク数
  int get remainingTasks => totalTasks - completedTasks;

  /// 遅延があるか
  bool get hasDelay => delayedTasks > 0 || (delayDays != null && delayDays! > 0);

  /// 確認待ちがあるか
  bool get hasPendingConfirmations => pendingConfirmations > 0;
}

/// CEO全現場俯瞰カード
class CEOOverviewCard extends StatelessWidget {
  final List<ProjectSummaryData> projects;
  final Function(String projectId)? onProjectTap;
  final VoidCallback? onViewDetails;

  const CEOOverviewCard({
    super.key,
    required this.projects,
    this.onProjectTap,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    // ステータス別集計
    final onTrackCount =
        projects.where((p) => p.status == ProjectHealthStatus.onTrack).length;
    final delayCount = projects
        .where((p) =>
            p.status == ProjectHealthStatus.minorDelay ||
            p.status == ProjectHealthStatus.majorDelay)
        .length;
    final pendingCount = projects
        .where((p) => p.status == ProjectHealthStatus.pendingConfirmation)
        .length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          _buildHeader(onTrackCount, delayCount, pendingCount),

          // ステータスサマリバー
          _buildStatusSummaryBar(onTrackCount, delayCount, pendingCount),

          // プロジェクトリスト
          if (projects.isEmpty)
            _buildEmptyState()
          else
            ...projects.map((project) => _buildProjectRow(project)),

          // フッター
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader(int onTrack, int delay, int pending) {
    final totalProjects = projects.length;
    final healthScore = _calculateOverallHealth();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          // アイコン
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // タイトル
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '全現場ダッシュボード',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalProjects件のプロジェクトを管理中',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // 健全性スコア
          _buildHealthScoreBadge(healthScore),
        ],
      ),
    );
  }

  Widget _buildHealthScoreBadge(int score) {
    Color color;
    String label;
    if (score >= 80) {
      color = const Color(0xFF4CAF50);
      label = '良好';
    } else if (score >= 60) {
      color = const Color(0xFF2196F3);
      label = '普通';
    } else if (score >= 40) {
      color = const Color(0xFFFF9800);
      label = '注意';
    } else {
      color = const Color(0xFFF44336);
      label = '要対応';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$score',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummaryBar(int onTrack, int delay, int pending) {
    final total = projects.length;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // プログレスバー
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                if (onTrack > 0)
                  Expanded(
                    flex: onTrack,
                    child: Container(
                      height: 8,
                      color: ProjectHealthStatus.onTrack.color,
                    ),
                  ),
                if (delay > 0)
                  Expanded(
                    flex: delay,
                    child: Container(
                      height: 8,
                      color: ProjectHealthStatus.majorDelay.color,
                    ),
                  ),
                if (pending > 0)
                  Expanded(
                    flex: pending,
                    child: Container(
                      height: 8,
                      color: ProjectHealthStatus.pendingConfirmation.color,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 凡例
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(
                  '順調', onTrack, ProjectHealthStatus.onTrack.color),
              _buildLegendItem(
                  '遅延', delay, ProjectHealthStatus.majorDelay.color),
              _buildLegendItem('確認待ち', pending,
                  ProjectHealthStatus.pendingConfirmation.color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectRow(ProjectSummaryData project) {
    return InkWell(
      onTap: onProjectTap != null ? () => onProjectTap!(project.projectId) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // ステータスアイコン
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: project.status.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                project.status.icon,
                color: project.status.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // プロジェクト情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.projectName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 遅延バッジ
                      if (project.delayDays != null && project.delayDays! > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.constructionRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+${project.delayDays}日',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // 現在フェーズ
                      if (project.currentPhaseName != null) ...[
                        Icon(
                          Icons.flag_outlined,
                          size: 12,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          project.currentPhaseName!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      // 確認待ち
                      if (project.pendingConfirmations > 0) ...[
                        Icon(
                          Icons.person_outline,
                          size: 12,
                          color: const Color(0xFF2196F3),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${project.pendingConfirmations}名確認待ち',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // 進捗
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(project.progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: project.status.color,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 60,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: project.progress,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation(project.status.color),
                      minHeight: 6,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_off_outlined,
              size: 48,
              color: AppColors.textTertiary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'プロジェクトがありません',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final totalDelayed = projects.fold<int>(
      0,
      (sum, p) => sum + p.delayedTasks,
    );
    final totalPending = projects.fold<int>(
      0,
      (sum, p) => sum + p.pendingConfirmations,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // 警告サマリ
          if (totalDelayed > 0 || totalPending > 0)
            Expanded(
              child: Row(
                children: [
                  if (totalDelayed > 0) ...[
                    Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: AppColors.constructionRed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$totalDelayed件遅延',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.constructionRed,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (totalPending > 0) ...[
                    const Icon(
                      Icons.schedule,
                      size: 16,
                      color: Color(0xFF2196F3),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$totalPending名確認待ち',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '全プロジェクト順調',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),

          // 詳細ボタン
          if (onViewDetails != null)
            TextButton.icon(
              onPressed: onViewDetails,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('詳細'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _calculateOverallHealth() {
    if (projects.isEmpty) return 100;

    int score = 100;

    for (final project in projects) {
      switch (project.status) {
        case ProjectHealthStatus.majorDelay:
          score -= 15;
          break;
        case ProjectHealthStatus.minorDelay:
          score -= 8;
          break;
        case ProjectHealthStatus.pendingConfirmation:
          score -= 5;
          break;
        case ProjectHealthStatus.paused:
          score -= 3;
          break;
        default:
          break;
      }

      // 遅延タスクによるペナルティ
      score -= (project.delayedTasks * 2);

      // 確認待ちによるペナルティ
      score -= project.pendingConfirmations;
    }

    return score.clamp(0, 100);
  }
}

/// コンパクト版CEOオーバービュー
class CEOOverviewCompact extends StatelessWidget {
  final List<ProjectSummaryData> projects;
  final VoidCallback? onTap;

  const CEOOverviewCompact({
    super.key,
    required this.projects,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onTrackCount =
        projects.where((p) => p.status == ProjectHealthStatus.onTrack).length;
    final issueCount = projects.length - onTrackCount;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.dashboard_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '全現場サマリ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${projects.length}件のプロジェクト',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (issueCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.constructionRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      size: 14,
                      color: AppColors.constructionRed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$issueCount件',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.constructionRed,
                      ),
                    ),
                  ],
                ),
              )
            else
              const Icon(
                Icons.check_circle,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
