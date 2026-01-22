/// Dependency Creation Dialog
/// Allows users to select dependency type and lag time when creating dependencies

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/dependency_model.dart';
import '../../../data/models/models.dart';

/// Dialog result for dependency creation
class DependencyDialogResult {
  final DependencyType type;
  final int lagDays;

  const DependencyDialogResult({
    required this.type,
    this.lagDays = 0,
  });
}

/// Shows a dialog to configure dependency type and lag
class DependencyDialog extends StatefulWidget {
  final Task fromTask;
  final Task toTask;
  final TaskDependency? existingDependency;

  const DependencyDialog({
    super.key,
    required this.fromTask,
    required this.toTask,
    this.existingDependency,
  });

  static Future<DependencyDialogResult?> show({
    required BuildContext context,
    required Task fromTask,
    required Task toTask,
    TaskDependency? existingDependency,
  }) {
    return showDialog<DependencyDialogResult>(
      context: context,
      builder: (context) => DependencyDialog(
        fromTask: fromTask,
        toTask: toTask,
        existingDependency: existingDependency,
      ),
    );
  }

  @override
  State<DependencyDialog> createState() => _DependencyDialogState();
}

class _DependencyDialogState extends State<DependencyDialog> {
  late DependencyType _selectedType;
  late TextEditingController _lagController;
  bool _isPositiveLag = true;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.existingDependency?.type ?? DependencyType.fs;
    final lag = widget.existingDependency?.lagDays ?? 0;
    _isPositiveLag = lag >= 0;
    _lagController = TextEditingController(text: lag.abs().toString());
  }

  @override
  void dispose() {
    _lagController.dispose();
    super.dispose();
  }

  int get _lagDays {
    final value = int.tryParse(_lagController.text) ?? 0;
    return _isPositiveLag ? value : -value;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.link,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.existingDependency != null ? '依存関係を編集' : '依存関係を作成',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'タスク間の関係を設定します',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Task info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildTaskInfo('先行タスク', widget.fromTask, AppColors.industrialOrange),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Icon(
                      Icons.arrow_downward,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  _buildTaskInfo('後続タスク', widget.toTask, AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Dependency type selection
            const Text(
              '依存関係タイプ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildTypeSelector(),
            const SizedBox(height: 24),

            // Lag time input
            const Text(
              'ラグ/リード (日数)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ラグ(+): 先行タスク後に待機日数、リード(-): 先行タスク完了前に開始',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 12),
            _buildLagInput(),
            const SizedBox(height: 32),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _onConfirm,
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(widget.existingDependency != null ? '更新' : '作成'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskInfo(String label, Task task, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                task.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${_formatDate(task.startDate)} - ${_formatDate(task.endDate)}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DependencyType.values.map((type) {
        final isSelected = _selectedType == type;
        return InkWell(
          onTap: () => setState(() => _selectedType = type),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    type.shortLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        type.description,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 18,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLagInput() {
    return Row(
      children: [
        // Sign toggle
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSignButton(
                '+',
                _isPositiveLag,
                () => setState(() => _isPositiveLag = true),
              ),
              _buildSignButton(
                '-',
                !_isPositiveLag,
                () => setState(() => _isPositiveLag = false),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Number input
        SizedBox(
          width: 80,
          child: TextField(
            controller: _lagController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixText: '日',
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Quick buttons
        Wrap(
          spacing: 4,
          children: [0, 1, 3, 7].map((days) {
            return ActionChip(
              label: Text(days == 0 ? '0' : '+$days'),
              onPressed: () {
                setState(() {
                  _isPositiveLag = true;
                  _lagController.text = days.toString();
                });
              },
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSignButton(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _onConfirm() {
    Navigator.pop(
      context,
      DependencyDialogResult(
        type: _selectedType,
        lagDays: _lagDays,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}

/// Quick dependency type picker (compact version for toolbar)
class DependencyTypePicker extends StatelessWidget {
  final DependencyType selectedType;
  final ValueChanged<DependencyType> onTypeChanged;

  const DependencyTypePicker({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: DependencyType.values.map((type) {
          final isSelected = selectedType == type;
          return Tooltip(
            message: type.label,
            child: InkWell(
              onTap: () => onTypeChanged(type),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  type.shortLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
