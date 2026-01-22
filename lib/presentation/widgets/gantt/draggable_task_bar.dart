import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import 'gantt_constants.dart';

/// Drag mode for task bar manipulation
enum TaskDragMode {
  none,
  move,      // ドラッグで移動（開始・終了日を同時に変更）
  resizeLeft,  // 左端をドラッグ（開始日を変更）
  resizeRight, // 右端をドラッグ（終了日を変更）
}

/// Enhanced draggable task bar with resize handles
class DraggableTaskBar extends StatefulWidget {
  final Task task;
  final double left;
  final double width;
  final double dayWidth;
  final DateTime timelineStartDate;
  final bool isSelected;
  final bool isCriticalPath;
  final int? delayDays;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final Function(DateTime newStart, DateTime newEnd)? onDateChange;
  final Function(DateTime newStart, DateTime newEnd)? onDateChangePreview;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  const DraggableTaskBar({
    super.key,
    required this.task,
    required this.left,
    required this.width,
    required this.dayWidth,
    required this.timelineStartDate,
    this.isSelected = false,
    this.isCriticalPath = false,
    this.delayDays,
    this.onTap,
    this.onDoubleTap,
    this.onDateChange,
    this.onDateChangePreview,
    this.onDragStart,
    this.onDragEnd,
  });

  @override
  State<DraggableTaskBar> createState() => _DraggableTaskBarState();
}

class _DraggableTaskBarState extends State<DraggableTaskBar>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  TaskDragMode _dragMode = TaskDragMode.none;

  // Drag state
  double _dragStartX = 0;
  double _currentLeft = 0;
  double _currentWidth = 0;
  DateTime? _previewStartDate;
  DateTime? _previewEndDate;

  // Animation
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  // Resize handle dimensions
  static const double _handleWidth = 8.0;
  static const double _handleHitArea = 16.0;

  @override
  void initState() {
    super.initState();
    _currentLeft = widget.left;
    _currentWidth = widget.width;

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
  void didUpdateWidget(DraggableTaskBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dragMode == TaskDragMode.none) {
      _currentLeft = widget.left;
      _currentWidth = widget.width;
    }
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

  TaskDragMode _getDragModeFromPosition(double localX) {
    if (localX <= _handleHitArea) {
      return TaskDragMode.resizeLeft;
    } else if (localX >= _currentWidth - _handleHitArea) {
      return TaskDragMode.resizeRight;
    }
    return TaskDragMode.move;
  }

  MouseCursor _getCursorForPosition(double localX) {
    final mode = _getDragModeFromPosition(localX);
    switch (mode) {
      case TaskDragMode.resizeLeft:
      case TaskDragMode.resizeRight:
        return SystemMouseCursors.resizeColumn;
      case TaskDragMode.move:
        return SystemMouseCursors.grab;
      case TaskDragMode.none:
        return SystemMouseCursors.basic;
    }
  }

  void _onDragStart(DragStartDetails details) {
    final localX = details.localPosition.dx;
    _dragMode = _getDragModeFromPosition(localX);
    _dragStartX = details.globalPosition.dx;
    _currentLeft = widget.left;
    _currentWidth = widget.width;

    widget.onDragStart?.call();
    HapticFeedback.lightImpact();

    setState(() {});
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_dragMode == TaskDragMode.none) return;

    final deltaX = details.globalPosition.dx - _dragStartX;
    final deltaDays = (deltaX / widget.dayWidth).round();

    DateTime newStart = widget.task.startDate;
    DateTime newEnd = widget.task.endDate;

    switch (_dragMode) {
      case TaskDragMode.move:
        // 全体を移動
        newStart = widget.task.startDate.add(Duration(days: deltaDays));
        newEnd = widget.task.endDate.add(Duration(days: deltaDays));
        _currentLeft = widget.left + deltaDays * widget.dayWidth;
        break;

      case TaskDragMode.resizeLeft:
        // 開始日を変更（最小1日は維持）
        final maxDeltaDays = widget.task.durationDays - 1;
        final clampedDelta = deltaDays.clamp(-365, maxDeltaDays);
        newStart = widget.task.startDate.add(Duration(days: clampedDelta));
        _currentLeft = widget.left + clampedDelta * widget.dayWidth;
        _currentWidth = widget.width - clampedDelta * widget.dayWidth;
        break;

      case TaskDragMode.resizeRight:
        // 終了日を変更（最小1日は維持）
        final minDays = 1 - widget.task.durationDays;
        final clampedDelta = deltaDays.clamp(minDays, 365);
        newEnd = widget.task.endDate.add(Duration(days: clampedDelta));
        _currentWidth = widget.width + clampedDelta * widget.dayWidth;
        break;

      case TaskDragMode.none:
        return;
    }

    _previewStartDate = newStart;
    _previewEndDate = newEnd;

    widget.onDateChangePreview?.call(newStart, newEnd);
    setState(() {});
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragMode == TaskDragMode.none) return;

    if (_previewStartDate != null && _previewEndDate != null) {
      widget.onDateChange?.call(_previewStartDate!, _previewEndDate!);
      HapticFeedback.mediumImpact();
    }

    _dragMode = TaskDragMode.none;
    _previewStartDate = null;
    _previewEndDate = null;

    widget.onDragEnd?.call();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.getTaskStatusColor(widget.task.status);
    final categoryColor = AppColors.getCategoryColor(widget.task.category);

    // Milestone rendering
    if (widget.task.isMilestone) {
      return _buildMilestone(statusColor);
    }

    final isDragging = _dragMode != TaskDragMode.none;
    final displayLeft = isDragging ? _currentLeft : widget.left;
    final displayWidth = isDragging ? _currentWidth : widget.width;

    return Positioned(
      left: displayLeft,
      top: (GanttConstants.rowHeight - GanttConstants.taskBarHeight) / 2,
      child: MouseRegion(
        onEnter: (_) => _onHoverStart(),
        onExit: (_) => _onHoverEnd(),
        cursor: _isHovered ? _getCursorForPosition(displayWidth / 2) : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          onPanStart: _onDragStart,
          onPanUpdate: _onDragUpdate,
          onPanEnd: _onDragEnd,
          child: AnimatedBuilder(
            animation: _hoverController,
            builder: (context, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main bar
                  Transform.scale(
                    scale: isDragging ? 1.05 : (widget.isSelected ? 1.03 : _scaleAnimation.value),
                    child: Container(
                      width: displayWidth.clamp(GanttConstants.minTaskBarWidth, double.infinity),
                      height: GanttConstants.taskBarHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            categoryColor.withOpacity(0.9),
                            categoryColor.withOpacity(0.75),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(GanttConstants.taskBarRadius),
                        border: Border.all(
                          color: isDragging
                              ? AppColors.primary
                              : (widget.isSelected
                                  ? AppColors.primary
                                  : categoryColor.withOpacity(0.3 + _glowAnimation.value * 0.5)),
                          width: isDragging ? 2.5 : (widget.isSelected ? 2.5 : 1 + _glowAnimation.value),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: categoryColor.withOpacity(isDragging ? 0.4 : 0.15 + _glowAnimation.value * 0.25),
                            blurRadius: isDragging ? 16 : 4 + _glowAnimation.value * 8,
                            spreadRadius: isDragging ? 4 : _glowAnimation.value * 2,
                            offset: Offset(0, isDragging ? 4 : 2 + _glowAnimation.value * 2),
                          ),
                          if (widget.isSelected || isDragging)
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          if (widget.isCriticalPath)
                            BoxShadow(
                              color: AppColors.error.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
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
                                width: displayWidth * widget.task.progress,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(GanttConstants.progressOpacity),
                                ),
                              ),
                            ),
                            // Critical path indicator
                            if (widget.isCriticalPath)
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.error.withOpacity(0.8),
                                        AppColors.error.withOpacity(0.4),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            // Task name
                            if (displayWidth > 60)
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
                            // Progress percentage
                            if (displayWidth > 80)
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
                            // Resize handles (visible on hover)
                            if (_isHovered || isDragging) ...[
                              // Left handle
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.resizeColumn,
                                  child: Container(
                                    width: _handleWidth,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(GanttConstants.taskBarRadius),
                                        bottomLeft: Radius.circular(GanttConstants.taskBarRadius),
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 2,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(1),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Right handle
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.resizeColumn,
                                  child: Container(
                                    width: _handleWidth,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(GanttConstants.taskBarRadius),
                                        bottomRight: Radius.circular(GanttConstants.taskBarRadius),
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 2,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(1),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Drag tooltip showing dates
                  if (isDragging && _previewStartDate != null && _previewEndDate != null)
                    Positioned(
                      top: -32,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildDragTooltip(),
                      ),
                    ),
                  // Delay indicator
                  if (widget.delayDays != null && widget.delayDays! > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: _buildDelayBadge(),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDragTooltip() {
    final startStr = _formatDate(_previewStartDate!);
    final endStr = _formatDate(_previewEndDate!);
    final duration = _previewEndDate!.difference(_previewStartDate!).inDays + 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.tooltipBackground,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today,
            size: 12,
            color: Colors.white70,
          ),
          const SizedBox(width: 6),
          Text(
            '$startStr → $endStr ($duration日)',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDelayBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        '+${widget.delayDays}日',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMilestone(Color color) {
    return Positioned(
      left: widget.left - GanttConstants.milestoneSize / 2,
      top: (GanttConstants.rowHeight - GanttConstants.milestoneSize) / 2,
      child: MouseRegion(
        onEnter: (_) => _onHoverStart(),
        onExit: (_) => _onHoverEnd(),
        child: GestureDetector(
          onTap: widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          child: Transform.rotate(
            angle: 0.785398,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}

/// Ghost bar shown during drag preview
class DragPreviewBar extends StatelessWidget {
  final double left;
  final double width;
  final Color color;

  const DragPreviewBar({
    super.key,
    required this.left,
    required this.width,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: (GanttConstants.rowHeight - GanttConstants.taskBarHeight) / 2,
      child: Container(
        width: width,
        height: GanttConstants.taskBarHeight,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(GanttConstants.taskBarRadius),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 2,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
      ),
    );
  }
}
