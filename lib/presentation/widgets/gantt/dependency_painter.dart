import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import 'gantt_constants.dart';

/// Custom painter for drawing dependency arrows between tasks
class DependencyPainter extends CustomPainter {
  final List<Task> tasks;
  final Map<String, int> taskIndexMap;
  final DateTime startDate;
  final double dayWidth;
  final double rowHeight;
  final String? selectedTaskId;
  final String? hoveredTaskId;

  DependencyPainter({
    required this.tasks,
    required this.taskIndexMap,
    required this.startDate,
    this.dayWidth = GanttConstants.dayWidth,
    this.rowHeight = GanttConstants.rowHeight,
    this.selectedTaskId,
    this.hoveredTaskId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final task in tasks) {
      if (task.dependsOn.isEmpty) continue;

      final toIndex = taskIndexMap[task.id];
      if (toIndex == null) continue;

      for (final dependencyId in task.dependsOn) {
        final fromIndex = taskIndexMap[dependencyId];
        if (fromIndex == null) continue;

        final fromTask = tasks.firstWhere(
          (t) => t.id == dependencyId,
          orElse: () => task,
        );

        _drawDependencyArrow(
          canvas,
          fromTask,
          task,
          fromIndex,
          toIndex,
        );
      }
    }
  }

  void _drawDependencyArrow(
    Canvas canvas,
    Task fromTask,
    Task toTask,
    int fromIndex,
    int toIndex,
  ) {
    // Calculate positions
    final fromEndX = _getTaskEndX(fromTask);
    final fromY = fromIndex * rowHeight + rowHeight / 2;

    final toStartX = _getTaskStartX(toTask);
    final toY = toIndex * rowHeight + rowHeight / 2;

    // Determine if this dependency is highlighted
    final isHighlighted = selectedTaskId == fromTask.id ||
        selectedTaskId == toTask.id ||
        hoveredTaskId == fromTask.id ||
        hoveredTaskId == toTask.id;

    // Set up paint with enhanced styling
    final paint = Paint()
      ..color = isHighlighted
          ? AppColors.ganttDependencyHighlight
          : AppColors.ganttDependencyLine.withOpacity(0.7)
      ..strokeWidth = isHighlighted ? 3.0 : 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Add dashed effect for non-highlighted arrows
    if (!isHighlighted) {
      paint.strokeWidth = 1.5;
    }

    // Create path for the arrow
    final path = Path();

    // Add horizontal gap from task bar end
    final startX = fromEndX + GanttConstants.dependencyHorizontalGap;

    // Start point (end of predecessor task)
    path.moveTo(startX, fromY);

    // Determine routing based on relative positions
    if (toStartX > startX + GanttConstants.dependencyHorizontalGap * 2) {
      // Simple case: successor is to the right
      // Draw horizontal line, then corner, then to target
      final midX = startX + (toStartX - startX) / 2;

      if ((toY - fromY).abs() < rowHeight) {
        // Same row or adjacent - simple L-shape
        path.lineTo(toStartX - GanttConstants.dependencyHorizontalGap, fromY);
        path.lineTo(toStartX - GanttConstants.dependencyHorizontalGap, toY);
      } else {
        // Different rows - S-curve routing
        path.lineTo(midX, fromY);
        path.lineTo(midX, toY);
      }
    } else {
      // Complex case: successor is to the left or overlapping
      // Need to route around
      final routeX = math.max(fromEndX, toStartX) + GanttConstants.dayWidth;
      final routeY = toY > fromY
          ? math.max(fromY, toY) + rowHeight / 3
          : math.min(fromY, toY) - rowHeight / 3;

      path.lineTo(routeX, fromY);
      path.lineTo(routeX, routeY);
      path.lineTo(toStartX - GanttConstants.dependencyHorizontalGap * 2, routeY);
      path.lineTo(toStartX - GanttConstants.dependencyHorizontalGap * 2, toY);
    }

    // End point (start of successor task)
    path.lineTo(toStartX - GanttConstants.dependencyHorizontalGap, toY);

    // Draw the path
    canvas.drawPath(path, paint);

    // Draw arrow head at the end
    _drawArrowHead(
      canvas,
      Offset(toStartX - GanttConstants.dependencyHorizontalGap, toY),
      0, // Arrow pointing right
      paint..style = PaintingStyle.fill,
    );

    // Draw connection dots at start and end
    if (isHighlighted) {
      final dotPaint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(startX, fromY),
        3,
        dotPaint,
      );
    }
  }

  void _drawArrowHead(Canvas canvas, Offset tip, double angle, Paint paint) {
    final arrowSize = GanttConstants.dependencyArrowSize;

    final path = Path();

    // Arrow pointing right (angle = 0)
    path.moveTo(tip.dx, tip.dy);
    path.lineTo(
      tip.dx - arrowSize * math.cos(angle - 0.5),
      tip.dy - arrowSize * math.sin(angle - 0.5),
    );
    path.lineTo(
      tip.dx - arrowSize * math.cos(angle + 0.5),
      tip.dy - arrowSize * math.sin(angle + 0.5),
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  double _getTaskStartX(Task task) {
    final daysDiff = task.startDate.difference(startDate).inDays;
    return daysDiff * dayWidth;
  }

  double _getTaskEndX(Task task) {
    if (task.isMilestone) {
      return _getTaskStartX(task) + GanttConstants.milestoneSize;
    }
    final daysDiff = task.endDate.difference(startDate).inDays + 1;
    return daysDiff * dayWidth;
  }

  @override
  bool shouldRepaint(covariant DependencyPainter oldDelegate) {
    return tasks != oldDelegate.tasks ||
        selectedTaskId != oldDelegate.selectedTaskId ||
        hoveredTaskId != oldDelegate.hoveredTaskId ||
        dayWidth != oldDelegate.dayWidth;
  }
}

/// Custom painter for the today line
class TodayLinePainter extends CustomPainter {
  final DateTime startDate;
  final double dayWidth;
  final double height;

  TodayLinePainter({
    required this.startDate,
    required this.dayWidth,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (today.isBefore(startDate)) return;

    final daysDiff = today.difference(startDate).inDays;
    final x = daysDiff * dayWidth + dayWidth / 2;

    if (x < 0 || x > size.width) return;

    // Draw the vertical line
    final linePaint = Paint()
      ..color = AppColors.ganttTodayLine
      ..strokeWidth = GanttConstants.todayLineWidth
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(x, 0),
      Offset(x, height),
      linePaint,
    );

    // Draw the triangle marker at the top
    final markerPaint = Paint()
      ..color = AppColors.ganttTodayLine
      ..style = PaintingStyle.fill;

    final markerPath = Path();
    markerPath.moveTo(x - 6, 0);
    markerPath.lineTo(x + 6, 0);
    markerPath.lineTo(x, 8);
    markerPath.close();

    canvas.drawPath(markerPath, markerPaint);

    // Draw "今日" label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '今日',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.ganttTodayLine,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, 10),
    );
  }

  @override
  bool shouldRepaint(covariant TodayLinePainter oldDelegate) {
    return startDate != oldDelegate.startDate ||
        dayWidth != oldDelegate.dayWidth ||
        height != oldDelegate.height;
  }
}

/// Custom painter for weekend highlighting columns
class WeekendHighlightPainter extends CustomPainter {
  final DateTime startDate;
  final DateTime endDate;
  final double dayWidth;
  final double height;

  WeekendHighlightPainter({
    required this.startDate,
    required this.endDate,
    required this.dayWidth,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var currentDate = startDate;
    var dayIndex = 0;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      if (GanttConstants.isWeekend(currentDate)) {
        final rect = Rect.fromLTWH(
          dayIndex * dayWidth,
          0,
          dayWidth,
          height,
        );

        final paint = Paint()
          ..color = AppColors.ganttWeekend.withOpacity(GanttConstants.weekendOpacity)
          ..style = PaintingStyle.fill;

        canvas.drawRect(rect, paint);
      }

      currentDate = currentDate.add(const Duration(days: 1));
      dayIndex++;
    }
  }

  @override
  bool shouldRepaint(covariant WeekendHighlightPainter oldDelegate) {
    return startDate != oldDelegate.startDate ||
        endDate != oldDelegate.endDate ||
        dayWidth != oldDelegate.dayWidth ||
        height != oldDelegate.height;
  }
}

/// Custom painter for the grid lines
class GridPainter extends CustomPainter {
  final DateTime startDate;
  final DateTime endDate;
  final double dayWidth;
  final double rowHeight;
  final int rowCount;
  final bool showVerticalLines;
  final bool showHorizontalLines;

  GridPainter({
    required this.startDate,
    required this.endDate,
    required this.dayWidth,
    required this.rowHeight,
    required this.rowCount,
    this.showVerticalLines = true,
    this.showHorizontalLines = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ganttGridLine
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final totalDays = endDate.difference(startDate).inDays + 1;

    // Draw vertical lines (day separators)
    if (showVerticalLines) {
      for (var i = 0; i <= totalDays; i++) {
        final x = i * dayWidth;

        // Check if this is first day of month for thicker line
        final date = startDate.add(Duration(days: i));
        final isMonthStart = date.day == 1;

        if (isMonthStart) {
          paint.color = AppColors.ganttGridLine;
          paint.strokeWidth = 1.5;
        } else {
          paint.color = AppColors.ganttGridLine.withOpacity(0.5);
          paint.strokeWidth = 0.5;
        }

        canvas.drawLine(
          Offset(x, 0),
          Offset(x, rowCount * rowHeight),
          paint,
        );
      }
    }

    // Draw horizontal lines (row separators)
    if (showHorizontalLines) {
      paint.color = AppColors.ganttGridLine;
      paint.strokeWidth = 1;

      for (var i = 0; i <= rowCount; i++) {
        final y = i * rowHeight;
        canvas.drawLine(
          Offset(0, y),
          Offset(totalDays * dayWidth, y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return startDate != oldDelegate.startDate ||
        endDate != oldDelegate.endDate ||
        dayWidth != oldDelegate.dayWidth ||
        rowHeight != oldDelegate.rowHeight ||
        rowCount != oldDelegate.rowCount;
  }
}

/// Helper class for dependency path calculation
class DependencyPath {
  final Task fromTask;
  final Task toTask;
  final Path path;
  final bool isHighlighted;

  DependencyPath({
    required this.fromTask,
    required this.toTask,
    required this.path,
    this.isHighlighted = false,
  });
}
