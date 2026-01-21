import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import 'gantt_constants.dart';

/// Individual task row component for the task list panel
class TaskRow extends StatefulWidget {
  final Task task;
  final bool hasChildren;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onExpandToggle;
  final double width;

  const TaskRow({
    super.key,
    required this.task,
    this.hasChildren = false,
    this.isSelected = false,
    this.onTap,
    this.onDoubleTap,
    this.onExpandToggle,
    this.width = GanttConstants.taskListWidth,
  });

  @override
  State<TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<TaskRow> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: GanttConstants.expandDuration,
      vsync: this,
    );
    _expandAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _expandController,
      curve: GanttConstants.expandCurve,
    ));

    if (widget.task.isExpanded) {
      _expandController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(TaskRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.isExpanded != oldWidget.task.isExpanded) {
      if (widget.task.isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final indent = widget.task.level * GanttConstants.treeIndent;
    final statusColor = AppColors.getTaskStatusColor(widget.task.status);
    final categoryColor = AppColors.getCategoryColor(widget.task.category);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: AnimatedContainer(
          duration: GanttConstants.hoverDuration,
          height: GanttConstants.rowHeight,
          width: widget.width,
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            border: Border(
              bottom: BorderSide(
                color: AppColors.ganttGridLine,
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            children: [
              // Indentation and expand button
              SizedBox(width: GanttConstants.cellPadding + indent),
              _buildExpandButton(),
              const SizedBox(width: 4),

              // Status indicator
              _buildStatusIndicator(statusColor),
              const SizedBox(width: 8),

              // Task name and info
              Expanded(
                child: _buildTaskInfo(categoryColor),
              ),

              // Progress indicator
              _buildProgressBadge(),
              const SizedBox(width: GanttConstants.cellPadding),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (widget.isSelected) {
      return AppColors.ganttRowSelected;
    }
    if (_isHovered) {
      return AppColors.ganttRowHover;
    }
    return AppColors.ganttBackground;
  }

  Widget _buildExpandButton() {
    if (!widget.hasChildren) {
      return SizedBox(width: GanttConstants.expandIconSize);
    }

    return GestureDetector(
      onTap: widget.onExpandToggle,
      child: AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _expandAnimation.value * 3.14159,
            child: Icon(
              Icons.expand_more,
              size: GanttConstants.expandIconSize,
              color: AppColors.iconDefault,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusIndicator(Color statusColor) {
    if (widget.task.isMilestone) {
      return Transform.rotate(
        angle: 0.785398, // 45 degrees
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      );
    }

    return Container(
      width: 4,
      height: 24,
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTaskInfo(Color categoryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.task.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.task.level == 0
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            // Category badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                TaskCategory.getLabel(widget.task.category),
                style: TextStyle(
                  fontSize: 10,
                  color: categoryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Date range
            Text(
              _formatDateRange(),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBadge() {
    final progress = (widget.task.progress * 100).round();
    final isComplete = progress >= 100;
    final isOverdue = widget.task.isOverdue;

    Color badgeColor;
    if (isComplete) {
      badgeColor = AppColors.success;
    } else if (isOverdue) {
      badgeColor = AppColors.error;
    } else {
      badgeColor = AppColors.taskInProgress;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$progress%',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  String _formatDateRange() {
    final start = widget.task.startDate;
    final end = widget.task.endDate;
    return GanttConstants.formatDateRange(start, end);
  }
}

/// Task bar component for the timeline panel
class TaskBar extends StatefulWidget {
  final Task task;
  final double left;
  final double width;
  final bool isSelected;
  final VoidCallback? onTap;
  final Function(DragUpdateDetails)? onDragUpdate;
  final Function(DragEndDetails)? onDragEnd;

  const TaskBar({
    super.key,
    required this.task,
    required this.left,
    required this.width,
    this.isSelected = false,
    this.onTap,
    this.onDragUpdate,
    this.onDragEnd,
  });

  @override
  State<TaskBar> createState() => _TaskBarState();
}

class _TaskBarState extends State<TaskBar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.getTaskStatusColor(widget.task.status);
    final categoryColor = AppColors.getCategoryColor(widget.task.category);

    // For milestones, render a diamond
    if (widget.task.isMilestone) {
      return _buildMilestone(statusColor);
    }

    return Positioned(
      left: widget.left,
      top: (GanttConstants.rowHeight - GanttConstants.taskBarHeight) / 2,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          onPanUpdate: widget.onDragUpdate,
          onPanEnd: widget.onDragEnd,
          child: AnimatedContainer(
            duration: GanttConstants.hoverDuration,
            width: widget.width.clamp(GanttConstants.minTaskBarWidth, double.infinity),
            height: GanttConstants.taskBarHeight,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: GanttConstants.taskBarOpacity),
              borderRadius: BorderRadius.circular(GanttConstants.taskBarRadius),
              border: Border.all(
                color: widget.isSelected
                    ? AppColors.primary
                    : (_isHovered ? categoryColor : Colors.transparent),
                width: widget.isSelected ? 2 : 1,
              ),
              boxShadow: _isHovered || widget.isSelected
                  ? [
                      BoxShadow(
                        color: categoryColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(GanttConstants.taskBarRadius),
              child: Stack(
                children: [
                  // Progress fill
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: widget.width * widget.task.progress,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: GanttConstants.progressOpacity),
                      ),
                    ),
                  ),
                  // Task name (only show if bar is wide enough)
                  if (widget.width > 60)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.task.name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  // Progress percentage (right side)
                  if (widget.width > 80)
                    Positioned(
                      right: 6,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Text(
                          '${(widget.task.progress * 100).round()}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMilestone(Color color) {
    return Positioned(
      left: widget.left - GanttConstants.milestoneSize / 2,
      top: (GanttConstants.rowHeight - GanttConstants.milestoneSize) / 2,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Transform.rotate(
            angle: 0.785398, // 45 degrees
            child: AnimatedContainer(
              duration: GanttConstants.hoverDuration,
              width: GanttConstants.milestoneSize,
              height: GanttConstants.milestoneSize,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: widget.isSelected
                      ? AppColors.primary
                      : (_isHovered ? Colors.white : Colors.transparent),
                  width: 2,
                ),
                boxShadow: _isHovered || widget.isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tooltip content for task bar hover
class TaskBarTooltip extends StatelessWidget {
  final Task task;

  const TaskBarTooltip({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.getTaskStatusColor(task.status);
    final statusLabel = AppConstants.statusLabels[task.status] ?? task.status;
    final priorityLabel = AppConstants.priorityLabels[task.priority] ?? task.priority;

    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: AppColors.tooltipBackground,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Task name
          Text(
            task.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // Status and priority row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '優先度: $priorityLabel',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Date range
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 12,
                color: Colors.white70,
              ),
              const SizedBox(width: 4),
              Text(
                '${GanttConstants.formatFullDate(task.startDate)} - ${GanttConstants.formatFullDate(task.endDate)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Duration
          Text(
            '期間: ${task.durationDays}日',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '進捗',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    '${(task.progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: task.progress,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(statusColor),
                  minHeight: 4,
                ),
              ),
            ],
          ),

          // Assignees (if any)
          if (task.assignees.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 12,
                  color: Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  task.assignees.map((a) => a.name).join(', '),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
