import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/services/safety_service.dart';

class KYActivityScreen extends StatelessWidget {
  final String projectId;
  final String projectName;
  final SafetyService safetyService;

  const KYActivityScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.safetyService,
  });

  @override
  Widget build(BuildContext context) {
    final records = safetyService.getKYRecordsByProject(projectId);
    final dateFormat = DateFormat('M/d');

    return Scaffold(
      appBar: AppBar(
        title: Text('KY活動 - $projectName'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: records.isEmpty
          ? const Center(child: Text('KY活動記録はありません'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final record = records[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.health_and_safety),
                    title: Text(record.workContent),
                    subtitle: Text([
                      if (record.location != null) record.location!,
                      '危険予測 ${record.hazardItems.length}件',
                      '参加 ${record.participantIds.length}名',
                    ].join(' / ')),
                    trailing: Text(dateFormat.format(record.date)),
                  ),
                );
              },
            ),
    );
  }
}
