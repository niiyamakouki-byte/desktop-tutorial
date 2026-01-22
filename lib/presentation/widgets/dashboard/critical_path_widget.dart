/// Critical Path Progress Widget
/// クリティカルパス進捗表示ウィジェット

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/project_health_model.dart';

/// Horizontal bar chart showing critical path progress
class CriticalPathProgressChart extends StatelessWidget {
  final CriticalPathProgress progress;
  final double height;
  final bool showTaskDetails;
  final Function(String taskId)? onTaskTap;

  const CriticalPathProgressChart({
    super.key,
    required this.progress,
    this.height = 200,
    this.showTaskDetails = true,
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.constructionRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.timeline,
                    color: AppColors.constructionRed,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'クリティカルパス進捗',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${progress.completedTasks}/${progress.totalTasks} タスク完了',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildProgressBadge(),
              ],
            ),
          ),

          // Overall progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildOverallProgressBar(),
          ),

          const SizedBox(height: 16),

          // Task bars
          if (showTaskDetails && progress.tasks.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: progress.tasks.length,
                itemBuilder: (context, index) {
                  return _buildTaskBar(progress.tasks[index]);
                },
              ),
            )
          else if (progress.tasks.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'クリティカルパスタスクなし',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

          // Summary footer
          if (progress.earliestCompletion != null)
            Container(
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
                  Text(
                    '予定完了: ${_formatDate(progress.earliestCompletion!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (progress.delayedTasks > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.constructionRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
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
                            '${progress.delayedTasks}件遅延',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.constructionRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBadge() {
    final isOnTrack = progress.isOnTrack;
    final color = isOnTrack ? AppColors.constructionGreen : AppColors.constructionRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnTrack ? Icons.check_circle : Icons.warning,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            isOnTrack ? '順調' : '遅延あり',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '全体進捗',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${progress.overallProgress.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress.overallProgress / 100,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.constructionRed,
                      AppColors.industrialOrange,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.constructionRed.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskBar(CriticalPathTask task) {
    final progressColor = task.isDelayed
        ? AppColors.constructionRed
        : (task.progress >= 100
            ? AppColors.constructionGreen
            : AppColors.industrialOrange);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTaskTap != null ? () => onTaskTap!(task.id) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: task.isDelayed
                ? AppColors.constructionRed.withOpacity(0.05)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: task.isDelayed
                  ? AppColors.constructionRed.withOpacity(0.3)
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: progressColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${task.order}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (task.isDelayed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.constructionRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+${task.delayDays}日',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: task.progress / 100,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: progressColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${task.progress.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: progressColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatDate(task.startDate)} - ${_formatDate(task.endDate)}',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}

/// Compact critical path indicator
class CriticalPathIndicator extends StatelessWidget {
  final int completedTasks;
  final int totalTasks;
  final int delayedTasks;
  final double progress;

  const CriticalPathIndicator({
    super.key,
    required this.completedTasks,
    required this.totalTasks,
    required this.delayedTasks,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final hasDelays = delayedTasks > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasDelays
            ? AppColors.constructionRed.withOpacity(0.1)
            : AppColors.constructionGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasDelays
              ? AppColors.constructionRed.withOpacity(0.3)
              : AppColors.constructionGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasDelays ? Icons.warning : Icons.check_circle,
            color: hasDelays
                ? AppColors.constructionRed
                : AppColors.constructionGreen,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'クリティカルパス',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$completedTasks / $totalTasks 完了',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${progress.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: hasDelays
                      ? AppColors.constructionRed
                      : AppColors.constructionGreen,
                ),
              ),
              if (hasDelays)
                Text(
                  '$delayedTasks件遅延',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.constructionRed,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
