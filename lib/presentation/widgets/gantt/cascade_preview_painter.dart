/// Cascade Preview Painter
/// カスケードプレビュー用のカスタムペインター
///
/// ドラッグ中に後続タスクのゴースト表示を行う

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/task_model.dart';
import '../../../data/services/drag_cascade_preview_service.dart';
import 'gantt_constants.dart';

/// カスケードプレビューペインター
class CascadePreviewPainter extends CustomPainter {
  final DragCascadePreviewResult preview;
  final Map<String, int> taskIndexMap;
  final DateTime startDate;
  final double dayWidth;
  final double rowHeight;
  final Map<String, Task> taskMap;

  CascadePreviewPainter({
    required this.preview,
    required this.taskIndexMap,
    required this.startDate,
    required this.dayWidth,
    required this.rowHeight,
    required this.taskMap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final previewItem in preview.previews) {
      final taskIndex = taskIndexMap[previewItem.taskId];
      if (taskIndex == null) continue;

      final task = taskMap[previewItem.taskId];
      if (task == null) continue;

      final top = taskIndex * rowHeight +
          (rowHeight - GanttConstants.taskBarHeight) / 2;

      if (previewItem.isDragged) {
        // ドラッグ対象：新しい位置を強調表示
        _drawDraggedPreview(canvas, previewItem, task, top);
      } else if (previewItem.isCascaded && previewItem.hasChange) {
        // カスケード対象：ゴースト表示
        _drawCascadedPreview(canvas, previewItem, task, top);
      }
    }

    // 影響範囲のハイライト
    _drawAffectedHighlight(canvas, size);
  }

  /// ドラッグ対象タスクのプレビュー描画
  void _drawDraggedPreview(
    Canvas canvas,
    DragTaskPreview previewItem,
    Task task,
    double top,
  ) {
    // 元の位置（薄いゴースト）
    final originalLeft =
        previewItem.originalStart.difference(startDate).inDays * dayWidth;
    final originalWidth = task.durationDays * dayWidth;

    final ghostPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final ghostBorderPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final ghostRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        originalLeft,
        top,
        originalWidth,
        GanttConstants.taskBarHeight,
      ),
      Radius.circular(GanttConstants.taskBarRadius),
    );

    canvas.drawRRect(ghostRect, ghostPaint);
    canvas.drawRRect(ghostRect, ghostBorderPaint);

    // 点線で接続
    _drawConnectionLine(
      canvas,
      Offset(originalLeft + originalWidth / 2, top + GanttConstants.taskBarHeight / 2),
      Offset(
        previewItem.previewStart.difference(startDate).inDays * dayWidth +
            originalWidth / 2,
        top + GanttConstants.taskBarHeight / 2,
      ),
      AppColors.primary,
    );
  }

  /// カスケード対象タスクのプレビュー描画
  void _drawCascadedPreview(
    Canvas canvas,
    DragTaskPreview previewItem,
    Task task,
    double top,
  ) {
    final taskWidth = task.durationDays * dayWidth;

    // 元の位置（薄いゴースト）
    final originalLeft =
        previewItem.originalStart.difference(startDate).inDays * dayWidth;

    final ghostPaint = Paint()
      ..color = AppColors.warning.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final ghostBorderPaint = Paint()
      ..color = AppColors.warning.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    final ghostRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        originalLeft,
        top,
        taskWidth,
        GanttConstants.taskBarHeight,
      ),
      Radius.circular(GanttConstants.taskBarRadius),
    );

    canvas.drawRRect(ghostRect, ghostPaint);
    _drawDashedRRect(canvas, ghostRect, ghostBorderPaint);

    // 新しい位置（プレビュー）
    final previewLeft =
        previewItem.previewStart.difference(startDate).inDays * dayWidth;

    final previewPaint = Paint()
      ..color = AppColors.warning.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final previewBorderPaint = Paint()
      ..color = AppColors.warning
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final previewRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        previewLeft,
        top,
        taskWidth,
        GanttConstants.taskBarHeight,
      ),
      Radius.circular(GanttConstants.taskBarRadius),
    );

    canvas.drawRRect(previewRect, previewPaint);
    canvas.drawRRect(previewRect, previewBorderPaint);

    // 移動量を表示
    final deltaDays = previewItem.deltaDays;
    if (deltaDays != 0) {
      _drawDeltaLabel(
        canvas,
        previewLeft + taskWidth / 2,
        top - 12,
        '+$deltaDays日',
      );
    }

    // 矢印で接続
    _drawArrow(
      canvas,
      Offset(originalLeft + taskWidth, top + GanttConstants.taskBarHeight / 2),
      Offset(previewLeft, top + GanttConstants.taskBarHeight / 2),
      AppColors.warning,
    );
  }

  /// 点線の接続線を描画
  void _drawConnectionLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
  ) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(start.dx, start.dy);

    const dashWidth = 4.0;
    const dashSpace = 3.0;

    final distance = (end - start).distance;
    final direction = (end - start) / distance;

    double drawn = 0;
    bool draw = true;

    while (drawn < distance) {
      final segmentLength = draw ? dashWidth : dashSpace;
      final segmentEnd = drawn + segmentLength > distance
          ? distance
          : drawn + segmentLength;

      if (draw) {
        canvas.drawLine(
          start + direction * drawn,
          start + direction * segmentEnd,
          paint,
        );
      }

      drawn = segmentEnd;
      draw = !draw;
    }
  }

  /// 矢印を描画
  void _drawArrow(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
  ) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 矢印本体
    canvas.drawLine(start, end, paint);

    // 矢印の頭
    const arrowSize = 8.0;
    final direction = (end - start).distance > 0
        ? (end - start) / (end - start).distance
        : Offset.zero;
    final perpendicular = Offset(-direction.dy, direction.dx);

    final arrowPath = Path();
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(
      end.dx - arrowSize * direction.dx + arrowSize * 0.5 * perpendicular.dx,
      end.dy - arrowSize * direction.dy + arrowSize * 0.5 * perpendicular.dy,
    );
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(
      end.dx - arrowSize * direction.dx - arrowSize * 0.5 * perpendicular.dx,
      end.dy - arrowSize * direction.dy - arrowSize * 0.5 * perpendicular.dy,
    );

    canvas.drawPath(arrowPath, paint);
  }

  /// 点線のRRectを描画
  void _drawDashedRRect(Canvas canvas, RRect rrect, Paint paint) {
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    const dashWidth = 5.0;
    const dashSpace = 3.0;

    for (final metric in metrics) {
      double distance = 0;
      bool draw = true;

      while (distance < metric.length) {
        final segmentLength = draw ? dashWidth : dashSpace;
        final end = (distance + segmentLength).clamp(0.0, metric.length);

        if (draw) {
          final extractPath = metric.extractPath(distance, end);
          canvas.drawPath(extractPath, paint);
        }

        distance = end;
        draw = !draw;
      }
    }
  }

  /// 移動日数ラベルを描画
  void _drawDeltaLabel(Canvas canvas, double x, double y, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final padding = 4.0;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, y),
        width: textPainter.width + padding * 2,
        height: textPainter.height + padding,
      ),
      const Radius.circular(4),
    );

    final bgPaint = Paint()..color = AppColors.warning;
    canvas.drawRRect(bgRect, bgPaint);

    textPainter.paint(
      canvas,
      Offset(
        x - textPainter.width / 2,
        y - textPainter.height / 2,
      ),
    );
  }

  /// 影響範囲のハイライト
  void _drawAffectedHighlight(Canvas canvas, Size size) {
    final affectedIndices = <int>[];
    for (final previewItem in preview.previews) {
      if (previewItem.isCascaded && previewItem.hasChange) {
        final index = taskIndexMap[previewItem.taskId];
        if (index != null) {
          affectedIndices.add(index);
        }
      }
    }

    if (affectedIndices.isEmpty) return;

    final minIndex = affectedIndices.reduce((a, b) => a < b ? a : b);
    final maxIndex = affectedIndices.reduce((a, b) => a > b ? a : b);

    // 左側にハイライトバーを描画
    final highlightPaint = Paint()
      ..color = AppColors.warning.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final highlightRect = Rect.fromLTWH(
      0,
      minIndex * rowHeight,
      size.width,
      (maxIndex - minIndex + 1) * rowHeight,
    );

    canvas.drawRect(highlightRect, highlightPaint);

    // 左端にアクセントバー
    final accentPaint = Paint()
      ..color = AppColors.warning.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final accentRect = Rect.fromLTWH(
      0,
      minIndex * rowHeight,
      3,
      (maxIndex - minIndex + 1) * rowHeight,
    );

    canvas.drawRect(accentRect, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CascadePreviewPainter oldDelegate) {
    return preview != oldDelegate.preview ||
        taskIndexMap != oldDelegate.taskIndexMap ||
        startDate != oldDelegate.startDate ||
        dayWidth != oldDelegate.dayWidth;
  }
}

/// カスケード影響サマリーオーバーレイ
class CascadePreviewOverlay extends StatelessWidget {
  final DragCascadePreviewResult preview;
  final VoidCallback? onCancel;

  const CascadePreviewOverlay({
    super.key,
    required this.preview,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (preview.cascadeCount == 0) return const SizedBox.shrink();

    return Positioned(
      right: 16,
      top: 60,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.warning.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.warning.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.link,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 6),
                Text(
                  '連動移動プレビュー',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${preview.cascadeCount}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'タスクが影響',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ドロップで確定',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
