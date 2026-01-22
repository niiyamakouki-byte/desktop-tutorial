/// QR Code Attendance Widgets
/// QRコード入退場管理ウィジェット

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/services/attendance_service.dart';

/// QR Code Display Widget (simulated)
class QRCodeDisplayWidget extends StatelessWidget {
  final String projectId;
  final String projectName;
  final double size;

  const QRCodeDisplayWidget({
    super.key,
    required this.projectId,
    required this.projectName,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Simulated QR Code pattern
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomPaint(
                painter: _QRCodePainter(projectId),
                size: Size(size - 64, size - 64),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            projectName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QRCodePainter extends CustomPainter {
  final String data;

  _QRCodePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final cellSize = size.width / 21;
    final random = data.hashCode;

    // Draw position detection patterns (corners)
    _drawPositionPattern(canvas, paint, 0, 0, cellSize);
    _drawPositionPattern(canvas, paint, size.width - 7 * cellSize, 0, cellSize);
    _drawPositionPattern(canvas, paint, 0, size.height - 7 * cellSize, cellSize);

    // Draw random data pattern
    for (int i = 0; i < 21; i++) {
      for (int j = 0; j < 21; j++) {
        if (_isPositionPattern(i, j)) continue;

        final shouldFill = ((random + i * 31 + j * 17) % 3) == 0;
        if (shouldFill) {
          canvas.drawRect(
            Rect.fromLTWH(i * cellSize, j * cellSize, cellSize * 0.9, cellSize * 0.9),
            paint,
          );
        }
      }
    }
  }

  void _drawPositionPattern(Canvas canvas, Paint paint, double x, double y, double cellSize) {
    // Outer square
    canvas.drawRect(Rect.fromLTWH(x, y, 7 * cellSize, 7 * cellSize), paint);

    // White middle
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(x + cellSize, y + cellSize, 5 * cellSize, 5 * cellSize), whitePaint);

    // Inner square
    canvas.drawRect(Rect.fromLTWH(x + 2 * cellSize, y + 2 * cellSize, 3 * cellSize, 3 * cellSize), paint);
  }

  bool _isPositionPattern(int i, int j) {
    // Top-left
    if (i < 8 && j < 8) return true;
    // Top-right
    if (i > 12 && j < 8) return true;
    // Bottom-left
    if (i < 8 && j > 12) return true;
    return false;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Attendance List Widget
class AttendanceListWidget extends StatelessWidget {
  final List<WorkerDailyAttendance> workers;
  final Function(WorkerDailyAttendance)? onWorkerTap;

  const AttendanceListWidget({
    super.key,
    required this.workers,
    this.onWorkerTap,
  });

  @override
  Widget build(BuildContext context) {
    if (workers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              '現在、現場にいる作業員はいません',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: workers.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final worker = workers[index];
        return WorkerAttendanceCard(
          worker: worker,
          onTap: () => onWorkerTap?.call(worker),
        );
      },
    );
  }
}

/// Worker Attendance Card
class WorkerAttendanceCard extends StatelessWidget {
  final WorkerDailyAttendance worker;
  final VoidCallback? onTap;

  const WorkerAttendanceCard({
    super.key,
    required this.worker,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  worker.workerName.isNotEmpty ? worker.workerName[0] : '?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.workerName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      worker.company,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Status and time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: worker.isCurrentlyOnSite
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.textTertiary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          worker.isCurrentlyOnSite ? Icons.check_circle : Icons.logout,
                          size: 14,
                          color: worker.isCurrentlyOnSite ? AppColors.success : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          worker.isCurrentlyOnSite ? '現場内' : '退場済',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: worker.isCurrentlyOnSite ? AppColors.success : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (worker.entryTime != null)
                    Text(
                      '入場: ${_formatTime(worker.entryTime!)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  Text(
                    worker.workedHoursDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Attendance Summary Card
class AttendanceSummaryCard extends StatelessWidget {
  final int totalWorkers;
  final int currentOnSite;
  final Map<String, int> workersByCompany;

  const AttendanceSummaryCard({
    super.key,
    required this.totalWorkers,
    required this.currentOnSite,
    required this.workersByCompany,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              const Text(
                '本日の入場状況',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('入場者数', '$totalWorkers名', Icons.login),
              const SizedBox(width: 24),
              _buildStatItem('現場内', '$currentOnSite名', Icons.location_on),
            ],
          ),
          if (workersByCompany.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: workersByCompany.entries.map((e) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      '${e.value}',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                  label: Text(e.key, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.surface,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
