/// QR Attendance Tracking Widgets
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/attendance_model.dart';

class AttendanceList extends StatelessWidget {
  final List<WorkerDailyAttendance> workers;

  const AttendanceList({super.key, required this.workers});

  @override
  Widget build(BuildContext context) {
    final onSite = workers.where((w) => w.isCurrentlyOnSite).toList();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.people, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('現場内作業員 (${onSite.length}名)', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          ...onSite.map((w) => _WorkerTile(worker: w)),
          if (onSite.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('現在、現場内に作業員はいません', style: TextStyle(color: AppColors.textSecondary))),
            ),
        ],
      ),
    );
  }
}

class _WorkerTile extends StatelessWidget {
  final WorkerDailyAttendance worker;

  const _WorkerTile({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Text(worker.workerName[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(worker.workerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(worker.company, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(worker.workedHoursDisplay, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              if (worker.entryTime != null)
                Text('${worker.entryTime!.hour}:${worker.entryTime!.minute.toString().padLeft(2, '0')}〜', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class AttendanceSummaryCard extends StatelessWidget {
  final int totalWorkers;
  final int currentOnSite;
  final int exitedToday;

  const AttendanceSummaryCard({super.key, required this.totalWorkers, required this.currentOnSite, required this.exitedToday});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.industrialGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: '登録作業員', value: '$totalWorkers', icon: Icons.badge),
          _StatItem(label: '現場内', value: '$currentOnSite', icon: Icons.location_on, highlight: true),
          _StatItem(label: '本日退場', value: '$exitedToday', icon: Icons.exit_to_app),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _StatItem({required this.label, required this.value, required this.icon, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: highlight ? Colors.white : Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: Colors.white, fontSize: highlight ? 28 : 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
      ],
    );
  }
}
