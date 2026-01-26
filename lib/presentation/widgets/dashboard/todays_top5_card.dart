/// Today's Top 5 Dashboard Card
/// 本日のTOP5タスクを表示するダッシュボードカード

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../data/models/phase_model.dart';

/// Card showing today's top 5 priority tasks
class TodaysTop5Card extends StatelessWidget {
  final List<Task> tasks;
  final Map<String, Phase> phaseMap;
  final Function(Task task)? onTaskTap;
  final VoidCallback? onViewAll;

  const TodaysTop5Card({
    super.key,
    required this.tasks,
    this.phaseMap = const {},
    this.onTaskTap,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final topTasks = _getTop5Tasks();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(topTasks.length),

          // Task list
          if (topTasks.isEmpty)
            _buildEmptyState()
          else
            ...topTasks
                .asMap()
                .entries
                .map((entry) => _buildTaskItem(entry.key + 1, entry.value, today)),

          // Footer
          if (topTasks.isNotEmpty) _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader(int taskCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.industrialOrange,
                  AppColors.industrialOrange.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.industrialOrange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '本日のTOP5',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _getSubtitleText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.industrialOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$taskCount件',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.industrialOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(int rank, Task task, DateTime today) {
    final isOverdue = task.isOverdue;
    final isToday = _isTaskForToday(task, today);
    final phase = task.phaseId != null ? phaseMap[task.phaseId] : null;
    final phaseColor = phase != null
        ? PhaseColors.getColorForOrder(phase.order)
        : AppColors.getCategoryColor(task.category);

    Color priorityColor;
    IconData priorityIcon;
    switch (task.priority) {
      case 'high':
        priorityColor = AppColors.constructionRed;
        priorityIcon = Icons.keyboard_double_arrow_up;
        break;
      case 'medium':
        priorityColor = AppColors.industrialOrange;
        priorityIcon = Icons.keyboard_arrow_up;
        break;
      default:
        priorityColor = AppColors.textTertiary;
        priorityIcon = Icons.remove;
    }

    return InkWell(
      onTap: onTaskTap != null ? () => onTaskTap!(task) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isOverdue
              ? AppColors.constructionRed.withOpacity(0.05)
              : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getRankColors(rank),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getRankColors(rank).first.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Phase color indicator
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: phaseColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),

            // Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOverdue)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.constructionRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '遅延',
                            style: TextStyle(
                              fontSize: 9,
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
                      // Phase/Category badge
                      if (phase != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: phaseColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            phase.shortName,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: phaseColor,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: phaseColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            TaskCategory.getLabel(task.category),
                            style: TextStyle(
                              fontSize: 9,
                              color: phaseColor,
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      // Date
                      Icon(
                        isToday ? Icons.today : Icons.calendar_today_outlined,
                        size: 11,
                        color: isToday
                            ? AppColors.primary
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _formatTaskDate(task, today),
                        style: TextStyle(
                          fontSize: 10,
                          color: isToday
                              ? AppColors.primary
                              : AppColors.textTertiary,
                          fontWeight: isToday ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Contractor
                      if (task.contractorName != null) ...[
                        const Icon(
                          Icons.business,
                          size: 11,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          task.contractorName!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Priority and progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      priorityIcon,
                      size: 14,
                      color: priorityColor,
                    ),
                    const SizedBox(width: 4),
                    _buildMiniProgressBar(task.progress, phaseColor),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${(task.progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: phaseColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniProgressBar(double progress, Color color) {
    return Container(
      width: 40,
      height: 6,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: AppColors.constructionGreen.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              '本日の優先タスクなし',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '新しいタスクを追加してください',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatBadge(
            Icons.warning_amber_rounded,
            '${_getOverdueCount()}件遅延',
            AppColors.constructionRed,
          ),
          _buildStatBadge(
            Icons.today,
            '${_getTodayCount()}件今日',
            AppColors.primary,
          ),
          if (onViewAll != null)
            TextButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.list_alt, size: 16),
              label: const Text('全て表示'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _buildStatBadge(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Get top 5 priority tasks
  List<Task> _getTop5Tasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Filter tasks that are not completed
    final activeTasks = tasks.where((t) => t.status != 'completed').toList();

    // Score each task
    final scored = activeTasks.map((task) {
      int score = 0;

      // Overdue tasks get highest priority
      if (task.isOverdue) {
        final overdueDays = now.difference(task.endDate).inDays;
        score += 1000 + (overdueDays * 10);
      }

      // Tasks scheduled for today
      if (_isTaskForToday(task, today)) {
        score += 500;
      }

      // High priority tasks
      switch (task.priority) {
        case 'high':
          score += 300;
          break;
        case 'medium':
          score += 150;
          break;
      }

      // Tasks starting soon (within 3 days)
      final daysUntilStart = task.startDate.difference(today).inDays;
      if (daysUntilStart >= 0 && daysUntilStart <= 3) {
        score += (3 - daysUntilStart) * 50;
      }

      // Tasks with low progress that are near deadline
      final daysUntilEnd = task.endDate.difference(today).inDays;
      if (daysUntilEnd >= 0 && daysUntilEnd <= 3 && task.progress < 0.8) {
        score += ((1 - task.progress) * 200).round();
      }

      return MapEntry(task, score);
    }).toList();

    // Sort by score descending
    scored.sort((a, b) => b.value.compareTo(a.value));

    // Return top 5
    return scored.take(5).map((e) => e.key).toList();
  }

  bool _isTaskForToday(Task task, DateTime today) {
    final taskStart = DateTime(task.startDate.year, task.startDate.month, task.startDate.day);
    final taskEnd = DateTime(task.endDate.year, task.endDate.month, task.endDate.day);
    return !today.isBefore(taskStart) && !today.isAfter(taskEnd);
  }

  int _getOverdueCount() {
    return tasks.where((t) => t.isOverdue && t.status != 'completed').length;
  }

  int _getTodayCount() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return tasks.where((t) => _isTaskForToday(t, today) && t.status != 'completed').length;
  }

  String _getSubtitleText() {
    final now = DateTime.now();
    final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final weekday = weekdays[(now.weekday - 1) % 7];
    return '${now.month}/${now.day} ($weekday) の優先タスク';
  }

  String _formatTaskDate(Task task, DateTime today) {
    if (_isTaskForToday(task, today)) {
      return '本日まで';
    }
    final diff = task.endDate.difference(today).inDays;
    if (diff < 0) {
      return '${-diff}日遅延';
    } else if (diff == 0) {
      return '本日';
    } else if (diff == 1) {
      return '明日';
    } else {
      return '${task.endDate.month}/${task.endDate.day}';
    }
  }

  List<Color> _getRankColors(int rank) {
    switch (rank) {
      case 1:
        return [const Color(0xFFFFD700), const Color(0xFFFFB300)]; // Gold
      case 2:
        return [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)]; // Silver
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFFA0522D)]; // Bronze
      default:
        return [AppColors.textSecondary, AppColors.textTertiary];
    }
  }
}

/// Compact version of Today's Top 5 for smaller spaces
class TodaysTop5Compact extends StatelessWidget {
  final List<Task> tasks;
  final VoidCallback? onTap;

  const TodaysTop5Compact({
    super.key,
    required this.tasks,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final overdueCount = tasks.where((t) => t.isOverdue && t.status != 'completed').length;
    final activeCount = tasks.where((t) => t.status != 'completed').length;

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
                color: AppColors.industrialOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.star_rounded,
                color: AppColors.industrialOrange,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '本日のTOP5',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$activeCount 件のタスク',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (overdueCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.constructionRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$overdueCount遅延',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
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
