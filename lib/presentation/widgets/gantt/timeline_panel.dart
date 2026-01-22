import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../data/models/dependency_model.dart';
import '../../../data/models/phase_model.dart';
import '../../../data/services/dependency_service.dart';
import 'gantt_constants.dart';
import 'task_row.dart';
import 'timeline_header.dart';
import 'dependency_painter.dart';
import 'enhanced_dependency_painter.dart';
import 'dependency_connector.dart';

/// Right panel showing the timeline grid and task bars
class TimelinePanel extends StatefulWidget {
  final List<Task> tasks;
  final DateTime startDate;
  final DateTime endDate;
  final String? selectedTaskId;
  final String? hoveredTaskId;
  final double dayWidth;
  final ScrollController horizontalScrollController;
  final ScrollController verticalScrollController;
  final GanttViewMode viewMode;
  final Function(Task task)? onTaskTap;
  final Function(Task task)? onTaskHover;
  final Function(Task task, DateTime newStart, DateTime newEnd)? onTaskDateChange;

  // New dependency-related properties
  final List<TaskDependency> dependencies;
  final DependencyService? dependencyService;
  final Set<String> criticalPathIds;
  final bool showCriticalPath;
  final Map<String, int>? delayImpactMap;
  final Function(String fromTaskId, String toTaskId, DependencyType type, int lagDays)? onDependencyCreated;
  final bool enableDependencyCreation;

  /// Map of phaseId -> Phase for color coding tasks by phase
  final Map<String, Phase> phaseMap;

  /// Whether to use phase-based coloring for task bars
  final bool usePhaseColors;

  const TimelinePanel({
    super.key,
    required this.tasks,
    required this.startDate,
    required this.endDate,
    this.selectedTaskId,
    this.hoveredTaskId,
    this.dayWidth = GanttConstants.dayWidth,
    required this.horizontalScrollController,
    required this.verticalScrollController,
    this.viewMode = GanttViewMode.day,
    this.onTaskTap,
    this.onTaskHover,
    this.onTaskDateChange,
    this.dependencies = const [],
    this.dependencyService,
    this.criticalPathIds = const {},
    this.showCriticalPath = true,
    this.delayImpactMap,
    this.onDependencyCreated,
    this.enableDependencyCreation = true,
    this.phaseMap = const {},
    this.usePhaseColors = true,
  });

  @override
  State<TimelinePanel> createState() => _TimelinePanelState();
}

class _TimelinePanelState extends State<TimelinePanel> {
  late ScrollController _headerScrollController;
  String? _localHoveredTaskId;

  @override
  void initState() {
    super.initState();
    _headerScrollController = ScrollController();

    // Sync header scroll with main scroll
    widget.horizontalScrollController.addListener(_syncHeaderScroll);
  }

  @override
  void dispose() {
    widget.horizontalScrollController.removeListener(_syncHeaderScroll);
    _headerScrollController.dispose();
    super.dispose();
  }

  void _syncHeaderScroll() {
    if (_headerScrollController.hasClients) {
      _headerScrollController.jumpTo(widget.horizontalScrollController.offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = widget.endDate.difference(widget.startDate).inDays + 1;
    final totalWidth = totalDays * widget.dayWidth;
    final totalHeight = widget.tasks.length * GanttConstants.rowHeight;

    return Column(
      children: [
        // Timeline header
        TimelineHeader(
          startDate: widget.startDate,
          endDate: widget.endDate,
          dayWidth: widget.dayWidth,
          scrollController: _headerScrollController,
          viewMode: widget.viewMode,
        ),
        // Timeline body
        Expanded(
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                // Handle horizontal scroll with shift key or horizontal scroll
                if (event.scrollDelta.dx != 0) {
                  final newOffset = widget.horizontalScrollController.offset +
                      event.scrollDelta.dx;
                  widget.horizontalScrollController.jumpTo(
                    newOffset.clamp(
                      0.0,
                      widget.horizontalScrollController.position.maxScrollExtent,
                    ),
                  );
                }
              }
            },
            child: SingleChildScrollView(
              controller: widget.horizontalScrollController,
              scrollDirection: Axis.horizontal,
              physics: GanttConstants.scrollPhysics,
              child: SizedBox(
                width: totalWidth,
                child: ListView.builder(
                  controller: widget.verticalScrollController,
                  itemCount: widget.tasks.length,
                  itemBuilder: (context, index) {
                    return _buildTimelineRow(index, totalWidth);
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineRow(int index, double totalWidth) {
    final task = widget.tasks[index];
    final isSelected = task.id == widget.selectedTaskId;
    final isHovered = task.id == (_localHoveredTaskId ?? widget.hoveredTaskId);

    // Calculate task bar position
    final startOffset = task.startDate.difference(widget.startDate).inDays;
    final taskWidth = task.isMilestone
        ? GanttConstants.milestoneSize
        : (task.durationDays * widget.dayWidth);
    final leftPosition = startOffset * widget.dayWidth;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _localHoveredTaskId = task.id);
        widget.onTaskHover?.call(task);
      },
      onExit: (_) {
        setState(() => _localHoveredTaskId = null);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: GanttConstants.rowHeight,
        width: totalWidth,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.ganttRowSelected
              : (isHovered ? AppColors.ganttRowHover : AppColors.ganttBackground),
          border: Border(
            bottom: BorderSide(
              color: AppColors.ganttGridLine,
              width: 1,
            ),
            left: isSelected
                ? BorderSide(color: AppColors.primary, width: 3)
                : BorderSide.none,
          ),
          boxShadow: isHovered && !isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Weekend highlighting
            CustomPaint(
              size: Size(totalWidth, GanttConstants.rowHeight),
              painter: WeekendHighlightPainter(
                startDate: widget.startDate,
                endDate: widget.endDate,
                dayWidth: widget.dayWidth,
                height: GanttConstants.rowHeight,
              ),
            ),
            // Grid lines (vertical day separators)
            CustomPaint(
              size: Size(totalWidth, GanttConstants.rowHeight),
              painter: _VerticalGridPainter(
                startDate: widget.startDate,
                endDate: widget.endDate,
                dayWidth: widget.dayWidth,
              ),
            ),
            // Today line for this row
            CustomPaint(
              size: Size(totalWidth, GanttConstants.rowHeight),
              painter: _TodayColumnPainter(
                startDate: widget.startDate,
                dayWidth: widget.dayWidth,
              ),
            ),
            // Task bar with phase color support
            TaskBar(
              task: task,
              left: leftPosition,
              width: taskWidth,
              isSelected: isSelected,
              onTap: () => widget.onTaskTap?.call(task),
              phase: task.phaseId != null ? widget.phaseMap[task.phaseId] : null,
              usePhaseColor: widget.usePhaseColors,
            ),
          ],
        ),
      ),
    );
  }
}

/// Timeline body with all visual layers
class TimelineBody extends StatelessWidget {
  final List<Task> tasks;
  final DateTime startDate;
  final DateTime endDate;
  final String? selectedTaskId;
  final String? hoveredTaskId;
  final double dayWidth;
  final ScrollController horizontalScrollController;
  final ScrollController verticalScrollController;
  final Function(Task task)? onTaskTap;
  final bool showDependencies;
  final bool showTodayLine;
  final bool showWeekends;

  // Dependency-related properties
  final List<TaskDependency> dependencies;
  final Set<String> criticalPathIds;
  final bool showCriticalPath;
  final Map<String, int>? delayImpactMap;

  // Phase-related properties
  final Map<String, Phase> phaseMap;
  final bool usePhaseColors;

  const TimelineBody({
    super.key,
    required this.tasks,
    required this.startDate,
    required this.endDate,
    this.selectedTaskId,
    this.hoveredTaskId,
    this.dayWidth = GanttConstants.dayWidth,
    required this.horizontalScrollController,
    required this.verticalScrollController,
    this.onTaskTap,
    this.showDependencies = true,
    this.showTodayLine = true,
    this.showWeekends = true,
    this.dependencies = const [],
    this.criticalPathIds = const {},
    this.showCriticalPath = true,
    this.delayImpactMap,
    this.phaseMap = const {},
    this.usePhaseColors = true,
  });

  @override
  Widget build(BuildContext context) {
    final totalDays = endDate.difference(startDate).inDays + 1;
    final totalWidth = totalDays * dayWidth;
    final totalHeight = tasks.length * GanttConstants.rowHeight;

    // Build task index map for dependency painter
    final taskIndexMap = <String, int>{};
    for (var i = 0; i < tasks.length; i++) {
      taskIndexMap[tasks[i].id] = i;
    }

    return SingleChildScrollView(
      controller: horizontalScrollController,
      scrollDirection: Axis.horizontal,
      physics: GanttConstants.scrollPhysics,
      child: SizedBox(
        width: totalWidth,
        height: totalHeight,
        child: Stack(
          children: [
            // Layer 1: Weekend highlighting
            if (showWeekends)
              Positioned.fill(
                child: CustomPaint(
                  painter: WeekendHighlightPainter(
                    startDate: startDate,
                    endDate: endDate,
                    dayWidth: dayWidth,
                    height: totalHeight,
                  ),
                ),
              ),

            // Layer 2: Grid lines
            Positioned.fill(
              child: CustomPaint(
                painter: GridPainter(
                  startDate: startDate,
                  endDate: endDate,
                  dayWidth: dayWidth,
                  rowHeight: GanttConstants.rowHeight,
                  rowCount: tasks.length,
                ),
              ),
            ),

            // Layer 3: Task bars (scrollable vertically)
            Positioned.fill(
              child: ListView.builder(
                controller: verticalScrollController,
                physics: GanttConstants.scrollPhysics,
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final startOffset = task.startDate.difference(startDate).inDays;
                  final taskWidth = task.isMilestone
                      ? GanttConstants.milestoneSize
                      : (task.durationDays * dayWidth);
                  final leftPosition = startOffset * dayWidth;

                  return SizedBox(
                    height: GanttConstants.rowHeight,
                    child: Stack(
                      children: [
                        TaskBar(
                          task: task,
                          left: leftPosition,
                          width: taskWidth,
                          isSelected: task.id == selectedTaskId,
                          onTap: () => onTaskTap?.call(task),
                          phase: task.phaseId != null ? phaseMap[task.phaseId] : null,
                          usePhaseColor: usePhaseColors,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Layer 4: Critical path highlight (if enabled)
            if (showCriticalPath && criticalPathIds.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: CriticalPathOverlay(
                      tasks: tasks,
                      criticalPathIds: criticalPathIds,
                      taskIndexMap: taskIndexMap,
                      startDate: startDate,
                      dayWidth: dayWidth,
                      rowHeight: GanttConstants.rowHeight,
                    ),
                  ),
                ),
              ),

            // Layer 5: Dependency arrows (enhanced)
            if (showDependencies)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: dependencies.isNotEmpty
                        ? EnhancedDependencyPainter(
                            tasks: tasks,
                            dependencies: dependencies,
                            taskIndexMap: taskIndexMap,
                            startDate: startDate,
                            dayWidth: dayWidth,
                            rowHeight: GanttConstants.rowHeight,
                            selectedTaskId: selectedTaskId,
                            hoveredTaskId: hoveredTaskId,
                            criticalPathIds: criticalPathIds,
                            delayImpactedTaskIds: delayImpactMap?.keys.toSet(),
                            showTypeLabels: true,
                          )
                        : DependencyPainter(
                            tasks: tasks,
                            taskIndexMap: taskIndexMap,
                            startDate: startDate,
                            dayWidth: dayWidth,
                            rowHeight: GanttConstants.rowHeight,
                            selectedTaskId: selectedTaskId,
                            hoveredTaskId: hoveredTaskId,
                          ),
                  ),
                ),
              ),

            // Layer 6: Delay impact overlay
            if (delayImpactMap != null && delayImpactMap!.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: DelayImpactOverlay(
                      tasks: tasks,
                      taskDelayMap: delayImpactMap!,
                      taskIndexMap: taskIndexMap,
                      startDate: startDate,
                      dayWidth: dayWidth,
                      rowHeight: GanttConstants.rowHeight,
                    ),
                  ),
                ),
              ),

            // Layer 5: Today line
            if (showTodayLine)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: TodayLinePainter(
                      startDate: startDate,
                      dayWidth: dayWidth,
                      height: totalHeight,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Vertical grid painter for individual rows
class _VerticalGridPainter extends CustomPainter {
  final DateTime startDate;
  final DateTime endDate;
  final double dayWidth;

  _VerticalGridPainter({
    required this.startDate,
    required this.endDate,
    required this.dayWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ganttGridLine.withOpacity(0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final totalDays = endDate.difference(startDate).inDays + 1;

    for (var i = 0; i <= totalDays; i++) {
      final x = i * dayWidth;
      final date = startDate.add(Duration(days: i));

      // Thicker line for month start
      if (date.day == 1) {
        paint.color = AppColors.ganttGridLine;
        paint.strokeWidth = 1;
      } else {
        paint.color = AppColors.ganttGridLine.withOpacity(0.3);
        paint.strokeWidth = 0.5;
      }

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalGridPainter oldDelegate) {
    return startDate != oldDelegate.startDate ||
        endDate != oldDelegate.endDate ||
        dayWidth != oldDelegate.dayWidth;
  }
}

/// Today column highlight painter
class _TodayColumnPainter extends CustomPainter {
  final DateTime startDate;
  final double dayWidth;

  _TodayColumnPainter({
    required this.startDate,
    required this.dayWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (today.isBefore(startDate)) return;

    final daysDiff = today.difference(startDate).inDays;
    final x = daysDiff * dayWidth;

    // Draw today column highlight
    final rect = Rect.fromLTWH(x, 0, dayWidth, size.height);
    final paint = Paint()
      ..color = AppColors.ganttToday.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, paint);

    // Draw today line
    final linePaint = Paint()
      ..color = AppColors.ganttTodayLine
      ..strokeWidth = GanttConstants.todayLineWidth
      ..style = PaintingStyle.stroke;

    final lineX = x + dayWidth / 2;
    canvas.drawLine(
      Offset(lineX, 0),
      Offset(lineX, size.height),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TodayColumnPainter oldDelegate) {
    return startDate != oldDelegate.startDate ||
        dayWidth != oldDelegate.dayWidth;
  }
}

/// Timeline overlay for showing current date tooltip
class TimelineDateOverlay extends StatelessWidget {
  final DateTime date;
  final double left;
  final double top;

  const TimelineDateOverlay({
    super.key,
    required this.date,
    required this.left,
    required this.top,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.tooltipBackground,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          GanttConstants.formatFullDate(date),
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Zoom control for timeline
class TimelineZoomControl extends StatelessWidget {
  final double currentZoom;
  final Function(double newZoom) onZoomChanged;
  final GanttViewMode currentMode;
  final Function(GanttViewMode mode) onModeChanged;

  const TimelineZoomControl({
    super.key,
    required this.currentZoom,
    required this.onZoomChanged,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // View mode selector
          ...GanttViewMode.values.map((mode) => _buildModeButton(mode)),
          Container(
            width: 1,
            height: 24,
            color: AppColors.divider,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          // Zoom controls
          _buildZoomButton(
            icon: Icons.remove,
            onPressed: currentZoom > GanttConstants.minZoom
                ? () => onZoomChanged(currentZoom - GanttConstants.zoomStep)
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${(currentZoom * 100).round()}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _buildZoomButton(
            icon: Icons.add,
            onPressed: currentZoom < GanttConstants.maxZoom
                ? () => onZoomChanged(currentZoom + GanttConstants.zoomStep)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(GanttViewMode mode) {
    final isSelected = mode == currentMode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => onModeChanged(mode),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            mode.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomButton({
    required IconData icon,
    VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 18,
          color: onPressed != null
              ? AppColors.iconDefault
              : AppColors.textTertiary,
        ),
      ),
    );
  }
}
