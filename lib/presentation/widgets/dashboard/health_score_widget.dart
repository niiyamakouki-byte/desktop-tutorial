/// Project Health Score Widget
/// プロジェクト健全性スコアの視覚化ウィジェット

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/project_health_model.dart';

/// Circular gauge displaying project health score
class HealthScoreGauge extends StatefulWidget {
  final double score;
  final HealthStatus status;
  final double size;
  final bool showBreakdown;
  final double? scheduleScore;
  final double? costScore;
  final double? resourceScore;
  final double? riskScore;

  const HealthScoreGauge({
    super.key,
    required this.score,
    required this.status,
    this.size = 200,
    this.showBreakdown = false,
    this.scheduleScore,
    this.costScore,
    this.resourceScore,
    this.riskScore,
  });

  @override
  State<HealthScoreGauge> createState() => _HealthScoreGaugeState();
}

class _HealthScoreGaugeState extends State<HealthScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(HealthScoreGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.score,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getStatusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.excellent:
        return AppColors.constructionGreen;
      case HealthStatus.good:
        return AppColors.primary;
      case HealthStatus.warning:
        return AppColors.safetyYellow;
      case HealthStatus.critical:
        return AppColors.industrialOrange;
      case HealthStatus.emergency:
        return AppColors.constructionRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _HealthGaugePainter(
                  score: _animation.value,
                  color: _getStatusColor(widget.status),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _animation.value.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: widget.size * 0.25,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(widget.status),
                        ),
                      ),
                      Text(
                        widget.status.label,
                        style: TextStyle(
                          fontSize: widget.size * 0.08,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.showBreakdown) ...[
          const SizedBox(height: 16),
          _buildBreakdown(),
        ],
      ],
    );
  }

  Widget _buildBreakdown() {
    return Column(
      children: [
        _buildBreakdownRow('工程', widget.scheduleScore ?? 0, 0.40),
        const SizedBox(height: 8),
        _buildBreakdownRow('コスト', widget.costScore ?? 0, 0.25),
        const SizedBox(height: 8),
        _buildBreakdownRow('リソース', widget.resourceScore ?? 0, 0.15),
        const SizedBox(height: 8),
        _buildBreakdownRow('リスク', widget.riskScore ?? 0, 0.20),
      ],
    );
  }

  Widget _buildBreakdownRow(String label, double score, double weight) {
    final color = _getScoreColor(score);
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: score / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 35,
          child: Text(
            '${score.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(
            '(${(weight * 100).toStringAsFixed(0)}%)',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppColors.constructionGreen;
    if (score >= 60) return AppColors.primary;
    if (score >= 40) return AppColors.safetyYellow;
    if (score >= 20) return AppColors.industrialOrange;
    return AppColors.constructionRed;
  }
}

class _HealthGaugePainter extends CustomPainter {
  final double score;
  final Color color;

  _HealthGaugePainter({
    required this.score,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background arc
    final bgPaint = Paint()
      ..color = AppColors.surfaceVariant
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5,
      false,
      bgPaint,
    );

    // Score arc
    final scorePaint = Paint()
      ..color = color
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100) * math.pi * 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      sweepAngle,
      false,
      scorePaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      sweepAngle,
      false,
      glowPaint,
    );

    // Tick marks
    _drawTickMarks(canvas, center, radius);
  }

  void _drawTickMarks(Canvas canvas, Offset center, double radius) {
    final tickPaint = Paint()
      ..color = AppColors.textTertiary
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 10; i++) {
      final angle = -math.pi * 0.75 + (i / 10) * math.pi * 1.5;
      final outerRadius = radius + 16;
      final innerRadius = i % 5 == 0 ? radius + 10 : radius + 13;

      final outerPoint = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );
      final innerPoint = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );

      canvas.drawLine(innerPoint, outerPoint, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HealthGaugePainter oldDelegate) {
    return score != oldDelegate.score || color != oldDelegate.color;
  }
}

/// Compact health score card
class HealthScoreCard extends StatelessWidget {
  final ProjectHealthScore healthScore;
  final VoidCallback? onTap;

  const HealthScoreCard({
    super.key,
    required this.healthScore,
    this.onTap,
  });

  Color _getStatusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.excellent:
        return AppColors.constructionGreen;
      case HealthStatus.good:
        return AppColors.primary;
      case HealthStatus.warning:
        return AppColors.safetyYellow;
      case HealthStatus.critical:
        return AppColors.industrialOrange;
      case HealthStatus.emergency:
        return AppColors.constructionRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(healthScore.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface,
                statusColor.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(healthScore.status),
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'プロジェクト健全性',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              healthScore.overallScore.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            Text(
                              '/100',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                healthScore.status.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Key metrics row
              Row(
                children: [
                  _buildMetric(
                    '遅延タスク',
                    healthScore.delayedTaskCount.toString(),
                    healthScore.delayedTaskCount > 0
                        ? AppColors.constructionRed
                        : AppColors.constructionGreen,
                  ),
                  _buildMetric(
                    '遅延日数',
                    '${healthScore.totalDelayDays}日',
                    healthScore.totalDelayDays > 0
                        ? AppColors.industrialOrange
                        : AppColors.constructionGreen,
                  ),
                  _buildMetric(
                    'クリティカル進捗',
                    '${healthScore.criticalPathProgress.toStringAsFixed(0)}%',
                    AppColors.primary,
                  ),
                  _buildMetric(
                    '推定遅延コスト',
                    _formatCost(healthScore.estimatedDelayCost),
                    healthScore.estimatedDelayCost > 0
                        ? AppColors.constructionRed
                        : AppColors.constructionGreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatCost(double cost) {
    if (cost >= 1000000) {
      return '¥${(cost / 10000).toStringAsFixed(0)}万';
    } else if (cost >= 1000) {
      return '¥${(cost / 1000).toStringAsFixed(0)}千';
    }
    return '¥${cost.toStringAsFixed(0)}';
  }

  IconData _getStatusIcon(HealthStatus status) {
    switch (status) {
      case HealthStatus.excellent:
        return Icons.sentiment_very_satisfied;
      case HealthStatus.good:
        return Icons.sentiment_satisfied;
      case HealthStatus.warning:
        return Icons.sentiment_neutral;
      case HealthStatus.critical:
        return Icons.sentiment_dissatisfied;
      case HealthStatus.emergency:
        return Icons.sentiment_very_dissatisfied;
    }
  }
}
