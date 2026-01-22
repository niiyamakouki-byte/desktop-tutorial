import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import '../../../data/models/dependency_model.dart';
import '../../../data/services/weather_service.dart';
import '../../../data/services/dependency_service.dart';
import '../common/context_menu.dart';
import 'gantt_constants.dart';
import 'task_list_panel.dart';
import 'timeline_panel.dart';
import 'dependency_painter.dart';
import 'enhanced_dependency_painter.dart';
import 'dependency_connector.dart';
import 'dependency_dialog.dart';
import 'task_row.dart';

/// Main Gantt Chart widget that combines task list and timeline panels
class GanttChart extends StatefulWidget {
  /// List of all tasks to display
  final List<Task> tasks;

  /// Currently selected task ID
  final String? selectedTaskId;

  /// Callback when a task is selected
  final Function(Task? task)? onTaskSelected;

  /// Callback when a task is double-tapped (for editing)
  final Function(Task task)? onTaskDoubleTap;

  /// Callback when a task's dates are changed via drag
  final Function(Task task, DateTime newStart, DateTime newEnd)? onTaskDateChange;

  /// Callback when task expand/collapse state changes
  final Function(Task task, bool isExpanded)? onTaskExpandToggle;

  /// Custom start date for the timeline (defaults to earliest task start - buffer)
  final DateTime? timelineStartDate;

  /// Custom end date for the timeline (defaults to latest task end + buffer)
  final DateTime? timelineEndDate;

  /// Initial view mode
  final GanttViewMode initialViewMode;

  /// Whether to show dependency arrows
  final bool showDependencies;

  /// Whether to show the today line
  final bool showTodayLine;

  /// Whether to highlight weekends
  final bool showWeekends;

  /// Initial task list panel width
  final double initialTaskListWidth;

  /// Whether the task list panel is resizable
  final bool resizableTaskList;

  /// Enable grid snap (tasks snap to 20px increments)
  final bool enableGridSnap;

  /// Grid snap increment in pixels
  final double gridSnapSize;

  /// Enable mouse wheel zoom
  final bool enableMouseWheelZoom;

  /// Enable pinch zoom for mobile
  final bool enablePinchZoom;

  /// Callback for task deletion
  final Function(Task task)? onTaskDelete;

  /// Callback for task duplication
  final Function(Task task)? onTaskDuplicate;

  /// Callback for task color change
  final Function(Task task, Color color)? onTaskColorChange;

  /// Show weather data on timeline
  final bool showWeather;

  /// Dependencies list (new system)
  final List<TaskDependency> dependencies;

  /// Dependency service for cycle detection
  final DependencyService? dependencyService;

  /// Critical path task IDs
  final Set<String> criticalPathIds;

  /// Show critical path highlighting
  final bool showCriticalPath;

  /// Delay impact map (taskId -> delay days)
  final Map<String, int>? delayImpactMap;

  /// Callback when dependency is created
  final Function(String fromTaskId, String toTaskId, DependencyType type, int lagDays)? onDependencyCreated;

  /// Callback when dependency is deleted
  final Function(String dependencyId)? onDependencyDeleted;

  const GanttChart({
    super.key,
    required this.tasks,
    this.selectedTaskId,
    this.onTaskSelected,
    this.onTaskDoubleTap,
    this.onTaskDateChange,
    this.onTaskExpandToggle,
    this.timelineStartDate,
    this.timelineEndDate,
    this.initialViewMode = GanttViewMode.day,
    this.showDependencies = true,
    this.showTodayLine = true,
    this.showWeekends = true,
    this.initialTaskListWidth = GanttConstants.taskListWidth,
    this.resizableTaskList = true,
    this.enableGridSnap = true,
    this.gridSnapSize = 20.0,
    this.enableMouseWheelZoom = true,
    this.enablePinchZoom = true,
    this.onTaskDelete,
    this.onTaskDuplicate,
    this.onTaskColorChange,
    this.showWeather = true,
    this.dependencies = const [],
    this.dependencyService,
    this.criticalPathIds = const {},
    this.showCriticalPath = true,
    this.delayImpactMap,
    this.onDependencyCreated,
    this.onDependencyDeleted,
  });

  @override
  State<GanttChart> createState() => _GanttChartState();
}

class _GanttChartState extends State<GanttChart> {
  late ScrollController _taskListScrollController;
  late ScrollController _timelineVerticalScrollController;
  late ScrollController _timelineHorizontalScrollController;

  late double _taskListWidth;
  late GanttViewMode _viewMode;
  double _zoomLevel = GanttConstants.defaultZoom;

  String? _selectedTaskId;
  String? _hoveredTaskId;

  // Computed date range
  late DateTime _startDate;
  late DateTime _endDate;

  // Visible tasks (accounting for collapsed parents)
  late List<Task> _visibleTasks;

  // Pinch zoom state
  double _baseZoom = 1.0;
  double _currentScale = 1.0;

  // Weather alerts
  List<WeatherAlert> _weatherAlerts = [];

  @override
  void initState() {
    super.initState();

    _taskListScrollController = ScrollController();
    _timelineVerticalScrollController = ScrollController();
    _timelineHorizontalScrollController = ScrollController();

    _taskListWidth = widget.initialTaskListWidth;
    _viewMode = widget.initialViewMode;
    _selectedTaskId = widget.selectedTaskId;

    _computeDateRange();
    _computeVisibleTasks();
    _loadWeatherAlerts();

    // Sync vertical scrolling between task list and timeline
    _taskListScrollController.addListener(_syncVerticalScroll);
    _timelineVerticalScrollController.addListener(_syncVerticalScrollReverse);
  }

  void _loadWeatherAlerts() {
    if (widget.showWeather) {
      WeatherService.initializeMockData();
      _weatherAlerts = WeatherService.getAlertsForDateRange(_startDate, _endDate);
    }
  }

  /// Handle mouse wheel for zoom
  void _handlePointerSignal(PointerSignalEvent event) {
    if (!widget.enableMouseWheelZoom) return;

    if (event is PointerScrollEvent) {
      // Check if Ctrl key is pressed for zoom
      if (HardwareKeyboard.instance.isControlPressed) {
        final delta = event.scrollDelta.dy;
        final newZoom = _zoomLevel + (delta > 0 ? -0.1 : 0.1);
        _handleZoomChange(newZoom);
      }
    }
  }

  /// Handle pinch zoom start
  void _handleScaleStart(ScaleStartDetails details) {
    if (!widget.enablePinchZoom) return;
    _baseZoom = _zoomLevel;
  }

  /// Handle pinch zoom update
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!widget.enablePinchZoom) return;
    if (details.pointerCount >= 2) {
      _currentScale = details.scale;
      final newZoom = _baseZoom * _currentScale;
      _handleZoomChange(newZoom);
    }
  }

  /// Snap position to grid
  double _snapToGrid(double position) {
    if (!widget.enableGridSnap) return position;
    return (position / widget.gridSnapSize).round() * widget.gridSnapSize;
  }

  /// Show context menu for a task
  void _showTaskContextMenu(BuildContext context, Offset position, Task task) {
    showContextMenu(
      context: context,
      position: position,
      items: [
        ContextMenuItem(
          label: '編集',
          icon: Icons.edit_outlined,
          onTap: () => widget.onTaskDoubleTap?.call(task),
        ),
        ContextMenuItem(
          label: '複製',
          icon: Icons.copy_outlined,
          onTap: () => widget.onTaskDuplicate?.call(task),
        ),
        ContextMenuItem(
          label: '色を変更',
          icon: Icons.palette_outlined,
          color: AppColors.primary,
          onTap: () => _showColorPicker(context, position, task),
        ),
        ContextMenuItem(
          label: '依存関係を追加',
          icon: Icons.link_outlined,
          onTap: () {
            // TODO: Show dependency picker
          },
        ),
        ContextMenuItem(
          label: '削除',
          icon: Icons.delete_outline,
          isDanger: true,
          onTap: () => _confirmDelete(context, task),
        ),
      ],
    );
  }

  /// Show color picker for task
  void _showColorPicker(BuildContext context, Offset position, Task task) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => overlayEntry.remove(),
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: position.dx,
            top: position.dy + 40,
            child: ColorPickerMenu(
              selectedColor: AppColors.getCategoryColor(task.category),
              onColorSelected: (color) {
                widget.onTaskColorChange?.call(task, color);
              },
              onDismiss: () => overlayEntry.remove(),
            ),
          ),
        ],
      ),
    );

    overlay.insert(overlayEntry);
  }

  /// Confirm task deletion
  void _confirmDelete(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タスクを削除'),
        content: Text('「${task.name}」を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onTaskDelete?.call(task);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(GanttChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.tasks != oldWidget.tasks) {
      _computeDateRange();
      _computeVisibleTasks();
    }

    if (widget.selectedTaskId != oldWidget.selectedTaskId) {
      _selectedTaskId = widget.selectedTaskId;
    }
  }

  @override
  void dispose() {
    _taskListScrollController.removeListener(_syncVerticalScroll);
    _timelineVerticalScrollController.removeListener(_syncVerticalScrollReverse);

    _taskListScrollController.dispose();
    _timelineVerticalScrollController.dispose();
    _timelineHorizontalScrollController.dispose();

    super.dispose();
  }

  void _syncVerticalScroll() {
    if (_timelineVerticalScrollController.hasClients &&
        _taskListScrollController.hasClients) {
      if (_timelineVerticalScrollController.offset !=
          _taskListScrollController.offset) {
        _timelineVerticalScrollController.jumpTo(_taskListScrollController.offset);
      }
    }
  }

  void _syncVerticalScrollReverse() {
    if (_taskListScrollController.hasClients &&
        _timelineVerticalScrollController.hasClients) {
      if (_taskListScrollController.offset !=
          _timelineVerticalScrollController.offset) {
        _taskListScrollController.jumpTo(_timelineVerticalScrollController.offset);
      }
    }
  }

  void _computeDateRange() {
    if (widget.tasks.isEmpty) {
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
      return;
    }

    if (widget.timelineStartDate != null && widget.timelineEndDate != null) {
      _startDate = widget.timelineStartDate!;
      _endDate = widget.timelineEndDate!;
      return;
    }

    // Calculate from tasks
    DateTime earliest = widget.tasks.first.startDate;
    DateTime latest = widget.tasks.first.endDate;

    for (final task in widget.tasks) {
      if (task.startDate.isBefore(earliest)) {
        earliest = task.startDate;
      }
      if (task.endDate.isAfter(latest)) {
        latest = task.endDate;
      }
    }

    // Add buffer
    _startDate = earliest.subtract(Duration(days: GanttConstants.bufferDaysBefore));
    _endDate = latest.add(Duration(days: GanttConstants.bufferDaysAfter));

    // Ensure start is beginning of month for cleaner display
    _startDate = DateTime(_startDate.year, _startDate.month, 1);
  }

  void _computeVisibleTasks() {
    _visibleTasks = widget.tasks.getVisibleTasks();
  }

  void _handleTaskTap(Task task) {
    setState(() {
      _selectedTaskId = task.id == _selectedTaskId ? null : task.id;
    });
    widget.onTaskSelected?.call(_selectedTaskId != null ? task : null);
  }

  void _handleTaskDoubleTap(Task task) {
    widget.onTaskDoubleTap?.call(task);
  }

  void _handleExpandToggle(Task task) {
    widget.onTaskExpandToggle?.call(task, !task.isExpanded);
    setState(() {
      _computeVisibleTasks();
    });
  }

  void _handleTaskListWidthChange(double newWidth) {
    setState(() {
      _taskListWidth = newWidth.clamp(200.0, 500.0);
    });
  }

  void _handleViewModeChange(GanttViewMode mode) {
    setState(() {
      _viewMode = mode;
    });
  }

  void _handleZoomChange(double zoom) {
    setState(() {
      _zoomLevel = zoom.clamp(GanttConstants.minZoom, GanttConstants.maxZoom);
    });
  }

  double get _effectiveDayWidth {
    return _viewMode.dayWidth * _zoomLevel;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) {
      return _buildEmptyState();
    }

    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: GestureDetector(
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.ganttBackground,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Weather alerts (if any)
              if (widget.showWeather && _weatherAlerts.isNotEmpty)
                _buildWeatherAlerts(),

              // Toolbar
              _buildToolbar(),

              // Main content
              Expanded(
                child: Row(
                  children: [
                    // Task list panel
                    TaskListPanel(
                      tasks: _visibleTasks,
                      allTasks: widget.tasks,
                      selectedTaskId: _selectedTaskId,
                      scrollController: _taskListScrollController,
                      width: _taskListWidth,
                      onTaskTap: _handleTaskTap,
                      onTaskDoubleTap: _handleTaskDoubleTap,
                      onExpandToggle: _handleExpandToggle,
                    ),

                    // Resizable divider
                    if (widget.resizableTaskList)
                  PanelDivider(
                    initialWidth: _taskListWidth,
                    onWidthChanged: _handleTaskListWidthChange,
                  ),

                // Timeline panel
                Expanded(
                  child: _buildTimelinePanel(),
                ),
              ],
            ),
          ),

          // Summary footer
          _buildFooter(),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildWeatherAlerts() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.safetyYellow.withOpacity(0.1),
            AppColors.industrialOrange.withOpacity(0.05),
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.industrialOrange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.industrialOrange,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.industrialOrange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'AI 推奨',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_weatherAlerts.length}件の天気アラート',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _weatherAlerts.first.message,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              // Show all alerts
            },
            icon: const Icon(Icons.schedule, size: 16),
            label: const Text('日程変更を推奨'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.industrialOrange,
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

  Widget _buildToolbar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          // Title
          const Icon(
            Icons.view_timeline,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          const Text(
            'ガントチャート',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),

          // View mode and zoom controls
          TimelineZoomControl(
            currentZoom: _zoomLevel,
            onZoomChanged: _handleZoomChange,
            currentMode: _viewMode,
            onModeChanged: _handleViewModeChange,
          ),

          const SizedBox(width: 12),

          // Today button
          _buildTodayButton(),

          const SizedBox(width: 8),

          // Expand/Collapse all
          _buildExpandCollapseButtons(),
        ],
      ),
    );
  }

  Widget _buildTodayButton() {
    return Tooltip(
      message: '今日に移動',
      child: InkWell(
        onTap: _scrollToToday,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.today,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '今日',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandCollapseButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: '全て展開',
          child: InkWell(
            onTap: _expandAll,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.unfold_more,
                size: 18,
                color: AppColors.iconDefault,
              ),
            ),
          ),
        ),
        Tooltip(
          message: '全て折りたたむ',
          child: InkWell(
            onTap: _collapseAll,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.unfold_less,
                size: 18,
                color: AppColors.iconDefault,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelinePanel() {
    final totalDays = _endDate.difference(_startDate).inDays + 1;
    final totalWidth = totalDays * _effectiveDayWidth;
    final totalHeight = _visibleTasks.length * GanttConstants.rowHeight;

    // Build task index map for dependency painter
    final taskIndexMap = <String, int>{};
    for (var i = 0; i < _visibleTasks.length; i++) {
      taskIndexMap[_visibleTasks[i].id] = i;
    }

    return Stack(
      children: [
        // Main timeline panel
        TimelinePanel(
          tasks: _visibleTasks,
          startDate: _startDate,
          endDate: _endDate,
          selectedTaskId: _selectedTaskId,
          hoveredTaskId: _hoveredTaskId,
          dayWidth: _effectiveDayWidth,
          horizontalScrollController: _timelineHorizontalScrollController,
          verticalScrollController: _timelineVerticalScrollController,
          viewMode: _viewMode,
          onTaskTap: _handleTaskTap,
          onTaskHover: (task) {
            setState(() {
              _hoveredTaskId = task.id;
            });
          },
          // Dependency-related parameters
          dependencies: widget.dependencies,
          dependencyService: widget.dependencyService,
          criticalPathIds: widget.criticalPathIds,
          showCriticalPath: widget.showCriticalPath,
          delayImpactMap: widget.delayImpactMap,
          onDependencyCreated: widget.onDependencyCreated,
          enableDependencyCreation: widget.showDependencies,
        ),

        // Dependency creation layer (drag & drop)
        if (widget.showDependencies)
          Positioned.fill(
            child: DependencyCreationLayer(
              tasks: _visibleTasks,
              taskIndexMap: taskIndexMap,
              startDate: _startDate,
              dayWidth: _effectiveDayWidth,
              rowHeight: GanttConstants.rowHeight,
              dependencyService: widget.dependencyService,
              onDependencyCreated: widget.onDependencyCreated,
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
    final totalTasks = widget.tasks.length;
    final completedTasks = widget.tasks.where((t) => t.status == 'completed').length;
    final inProgressTasks = widget.tasks.where((t) => t.status == 'in_progress').length;
    final delayedTasks = widget.tasks.where((t) => t.isOverdue).length;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          _buildStatusBadge('合計', totalTasks.toString(), AppColors.textSecondary),
          const SizedBox(width: 16),
          _buildStatusBadge('完了', completedTasks.toString(), AppColors.success),
          const SizedBox(width: 16),
          _buildStatusBadge('進行中', inProgressTasks.toString(), AppColors.taskInProgress),
          const SizedBox(width: 16),
          if (delayedTasks > 0)
            _buildStatusBadge('遅延', delayedTasks.toString(), AppColors.error),
          const Spacer(),
          Text(
            '${GanttConstants.formatFullDate(_startDate)} - ${GanttConstants.formatFullDate(_endDate)}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, String count, Color color) {
    return Row(
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
          '$label: $count',
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ganttBackground,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: EmptyTaskList(
          onAddTask: () {
            // Parent should handle this via onTaskDoubleTap or similar
          },
        ),
      ),
    );
  }

  void _scrollToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (today.isBefore(_startDate) || today.isAfter(_endDate)) {
      // Today is outside the visible range
      return;
    }

    final daysDiff = today.difference(_startDate).inDays;
    final targetOffset = (daysDiff * _effectiveDayWidth) - 100; // Center with some offset

    _timelineHorizontalScrollController.animateTo(
      targetOffset.clamp(0.0, _timelineHorizontalScrollController.position.maxScrollExtent),
      duration: AppConstants.animationNormal,
      curve: Curves.easeInOut,
    );
  }

  void _expandAll() {
    for (final task in widget.tasks) {
      if (!task.isExpanded && widget.tasks.hasChildren(task.id)) {
        widget.onTaskExpandToggle?.call(task, true);
      }
    }
    setState(() {
      _computeVisibleTasks();
    });
  }

  void _collapseAll() {
    for (final task in widget.tasks) {
      if (task.isExpanded && widget.tasks.hasChildren(task.id)) {
        widget.onTaskExpandToggle?.call(task, false);
      }
    }
    setState(() {
      _computeVisibleTasks();
    });
  }
}

/// Lightweight Gantt chart for preview/thumbnail purposes
class GanttChartPreview extends StatelessWidget {
  final List<Task> tasks;
  final double height;

  const GanttChartPreview({
    super.key,
    required this.tasks,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'タスクなし',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }

    // Calculate date range
    DateTime earliest = tasks.first.startDate;
    DateTime latest = tasks.first.endDate;

    for (final task in tasks) {
      if (task.startDate.isBefore(earliest)) {
        earliest = task.startDate;
      }
      if (task.endDate.isAfter(latest)) {
        latest = task.endDate;
      }
    }

    final totalDays = latest.difference(earliest).inDays + 1;

    return Container(
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dayWidth = constraints.maxWidth / totalDays;
          final rowHeight = (constraints.maxHeight - 20) / tasks.length.clamp(1, 5);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mini header
              Text(
                '${earliest.month}/${earliest.day} - ${latest.month}/${latest.day}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              // Task bars
              Expanded(
                child: Stack(
                  children: tasks.take(5).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final task = entry.value;
                    final startOffset = task.startDate.difference(earliest).inDays;
                    final barWidth = task.durationDays * dayWidth;
                    final left = startOffset * dayWidth;

                    return Positioned(
                      left: left.clamp(0.0, constraints.maxWidth - 4),
                      top: index * rowHeight + 2,
                      child: Container(
                        width: barWidth.clamp(4.0, constraints.maxWidth - left),
                        height: rowHeight - 4,
                        decoration: BoxDecoration(
                          color: AppColors.getCategoryColor(task.category),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
