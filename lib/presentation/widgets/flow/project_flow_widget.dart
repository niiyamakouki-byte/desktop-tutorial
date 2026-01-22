import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/project_flow_model.dart';

/// Project Flow Widget
/// Visual representation of project stages: 依頼→現調→仕様→品番→図面→金額→契約→着工→完工
class ProjectFlowWidget extends StatelessWidget {
  final ProjectFlow flow;
  final Function(ProjectStage)? onStageSelected;
  final Function(ProjectStage, StageChecklistItem)? onChecklistItemToggle;
  final bool isCompact;

  const ProjectFlowWidget({
    super.key,
    required this.flow,
    this.onStageSelected,
    this.onChecklistItemToggle,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactFlow();
    }
    return _buildFullFlow();
  }

  Widget _buildCompactFlow() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
      child: Row(
        children: [
          for (var i = 0; i < ProjectStage.values.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  color: flow.stageProgress[ProjectStage.values[i]]?.status ==
                          StageStatus.completed
                      ? AppColors.constructionGreen
                      : AppColors.border,
                ),
              ),
            _buildCompactStageIndicator(ProjectStage.values[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactStageIndicator(ProjectStage stage) {
    final progress = flow.stageProgress[stage];
    final isCurrent = stage == flow.currentStage;
    final isCompleted = progress?.status == StageStatus.completed;

    Color bgColor;
    Color iconColor;
    IconData icon;

    if (isCompleted) {
      bgColor = AppColors.constructionGreen;
      iconColor = Colors.white;
      icon = Icons.check;
    } else if (isCurrent) {
      bgColor = AppColors.industrialOrange;
      iconColor = Colors.white;
      icon = Icons.play_arrow;
    } else {
      bgColor = AppColors.surfaceVariant;
      iconColor = AppColors.textTertiary;
      icon = Icons.circle_outlined;
    }

    return Tooltip(
      message: stage.label,
      child: GestureDetector(
        onTap: () => onStageSelected?.call(stage),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrent ? AppColors.industrialOrange : Colors.transparent,
              width: 2,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppColors.industrialOrange.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
      ),
    );
  }

  Widget _buildFullFlow() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_tree_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'プロジェクトフロー',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '現在: ${flow.currentStage.label} (${(flow.overallProgress * 100).toInt()}%完了)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Next action button
              if (flow.canAdvanceToNextStage && flow.currentStage.next != null)
                TextButton.icon(
                  onPressed: () => onStageSelected?.call(flow.currentStage.next!),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text('${flow.currentStage.next!.label}へ進む'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.constructionGreen,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingL),

          // Overall progress bar
          _buildOverallProgressBar(),
          const SizedBox(height: AppConstants.paddingL),

          // Stage cards
          Expanded(
            child: ListView.builder(
              itemCount: ProjectStage.values.length,
              itemBuilder: (context, index) {
                return _buildStageCard(ProjectStage.values[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var stage in ProjectStage.values)
              Expanded(
                child: Container(
                  height: 8,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: _getStageColor(stage),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '依頼',
              style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
            ),
            const Text(
              '完工',
              style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStageColor(ProjectStage stage) {
    final progress = flow.stageProgress[stage];
    if (progress == null) return AppColors.border;

    switch (progress.status) {
      case StageStatus.completed:
        return AppColors.constructionGreen;
      case StageStatus.inProgress:
        return AppColors.industrialOrange;
      case StageStatus.blocked:
        return AppColors.constructionRed;
      case StageStatus.skipped:
        return AppColors.textTertiary;
      default:
        return AppColors.border;
    }
  }

  Widget _buildStageCard(ProjectStage stage) {
    final progress = flow.stageProgress[stage];
    if (progress == null) return const SizedBox();

    final isCurrent = stage == flow.currentStage;
    final isCompleted = progress.status == StageStatus.completed;
    final completionPercent = (progress.completionPercentage * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.industrialOrange.withOpacity(0.05) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? AppColors.industrialOrange.withOpacity(0.3)
              : AppColors.border,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: _buildStageIcon(stage, progress),
          title: Row(
            children: [
              Text(
                stage.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              if (isCompleted)
                const Icon(Icons.check_circle, color: AppColors.constructionGreen, size: 16)
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.industrialOrange.withOpacity(0.2)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$completionPercent%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isCurrent
                          ? AppColors.industrialOrange
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            stage.description,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
          children: [
            _buildChecklist(stage, progress),
          ],
        ),
      ),
    );
  }

  Widget _buildStageIcon(ProjectStage stage, StageProgress progress) {
    IconData icon;
    Color bgColor;
    Color iconColor;

    switch (stage) {
      case ProjectStage.inquiry:
        icon = Icons.request_page_outlined;
        break;
      case ProjectStage.siteVisit:
        icon = Icons.home_work_outlined;
        break;
      case ProjectStage.specification:
        icon = Icons.description_outlined;
        break;
      case ProjectStage.productSelect:
        icon = Icons.category_outlined;
        break;
      case ProjectStage.drawing:
        icon = Icons.architecture_outlined;
        break;
      case ProjectStage.pricing:
        icon = Icons.calculate_outlined;
        break;
      case ProjectStage.contract:
        icon = Icons.handshake_outlined;
        break;
      case ProjectStage.construction:
        icon = Icons.construction_outlined;
        break;
      case ProjectStage.completed:
        icon = Icons.verified_outlined;
        break;
    }

    switch (progress.status) {
      case StageStatus.completed:
        bgColor = AppColors.constructionGreen.withOpacity(0.15);
        iconColor = AppColors.constructionGreen;
        break;
      case StageStatus.inProgress:
        bgColor = AppColors.industrialOrange.withOpacity(0.15);
        iconColor = AppColors.industrialOrange;
        break;
      case StageStatus.blocked:
        bgColor = AppColors.constructionRed.withOpacity(0.15);
        iconColor = AppColors.constructionRed;
        break;
      default:
        bgColor = AppColors.surfaceVariant;
        iconColor = AppColors.textTertiary;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  Widget _buildChecklist(ProjectStage stage, StageProgress progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'チェックリスト',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...progress.checklist.map((item) => _buildChecklistItem(stage, item)),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(ProjectStage stage, StageChecklistItem item) {
    return InkWell(
      onTap: () => onChecklistItemToggle?.call(stage, item),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.isCompleted
                    ? AppColors.constructionGreen
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.isCompleted
                      ? AppColors.constructionGreen
                      : (item.isRequired
                          ? AppColors.industrialOrange.withOpacity(0.5)
                          : AppColors.border),
                  width: item.isRequired && !item.isCompleted ? 2 : 1,
                ),
              ),
              child: item.isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: item.isCompleted
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                      decoration:
                          item.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (item.isRequired) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.industrialOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        '必須',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.industrialOrange,
                        ),
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
}

/// Compact horizontal flow indicator for headers
class ProjectFlowIndicator extends StatelessWidget {
  final ProjectFlow flow;
  final Function(ProjectStage)? onStageTap;

  const ProjectFlowIndicator({
    super.key,
    required this.flow,
    this.onStageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < ProjectStage.values.length; i++) ...[
            if (i > 0)
              Container(
                width: 16,
                height: 2,
                color: _isStageComplete(ProjectStage.values[i - 1])
                    ? AppColors.constructionGreen
                    : AppColors.border,
              ),
            _buildIndicator(ProjectStage.values[i]),
          ],
        ],
      ),
    );
  }

  bool _isStageComplete(ProjectStage stage) {
    return flow.stageProgress[stage]?.status == StageStatus.completed;
  }

  Widget _buildIndicator(ProjectStage stage) {
    final progress = flow.stageProgress[stage];
    final isCurrent = stage == flow.currentStage;
    final isComplete = progress?.status == StageStatus.completed;

    return Tooltip(
      message: stage.label,
      child: GestureDetector(
        onTap: () => onStageTap?.call(stage),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isComplete
                ? AppColors.constructionGreen
                : (isCurrent ? AppColors.industrialOrange : AppColors.surface),
            shape: BoxShape.circle,
            border: Border.all(
              color: isComplete
                  ? AppColors.constructionGreen
                  : (isCurrent
                      ? AppColors.industrialOrange
                      : AppColors.border),
            ),
          ),
          child: Center(
            child: isComplete
                ? const Icon(Icons.check, color: Colors.white, size: 12)
                : Text(
                    '${stage.index + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isCurrent
                          ? Colors.white
                          : AppColors.textTertiary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
