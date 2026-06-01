import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/services/safety_service.dart';

class SafetyPatrolScreen extends StatelessWidget {
  final String projectId;
  final String projectName;
  final SafetyService safetyService;

  const SafetyPatrolScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.safetyService,
  });

  @override
  Widget build(BuildContext context) {
    final records = safetyService.getPatrolRecordsByProject(projectId);
    final dateFormat = DateFormat('M/d');

    return Scaffold(
      appBar: AppBar(
        title: Text('安全パトロール - $projectName'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: records.isEmpty
          ? const Center(child: Text('安全パトロール記録はありません'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final record = records[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.fact_check),
                    title: Text(record.patrollerName),
                    subtitle: Text(
                      '適合率 ${record.conformanceRate.toStringAsFixed(0)}% / 不適合 ${record.nonConformCount}件',
                    ),
                    trailing: Text(dateFormat.format(record.patrolDate)),
                  ),
                );
              },
            ),
    );
  }
}
