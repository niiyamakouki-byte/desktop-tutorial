import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import 'date_picker_section.dart';
import 'progress_slider.dart';
import 'status_selector.dart';
import 'priority_selector.dart';
import 'assignee_selector.dart';

/// Main Task Edit Modal widget
/// Displays a modal overlay for editing task details
class TaskEditModal extends StatefulWidget {
  /// The task to edit (null for new task)
  final Task? task;

  /// Project ID for new tasks
  final String projectId;

  /// List of available users for assignment
  final List<User> availableUsers;

  /// Callback when task is saved
  final ValueChanged<Task> onSave;

  /// Callback when modal is closed
  final VoidCallback onClose;

  /// Callback when task is deleted (optional)
  final VoidCallback? onDelete;

  const TaskEditModal({
    super.key,
    this.task,
    required this.projectId,
    required this.availableUsers,
    required this.onSave,
    required this.onClose,
    this.onDelete,
  });

  /// Shows the task edit modal as an overlay
  static Future<Task?> show({
    required BuildContext context,
    Task? task,
    required String projectId,
    required List<User> availableUsers,
    VoidCallback? onDelete,
  }) async {
    Task? result;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'TaskEditModal',
      barrierColor: Colors.black54,
      transitionDuration: AppConstants.animationNormal,
      pageBuilder: (context, animation, secondaryAnimation) {
        return TaskEditModal(
          task: task,
          projectId: projectId,
          availableUsers: availableUsers,
          onSave: (savedTask) {
            result = savedTask;
            Navigator.of(context).pop();
          },
          onClose: () => Navigator.of(context).pop(),
          onDelete: onDelete,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );

    return result;
  }

  @override
  State<TaskEditModal> createState() => _TaskEditModalState();
}

class _TaskEditModalState extends State<TaskEditModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Form fields
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;

  late String _status;
  late String _priority;
  late String _category;
  late DateTime _startDate;
  late DateTime _endDate;
  late double _progress;
  late List<User> _assignees;

  final _formKey = GlobalKey<FormState>();
  bool _hasChanges = false;
  bool _isSaving = false;

  // Category options
  static const List<Map<String, dynamic>> _categories = [
    {'value': 'foundation', 'label': '基礎工事', 'color': AppColors.categoryFoundation},
    {'value': 'structure', 'label': '構造', 'color': AppColors.categoryStructure},
    {'value': 'electrical', 'label': '電気設備', 'color': AppColors.categoryElectrical},
    {'value': 'plumbing', 'label': '配管', 'color': AppColors.categoryPlumbing},
    {'value': 'finishing', 'label': '仕上げ', 'color': AppColors.categoryFinishing},
    {'value': 'inspection', 'label': '検査', 'color': AppColors.categoryInspection},
    {'value': 'general', 'label': '一般', 'color': AppColors.categoryGeneral},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeFormFields();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: AppConstants.animationNormal,
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  void _initializeFormFields() {
    final task = widget.task;
    final now = DateTime.now();

    _nameController = TextEditingController(text: task?.name ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _notesController = TextEditingController(text: task?.notes ?? '');

    _status = task?.status ?? AppConstants.statusNotStarted;
    _priority = task?.priority ?? AppConstants.priorityMedium;
    _category = task?.category ?? 'general';
    _startDate = task?.startDate ?? now;
    _endDate = task?.endDate ?? now.add(const Duration(days: 7));
    _progress = task?.progress ?? 0.0;
    _assignees = task?.assignees ?? [];

    // Add listeners for change detection
    _nameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _notesController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Simulate save delay for UX
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();
    final task = Task(
      id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      projectId: widget.projectId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      startDate: _startDate,
      endDate: _endDate,
      progress: _progress,
      status: _status,
      priority: _priority,
      category: _category,
      parentId: widget.task?.parentId,
      dependsOn: widget.task?.dependsOn ?? [],
      assignees: _assignees,
      isExpanded: widget.task?.isExpanded ?? true,
      isMilestone: widget.task?.isMilestone ?? false,
      level: widget.task?.level ?? 0,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: widget.task?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSave(task);
  }

  void _handleClose() {
    if (_hasChanges) {
      _showDiscardDialog();
    } else {
      widget.onClose();
    }
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        title: const Text(
          '変更を破棄しますか？',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          '保存されていない変更があります。破棄してよろしいですか？',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onClose();
            },
            child: const Text(
              '破棄',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        title: const Text(
          'タスクを削除しますか？',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'この操作は取り消せません。タスクを削除してもよろしいですか？',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete?.call();
            },
            child: const Text(
              '削除',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNewTask = widget.task == null;
    final screenSize = MediaQuery.of(context).size;
    final modalWidth = screenSize.width > 800 ? 600.0 : screenSize.width * 0.9;

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: child,
            );
          },
          child: Container(
            width: modalWidth,
            constraints: BoxConstraints(
              maxHeight: screenSize.height * 0.9,
            ),
            margin: const EdgeInsets.all(AppConstants.paddingL),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.radiusXL),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowDark,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildHeader(isNewTask),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.paddingXL),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Task Details Section
                          _buildSectionHeader('タスク詳細', Icons.assignment_outlined),
                          const SizedBox(height: AppConstants.paddingM),
                          _buildNameField(),
                          const SizedBox(height: AppConstants.paddingL),
                          _buildDescriptionField(),
                          const SizedBox(height: AppConstants.paddingL),
                          _buildCategorySelector(),

                          const SizedBox(height: AppConstants.paddingXL),
                          const Divider(color: AppColors.divider),
                          const SizedBox(height: AppConstants.paddingXL),

                          // Schedule Section
                          _buildSectionHeader('スケジュール', Icons.schedule_outlined),
                          const SizedBox(height: AppConstants.paddingM),
                          DatePickerSection(
                            startDate: _startDate,
                            endDate: _endDate,
                            onStartDateChanged: (date) {
                              setState(() {
                                _startDate = date;
                                _hasChanges = true;
                              });
                            },
                            onEndDateChanged: (date) {
                              setState(() {
                                _endDate = date;
                                _hasChanges = true;
                              });
                            },
                          ),

                          const SizedBox(height: AppConstants.paddingXL),
                          const Divider(color: AppColors.divider),
                          const SizedBox(height: AppConstants.paddingXL),

                          // Progress Section
                          _buildSectionHeader('進捗', Icons.trending_up_outlined),
                          const SizedBox(height: AppConstants.paddingM),
                          ProgressSlider(
                            value: _progress,
                            onChanged: (value) {
                              setState(() {
                                _progress = value;
                                _hasChanges = true;
                                // Auto-update status based on progress
                                if (value >= 1.0) {
                                  _status = AppConstants.statusCompleted;
                                } else if (value > 0 &&
                                    _status == AppConstants.statusNotStarted) {
                                  _status = AppConstants.statusInProgress;
                                }
                              });
                            },
                            label: '完了率',
                          ),

                          const SizedBox(height: AppConstants.paddingXL),
                          const Divider(color: AppColors.divider),
                          const SizedBox(height: AppConstants.paddingXL),

                          // Status & Priority Section
                          _buildSectionHeader('ステータス・優先度', Icons.flag_outlined),
                          const SizedBox(height: AppConstants.paddingM),
                          StatusSelector(
                            selectedStatus: _status,
                            onChanged: (status) {
                              setState(() {
                                _status = status;
                                _hasChanges = true;
                              });
                            },
                            label: 'ステータス',
                          ),
                          const SizedBox(height: AppConstants.paddingL),
                          PrioritySelector(
                            selectedPriority: _priority,
                            onChanged: (priority) {
                              setState(() {
                                _priority = priority;
                                _hasChanges = true;
                              });
                            },
                            label: '優先度',
                          ),

                          const SizedBox(height: AppConstants.paddingXL),
                          const Divider(color: AppColors.divider),
                          const SizedBox(height: AppConstants.paddingXL),

                          // Assignees Section
                          _buildSectionHeader('担当者', Icons.people_outline),
                          const SizedBox(height: AppConstants.paddingM),
                          AssigneeSelector(
                            availableUsers: widget.availableUsers,
                            selectedUsers: _assignees,
                            onChanged: (users) {
                              setState(() {
                                _assignees = users;
                                _hasChanges = true;
                              });
                            },
                          ),

                          const SizedBox(height: AppConstants.paddingXL),
                          const Divider(color: AppColors.divider),
                          const SizedBox(height: AppConstants.paddingXL),

                          // Notes Section
                          _buildSectionHeader('メモ', Icons.note_outlined),
                          const SizedBox(height: AppConstants.paddingM),
                          _buildNotesField(),

                          const SizedBox(height: AppConstants.paddingL),
                        ],
                      ),
                    ),
                  ),
                ),

                // Footer with buttons
                _buildFooter(isNewTask),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isNewTask) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingXL,
        vertical: AppConstants.paddingL,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: const Icon(
              Icons.edit_note,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.paddingM),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isNewTask ? '新規タスク作成' : 'タスク編集',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (!isNewTask && widget.task != null)
                  Text(
                    'ID: ${widget.task!.id}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),

          // Close button
          IconButton(
            onPressed: _handleClose,
            icon: const Icon(Icons.close),
            color: AppColors.iconDefault,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppConstants.paddingS),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'タスク名 *',
        hintText: 'タスク名を入力',
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingL,
          vertical: AppConstants.paddingM,
        ),
      ),
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'タスク名を入力してください';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: '説明',
        hintText: 'タスクの説明を入力（任意）',
        alignLabelWithHint: true,
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(AppConstants.paddingL),
      ),
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'カテゴリー',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.paddingM),
        Wrap(
          spacing: AppConstants.paddingS,
          runSpacing: AppConstants.paddingS,
          children: _categories.map((cat) {
            final isSelected = cat['value'] == _category;
            final color = cat['color'] as Color;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _category = cat['value'] as String;
                  _hasChanges = true;
                });
              },
              child: AnimatedContainer(
                duration: AppConstants.animationFast,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingM,
                  vertical: AppConstants.paddingS,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.15) : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                  border: Border.all(
                    color: isSelected ? color : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    Text(
                      cat['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? color : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'メモや補足情報を入力...',
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(AppConstants.paddingL),
      ),
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildFooter(bool isNewTask) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      child: Row(
        children: [
          // Delete button (only for existing tasks)
          if (!isNewTask && widget.onDelete != null)
            TextButton.icon(
              onPressed: _showDeleteDialog,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('削除'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingM,
                  vertical: AppConstants.paddingS,
                ),
              ),
            ),

          const Spacer(),

          // Cancel button
          TextButton(
            onPressed: _handleClose,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingXL,
                vertical: AppConstants.paddingM,
              ),
            ),
            child: const Text(
              'キャンセル',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: AppConstants.paddingM),

          // Save button
          ElevatedButton(
            onPressed: _isSaving ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingXL,
                vertical: AppConstants.paddingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.save_outlined, size: 18),
                      const SizedBox(width: AppConstants.paddingS),
                      Text(
                        isNewTask ? '作成' : '保存',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

