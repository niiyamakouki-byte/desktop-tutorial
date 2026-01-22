import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import '../../../data/models/phase_model.dart';
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

  /// Phase information for display
  final Phase? phase;

  const TaskRow({
    super.key,
    required this.task,
    this.hasChildren = false,
    this.isSelected = false,
    this.onTap,
    this.onDoubleTap,
    this.onExpandToggle,
    this.width = GanttConstants.taskListWidth,
    this.phase,
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
    final delayStatus = widget.task.delayStatus;
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
              // 左ステータスレール（遅延状態で色が変わる）
              _buildStatusRail(delayStatus),

              // Indentation and expand button
              SizedBox(width: GanttConstants.cellPadding + indent),
              _buildExpandButton(),
              const SizedBox(width: 4),

              // Task name and info
              Expanded(
                child: _buildTaskInfoEnhanced(categoryColor, delayStatus),
              ),

              // 添付アイコン
              _buildAttachmentIcons(),
              const SizedBox(width: 8),

              // Progress indicator
              _buildProgressBadge(),
              const SizedBox(width: GanttConstants.cellPadding),
            ],
          ),
        ),
      ),
    );
  }

  /// 左ステータスレール（太め、遅延状態で色変化）
  Widget _buildStatusRail(DelayStatus status) {
    return Container(
      width: 4,
      height: double.infinity,
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(2),
          bottomRight: Radius.circular(2),
        ),
      ),
    );
  }

  /// 強化版タスク情報（期限・担当者を含む）
  Widget _buildTaskInfoEnhanced(Color categoryColor, DelayStatus delayStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1行目: タスク名
        Row(
          children: [
            Expanded(
              child: Text(
                widget.task.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.task.level == 0
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 2行目: ステータス・期限・担当者
        Row(
          children: [
            // 遅延/待ちバッジ
            if (delayStatus != DelayStatus.onTrack) ...[
              _buildDelayBadge(delayStatus),
              const SizedBox(width: 6),
            ],
            // 期限表示
            _buildDeadlineChip(),
            const SizedBox(width: 6),
            // 担当者チップ
            if (widget.task.assigneeDisplayText.isNotEmpty) ...[
              _buildAssigneeChip(),
              const SizedBox(width: 6),
            ],
            // フェーズバッジ
            if (widget.phase != null) ...[
              _buildPhaseBadge(widget.phase!),
            ],
          ],
        ),
      ],
    );
  }

  /// 遅延/待ちバッジ
  Widget _buildDelayBadge(DelayStatus status) {
    String text;
    if (status == DelayStatus.overdue) {
      final days = widget.task.daysOverdue;
      text = '+$days日';
    } else if (status == DelayStatus.blocked) {
      text = widget.task.blockingReason?.displayName ?? '待ち';
    } else {
      text = status.displayName;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: status.color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: 10,
            color: status.color,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: status.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 期限チップ
  Widget _buildDeadlineChip() {
    final deadlineText = widget.task.deadlineText;
    final isOverdue = widget.task.isOverdue;
    final isToday = widget.task.isToday;

    Color textColor;
    if (isOverdue) {
      textColor = AppColors.error;
    } else if (isToday) {
      textColor = AppColors.warning;
    } else {
      textColor = AppColors.textSecondary;
    }

    return Text(
      '期日 ${widget.task.endDate.month}/${widget.task.endDate.day} ($deadlineText)',
      style: TextStyle(
        fontSize: 10,
        color: textColor,
        fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  /// 担当者チップ
  Widget _buildAssigneeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person_outline,
            size: 10,
            color: AppColors.primary,
          ),
          const SizedBox(width: 2),
          Text(
            widget.task.assigneeDisplayText,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 添付アイコン群
  Widget _buildAttachmentIcons() {
    final status = widget.task.attachmentStatus;
    if (!status.hasAny) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 図面アイコン
        if (status.hasDrawing)
          _buildAttachmentIcon(
            Icons.architecture,
            status.isLatestDrawing ? AppColors.success : AppColors.textTertiary,
            status.isLatestDrawing ? '最新' : null,
          ),
        // 写真アイコン
        if (status.photoCount > 0)
          _buildAttachmentIcon(
            Icons.photo_camera,
            status.todayPhotoCount > 0 ? AppColors.primary : AppColors.textTertiary,
            status.todayPhotoCount > 0 ? '${status.todayPhotoCount}' : null,
          ),
        // コメントアイコン
        if (status.unreadComments > 0)
          _buildAttachmentIcon(
            Icons.chat_bubble_outline,
            status.hasActionRequired ? AppColors.error : AppColors.warning,
            '${status.unreadComments}',
          ),
      ],
    );
  }

  Widget _buildAttachmentIcon(IconData icon, Color color, String? badge) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: 14, color: color),
          if (badge != null)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
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
            // Phase badge (if task has a phase)
            if (widget.phase != null) ...[
              _buildPhaseBadge(widget.phase!),
              const SizedBox(width: 6),
            ],
            // Category badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.15),
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
            Flexible(
              child: Text(
                _formatDateRange(),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhaseBadge(Phase phase) {
    final phaseColor = PhaseColors.getColorForOrder(phase.order);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: phaseColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: phaseColor.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: phaseColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            phase.shortName,
            style: TextStyle(
              fontSize: 9,
              color: phaseColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
        color: badgeColor.withOpacity(0.12),
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

  /// Phase information for color coding (if available)
  final Phase? phase;

  /// Whether to use phase-based coloring
  final bool usePhaseColor;

  const TaskBar({
    super.key,
    required this.task,
    required this.left,
    required this.width,
    this.isSelected = false,
    this.onTap,
    this.onDragUpdate,
    this.onDragEnd,
    this.phase,
    this.usePhaseColor = true,
  });

  @override
  State<TaskBar> createState() => _TaskBarState();
}

class _TaskBarState extends State<TaskBar> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHoverStart() {
    setState(() => _isHovered = true);
    _hoverController.forward();
  }

  void _onHoverEnd() {
    setState(() => _isHovered = false);
    _hoverController.reverse();
  }

  /// Get the display color for this task bar
  Color _getTaskBarColor() {
    // Use phase color if phase is provided and usePhaseColor is enabled
    if (widget.usePhaseColor && widget.phase != null) {
      return PhaseColors.getColorForOrder(widget.phase!.order);
    }
    // Fallback to category color
    return AppColors.getCategoryColor(widget.task.category);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.getTaskStatusColor(widget.task.status);
    final barColor = _getTaskBarColor();

    // For milestones, render a diamond
    if (widget.task.isMilestone) {
      return _buildMilestone(statusColor);
    }

    return Positioned(
      left: widget.left,
      top: (GanttConstants.rowHeight - GanttConstants.taskBarHeight) / 2,
      child: MouseRegion(
        onEnter: (_) => _onHoverStart(),
        onExit: (_) => _onHoverEnd(),
        child: GestureDetector(
          onTap: widget.onTap,
          onPanUpdate: widget.onDragUpdate,
          onPanEnd: widget.onDragEnd,
          child: AnimatedBuilder(
            animation: _hoverController,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isSelected ? 1.03 : _scaleAnimation.value,
                child: Container(
                  width: widget.width.clamp(GanttConstants.minTaskBarWidth, double.infinity),
                  height: GanttConstants.taskBarHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        barColor.withOpacity(0.9),
                        barColor.withOpacity(0.75),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(GanttConstants.taskBarRadius),
                    border: Border.all(
                      color: widget.isSelected
                          ? AppColors.primary
                          : barColor.withOpacity(0.3 + _glowAnimation.value * 0.5),
                      width: widget.isSelected ? 2.5 : 1 + _glowAnimation.value,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: barColor.withOpacity(0.15 + _glowAnimation.value * 0.25),
                        blurRadius: 4 + _glowAnimation.value * 8,
                        spreadRadius: _glowAnimation.value * 2,
                        offset: Offset(0, 2 + _glowAnimation.value * 2),
                      ),
                      if (widget.isSelected)
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                    ],
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
                        color: Colors.white.withOpacity(GanttConstants.progressOpacity),
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '${(widget.task.progress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
                          color: color.withOpacity(0.4),
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
                  color: statusColor.withOpacity(0.2),
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
                  color: Colors.white.withOpacity(0.7),
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
                  color: Colors.white.withOpacity(0.7),
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
              color: Colors.white.withOpacity(0.7),
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
                      color: Colors.white.withOpacity(0.7),
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
                    color: Colors.white.withOpacity(0.7),
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

/// Phase legend widget to display phase color coding
class PhaseLegend extends StatelessWidget {
  final List<Phase> phases;
  final bool compact;

  const PhaseLegend({
    super.key,
    required this.phases,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (phases.isEmpty) return const SizedBox.shrink();

    if (compact) {
      return _buildCompactLegend();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'フェーズ凡例',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: phases.map((phase) => _buildLegendItem(phase)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLegend() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: phases.map((phase) => _buildCompactItem(phase)).toList(),
    );
  }

  Widget _buildLegendItem(Phase phase) {
    final color = PhaseColors.getColorForOrder(phase.order);
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
          phase.name,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactItem(Phase phase) {
    final color = PhaseColors.getColorForOrder(phase.order);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            phase.shortName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
