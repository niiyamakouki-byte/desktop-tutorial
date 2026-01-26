import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../state/workspace_state.dart';
import 'project_workspace.dart';

/// 左カラム：タスクナビゲーター
///
/// - ツリー構造のタスク一覧
/// - クイックフィルターバー
/// - 検索
/// - クイックアクション（遅延報告、写真追加等）
class LeftTaskNavigator extends StatelessWidget {
  final String projectId;
  final List<TaskTreeNode> tree;
  final Map<String, Task> tasksById;
  final ProjectWorkspaceController controller;
  final TaskCounts counts;
  final bool isMobile;

  /// クイックアクションコールバック
  final void Function(QuickActionArgs args)? onQuickAction;

  const LeftTaskNavigator({
    super.key,
    required this.projectId,
    required this.tree,
    required this.tasksById,
    required this.controller,
    required this.counts,
    this.isMobile = false,
    this.onQuickAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;

        return Container(
          color: AppColors.surface,
          child: Column(
            children: [
              // 検索バー
              _SearchBar(
                searchText: state.filters.searchText ?? '',
                onChanged: (text) {
                  controller.updateFilters((f) => f.copyWith(
                    searchText: text.isEmpty ? null : text,
                    clearSearch: text.isEmpty,
                  ));
                },
              ),

              // クイックフィルター
              _QuickFilterBar(
                currentFilter: state.filters.quick,
                counts: counts,
                onFilterChanged: (filter) {
                  controller.updateFilters((f) => f.copyWith(quick: filter));
                },
              ),

              // ソート & 追加フィルター
              _FilterSortRow(
                sort: state.sort,
                hasActiveFilters: state.filters.hasActiveFilters,
                onSortChanged: controller.updateSort,
                onClearFilters: () {
                  controller.updateFilters((f) => const TaskFilters());
                },
              ),

              const Divider(height: 1),

              // タスクツリー
              Expanded(
                child: _TaskTreeView(
                  nodes: tree,
                  tasksById: tasksById,
                  selectedTaskId: state.selection.selectedTaskId,
                  onSelectTask: controller.selectTask,
                  onQuickAction: onQuickAction,
                  isMobile: isMobile,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 検索バー
class _SearchBar extends StatelessWidget {
  final String searchText;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.searchText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'タスクを検索...',
          hintStyle: TextStyle(
            color: AppColors.textTertiary,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: AppColors.textTertiary,
          ),
          suffixIcon: searchText.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 18, color: AppColors.textTertiary),
                  onPressed: () => onChanged(''),
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
        onChanged: onChanged,
      ),
    );
  }
}

/// クイックフィルターバー
class _QuickFilterBar extends StatelessWidget {
  final QuickFilter currentFilter;
  final TaskCounts counts;
  final ValueChanged<QuickFilter> onFilterChanged;

  const _QuickFilterBar({
    required this.currentFilter,
    required this.counts,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _FilterChip(
            label: 'すべて',
            count: counts.total,
            isSelected: currentFilter == QuickFilter.all,
            onTap: () => onFilterChanged(QuickFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '今日',
            count: counts.today,
            isSelected: currentFilter == QuickFilter.today,
            color: AppColors.info,
            onTap: () => onFilterChanged(QuickFilter.today),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '遅延',
            count: counts.delayed,
            isSelected: currentFilter == QuickFilter.delayed,
            color: AppColors.error,
            onTap: () => onFilterChanged(QuickFilter.delayed),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '待ち',
            count: counts.waiting,
            isSelected: currentFilter == QuickFilter.waiting,
            color: AppColors.warning,
            onTap: () => onFilterChanged(QuickFilter.waiting),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '自分',
            count: counts.mine,
            isSelected: currentFilter == QuickFilter.mine,
            color: AppColors.primary,
            onTap: () => onFilterChanged(QuickFilter.mine),
          ),
        ],
      ),
    );
  }
}

/// フィルターチップ
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? chipColor : AppColors.textSecondary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? chipColor : AppColors.divider,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ソート & フィルター行
class _FilterSortRow extends StatelessWidget {
  final TaskSort sort;
  final bool hasActiveFilters;
  final ValueChanged<TaskSort> onSortChanged;
  final VoidCallback onClearFilters;

  const _FilterSortRow({
    required this.sort,
    required this.hasActiveFilters,
    required this.onSortChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // ソート
          PopupMenuButton<TaskSort>(
            initialValue: sort,
            onSelected: onSortChanged,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  sort.label,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
              ],
            ),
            itemBuilder: (context) => TaskSort.values.map((s) {
              return PopupMenuItem(
                value: s,
                child: Text(s.label),
              );
            }).toList(),
          ),

          const Spacer(),

          // フィルタークリア
          if (hasActiveFilters)
            TextButton.icon(
              onPressed: onClearFilters,
              icon: Icon(Icons.filter_alt_off, size: 14, color: AppColors.primary),
              label: Text(
                'クリア',
                style: TextStyle(fontSize: 12, color: AppColors.primary),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }
}

/// タスクツリービュー
class _TaskTreeView extends StatelessWidget {
  final List<TaskTreeNode> nodes;
  final Map<String, Task> tasksById;
  final String? selectedTaskId;
  final ValueChanged<String?> onSelectTask;
  final void Function(QuickActionArgs args)? onQuickAction;
  final bool isMobile;

  const _TaskTreeView({
    required this.nodes,
    required this.tasksById,
    required this.selectedTaskId,
    required this.onSelectTask,
    this.onQuickAction,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        return _buildTreeNode(nodes[index], 0);
      },
    );
  }

  Widget _buildTreeNode(TaskTreeNode node, int depth) {
    final task = tasksById[node.taskId];
    if (task == null) return const SizedBox.shrink();

    final isSelected = selectedTaskId == node.taskId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TaskRow(
          task: task,
          depth: depth,
          isSelected: isSelected,
          hasChildren: node.children.isNotEmpty,
          isExpanded: node.isExpanded,
          onTap: () => onSelectTask(node.taskId),
          onQuickAction: onQuickAction != null
              ? (action) => onQuickAction!(QuickActionArgs(
                    taskId: node.taskId,
                    action: action,
                  ))
              : null,
          isMobile: isMobile,
        ),
        if (node.isExpanded)
          ...node.children.map((child) => _buildTreeNode(child, depth + 1)),
      ],
    );
  }
}

/// タスク行
class _TaskRow extends StatelessWidget {
  final Task task;
  final int depth;
  final bool isSelected;
  final bool hasChildren;
  final bool isExpanded;
  final VoidCallback onTap;
  final void Function(QuickActionType)? onQuickAction;
  final bool isMobile;

  const _TaskRow({
    required this.task,
    required this.depth,
    required this.isSelected,
    required this.hasChildren,
    required this.isExpanded,
    required this.onTap,
    this.onQuickAction,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDelayed = task.delayStatus == DelayStatus.overdue;
    final isWaiting = task.delayStatus == DelayStatus.waiting;
    final minHeight = isMobile ? 56.0 : 48.0;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: EdgeInsets.only(
          left: 12 + (depth * 16),
          right: 8,
          top: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            // 展開アイコン（子がある場合）
            if (hasChildren)
              Icon(
                isExpanded ? Icons.expand_more : Icons.chevron_right,
                size: 16,
                color: AppColors.textTertiary,
              )
            else
              const SizedBox(width: 16),

            const SizedBox(width: 4),

            // ステータスインジケーター
            _StatusIndicator(task: task),

            const SizedBox(width: 8),

            // タスク名
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    task.name,
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.contractorName != null || task.assigneeName != null)
                    Text(
                      task.contractorName ?? task.assigneeName ?? '',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),

            // バッジ類
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 遅延バッジ
                if (isDelayed)
                  _DelayBadge(daysOverdue: task.daysOverdue, isMobile: isMobile),

                // 待ちバッジ
                if (isWaiting)
                  _WaitingBadge(isMobile: isMobile),

                // クイックアクション
                if (onQuickAction != null && !isMobile)
                  _QuickActionButtons(
                    task: task,
                    onAction: onQuickAction!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ステータスインジケーター
class _StatusIndicator extends StatelessWidget {
  final Task task;

  const _StatusIndicator({required this.task});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData? icon;

    switch (task.delayStatus) {
      case DelayStatus.onTrack:
        color = AppColors.success;
        break;
      case DelayStatus.atRisk:
        color = AppColors.warning;
        break;
      case DelayStatus.waiting:
        color = AppColors.info;
        icon = Icons.hourglass_empty;
        break;
      case DelayStatus.overdue:
        color = AppColors.error;
        icon = Icons.warning_amber;
        break;
    }

    if (task.progress >= 100) {
      color = AppColors.success;
      icon = Icons.check_circle;
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: icon != null
          ? Icon(icon, size: 12, color: color)
          : Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
    );
  }
}

/// 遅延バッジ
class _DelayBadge extends StatelessWidget {
  final int daysOverdue;
  final bool isMobile;

  const _DelayBadge({required this.daysOverdue, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final isUrgent = daysOverdue >= 3;

    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 6,
        vertical: isMobile ? 4 : 2,
      ),
      decoration: BoxDecoration(
        color: isUrgent ? AppColors.error : AppColors.warning,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '⚠',
            style: TextStyle(fontSize: isMobile ? 10 : 8),
          ),
          const SizedBox(width: 2),
          Text(
            '+${daysOverdue}d',
            style: TextStyle(
              fontSize: isMobile ? 11 : 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// 待ちバッジ
class _WaitingBadge extends StatelessWidget {
  final bool isMobile;

  const _WaitingBadge({this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 6,
        vertical: isMobile ? 4 : 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.info,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '待ち',
        style: TextStyle(
          fontSize: isMobile ? 11 : 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// クイックアクションボタン
class _QuickActionButtons extends StatelessWidget {
  final Task task;
  final void Function(QuickActionType) onAction;

  const _QuickActionButtons({
    required this.task,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 遅延報告
        _QuickActionButton(
          icon: Icons.warning_amber_outlined,
          tooltip: '遅延・待ち報告',
          onTap: () => onAction(QuickActionType.openDelayForm),
        ),
        // 写真追加
        _QuickActionButton(
          icon: Icons.add_a_photo_outlined,
          tooltip: '写真追加',
          onTap: () => onAction(QuickActionType.addPhoto),
        ),
        // 図面
        _QuickActionButton(
          icon: Icons.description_outlined,
          tooltip: '最新図面',
          onTap: () => onAction(QuickActionType.openLatestDrawing),
        ),
      ],
    );
  }
}

/// クイックアクションボタン
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
