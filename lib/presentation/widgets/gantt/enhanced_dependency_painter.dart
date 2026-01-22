/// Enhanced Dependency Painter
/// Supports all dependency types (FS/SS/FF/SF), critical path highlighting,
/// and delay impact visualization with beautiful Bezier curves

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../data/models/dependency_model.dart';
import 'gantt_constants.dart';

/// Enhanced dependency painter with full feature support
class EnhancedDependencyPainter extends CustomPainter {
  final List<Task> tasks;
  final List<TaskDependency> dependencies;
  final Map<String, int> taskIndexMap;
  final DateTime startDate;
  final double dayWidth;
  final double rowHeight;
  final String? selectedTaskId;
  final String? hoveredTaskId;
  final Set<String> criticalPathIds;
  final Set<String>? delayImpactedTaskIds;
  final bool showTypeLabels;

  EnhancedDependencyPainter({
    required this.tasks,
    required this.dependencies,
    required this.taskIndexMap,
    required this.startDate,
    this.dayWidth = GanttConstants.dayWidth,
    this.rowHeight = GanttConstants.rowHeight,
    this.selectedTaskId,
    this.hoveredTaskId,
    this.criticalPathIds = const {},
    this.delayImpactedTaskIds,
    this.showTypeLabels = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final taskMap = {for (var t in tasks) t.id: t};

    for (final dep in dependencies) {
      final fromTask = taskMap[dep.fromTaskId];
      final toTask = taskMap[dep.toTaskId];

      if (fromTask == null || toTask == null) continue;

      final fromIndex = taskIndexMap[dep.fromTaskId];
      final toIndex = taskIndexMap[dep.toTaskId];

      if (fromIndex == null || toIndex == null) continue;

      _drawDependencyArrow(
        canvas,
        fromTask,
        toTask,
        fromIndex,
        toIndex,
        dep,
      );
    }
  }

  void _drawDependencyArrow(
    Canvas canvas,
    Task fromTask,
    Task toTask,
    int fromIndex,
    int toIndex,
    TaskDependency dependency,
  ) {
    // Determine start and end points based on dependency type
    late double startX, endX;
    final startY = fromIndex * rowHeight + rowHeight / 2;
    final endY = toIndex * rowHeight + rowHeight / 2;

    switch (dependency.type) {
      case DependencyType.fs: // Finish-to-Start
        startX = _getTaskEndX(fromTask);
        endX = _getTaskStartX(toTask);
        break;
      case DependencyType.ss: // Start-to-Start
        startX = _getTaskStartX(fromTask);
        endX = _getTaskStartX(toTask);
        break;
      case DependencyType.ff: // Finish-to-Finish
        startX = _getTaskEndX(fromTask);
        endX = _getTaskEndX(toTask);
        break;
      case DependencyType.sf: // Start-to-Finish
        startX = _getTaskStartX(fromTask);
        endX = _getTaskEndX(toTask);
        break;
    }

    // Check highlighting conditions
    final isSelected = selectedTaskId == fromTask.id || selectedTaskId == toTask.id;
    final isHovered = hoveredTaskId == fromTask.id || hoveredTaskId == toTask.id;
    final isCritical = criticalPathIds.contains(fromTask.id) &&
        criticalPathIds.contains(toTask.id);
    final isDelayImpacted = delayImpactedTaskIds?.contains(toTask.id) ?? false;

    // Determine color and style
    Color lineColor;
    double strokeWidth;

    if (isDelayImpacted) {
      lineColor = AppColors.constructionRed;
      strokeWidth = 3.0;
    } else if (isCritical) {
      lineColor = AppColors.constructionRed.withOpacity(0.8);
      strokeWidth = 2.5;
    } else if (isSelected || isHovered) {
      lineColor = AppColors.primary;
      strokeWidth = 2.5;
    } else {
      lineColor = AppColors.ganttDependencyLine.withOpacity(0.6);
      strokeWidth = 1.5;
    }

    // Set up paint
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Create bezier curve path
    final path = _createBezierPath(
      startX: startX,
      startY: startY,
      endX: endX,
      endY: endY,
      dependency: dependency,
    );

    // Draw the path
    canvas.drawPath(path, paint);

    // Draw arrow head
    _drawArrowHead(
      canvas,
      endX,
      endY,
      dependency.type,
      paint..style = PaintingStyle.fill,
    );

    // Draw connection dots
    if (isSelected || isHovered || isCritical) {
      _drawConnectionDot(canvas, startX, startY, lineColor);
      _drawConnectionDot(canvas, endX, endY, lineColor);
    }

    // Draw type label
    if (showTypeLabels && (isSelected || isHovered)) {
      _drawTypeLabel(canvas, startX, startY, endX, endY, dependency);
    }

    // Draw lag indicator if lag exists
    if (dependency.lagDays != 0) {
      _drawLagIndicator(canvas, startX, startY, endX, endY, dependency);
    }
  }

  Path _createBezierPath({
    required double startX,
    required double startY,
    required double endX,
    required double endY,
    required TaskDependency dependency,
  }) {
    final path = Path();
    final gap = GanttConstants.dependencyHorizontalGap;

    // Add gap based on dependency type
    double adjustedStartX, adjustedEndX;

    switch (dependency.type) {
      case DependencyType.fs:
        adjustedStartX = startX + gap;
        adjustedEndX = endX - gap;
        break;
      case DependencyType.ss:
        adjustedStartX = startX - gap;
        adjustedEndX = endX - gap;
        break;
      case DependencyType.ff:
        adjustedStartX = startX + gap;
        adjustedEndX = endX + gap;
        break;
      case DependencyType.sf:
        adjustedStartX = startX - gap;
        adjustedEndX = endX + gap;
        break;
    }

    path.moveTo(adjustedStartX, startY);

    // Calculate control points for smooth bezier curve
    final dx = adjustedEndX - adjustedStartX;
    final dy = adjustedEndY - startY;
    final distance = math.sqrt(dx * dx + dy * dy);

    // Adaptive curvature based on distance
    final curvature = math.min(distance * 0.3, 50.0);

    if ((adjustedEndX - adjustedStartX).abs() < gap * 3 || dx < 0) {
      // Need to route around (complex path)
      final midY = startY + (endY - startY) / 2;
      final routeX = dependency.type == DependencyType.ss ||
              dependency.type == DependencyType.sf
          ? math.min(adjustedStartX, adjustedEndX) - gap * 2
          : math.max(adjustedStartX, adjustedEndX) + gap * 2;

      // Use quadratic bezier for smoother corners
      path.quadraticBezierTo(
        adjustedStartX,
        midY,
        routeX,
        midY,
      );
      path.quadraticBezierTo(
        routeX,
        endY,
        adjustedEndX,
        endY,
      );
    } else {
      // Simple bezier curve
      final cp1x = adjustedStartX + curvature;
      final cp2x = adjustedEndX - curvature;

      path.cubicTo(
        cp1x,
        startY,
        cp2x,
        endY,
        adjustedEndX,
        endY,
      );
    }

    return path;
  }

  double get adjustedEndY => 0; // Will be set in _createBezierPath scope

  void _drawArrowHead(
    Canvas canvas,
    double x,
    double y,
    DependencyType type,
    Paint paint,
  ) {
    final size = GanttConstants.dependencyArrowSize;

    // Arrow direction based on type
    double direction;
    switch (type) {
      case DependencyType.fs:
      case DependencyType.ss:
        direction = 0; // Right (pointing to start of successor)
        break;
      case DependencyType.ff:
      case DependencyType.sf:
        direction = math.pi; // Left (pointing to end of successor)
        break;
    }

    final path = Path();
    path.moveTo(x, y);
    path.lineTo(
      x - size * math.cos(direction - 0.4),
      y - size * math.sin(direction - 0.4),
    );
    path.lineTo(
      x - size * math.cos(direction + 0.4),
      y - size * math.sin(direction + 0.4),
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawConnectionDot(Canvas canvas, double x, double y, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), 4, paint);

    // White inner dot
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), 2, innerPaint);
  }

  void _drawTypeLabel(
    Canvas canvas,
    double startX,
    double startY,
    double endX,
    double endY,
    TaskDependency dependency,
  ) {
    final midX = (startX + endX) / 2;
    final midY = (startY + endY) / 2;

    // Draw background
    final bgPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const labelWidth = 28.0;
    const labelHeight = 16.0;

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(midX, midY),
        width: labelWidth,
        height: labelHeight,
      ),
      const Radius.circular(4),
    );

    canvas.drawRRect(rect, bgPaint);
    canvas.drawRRect(rect, borderPaint);

    // Draw text
    final textPainter = TextPainter(
      text: TextSpan(
        text: dependency.type.shortLabel,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(midX - textPainter.width / 2, midY - textPainter.height / 2),
    );
  }

  void _drawLagIndicator(
    Canvas canvas,
    double startX,
    double startY,
    double endX,
    double endY,
    TaskDependency dependency,
  ) {
    if (dependency.lagDays == 0) return;

    final midX = (startX + endX) / 2;
    final midY = (startY + endY) / 2 + 12;

    final text = dependency.lagDays > 0
        ? '+${dependency.lagDays}日'
        : '${dependency.lagDays}日';

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: dependency.lagDays > 0
              ? AppColors.constructionRed
              : AppColors.constructionGreen,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(midX - textPainter.width / 2, midY),
    );
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
  bool shouldRepaint(covariant EnhancedDependencyPainter oldDelegate) {
    return tasks != oldDelegate.tasks ||
        dependencies != oldDelegate.dependencies ||
        selectedTaskId != oldDelegate.selectedTaskId ||
        hoveredTaskId != oldDelegate.hoveredTaskId ||
        criticalPathIds != oldDelegate.criticalPathIds ||
        delayImpactedTaskIds != oldDelegate.delayImpactedTaskIds ||
        dayWidth != oldDelegate.dayWidth;
  }
}

/// Critical path highlight overlay
class CriticalPathOverlay extends CustomPainter {
  final List<Task> tasks;
  final Set<String> criticalPathIds;
  final Map<String, int> taskIndexMap;
  final DateTime startDate;
  final double dayWidth;
  final double rowHeight;

  CriticalPathOverlay({
    required this.tasks,
    required this.criticalPathIds,
    required this.taskIndexMap,
    required this.startDate,
    this.dayWidth = GanttConstants.dayWidth,
    this.rowHeight = GanttConstants.rowHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (criticalPathIds.isEmpty) return;

    for (final task in tasks) {
      if (!criticalPathIds.contains(task.id)) continue;

      final index = taskIndexMap[task.id];
      if (index == null) continue;

      final left = _getTaskStartX(task);
      final width = _getTaskEndX(task) - left;
      final top = index * rowHeight + 4;
      final height = rowHeight - 8;

      // Draw glow effect
      final glowPaint = Paint()
        ..color = AppColors.constructionRed.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left - 4, top - 4, width + 8, height + 8),
        const Radius.circular(8),
      );

      canvas.drawRRect(rect, glowPaint);
    }
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
  bool shouldRepaint(covariant CriticalPathOverlay oldDelegate) {
    return criticalPathIds != oldDelegate.criticalPathIds ||
        tasks != oldDelegate.tasks ||
        dayWidth != oldDelegate.dayWidth;
  }
}

/// Delay impact visualization overlay
class DelayImpactOverlay extends CustomPainter {
  final List<Task> tasks;
  final Map<String, int> taskDelayMap;
  final Map<String, int> taskIndexMap;
  final DateTime startDate;
  final double dayWidth;
  final double rowHeight;

  DelayImpactOverlay({
    required this.tasks,
    required this.taskDelayMap,
    required this.taskIndexMap,
    required this.startDate,
    this.dayWidth = GanttConstants.dayWidth,
    this.rowHeight = GanttConstants.rowHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (taskDelayMap.isEmpty) return;

    final taskMap = {for (var t in tasks) t.id: t};

    for (final entry in taskDelayMap.entries) {
      final task = taskMap[entry.key];
      if (task == null) continue;

      final index = taskIndexMap[entry.key];
      if (index == null) continue;

      final delayDays = entry.value;
      final endX = _getTaskEndX(task);
      final delayWidth = delayDays * dayWidth;
      final y = index * rowHeight + rowHeight / 2;

      // Draw delay extension (dashed)
      final delayPaint = Paint()
        ..color = AppColors.constructionRed.withOpacity(0.3)
        ..strokeWidth = rowHeight * 0.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Draw as dashed pattern
      _drawDashedLine(
        canvas,
        Offset(endX, y),
        Offset(endX + delayWidth, y),
        delayPaint,
      );

      // Draw delay label
      final textPainter = TextPainter(
        text: TextSpan(
          text: '+$delayDays日',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.constructionRed,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(endX + delayWidth / 2 - textPainter.width / 2, y - 20),
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 8.0;
    const gapLength = 4.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final unitX = dx / distance;
    final unitY = dy / distance;

    var currentX = start.dx;
    var currentY = start.dy;
    var drawn = 0.0;

    while (drawn < distance) {
      final nextDrawn = math.min(drawn + dashLength, distance);
      canvas.drawLine(
        Offset(currentX, currentY),
        Offset(
          start.dx + unitX * nextDrawn,
          start.dy + unitY * nextDrawn,
        ),
        paint,
      );

      drawn = nextDrawn + gapLength;
      currentX = start.dx + unitX * drawn;
      currentY = start.dy + unitY * drawn;
    }
  }

  double _getTaskEndX(Task task) {
    if (task.isMilestone) {
      final daysDiff = task.startDate.difference(startDate).inDays;
      return daysDiff * dayWidth + GanttConstants.milestoneSize;
    }
    final daysDiff = task.endDate.difference(startDate).inDays + 1;
    return daysDiff * dayWidth;
  }

  @override
  bool shouldRepaint(covariant DelayImpactOverlay oldDelegate) {
    return taskDelayMap != oldDelegate.taskDelayMap ||
        tasks != oldDelegate.tasks ||
        dayWidth != oldDelegate.dayWidth;
  }
}
