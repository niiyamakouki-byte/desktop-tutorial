import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/services/batch_notification_service.dart';

class NotificationCenterDialog extends StatefulWidget {
  final BatchNotificationService service;
  final String projectId;
  final List<NotificationRecipient> recipients;

  const NotificationCenterDialog({
    super.key,
    required this.service,
    required this.projectId,
    required this.recipients,
  });

  static Future<void> show({
    required BuildContext context,
    required BatchNotificationService service,
    required String projectId,
    required List<NotificationRecipient> recipients,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => NotificationCenterDialog(
        service: service,
        projectId: projectId,
        recipients: recipients,
      ),
    );
  }

  @override
  State<NotificationCenterDialog> createState() => _NotificationCenterDialogState();
}

class _NotificationCenterDialogState extends State<NotificationCenterDialog> {
  final _messageController = TextEditingController();
  BatchNotificationType _type = BatchNotificationType.scheduleChange;
  List<NotificationJob> _jobs = [];
  StreamSubscription<List<NotificationJob>>? _jobsSubscription;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _jobs = widget.service.jobs;
    _jobsSubscription = widget.service.jobsStream.listen((jobs) {
      if (!mounted) return;
      setState(() => _jobs = jobs);
    });
  }

  @override
  void dispose() {
    _jobsSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || widget.recipients.isEmpty) return;

    setState(() => _isSending = true);
    await widget.service.createJob(
      type: _type,
      projectId: widget.projectId,
      message: message,
      recipients: widget.recipients,
    );
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 820,
        height: 620,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    '通知センター',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<BatchNotificationType>(
                      value: _type,
                      decoration: const InputDecoration(labelText: '通知種別'),
                      items: BatchNotificationType.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _type = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: '通知メッセージ',
                        hintText: '例: 明日のコンクリート打設は8:00集合です',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSending ? null : _send,
                    icon: _isSending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: const Text('送信'),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Text(
                '送信先: ${widget.recipients.length}名',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _jobs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final job = _jobs[_jobs.length - 1 - index];
                  final progress =
                      job.recipients.isEmpty ? 0 : job.processedCount / job.recipients.length;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              job.type.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _statusColor(job.status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _statusLabel(job.status),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _statusColor(job.status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${job.successCount}/${job.recipients.length}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(job.message, style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: progress),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(JobStatus status) {
    switch (status) {
      case JobStatus.completed:
        return AppColors.success;
      case JobStatus.failed:
      case JobStatus.partiallyFailed:
        return AppColors.error;
      case JobStatus.processing:
        return AppColors.info;
      case JobStatus.cancelled:
        return AppColors.warning;
      case JobStatus.pending:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return '待機中';
      case JobStatus.processing:
        return '送信中';
      case JobStatus.completed:
        return '完了';
      case JobStatus.partiallyFailed:
        return '一部失敗';
      case JobStatus.failed:
        return '失敗';
      case JobStatus.cancelled:
        return 'キャンセル';
    }
  }
}
