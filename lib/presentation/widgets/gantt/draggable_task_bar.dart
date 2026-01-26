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
                  // Main bar - Compass-demo style clean design
                  Transform.scale(
                    scale: isDragging ? 1.02 : (widget.isSelected ? 1.01 : _scaleAnimation.value),
                    child: Container(
                      width: displayWidth.clamp(GanttConstants.minTaskBarWidth, double.infinity),
                      height: GanttConstants.taskBarHeight,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(GanttConstants.taskBarRadius),
                        border: Border.all(
                          color: isDragging || widget.isSelected
                              ? categoryColor.withOpacity(0.8)
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDragging ? 0.2 : 0.08),
                            blurRadius: isDragging ? 12 : 4,
                            spreadRadius: 0,
                            offset: Offset(0, isDragging ? 3 : 1),
                          ),
                          if (widget.isSelected)
                            BoxShadow(
                              color: categoryColor.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          if (widget.isCriticalPath)
                            BoxShadow(
                              color: AppColors.error.withOpacity(0.25),
                              blurRadius: 6,
                              spreadRadius: 0,
                            ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(GanttConstants.taskBarRadius),
                        child: Stack(
                          children: [
                            // Progress fill - cleaner stripe style
                            if (widget.task.progress > 0)
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: displayWidth * widget.task.progress,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.25),
                                        Colors.white.withOpacity(0.15),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ),
                            // Critical path indicator - subtle top stripe
                            if (widget.isCriticalPath)
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 2,
                                  color: AppColors.error.withOpacity(0.9),
                                ),
                              ),
                            // Task name - larger text for readability
                            if (displayWidth > 50)
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      widget.task.name,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            // Progress percentage - simplified
                            if (displayWidth > 100 && widget.task.progress > 0)
                              Positioned(
                                right: 8,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: Text(
                                    '${(widget.task.progress * 100).round()}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                              ),
                            // Resize handles - cleaner compass-demo style
                            if (_isHovered || isDragging) ...[
                              // Left handle
                              Positioned(
                                left: 0,
                                top: 4,
                                bottom: 4,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.resizeColumn,
                                  child: Container(
                                    width: _handleWidth,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(isDragging ? 0.5 : 0.35),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        bottomLeft: Radius.circular(4),
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 2,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
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
                                top: 4,
                                bottom: 4,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.resizeColumn,
                                  child: Container(
                                    width: _handleWidth,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(isDragging ? 0.5 : 0.35),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(4),
                                        bottomRight: Radius.circular(4),
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 2,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.date_range_rounded,
            size: 14,
            color: Colors.white.withOpacity(0.8),
          ),
          const SizedBox(width: 8),
          Text(
            '$startStr → $endStr',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$duration日',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
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
