import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import '../../../data/services/change_history_service.dart';
import '../chat/user_avatar.dart';

/// 変更履歴パネル
///
/// タスクまたはプロジェクトの変更履歴をタイムライン形式で表示
/// 誰がいつ何を変えたかを視覚的に確認できる
class ChangeHistoryPanel extends StatefulWidget {
  /// 表示対象のタスクID（nullの場合はプロジェクト全体）
  final String? taskId;

  /// 表示対象のプロジェクトID
  final String projectId;

  /// タスク名（ヘッダー表示用）
  final String? taskName;

  /// 閉じるコールバック
  final VoidCallback? onClose;

  /// 最大表示件数
  final int maxItems;

  const ChangeHistoryPanel({
    super.key,
    this.taskId,
    required this.projectId,
    this.taskName,
    this.onClose,
    this.maxItems = 50,
  });

  @override
  State<ChangeHistoryPanel> createState() => _ChangeHistoryPanelState();
}

class _ChangeHistoryPanelState extends State<ChangeHistoryPanel> {
  final ChangeHistoryService _historyService = ChangeHistoryService();
  ChangeHistoryFilter _filter = const ChangeHistoryFilter();
  bool _showFilterOptions = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (_showFilterOptions) _buildFilterOptions(),
          Expanded(
            child: _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '変更履歴',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.taskName != null)
                  Text(
                    widget.taskName!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _showFilterOptions = !_showFilterOptions;
              });
            },
            icon: Icon(
              Icons.filter_list,
              color: _showFilterOptions
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            tooltip: 'フィルター',
          ),
          if (widget.onClose != null)
            IconButton(
              onPressed: widget.onClose,
              icon: Icon(
                Icons.close,
                color: AppColors.textSecondary,
              ),
              tooltip: '閉じる',
            ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildFilterChip(
            label: '日程変更',
            type: ChangeType.scheduleChange,
            icon: Icons.calendar_today,
          ),
          _buildFilterChip(
            label: '進捗更新',
            type: ChangeType.progressChange,
            icon: Icons.trending_up,
          ),
          _buildFilterChip(
            label: 'ステータス',
            type: ChangeType.statusChange,
            icon: Icons.flag,
          ),
          _buildFilterChip(
            label: 'ドラッグ',
            type: ChangeType.dragDrop,
            icon: Icons.open_with,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required ChangeType type,
    required IconData icon,
  }) {
    final isSelected = _filter.changeTypes?.contains(type) ?? false;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isSelected ? Colors.white : type.color,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          final currentTypes =
              List<ChangeType>.from(_filter.changeTypes ?? []);
          if (selected) {
            currentTypes.add(type);
          } else {
            currentTypes.remove(type);
          }
          _filter = ChangeHistoryFilter(
            changeTypes: currentTypes.isEmpty ? null : currentTypes,
            userId: _filter.userId,
            fromDate: _filter.fromDate,
            toDate: _filter.toDate,
          );
        });
      },
      selectedColor: type.color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontSize: 12,
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListenableBuilder(
      listenable: _historyService,
      builder: (context, _) {
        final history = _historyService.getFilteredHistory(
          taskId: widget.taskId,
          projectId: widget.projectId,
          filter: _filter,
          limit: widget.maxItems,
        );

        if (history.isEmpty) {
          return _buildEmptyState();
        }

        // 日付でグループ化
        final groupedHistory = history.groupByDate();
        final sortedDates = groupedHistory.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final dateKey = sortedDates[index];
            final items = groupedHistory[dateKey]!;
            return _buildDateGroup(dateKey, items);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              '変更履歴がありません',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'タスクを編集すると\nここに履歴が表示されます',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateGroup(String dateKey, List<TaskChangeHistory> items) {
    final dateLabel = _formatDateLabel(dateKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            dateLabel,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...items.map((item) => _buildHistoryItem(item)),
      ],
    );
  }

  String _formatDateLabel(String dateKey) {
    final parts = dateKey.split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return '今日';
    } else if (date == yesterday) {
      return '昨日';
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  Widget _buildHistoryItem(TaskChangeHistory history) {
    return InkWell(
      onTap: () => _showHistoryDetail(history),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイムライン線
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: history.changeType.color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: history.changeType.color,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    history.changeType.icon,
                    size: 16,
                    color: history.changeType.color,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (history.changedBy != null) ...[
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: UserAvatar(
                            user: history.changedBy!,
                            size: 20,
                            showOnlineIndicator: false,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          history.changedByName,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        history.timeAgo,
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    history.summary,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  if (history.changes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ...history.changes.take(2).map((change) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(
                                change.field.icon,
                                size: 12,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${change.field.displayName}: ${change.displayText}',
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (history.changes.length > 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '+${history.changes.length - 2}件の変更',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                  if (history.reason != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            history.reason!,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistoryDetail(TaskChangeHistory history) {
    showDialog(
      context: context,
      builder: (context) => _HistoryDetailDialog(history: history),
    );
  }
}

/// 履歴詳細ダイアログ
class _HistoryDetailDialog extends StatelessWidget {
  final TaskChangeHistory history;

  const _HistoryDetailDialog({required this.history});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: history.changeType.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              history.changeType.icon,
              size: 18,
              color: history.changeType.color,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            history.changeType.displayName,
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('変更者', history.changedByName),
              _buildInfoRow('日時', _formatDateTime(history.changedAt)),
              if (history.reason != null)
                _buildInfoRow('理由', history.reason!),
              if (history.comment != null)
                _buildInfoRow('コメント', history.comment!),
              const Divider(height: 24),
              const Text(
                '変更内容',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...history.changes.map((change) => _buildChangeRow(change)),
              if (history.changes.isEmpty)
                Text(
                  history.summary,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeRow(FieldChange change) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                change.field.icon,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                change.field.displayName,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '変更前',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      change.oldValue?.toString() ?? '(なし)',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward,
                size: 16,
                color: AppColors.textTertiary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '変更後',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      change.newValue?.toString() ?? '(なし)',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// コンパクトな変更履歴インジケーター
///
/// タスク行に表示する小さな履歴インジケーター
class ChangeHistoryIndicator extends StatelessWidget {
  final String taskId;
  final VoidCallback? onTap;

  const ChangeHistoryIndicator({
    super.key,
    required this.taskId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final historyService = ChangeHistoryService();
    final history = historyService.getHistoryForTask(taskId);

    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    final latest = history.first;

    return Tooltip(
      message: '${latest.changedByName}が${latest.timeAgo}に${latest.summary}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: latest.changeType.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: latest.changeType.color.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 12,
                color: latest.changeType.color,
              ),
              const SizedBox(width: 4),
              Text(
                latest.timeAgo,
                style: TextStyle(
                  color: latest.changeType.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
