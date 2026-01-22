import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import '../../../data/models/phase_model.dart';
import '../../../data/services/change_history_service.dart';
import '../chat/user_avatar.dart';
import 'change_history_panel.dart';

/// 右パネルの表示モード
enum ContextPanelMode {
  /// プロジェクト概要（何も選択していない時）
  project,

  /// タスク詳細（タスク選択時）
  task,

  /// 閉じている
  closed,
}

/// コンテキストパネル（右パネル）
///
/// タスク選択で即座にTask Modeに切り替わる
/// 選択解除でProject Modeに戻る
class ContextPanel extends StatefulWidget {
  /// 現在のモード
  final ContextPanelMode mode;

  /// 選択中のタスク（Task Modeで使用）
  final Task? selectedTask;

  /// プロジェクト情報
  final Project? project;

  /// タスクのフェーズ情報
  final Phase? taskPhase;

  /// 閉じるコールバック
  final VoidCallback? onClose;

  /// プロジェクトモードに戻るコールバック
  final VoidCallback? onBackToProject;

  /// タスク状態変更コールバック
  final Function(Task task, String newStatus)? onTaskStatusChange;

  /// タスク遅延理由設定コールバック
  final Function(Task task, String? reason)? onTaskDelayReasonChange;

  /// 写真追加コールバック
  final VoidCallback? onAddPhoto;

  /// 図面を開くコールバック
  final Function(String documentId)? onOpenDocument;

  /// パネル幅
  final double width;

  const ContextPanel({
    super.key,
    required this.mode,
    this.selectedTask,
    this.project,
    this.taskPhase,
    this.onClose,
    this.onBackToProject,
    this.onTaskStatusChange,
    this.onTaskDelayReasonChange,
    this.onAddPhoto,
    this.onOpenDocument,
    this.width = 380,
  });

  @override
  State<ContextPanel> createState() => _ContextPanelState();
}

class _ContextPanelState extends State<ContextPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    if (widget.mode != ContextPanelMode.closed) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(ContextPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode) {
      if (widget.mode == ContextPanelMode.closed) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(widget.width * _slideAnimation.value, 0),
          child: Container(
            width: widget.width,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                left: BorderSide(color: AppColors.divider, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(-2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _showHistory && widget.selectedTask != null
                      ? ChangeHistoryPanel(
                          taskId: widget.selectedTask!.id,
                          projectId: widget.selectedTask!.projectId,
                          taskName: widget.selectedTask!.name,
                          onClose: () => setState(() => _showHistory = false),
                        )
                      : (widget.mode == ContextPanelMode.task
                          ? _buildTaskMode()
                          : _buildProjectMode()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final isTaskMode = widget.mode == ContextPanelMode.task;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 戻るボタン（Task Modeのみ）
          if (isTaskMode) ...[
            InkWell(
              onTap: widget.onBackToProject,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'プロジェクト概要',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Icon(
              Icons.dashboard_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'プロジェクト概要',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          const Spacer(),
          // 履歴ボタン（Task Modeのみ）
          if (isTaskMode)
            Tooltip(
              message: '変更履歴',
              child: InkWell(
                onTap: () => setState(() => _showHistory = !_showHistory),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.history,
                    size: 18,
                    color: _showHistory
                        ? AppColors.primary
                        : AppColors.iconDefault,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 4),
          // 閉じるボタン
          Tooltip(
            message: '閉じる',
            child: InkWell(
              onTap: widget.onClose,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.iconDefault,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectMode() {
    if (widget.project == null) {
      return const Center(
        child: Text('プロジェクトを選択してください'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // プロジェクト概要カード
        _buildProjectCard(),
        const SizedBox(height: 16),

        // 今日のアラート
        _buildAlertsSection(),
        const SizedBox(height: 16),

        // メンバー
        _buildMembersSection(),
        const SizedBox(height: 16),

        // 最新資料
        _buildDocumentsSection(),
      ],
    );
  }

  Widget _buildProjectCard() {
    final project = widget.project!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (project.description != null && project.description!.isNotEmpty)
            Text(
              project.description!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                '${project.startDate.month}/${project.startDate.day} - ${project.endDate.month}/${project.endDate.day}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 進捗バー
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '全体進捗',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${(project.progress * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: project.progress,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber, size: 18, color: AppColors.warning),
            const SizedBox(width: 8),
            Text(
              '今日のアラート',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAlertItem('遅延', '3件', AppColors.error, Icons.schedule),
        const SizedBox(height: 8),
        _buildAlertItem('待ち', '5件', AppColors.warning, Icons.hourglass_empty),
        const SizedBox(height: 8),
        _buildAlertItem('未読指示', '2件', AppColors.info, Icons.message),
      ],
    );
  }

  Widget _buildAlertItem(String label, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            count,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 16, color: color),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    final members = widget.project?.members ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people_outline, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              'メンバー',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${members.length}人',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (members.isEmpty)
          Text(
            'メンバーがいません',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: members.take(6).map((member) {
              return Tooltip(
                message: '${member.name} (${UserRole.getLabel(member.role)})',
                child: Stack(
                  children: [
                    UserAvatar(
                      user: member,
                      size: 36,
                      showOnlineIndicator: true,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.folder_outlined, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              '最新資料',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDocumentItem('基礎図面 v2.3', 'DWG', '今日'),
        const SizedBox(height: 8),
        _buildDocumentItem('現場指示書 #45', 'PDF', '昨日'),
        const SizedBox(height: 8),
        _buildDocumentItem('材料発注リスト', 'XLS', '2日前'),
      ],
    );
  }

  Widget _buildDocumentItem(String name, String type, String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            date,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskMode() {
    final task = widget.selectedTask;
    if (task == null) {
      return const Center(
        child: Text('タスクを選択してください'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // タスク要約ヘッダー
        _buildTaskSummary(task),
        const SizedBox(height: 16),

        // ワンタップ操作
        _buildQuickActions(task),
        const SizedBox(height: 16),

        // 遅延/待ち理由（該当時のみ）
        if (task.delayStatus != DelayStatus.onTrack) ...[
          _buildDelayReasonSection(task),
          const SizedBox(height: 16),
        ],

        // 担当情報
        _buildAssigneeSection(task),
        const SizedBox(height: 16),

        // タスク紐付け資料
        _buildTaskDocuments(task),
        const SizedBox(height: 16),

        // 写真セクション
        _buildPhotosSection(task),
        const SizedBox(height: 16),

        // 変更履歴サマリー
        _buildHistorySummary(task),
      ],
    );
  }

  Widget _buildTaskSummary(Task task) {
    final delayStatus = task.delayStatus;
    final phaseColor = widget.taskPhase != null
        ? PhaseColors.getColorForOrder(widget.taskPhase!.order)
        : AppColors.getCategoryColor(task.category);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            phaseColor.withOpacity(0.15),
            phaseColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: phaseColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タスク名と状態チップ
          Row(
            children: [
              Expanded(
                child: Text(
                  task.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildStatusChip(delayStatus),
            ],
          ),
          const SizedBox(height: 12),

          // 期日・超過日数・担当
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                Icons.calendar_today,
                '期日: ${task.endDate.month}/${task.endDate.day}',
                task.isOverdue ? AppColors.error : AppColors.textSecondary,
              ),
              if (task.isOverdue)
                _buildInfoChip(
                  Icons.warning_amber,
                  '超過: +${task.daysOverdue}日',
                  AppColors.error,
                ),
              if (task.assigneeDisplayText.isNotEmpty)
                _buildInfoChip(
                  Icons.person_outline,
                  task.assigneeDisplayText,
                  AppColors.primary,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 進捗バー
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '進捗',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${(task.progress * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: phaseColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: task.progress,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation(phaseColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(DelayStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'クイック操作',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                Icons.check_circle_outline,
                '状態変更',
                AppColors.success,
                () => _showStatusChangeDialog(task),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                Icons.schedule,
                '遅延理由',
                AppColors.warning,
                () => _showDelayReasonDialog(task),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                Icons.camera_alt_outlined,
                '写真追加',
                AppColors.primary,
                widget.onAddPhoto,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                Icons.description_outlined,
                '図面を開く',
                AppColors.info,
                () => widget.onOpenDocument?.call(task.id),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDelayReasonSection(Task task) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: task.delayStatus.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: task.delayStatus.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                task.delayStatus.icon,
                size: 16,
                color: task.delayStatus.color,
              ),
              const SizedBox(width: 8),
              Text(
                task.delayStatus == DelayStatus.blocked ? '待ち理由' : '遅延理由',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: task.delayStatus.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (task.blockingReason != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                task.blockingReason!.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: task.delayStatus.color,
                ),
              ),
            ),
          ],
          if (task.blockingDetails != null) ...[
            const SizedBox(height: 8),
            Text(
              task.blockingDetails!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (task.delayReason != null) ...[
            const SizedBox(height: 8),
            Text(
              task.delayReason!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssigneeSection(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '担当',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.business,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.contractorName ?? '未割当',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (task.assigneeName != null)
                      Text(
                        task.assigneeName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.chat_bubble_outline, size: 20),
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskDocuments(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'タスク紐付け資料',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        if (task.attachmentStatus.hasDrawing)
          _buildDocumentItem('最新図面 v1.2', 'DWG', '最新'),
        const SizedBox(height: 8),
        _buildDocumentItem('作業指示書', 'PDF', '昨日'),
      ],
    );
  }

  Widget _buildPhotosSection(Task task) {
    final photoCount = task.attachmentStatus.photoCount;
    final todayCount = task.attachmentStatus.todayPhotoCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '写真',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '$photoCount枚',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
            if (todayCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '今日 +$todayCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: photoCount > 0
              ? Row(
                  children: [
                    const SizedBox(width: 8),
                    ...List.generate(
                      photoCount.clamp(0, 3),
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 60,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                    if (photoCount > 3) ...[
                      const SizedBox(width: 8),
                      Text(
                        '+${photoCount - 3}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      onPressed: widget.onAddPhoto,
                      icon: const Icon(Icons.add_a_photo),
                      color: AppColors.primary,
                    ),
                  ],
                )
              : InkWell(
                  onTap: widget.onAddPhoto,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 24,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '写真を追加',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHistorySummary(Task task) {
    final historyService = ChangeHistoryService();
    final history = historyService.getHistoryForTask(task.id);
    final recent = history.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '変更履歴',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            if (history.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _showHistory = true),
                child: Text(
                  '全て見る (${history.length})',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '変更履歴がありません',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          )
        else
          ...recent.map((item) => _buildHistoryItem(item)),
      ],
    );
  }

  Widget _buildHistoryItem(TaskChangeHistory history) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: history.changeType.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              history.changeType.icon,
              size: 12,
              color: history.changeType.color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history.summary,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${history.changedByName} • ${history.timeAgo}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusChangeDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('状態変更'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption('not_started', '未着手', Icons.circle_outlined),
            _buildStatusOption('in_progress', '進行中', Icons.play_circle_outline),
            _buildStatusOption('completed', '完了', Icons.check_circle_outline),
            _buildStatusOption('on_hold', '保留', Icons.pause_circle_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(String status, String label, IconData icon) {
    final isSelected = widget.selectedTask?.status == status;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : null),
      title: Text(label),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context);
        widget.onTaskStatusChange?.call(widget.selectedTask!, status);
      },
    );
  }

  void _showDelayReasonDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('遅延/待ち理由'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: BlockingReason.values.map((reason) {
            return ListTile(
              leading: Icon(reason.icon),
              title: Text(reason.displayName),
              onTap: () {
                Navigator.pop(context);
                widget.onTaskDelayReasonChange?.call(task, reason.value);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
