import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/safety_models.dart';
import '../../../data/services/safety_service.dart';

class NearMissScreen extends StatelessWidget {
  final String projectId;
  final String projectName;
  final SafetyService safetyService;

  const NearMissScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.safetyService,
  });

  @override
  Widget build(BuildContext context) {
    final reports = safetyService.getNearMissReportsByProject(projectId);
    final dateFormat = DateFormat('M/d HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('ヒヤリハット - $projectName'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: reports.isEmpty
          ? const Center(child: Text('ヒヤリハット報告はありません'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final report = reports[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.report_problem,
                      color: _severityColor(report.severity),
                    ),
                    title: Text(report.description),
                    subtitle: Text(
                      '${report.location} / ${report.category.displayName} / ${report.status.displayName}',
                    ),
                    trailing: Text(dateFormat.format(report.occurredAt)),
                  ),
                );
              },
            ),
    );
  }

  Color _severityColor(NearMissSeverity severity) {
    switch (severity) {
      case NearMissSeverity.high:
        return Colors.red;
      case NearMissSeverity.medium:
        return Colors.orange;
      case NearMissSeverity.low:
        return Colors.amber;
    }
  }
}
