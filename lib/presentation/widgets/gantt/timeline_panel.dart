import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../data/models/dependency_model.dart';
import '../../../data/models/phase_model.dart';
import '../../../data/services/dependency_service.dart';
import '../../../data/services/drag_cascade_preview_service.dart';
import 'gantt_constants.dart';
import 'task_row.dart';
import 'timeline_header.dart';
import 'dependency_painter.dart';
import 'enhanced_dependency_painter.dart';
import 'dependency_connector.dart';
import 'dependency_dialog.dart';
import 'cascade_preview_painter.dart';

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

  // Dependency drag state
  late DependencyDragController _dependencyDragController;
  DependencyDragState? _dependencyDragState;
  String? _dependencyDragSourceId;

  // Resize state tracking
  String? _resizingTaskId;
  double _resizeAccumulatedDelta = 0.0;
  DateTime? _resizeOriginalStart;
  DateTime? _resizeOriginalEnd;
  bool _isResizingStart = false; // true = resizing start date, false = resizing end date

  // Drag state tracking (for task move with cascade preview)
  String? _draggingTaskId;
  double _dragAccumulatedDelta = 0.0;
  DateTime? _dragOriginalStart;
  DateTime? _dragOriginalEnd;
  DragCascadePreviewResult? _cascadePreview;
  final DragCascadePreviewService _cascadePreviewService = DragCascadePreviewService();

  @override
  void initState() {
    super.initState();
    _headerScrollController = ScrollController();

    // Initialize dependency drag controller
    _dependencyDragController = DependencyDragController();
    _dependencyDragController.addListener(_onDependencyDragChanged);

    // Initialize cascade preview service
    _cascadePreviewService.initialize(
      tasks: widget.tasks,
      dependencies: widget.dependencies,
    );

    // Sync header scroll with main scroll
    widget.horizontalScrollController.addListener(_syncHeaderScroll);
  }
  
  @override
  void didUpdateWidget(TimelinePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update cascade preview service when tasks or dependencies change
    if (widget.tasks != oldWidget.tasks) {
      _cascadePreviewService.updateTasks(widget.tasks);
    }
    if (widget.dependencies != oldWidget.dependencies) {
      _cascadePreviewService.updateDependencies(widget.dependencies);
    }
  }

  @override
  void dispose() {
    widget.horizontalScrollController.removeListener(_syncHeaderScroll);
    _headerScrollController.dispose();
    _dependencyDragController.removeListener(_onDependencyDragChanged);
    _dependencyDragController.dispose();
    super.dispose();
  }

  void _onDependencyDragChanged() {
    setState(() {
      _dependencyDragState = _dependencyDragController.dragState;
      _dependencyDragSourceId = _dependencyDragController.sourceTaskId;
    });
  }

  /// Calculate valid target task IDs for dependency creation
  Set<String> _computeValidTargets(String sourceTaskId) {
    final validTargets = <String>{};
    for (final task in widget.tasks) {
      if (task.id == sourceTaskId) continue;
      // Check for cycle using dependency service if available
      if (widget.dependencyService != null) {
        if (!widget.dependencyService!.wouldCreateCycle(sourceTaskId, task.id)) {
          validTargets.add(task.id);
        }
      } else {
        // Fallback: simple check
        if (!task.dependsOn.contains(sourceTaskId)) {
          validTargets.add(task.id);
        }
      }
    }
    return validTargets;
  }

  /// Handle dependency drag start from TaskBar
  void _handleDependencyDragStart(Task task, Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(globalPosition);
    final validTargets = _computeValidTargets(task.id);

    _dependencyDragController.startDrag(
      fromTaskId: task.id,
      fromConnector: ConnectorType.output,
      startPosition: localPosition,
      validTargetIds: validTargets,
    );
  }

  /// Handle dependency drag update
  void _handleDependencyDragUpdate(Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox;
    var localPosition = renderBox.globalToLocal(globalPosition);

    // Find hovered task and implement snapping
    String? hoveredTaskId;
    Offset? snapPosition;
    final taskIndexMap = _buildTaskIndexMap();
    const snapDistance = 30.0; // Distance at which snapping activates

    for (final task in widget.tasks) {
      final index = taskIndexMap[task.id];
      if (index == null) continue;
      if (task.id == _dependencyDragController.sourceTaskId) continue;
      if (!_dependencyDragController.isValidTarget(task.id)) continue;

      final taskBounds = _getTaskBounds(task, index);

      // Calculate the input connector position (left side center of task bar)
      final inputConnectorX = taskBounds.left;
      final inputConnectorY = taskBounds.top + taskBounds.height / 2;
      final inputConnectorPos = Offset(inputConnectorX, inputConnectorY);

      // Check distance to input connector for snapping
      final distance = (localPosition - inputConnectorPos).distance;

      if (distance < snapDistance) {
        hoveredTaskId = task.id;
        snapPosition = inputConnectorPos;
        break;
      }

      // Also check if cursor is within task bounds (wider hit area)
      if (taskBounds.inflate(10).contains(localPosition)) {
        hoveredTaskId = task.id;
        snapPosition = inputConnectorPos;
        break;
      }
    }

    // Use snap position if available, otherwise use cursor position
    final finalPosition = snapPosition ?? localPosition;

    _dependencyDragController.updateDrag(finalPosition, hoveredTaskId: hoveredTaskId);
  }

  /// Handle dependency drag end
  Future<void> _handleDependencyDragEnd(Task? targetTask) async {
    final hoveredTaskId = _dependencyDragController.hoveredTaskId;
    final sourceTaskId = _dependencyDragController.sourceTaskId;

    if (hoveredTaskId != null && sourceTaskId != null) {
      final fromTask = widget.tasks.firstWhere(
        (t) => t.id == sourceTaskId,
        orElse: () => widget.tasks.first,
      );
      final toTask = widget.tasks.firstWhere(
        (t) => t.id == hoveredTaskId,
        orElse: () => widget.tasks.first,
      );

      _dependencyDragController.endDrag();

      // Show dependency type selection dialog
      final result = await DependencyDialog.show(
        context: context,
        fromTask: fromTask,
        toTask: toTask,
      );

      if (result != null) {
        widget.onDependencyCreated?.call(
          sourceTaskId,
          hoveredTaskId,
          result.type,
          result.lagDays,
        );
      }
    } else {
      _dependencyDragController.endDrag();
    }
  }

  Map<String, int> _buildTaskIndexMap() {
    final map = <String, int>{};
    for (var i = 0; i < widget.tasks.length; i++) {
      map[widget.tasks[i].id] = i;
    }
    return map;
  }

  Rect _getTaskBounds(Task task, int index) {
    final startOffset = task.startDate.difference(widget.startDate).inDays;
    final taskWidth = task.isMilestone
        ? GanttConstants.milestoneSize
        : task.durationDays * widget.dayWidth;
    final left = startOffset * widget.dayWidth;
    final top = index * GanttConstants.rowHeight;
    return Rect.fromLTWH(left, top, taskWidth, GanttConstants.rowHeight);
  }

  /// Build a map of task ID to bounds for the dependency drag painter
  Map<String, Rect> _buildTaskBoundsMap(Map<String, int> taskIndexMap) {
    final bounds = <String, Rect>{};
    for (final task in widget.tasks) {
      final index = taskIndexMap[task.id];
      if (index != null) {
        bounds[task.id] = _getTaskBounds(task, index);
      }
    }
    return bounds;
  }

  void _syncHeaderScroll() {
    if (_headerScrollController.hasClients) {
      _headerScrollController.jumpTo(widget.horizontalScrollController.offset);
    }
  }

  /// Start tracking resize for a task
  void _startResize(Task task, bool isStart) {
    setState(() {
      _resizingTaskId = task.id;
      _resizeAccumulatedDelta = 0.0;
      _resizeOriginalStart = task.startDate;
      _resizeOriginalEnd = task.endDate;
      _isResizingStart = isStart;
    });
  }

  /// Update resize with accumulated delta (snaps to days)
  void _updateResize(Task task, double delta, bool isStart) {
    if (_resizingTaskId != task.id) {
      _startResize(task, isStart);
    }

    _resizeAccumulatedDelta += delta;

    // Calculate number of days to adjust (snap to day boundaries)
    final daysDelta = (_resizeAccumulatedDelta / widget.dayWidth).round();

    if (daysDelta != 0 && _resizeOriginalStart != null && _resizeOriginalEnd != null) {
      DateTime newStart = _resizeOriginalStart!;
      DateTime newEnd = _resizeOriginalEnd!;

      if (isStart) {
        // Resizing start date (left handle)
        newStart = _resizeOriginalStart!.add(Duration(days: daysDelta));
        // Ensure start doesn't go past end
        if (newStart.isAfter(newEnd.subtract(const Duration(days: 1)))) {
          newStart = newEnd.subtract(const Duration(days: 1));
        }
      } else {
        // Resizing end date (right handle)
        newEnd = _resizeOriginalEnd!.add(Duration(days: daysDelta));
        // Ensure end doesn't go before start
        if (newEnd.isBefore(newStart.add(const Duration(days: 1)))) {
          newEnd = newStart.add(const Duration(days: 1));
        }
      }

      // Call the callback to update the task
      widget.onTaskDateChange?.call(task, newStart, newEnd);
    }
  }

  /// End resize operation
  void _endResize(Task task) {
    // Reset resize state
    setState(() {
      _resizingTaskId = null;
      _resizeAccumulatedDelta = 0.0;
      _resizeOriginalStart = null;
      _resizeOriginalEnd = null;
    });
  }

  /// Start tracking drag for a task (whole task move)
  void _startDrag(Task task) {
    setState(() {
      _draggingTaskId = task.id;
      _dragAccumulatedDelta = 0.0;
      _dragOriginalStart = task.startDate;
      _dragOriginalEnd = task.endDate;
      _cascadePreview = null;
    });
    _cascadePreviewService.startDrag(task.id);
  }

  /// Update drag with accumulated delta and calculate cascade preview
  void _updateDrag(Task task, double delta) {
    if (_draggingTaskId != task.id) {
      _startDrag(task);
    }

    _dragAccumulatedDelta += delta;

    // Calculate number of days to adjust
    final daysDelta = (_dragAccumulatedDelta / widget.dayWidth).round();

    if (_dragOriginalStart != null && _dragOriginalEnd != null) {
      // Calculate cascade preview
      final preview = _cascadePreviewService.calculatePreview(
        taskId: task.id,
        deltaDays: daysDelta,
      );
      
      setState(() {
        _cascadePreview = preview;
      });
    }
  }

  /// End drag operation and apply changes
  void _endDrag(Task task) {
    if (_draggingTaskId != task.id) return;

    // Calculate final day delta
    final daysDelta = (_dragAccumulatedDelta / widget.dayWidth).round();

    if (daysDelta != 0 && _dragOriginalStart != null && _dragOriginalEnd != null) {
      final newStart = _dragOriginalStart!.add(Duration(days: daysDelta));
      final newEnd = _dragOriginalEnd!.add(Duration(days: daysDelta));

      // Apply changes to the dragged task
      widget.onTaskDateChange?.call(task, newStart, newEnd);

      // Apply cascade changes to successor tasks
      if (_cascadePreview != null) {
        for (final preview in _cascadePreview!.cascadedPreviews) {
          if (preview.hasChange) {
            final cascadedTask = widget.tasks.firstWhere(
              (t) => t.id == preview.taskId,
              orElse: () => task,
            );
            if (cascadedTask.id != task.id) {
              widget.onTaskDateChange?.call(
                cascadedTask,
                preview.previewStart,
                preview.previewEnd,
              );
            }
          }
        }
      }
    }

    // Reset drag state
    setState(() {
      _draggingTaskId = null;
      _dragAccumulatedDelta = 0.0;
      _dragOriginalStart = null;
      _dragOriginalEnd = null;
      _cascadePreview = null;
    });
    _cascadePreviewService.endDrag();
  }

  /// Cancel drag without applying changes
  void _cancelDrag() {
    setState(() {
      _draggingTaskId = null;
      _dragAccumulatedDelta = 0.0;
      _dragOriginalStart = null;
      _dragOriginalEnd = null;
      _cascadePreview = null;
    });
    _cascadePreviewService.endDrag();
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = widget.endDate.difference(widget.startDate).inDays + 1;
    final totalWidth = totalDays * widget.dayWidth;
    final totalHeight = widget.tasks.length * GanttConstants.rowHeight;

    // Build task index map for cascade preview painter
    final taskIndexMap = <String, int>{};
    final taskMap = <String, Task>{};
    for (var i = 0; i < widget.tasks.length; i++) {
      taskIndexMap[widget.tasks[i].id] = i;
      taskMap[widget.tasks[i].id] = widget.tasks[i];
    }

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
        // Timeline body with cascade preview overlay
        Expanded(
          child: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              // Cancel dependency drag with Escape key
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape &&
                  _dependencyDragController.isDragging) {
                _dependencyDragController.endDrag();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Stack(
              children: [
                // Main timeline content
                Listener(
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
                    child: Stack(
                      children: [
                        // Task rows
                        ListView.builder(
                          controller: widget.verticalScrollController,
                          itemCount: widget.tasks.length,
                          itemBuilder: (context, index) {
                            return _buildTimelineRow(index, totalWidth);
                          },
                        ),
                        // Cascade preview overlay (above task bars)
                        if (_cascadePreview != null && _draggingTaskId != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: CascadePreviewPainter(
                                  preview: _cascadePreview!,
                                  taskIndexMap: taskIndexMap,
                                  startDate: widget.startDate,
                                  dayWidth: widget.dayWidth,
                                  rowHeight: GanttConstants.rowHeight,
                                  taskMap: taskMap,
                                ),
                              ),
                            ),
                          ),
                        // Dependency drag line overlay (bezier curve)
                        if (_dependencyDragState != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: DependencyDragPainter(
                                  dragState: _dependencyDragState,
                                  taskBounds: _buildTaskBoundsMap(taskIndexMap),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // Cascade preview info overlay (fixed position)
              if (_cascadePreview != null && _cascadePreview!.cascadeCount > 0)
                CascadePreviewOverlay(
                  preview: _cascadePreview!,
                  onCancel: _cancelDrag,
                ),
              // Dependency drag hint overlay
              if (_dependencyDragState != null)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.tooltipBackground,
                        borderRadius: BorderRadius.circular(10),
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
                            _dependencyDragController.hoveredTaskId != null
                                ? Icons.check_circle
                                : Icons.link,
                            color: _dependencyDragController.hoveredTaskId != null
                                ? AppColors.constructionGreen
                                : AppColors.industrialOrange,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _dependencyDragController.hoveredTaskId != null
                                ? '離して依存関係を作成'
                                : 'タスクにドラッグして接続',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
            // Task bar with phase color support, drag, resize handles, and dependency connectors
            TaskBar(
              task: task,
              left: leftPosition,
              width: taskWidth,
              isSelected: isSelected,
              onTap: () => widget.onTaskTap?.call(task),
              phase: task.phaseId != null ? widget.phaseMap[task.phaseId] : null,
              usePhaseColor: widget.usePhaseColors,
              // Drag callbacks for task move with cascade preview
              onDragUpdate: widget.onTaskDateChange != null
                  ? (details) => _updateDrag(task, details.delta.dx)
                  : null,
              onDragEnd: widget.onTaskDateChange != null
                  ? (details) => _endDrag(task)
                  : null,
              // Resize callbacks for start date (left handle)
              onResizeStartUpdate: widget.onTaskDateChange != null
                  ? (delta) => _updateResize(task, delta, true)
                  : null,
              onResizeStartEnd: widget.onTaskDateChange != null
                  ? () => _endResize(task)
                  : null,
              // Resize callbacks for end date (right handle)
              onResizeEndUpdate: widget.onTaskDateChange != null
                  ? (delta) => _updateResize(task, delta, false)
                  : null,
              onResizeEndEnd: widget.onTaskDateChange != null
                  ? () => _endResize(task)
                  : null,
              // Dependency drag callbacks
              showDependencyHandle: widget.enableDependencyCreation,
              onDependencyDragStart: widget.enableDependencyCreation
                  ? _handleDependencyDragStart
                  : null,
              onDependencyDragUpdate: widget.enableDependencyCreation
                  ? _handleDependencyDragUpdate
                  : null,
              onDependencyDragEnd: widget.enableDependencyCreation
                  ? _handleDependencyDragEnd
                  : null,
              isValidDropTarget: _dependencyDragController.isValidTarget(task.id),
              isDependencyDragActive: _dependencyDragController.isDragging &&
                  task.id != _dependencyDragController.sourceTaskId,
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

/// Today column highlight painter with week band
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

    // 今週の帯を描画（月曜日から日曜日）
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    final weekStartDiff = weekStart.difference(startDate).inDays;
    final weekEndDiff = weekEnd.difference(startDate).inDays;

    if (weekStartDiff >= 0) {
      final weekStartX = weekStartDiff * dayWidth;
      final weekWidth = (weekEndDiff - weekStartDiff + 1) * dayWidth;
      final weekRect = Rect.fromLTWH(
        weekStartX.clamp(0.0, size.width),
        0,
        weekWidth.clamp(0.0, size.width - weekStartX),
        size.height,
      );

      // 今週帯の背景色（薄い）
      final weekPaint = Paint()
        ..color = AppColors.primary.withOpacity(GanttConstants.thisWeekBandOpacity)
        ..style = PaintingStyle.fill;

      canvas.drawRect(weekRect, weekPaint);
    }

    // 今日のカラム背景（やや強調）
    final rect = Rect.fromLTWH(x, 0, dayWidth, size.height);
    final paint = Paint()
      ..color = AppColors.ganttToday.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, paint);

    // 今日ラインのグロー効果
    final lineX = x + dayWidth / 2;

    // グロー（外側）
    final glowPaint = Paint()
      ..color = AppColors.ganttTodayLine.withOpacity(0.3)
      ..strokeWidth = GanttConstants.todayLineWidth + GanttConstants.todayLineGlowRadius
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawLine(
      Offset(lineX, 0),
      Offset(lineX, size.height),
      glowPaint,
    );

    // 今日ライン（太く強調）
    final linePaint = Paint()
      ..color = AppColors.ganttTodayLine
      ..strokeWidth = GanttConstants.todayLineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

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
