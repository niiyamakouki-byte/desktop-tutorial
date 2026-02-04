import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../data/models/dependency_model.dart';
import '../../../data/services/dependency_service.dart';
import 'gantt_constants.dart';
import 'dependency_dialog.dart';

/// Connector point type
enum ConnectorType { input, output }

/// Dependency drag state
class DependencyDragState {
  final String fromTaskId;
  final ConnectorType fromConnector;
  final Offset startPosition;
  final Offset currentPosition;
  final String? hoveredTaskId;

  const DependencyDragState({
    required this.fromTaskId,
    required this.fromConnector,
    required this.startPosition,
    required this.currentPosition,
    this.hoveredTaskId,
  });

  DependencyDragState copyWith({
    String? fromTaskId,
    ConnectorType? fromConnector,
    Offset? startPosition,
    Offset? currentPosition,
    String? hoveredTaskId,
  }) {
    return DependencyDragState(
      fromTaskId: fromTaskId ?? this.fromTaskId,
      fromConnector: fromConnector ?? this.fromConnector,
      startPosition: startPosition ?? this.startPosition,
      currentPosition: currentPosition ?? this.currentPosition,
      hoveredTaskId: hoveredTaskId,
    );
  }
}

/// Connector widget for task bars
/// Shows input (left) and output (right) connection points
class TaskConnectors extends StatefulWidget {
  final Task task;
  final double taskBarLeft;
  final double taskBarWidth;
  final double rowTop;
  final bool showConnectors;
  final bool isSourceTask;
  final bool isValidTarget;
  final Function(Task task, ConnectorType type, Offset globalPosition)? onDragStart;
  final Function(Offset globalPosition)? onDragUpdate;
  final Function(Task? targetTask)? onDragEnd;
  final VoidCallback? onConnectorHover;
  final VoidCallback? onConnectorLeave;

  const TaskConnectors({
    super.key,
    required this.task,
    required this.taskBarLeft,
    required this.taskBarWidth,
    required this.rowTop,
    this.showConnectors = false,
    this.isSourceTask = false,
    this.isValidTarget = false,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onConnectorHover,
    this.onConnectorLeave,
  });

  @override
  State<TaskConnectors> createState() => _TaskConnectorsState();
}

class _TaskConnectorsState extends State<TaskConnectors>
    with SingleTickerProviderStateMixin {
  bool _isHoveringInput = false;
  bool _isHoveringOutput = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectorSize = GanttConstants.connectorSize;
    final taskBarCenterY = widget.rowTop + GanttConstants.rowHeight / 2;

    return Stack(
      children: [
        // Input connector (left side)
        Positioned(
          left: widget.taskBarLeft - connectorSize / 2 - 2,
          top: taskBarCenterY - connectorSize / 2,
          child: _buildConnector(
            type: ConnectorType.input,
            isHovering: _isHoveringInput,
            onHoverStart: () {
              setState(() => _isHoveringInput = true);
              widget.onConnectorHover?.call();
            },
            onHoverEnd: () {
              setState(() => _isHoveringInput = false);
              widget.onConnectorLeave?.call();
            },
          ),
        ),

        // Output connector (right side)
        Positioned(
          left: widget.taskBarLeft + widget.taskBarWidth - connectorSize / 2 + 2,
          top: taskBarCenterY - connectorSize / 2,
          child: _buildConnector(
            type: ConnectorType.output,
            isHovering: _isHoveringOutput,
            onHoverStart: () {
              setState(() => _isHoveringOutput = true);
              widget.onConnectorHover?.call();
            },
            onHoverEnd: () {
              setState(() => _isHoveringOutput = false);
              widget.onConnectorLeave?.call();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConnector({
    required ConnectorType type,
    required bool isHovering,
    required VoidCallback onHoverStart,
    required VoidCallback onHoverEnd,
  }) {
    final connectorSize = GanttConstants.connectorSize;
    final isOutput = type == ConnectorType.output;
    final showExpanded = widget.showConnectors || isHovering || widget.isSourceTask;
    final isValidDrop = widget.isValidTarget && type == ConnectorType.input;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final pulseScale = widget.isValidTarget ? 1.0 + _pulseAnimation.value * 0.3 : 1.0;

        return MouseRegion(
          onEnter: (_) => onHoverStart(),
          onExit: (_) => onHoverEnd(),
          child: GestureDetector(
            onPanStart: (details) {
              widget.onDragStart?.call(widget.task, type, details.globalPosition);
            },
            onPanUpdate: (details) {
              widget.onDragUpdate?.call(details.globalPosition);
            },
            onPanEnd: (details) {
              widget.onDragEnd?.call(null);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: connectorSize * (showExpanded ? 1.5 : 1.0) * pulseScale,
              height: connectorSize * (showExpanded ? 1.5 : 1.0) * pulseScale,
              decoration: BoxDecoration(
                color: isValidDrop
                    ? AppColors.constructionGreen
                    : (isOutput
                        ? AppColors.industrialOrange
                        : AppColors.primary),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: showExpanded ? 2 : 1,
                ),
                boxShadow: showExpanded || isValidDrop
                    ? [
                        BoxShadow(
                          color: (isValidDrop
                              ? AppColors.constructionGreen
                              : AppColors.industrialOrange).withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  isOutput ? Icons.arrow_forward : Icons.arrow_back,
                  size: connectorSize * 0.6,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Painter for drawing the dragging dependency line
class DependencyDragPainter extends CustomPainter {
  final DependencyDragState? dragState;
  final Map<String, Rect> taskBounds;

  DependencyDragPainter({
    this.dragState,
    required this.taskBounds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dragState == null) return;

    final start = dragState!.startPosition;
    final end = dragState!.currentPosition;
    final isValidTarget = dragState!.hoveredTaskId != null;

    // Draw bezier curve
    final paint = Paint()
      ..color = isValidTarget
          ? AppColors.constructionGreen
          : AppColors.industrialOrange
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Calculate control points for smooth bezier curve
    final midX = (start.dx + end.dx) / 2;
    final dx = (end.dx - start.dx).abs();
    final controlOffset = math.max(dx * 0.5, 50);

    path.cubicTo(
      start.dx + controlOffset, start.dy,
      end.dx - controlOffset, end.dy,
      end.dx, end.dy,
    );

    canvas.drawPath(path, paint);

    // Draw arrow head at end
    _drawArrowHead(canvas, end, paint, start);

    // Draw glow effect
    final glowPaint = Paint()
      ..color = (isValidTarget
          ? AppColors.constructionGreen
          : AppColors.industrialOrange).withOpacity(0.3)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(path, glowPaint);

    // Draw start point indicator
    final startDotPaint = Paint()
      ..color = AppColors.industrialOrange
      ..style = PaintingStyle.fill;
    canvas.drawCircle(start, 6, startDotPaint);
    canvas.drawCircle(start, 6, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    // Draw end point indicator
    if (isValidTarget) {
      final endDotPaint = Paint()
        ..color = AppColors.constructionGreen
        ..style = PaintingStyle.fill;
      canvas.drawCircle(end, 8, endDotPaint);
      canvas.drawCircle(end, 8, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset tip, Paint paint, Offset from) {
    final angle = math.atan2(tip.dy - from.dy, tip.dx - from.dx);
    const arrowSize = 12.0;
    const arrowAngle = 0.5;

    final path = Path();
    path.moveTo(tip.dx, tip.dy);
    path.lineTo(
      tip.dx - arrowSize * math.cos(angle - arrowAngle),
      tip.dy - arrowSize * math.sin(angle - arrowAngle),
    );
    path.moveTo(tip.dx, tip.dy);
    path.lineTo(
      tip.dx - arrowSize * math.cos(angle + arrowAngle),
      tip.dy - arrowSize * math.sin(angle + arrowAngle),
    );

    canvas.drawPath(path, paint..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant DependencyDragPainter oldDelegate) {
    return dragState != oldDelegate.dragState ||
        taskBounds != oldDelegate.taskBounds;
  }
}

/// Controller for managing dependency drag state across the timeline
/// This is used to coordinate between TaskBars and the overlay
class DependencyDragController extends ChangeNotifier {
  DependencyDragState? _dragState;
  String? _hoveredTaskId;
  final Set<String> _validTargetIds = {};

  DependencyDragState? get dragState => _dragState;
  String? get hoveredTaskId => _hoveredTaskId;
  bool get isDragging => _dragState != null;
  String? get sourceTaskId => _dragState?.fromTaskId;

  bool isValidTarget(String taskId) {
    return _dragState != null &&
        taskId != _dragState!.fromTaskId &&
        _validTargetIds.contains(taskId);
  }

  void startDrag({
    required String fromTaskId,
    required ConnectorType fromConnector,
    required Offset startPosition,
    required Set<String> validTargetIds,
  }) {
    _validTargetIds.clear();
    _validTargetIds.addAll(validTargetIds);
    _dragState = DependencyDragState(
      fromTaskId: fromTaskId,
      fromConnector: fromConnector,
      startPosition: startPosition,
      currentPosition: startPosition,
    );
    notifyListeners();
  }

  void updateDrag(Offset position, {String? hoveredTaskId}) {
    if (_dragState == null) return;
    _dragState = _dragState!.copyWith(
      currentPosition: position,
      hoveredTaskId: hoveredTaskId,
    );
    _hoveredTaskId = hoveredTaskId;
    notifyListeners();
  }

  void endDrag() {
    _dragState = null;
    _hoveredTaskId = null;
    _validTargetIds.clear();
    notifyListeners();
  }

  void setHoveredTask(String? taskId) {
    if (_dragState == null) return;
    _hoveredTaskId = taskId;
    _dragState = _dragState!.copyWith(hoveredTaskId: taskId);
    notifyListeners();
  }
}

/// Widget that wraps the timeline to handle dependency creation
class DependencyCreationLayer extends StatefulWidget {
  final List<Task> tasks;
  final Map<String, int>? taskIndexMap;
  final Map<String, Rect>? taskBounds;
  final DateTime? startDate;
  final double? dayWidth;
  final double? rowHeight;
  final DependencyService? dependencyService;
  final Function(String fromTaskId, String toTaskId, DependencyType type, int lagDays)? onDependencyCreated;
  final Widget? child;

  /// External drag controller for coordinating with TaskBars
  final DependencyDragController? dragController;

  const DependencyCreationLayer({
    super.key,
    required this.tasks,
    this.taskIndexMap,
    this.dragController,
    this.taskBounds,
    this.startDate,
    this.dayWidth,
    this.rowHeight,
    this.dependencyService,
    this.onDependencyCreated,
    this.child,
  });

  @override
  State<DependencyCreationLayer> createState() => _DependencyCreationLayerState();
}

class _DependencyCreationLayerState extends State<DependencyCreationLayer> {
  DependencyDragState? _dragState;
  String? _hoveredTaskId;
  late DependencyDragController _internalController;

  DependencyDragController get _controller =>
      widget.dragController ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = DependencyDragController();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(DependencyCreationLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dragController != widget.dragController) {
      oldWidget.dragController?.removeListener(_onControllerChanged);
      _controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _internalController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {
      _dragState = _controller.dragState;
      _hoveredTaskId = _controller.hoveredTaskId;
    });
  }

  /// Compute task bounds from parameters if not provided directly
  Map<String, Rect> _computeTaskBounds() {
    if (widget.taskBounds != null) return widget.taskBounds!;

    final bounds = <String, Rect>{};
    final startDate = widget.startDate ?? DateTime.now();
    final dayWidth = widget.dayWidth ?? GanttConstants.dayWidth;
    final rowHeight = widget.rowHeight ?? GanttConstants.rowHeight;
    final taskIndexMap = widget.taskIndexMap ?? {};

    for (final task in widget.tasks) {
      final index = taskIndexMap[task.id] ?? widget.tasks.indexOf(task);
      final startOffset = task.startDate.difference(startDate).inDays;
      final taskWidth = task.isMilestone
          ? GanttConstants.milestoneSize
          : task.durationDays * dayWidth;
      final left = startOffset * dayWidth;
      final top = index * rowHeight;

      bounds[task.id] = Rect.fromLTWH(left, top, taskWidth, rowHeight);
    }

    return bounds;
  }

  void _handleDragStart(Task task, ConnectorType type, Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(globalPosition);

    setState(() {
      _dragState = DependencyDragState(
        fromTaskId: task.id,
        fromConnector: type,
        startPosition: localPosition,
        currentPosition: localPosition,
      );
    });
  }

  void _handleDragUpdate(Offset globalPosition) {
    if (_dragState == null) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(globalPosition);
    final taskBounds = _computeTaskBounds();

    // Check if hovering over a valid target
    String? hoveredId;
    for (final entry in taskBounds.entries) {
      if (entry.key != _dragState!.fromTaskId &&
          entry.value.contains(localPosition)) {
        // Check if this would create a circular dependency
        if (!_wouldCreateCircular(entry.key)) {
          hoveredId = entry.key;
        }
        break;
      }
    }

    setState(() {
      _dragState = _dragState!.copyWith(
        currentPosition: localPosition,
        hoveredTaskId: hoveredId,
      );
      _hoveredTaskId = hoveredId;
    });
  }

  void _handleDragEnd() async {
    if (_dragState?.hoveredTaskId != null) {
      final fromTaskId = _dragState!.fromTaskId;
      final toTaskId = _dragState!.hoveredTaskId!;

      // Get tasks for dialog
      final fromTask = widget.tasks.firstWhere(
        (t) => t.id == fromTaskId,
        orElse: () => widget.tasks.first,
      );
      final toTask = widget.tasks.firstWhere(
        (t) => t.id == toTaskId,
        orElse: () => widget.tasks.first,
      );

      // Clear drag state first
      setState(() {
        _dragState = null;
        _hoveredTaskId = null;
      });

      // Show dialog to select dependency type
      final result = await DependencyDialog.show(
        context: context,
        fromTask: fromTask,
        toTask: toTask,
      );

      if (result != null) {
        widget.onDependencyCreated?.call(
          fromTaskId,
          toTaskId,
          result.type,
          result.lagDays,
        );
      }
    } else {
      setState(() {
        _dragState = null;
        _hoveredTaskId = null;
      });
    }
  }

  bool _wouldCreateCircular(String targetId) {
    // Use DependencyService for proper cycle detection if available
    if (widget.dependencyService != null && _dragState != null) {
      return widget.dependencyService!.wouldCreateCycle(
        _dragState!.fromTaskId,
        targetId,
      );
    }

    // Fallback to simple check
    final targetTask = widget.tasks.firstWhere(
      (t) => t.id == targetId,
      orElse: () => widget.tasks.first,
    );
    return targetTask.dependsOn.contains(_dragState?.fromTaskId);
  }

  @override
  Widget build(BuildContext context) {
    final taskBounds = _computeTaskBounds();
    final rowHeight = widget.rowHeight ?? GanttConstants.rowHeight;
    final dayWidth = widget.dayWidth ?? GanttConstants.dayWidth;
    final startDate = widget.startDate ?? DateTime.now();

    return GestureDetector(
      onPanStart: (details) {
        // Find which task connector was touched
        final position = details.localPosition;
        for (final task in widget.tasks) {
          final bounds = taskBounds[task.id];
          if (bounds == null) continue;

          // Check if near output connector (right side)
          final outputX = bounds.right;
          final centerY = bounds.top + bounds.height / 2;
          final connectorRadius = GanttConstants.connectorSize * 2;

          if ((position.dx - outputX).abs() < connectorRadius &&
              (position.dy - centerY).abs() < connectorRadius) {
            _handleDragStart(task, ConnectorType.output, details.globalPosition);
            return;
          }

          // Check if near input connector (left side)
          final inputX = bounds.left;
          if ((position.dx - inputX).abs() < connectorRadius &&
              (position.dy - centerY).abs() < connectorRadius) {
            _handleDragStart(task, ConnectorType.input, details.globalPosition);
            return;
          }
        }
      },
      onPanUpdate: (details) => _handleDragUpdate(details.globalPosition),
      onPanEnd: (_) => _handleDragEnd(),
      child: Stack(
        children: [
          // Child widget if provided
          if (widget.child != null) widget.child!,

          // Task connector indicators
          ...widget.tasks.map((task) {
            final bounds = taskBounds[task.id];
            if (bounds == null) return const SizedBox.shrink();

            final isSource = _dragState?.fromTaskId == task.id;
            final isTarget = _dragState?.hoveredTaskId == task.id;

            return TaskConnectors(
              task: task,
              taskBarLeft: bounds.left,
              taskBarWidth: bounds.width,
              rowTop: bounds.top,
              showConnectors: _dragState != null,
              isSourceTask: isSource,
              isValidTarget: isTarget,
            );
          }),

          // Dependency drag overlay
          if (_dragState != null)
            Positioned.fill(
              child: CustomPaint(
                painter: DependencyDragPainter(
                  dragState: _dragState,
                  taskBounds: taskBounds,
                ),
              ),
            ),

          // Connection hint overlay
          if (_dragState != null)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.tooltipBackground,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _dragState!.hoveredTaskId != null
                            ? Icons.check_circle
                            : Icons.link,
                        color: _dragState!.hoveredTaskId != null
                            ? AppColors.constructionGreen
                            : AppColors.industrialOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _dragState!.hoveredTaskId != null
                            ? '離して依存関係を作成'
                            : 'タスクにドラッグして接続',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
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
    );
  }
}
