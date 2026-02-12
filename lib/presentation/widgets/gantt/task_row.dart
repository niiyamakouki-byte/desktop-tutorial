import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  bool _isTaskNameExpanded = false; // Add this line
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
    // Calculate if text exceeds max lines for 'more' button visibility
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.task.name,
        style: TextStyle(
          fontSize: 13,
          fontWeight: widget.task.level == 0 ? FontWeight.w600 : FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width * 0.4); // Adjust maxWidth as needed

    final showExpandCollapseButton = textPainter.didExceedMaxLines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1行目: タスク名
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (showExpandCollapseButton) {
                    setState(() {
                      _isTaskNameExpanded = !_isTaskNameExpanded;
                    });
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.task.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: widget.task.level == 0
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: _isTaskNameExpanded ? null : 1,
                      overflow: _isTaskNameExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                    if (textPainter.didExceedMaxLines) // Use local variable here
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          _isTaskNameExpanded ? '▲ 閉じる' : '▼ もっと見る',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
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

  /// 遅延/待ちバッジ（⚠ +Xd形式で視覚強調）
  Widget _buildDelayBadge(DelayStatus status) {
    String text;
    bool isUrgent = false;

    if (status == DelayStatus.overdue) {
      final days = widget.task.daysOverdue;
      text = '+${days}d';
      isUrgent = days >= 3; // 3日以上遅延は緊急扱い
    } else if (status == DelayStatus.blocked) {
      text = widget.task.blockingReason?.displayName ?? '待ち';
    } else if (status == DelayStatus.atRisk) {
      final days = widget.task.daysRemaining;
      text = '残${days}d';
    } else {
      text = status.displayName;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: isUrgent ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: status.color.withValues(alpha: isUrgent ? 0.7 : 0.4),
          width: isUrgent ? 1.5 : 1,
        ),
        boxShadow: isUrgent
            ? [
                BoxShadow(
                  color: status.color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ⚠️ アイコン（遅延時は警告マーク）
          if (status == DelayStatus.overdue)
            const Text(
              '⚠',
              style: TextStyle(fontSize: 10),
            )
          else
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
              fontWeight: isUrgent ? FontWeight.w700 : FontWeight.w600,
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

/// Enum to track which resize handle is being dragged
enum ResizeHandle { none, start, end }

/// Callback signature for dependency drag events
typedef OnDependencyDragStart = void Function(Task task, Offset globalPosition);
typedef OnDependencyDragUpdate = void Function(Offset globalPosition);
typedef OnDependencyDragEnd = void Function(Task? targetTask);

/// Task bar component for the timeline panel
class TaskBar extends StatefulWidget {
  final Task task;
  final double left;
  final double width;
  final bool isSelected;
  final VoidCallback? onTap;
  final Function(DragUpdateDetails)? onDragUpdate;
  final Function(DragEndDetails)? onDragEnd;

  /// Callback when start date is being resized (left handle)
  /// The double parameter represents the delta in pixels
  final Function(double delta)? onResizeStartUpdate;
  final VoidCallback? onResizeStartEnd;

  /// Callback when end date is being resized (right handle)
  /// The double parameter represents the delta in pixels
  final Function(double delta)? onResizeEndUpdate;
  final VoidCallback? onResizeEndEnd;

  /// Phase information for color coding (if available)
  final Phase? phase;

  /// Whether to use phase-based coloring
  final bool usePhaseColor;

  // === Dependency drag handle parameters ===

  /// Whether to show the dependency connector handle on hover
  final bool showDependencyHandle;

  /// Callback when dependency drag starts from this task's output connector
  final OnDependencyDragStart? onDependencyDragStart;

  /// Callback when dependency drag updates
  final OnDependencyDragUpdate? onDependencyDragUpdate;

  /// Callback when dependency drag ends
  final OnDependencyDragEnd? onDependencyDragEnd;

  /// Whether this task is a valid drop target for dependency creation
  final bool isValidDropTarget;

  /// Whether a dependency drag is active from another task
  final bool isDependencyDragActive;

  const TaskBar({
    super.key,
    required this.task,
    required this.left,
    required this.width,
    this.isSelected = false,
    this.onTap,
    this.onDragUpdate,
    this.onDragEnd,
    this.onResizeStartUpdate,
    this.onResizeStartEnd,
    this.onResizeEndUpdate,
    this.onResizeEndEnd,
    this.phase,
    this.usePhaseColor = true,
    this.showDependencyHandle = true,
    this.onDependencyDragStart,
    this.onDependencyDragUpdate,
    this.onDependencyDragEnd,
    this.isValidDropTarget = false,
    this.isDependencyDragActive = false,
  });

  @override
  State<TaskBar> createState() => _TaskBarState();
}

class _TaskBarState extends State<TaskBar> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isStartHandleHovered = false;
  bool _isEndHandleHovered = false;
  bool _isDependencyHandleHovered = false;
  bool _isDependencyDragging = false;
  ResizeHandle _activeResize = ResizeHandle.none;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  /// Width of the resize handle hit area
  static const double _handleWidth = 12.0;
  /// Visual width of the handle indicator
  static const double _handleIndicatorWidth = 4.0;
  /// Size of the dependency connector handle
  static const double _dependencyHandleSize = 14.0;

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
    setState(() {
      _isHovered = false;
      _isStartHandleHovered = false;
      _isEndHandleHovered = false;
    });
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

  /// Build a resize handle widget
  Widget _buildResizeHandle({
    required bool isStart,
    required bool isHovered,
    required Color barColor,
  }) {
    final isActive = (isStart && _activeResize == ResizeHandle.start) ||
        (!isStart && _activeResize == ResizeHandle.end);

    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) {
        setState(() {
          if (isStart) {
            _isStartHandleHovered = true;
          } else {
            _isEndHandleHovered = true;
          }
        });
      },
      onExit: (_) {
        setState(() {
          if (isStart) {
            _isStartHandleHovered = false;
          } else {
            _isEndHandleHovered = false;
          }
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          HapticFeedback.lightImpact();
          setState(() {
            _activeResize = isStart ? ResizeHandle.start : ResizeHandle.end;
          });
        },
        onHorizontalDragUpdate: (details) {
          if (isStart) {
            widget.onResizeStartUpdate?.call(details.delta.dx);
          } else {
            widget.onResizeEndUpdate?.call(details.delta.dx);
          }
        },
        onHorizontalDragEnd: (_) {
          HapticFeedback.mediumImpact();
          setState(() => _activeResize = ResizeHandle.none);
          if (isStart) {
            widget.onResizeStartEnd?.call();
          } else {
            widget.onResizeEndEnd?.call();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: _handleWidth,
          height: GanttConstants.taskBarHeight,
          alignment: isStart ? Alignment.centerLeft : Alignment.centerRight,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: _handleIndicatorWidth,
            height: isHovered || isActive
                ? GanttConstants.taskBarHeight - 4
                : GanttConstants.taskBarHeight - 12,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : (isHovered
                      ? Colors.white.withOpacity(0.9)
                      : Colors.white.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(2),
              boxShadow: isActive || isHovered
                  ? [
                      BoxShadow(
                        color: barColor.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  /// Build the dependency connector handle (small circle at right edge)
  Widget _buildDependencyHandle(Color barColor) {
    final isActive = _isDependencyDragging;
    final showHandle = _isHovered || isActive || widget.isDependencyDragActive;

    // Pulse animation for valid drop target
    final isPulsingTarget = widget.isValidDropTarget;

    return Positioned(
      right: -_dependencyHandleSize / 2 - 2,
      top: (GanttConstants.taskBarHeight - _dependencyHandleSize) / 2,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        onEnter: (_) => setState(() => _isDependencyHandleHovered = true),
        onExit: (_) => setState(() => _isDependencyHandleHovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            setState(() => _isDependencyDragging = true);
            widget.onDependencyDragStart?.call(widget.task, details.globalPosition);
          },
          onPanUpdate: (details) {
            widget.onDependencyDragUpdate?.call(details.globalPosition);
          },
          onPanEnd: (details) {
            setState(() => _isDependencyDragging = false);
            widget.onDependencyDragEnd?.call(null);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: _dependencyHandleSize * (showHandle ? 1.2 : 0.8),
            height: _dependencyHandleSize * (showHandle ? 1.2 : 0.8),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.industrialOrange
                  : (_isDependencyHandleHovered
                      ? AppColors.industrialOrange.withOpacity(0.9)
                      : barColor.withOpacity(showHandle ? 0.8 : 0.5)),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: showHandle ? 2.0 : 1.0,
              ),
              boxShadow: showHandle
                  ? [
                      BoxShadow(
                        color: (isActive ? AppColors.industrialOrange : barColor)
                            .withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: showHandle
                ? const Center(
                    child: Icon(
                      Icons.arrow_forward,
                      size: 10,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  /// Build the input connector indicator (left side, for drop target)
  Widget _buildInputConnectorIndicator() {
    if (!widget.isValidDropTarget) return const SizedBox.shrink();

    return Positioned(
      left: -_dependencyHandleSize / 2 - 2,
      top: (GanttConstants.taskBarHeight - _dependencyHandleSize) / 2,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.3),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              width: _dependencyHandleSize,
              height: _dependencyHandleSize,
              decoration: BoxDecoration(
                color: AppColors.constructionGreen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.constructionGreen.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
        onEnd: () {
          // Restart animation
          if (mounted && widget.isValidDropTarget) {
            setState(() {});
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.getTaskStatusColor(widget.task.status);
    final barColor = _getTaskBarColor();
    final isResizing = _activeResize != ResizeHandle.none;

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
          onPanUpdate: isResizing ? null : widget.onDragUpdate,
          onPanEnd: isResizing ? null : widget.onDragEnd,
          child: AnimatedBuilder(
            animation: _hoverController,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isSelected ? 1.03 : _scaleAnimation.value,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: widget.width.clamp(GanttConstants.minTaskBarWidth, double.infinity),
                  height: GanttConstants.taskBarHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        barColor.withOpacity(isResizing ? 1.0 : 0.9),
                        barColor.withOpacity(isResizing ? 0.85 : 0.75),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(GanttConstants.taskBarRadius),
                    border: Border.all(
                      color: isResizing
                          ? Colors.white
                          : (widget.isSelected
                              ? AppColors.primary
                              : barColor.withOpacity(0.3 + _glowAnimation.value * 0.5)),
                      width: isResizing ? 2.0 : (widget.isSelected ? 2.5 : 1 + _glowAnimation.value),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: barColor.withOpacity(isResizing ? 0.5 : 0.15 + _glowAnimation.value * 0.25),
                        blurRadius: isResizing ? 12 : 4 + _glowAnimation.value * 8,
                        spreadRadius: isResizing ? 3 : _glowAnimation.value * 2,
                        offset: Offset(0, isResizing ? 4 : 2 + _glowAnimation.value * 2),
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
                      clipBehavior: Clip.none,
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
                              padding: const EdgeInsets.symmetric(horizontal: 14),
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
                            right: 14,
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
                        // 遅延インジケーター（⚠ +Xd形式）
                        if (widget.task.delayStatus == DelayStatus.overdue)
                          Positioned(
                            right: widget.width > 80 ? 48 : 4,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.error.withOpacity(0.4),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('⚠', style: TextStyle(fontSize: 9)),
                                  const SizedBox(width: 2),
                                  Text(
                                    '+${widget.task.daysOverdue}d',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Left resize handle (start date)
                        if (_isHovered || isResizing)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: _buildResizeHandle(
                              isStart: true,
                              isHovered: _isStartHandleHovered,
                              barColor: barColor,
                            ),
                          ),
                        // Right resize handle (end date)
                        if (_isHovered || isResizing)
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: _buildResizeHandle(
                              isStart: false,
                              isHovered: _isEndHandleHovered,
                              barColor: barColor,
                            ),
                          ),
                        // Dependency output connector (right side, for creating dependencies)
                        if (widget.showDependencyHandle && (_isHovered || _isDependencyDragging || widget.isDependencyDragActive))
                          _buildDependencyHandle(barColor),
                        // Dependency input connector indicator (left side, shown when valid drop target)
                        if (widget.isValidDropTarget)
                          _buildInputConnectorIndicator(),
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
