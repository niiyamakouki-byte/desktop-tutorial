/// Rain Cancellation Dialog
/// 雨天中止ダイアログ - 日程スライド機能

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/dependency_model.dart';

/// 雨天中止による日程変更の結果
class RainCancelResult {
  final DateTime rainDate;
  final int delayDays;
  final List<TaskSlideInfo> affectedTasks;

  const RainCancelResult({
    required this.rainDate,
    required this.delayDays,
    required this.affectedTasks,
  });
}

/// タスクスライド情報
class TaskSlideInfo {
  final Task task;
  final DateTime originalStart;
  final DateTime originalEnd;
  final DateTime newStart;
  final DateTime newEnd;
  final bool isDirect; // 直接影響か依存関係による影響か

  const TaskSlideInfo({
    required this.task,
    required this.originalStart,
    required this.originalEnd,
    required this.newStart,
    required this.newEnd,
    this.isDirect = false,
  });

  int get delayDays => newStart.difference(originalStart).inDays;

  /// 新しい開始日が土日かどうか
  bool get startsOnWeekend => newStart.weekday == DateTime.saturday || newStart.weekday == DateTime.sunday;

  /// 新しい終了日が土日かどうか
  bool get endsOnWeekend => newEnd.weekday == DateTime.saturday || newEnd.weekday == DateTime.sunday;

  /// 期間内に土日が含まれるか
  bool get includesWeekend {
    DateTime current = newStart;
    while (!current.isAfter(newEnd)) {
      if (current.weekday == DateTime.saturday || current.weekday == DateTime.sunday) {
        return true;
      }
      current = current.add(const Duration(days: 1));
    }
    return false;
  }
}

/// 雨天中止ダイアログ
class RainCancelDialog extends StatefulWidget {
  final List<Task> tasks;
  final List<TaskDependency> dependencies;
  final DateTime? initialDate;

  const RainCancelDialog({
    super.key,
    required this.tasks,
    required this.dependencies,
    this.initialDate,
  });

  @override
  State<RainCancelDialog> createState() => _RainCancelDialogState();

  /// ダイアログを表示
  static Future<RainCancelResult?> show({
    required BuildContext context,
    required List<Task> tasks,
    required List<TaskDependency> dependencies,
    DateTime? initialDate,
  }) {
    return showDialog<RainCancelResult>(
      context: context,
      builder: (context) => RainCancelDialog(
        tasks: tasks,
        dependencies: dependencies,
        initialDate: initialDate,
      ),
    );
  }
}

class _RainCancelDialogState extends State<RainCancelDialog> {
  late DateTime _selectedDate;
  int _delayDays = 1;
  List<TaskSlideInfo> _previewTasks = [];
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _calculatePreview();
  }

  void _calculatePreview() {
    final affectedTasks = <TaskSlideInfo>[];
    final selectedDateOnly = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    // 選択日以降に開始するタスクを取得
    final directlyAffected = widget.tasks.where((task) {
      final taskStartOnly = DateTime(
        task.startDate.year,
        task.startDate.month,
        task.startDate.day,
      );
      return taskStartOnly.isAtSameMomentAs(selectedDateOnly) ||
          taskStartOnly.isAfter(selectedDateOnly);
    }).toList();

    // 直接影響を受けるタスク
    for (final task in directlyAffected) {
      affectedTasks.add(TaskSlideInfo(
        task: task,
        originalStart: task.startDate,
        originalEnd: task.endDate,
        newStart: task.startDate.add(Duration(days: _delayDays)),
        newEnd: task.endDate.add(Duration(days: _delayDays)),
        isDirect: true,
      ));
    }

    // 依存関係による追加影響を計算
    final directIds = directlyAffected.map((t) => t.id).toSet();
    final processedIds = <String>{...directIds};

    void addDependentTasks(String taskId) {
      final successors = widget.dependencies
          .where((d) => d.fromTaskId == taskId)
          .map((d) => d.toTaskId);

      for (final successorId in successors) {
        if (processedIds.contains(successorId)) continue;
        processedIds.add(successorId);

        final successorTask = widget.tasks.firstWhere(
          (t) => t.id == successorId,
          orElse: () => widget.tasks.first,
        );

        if (successorTask.id == successorId) {
          // このタスクが直接影響を受けていない場合のみ追加
          if (!directIds.contains(successorId)) {
            affectedTasks.add(TaskSlideInfo(
              task: successorTask,
              originalStart: successorTask.startDate,
              originalEnd: successorTask.endDate,
              newStart: successorTask.startDate.add(Duration(days: _delayDays)),
              newEnd: successorTask.endDate.add(Duration(days: _delayDays)),
              isDirect: false,
            ));
          }

          // 再帰的に後続タスクを処理
          addDependentTasks(successorId);
        }
      }
    }

    // 直接影響を受けるタスクの依存関係を辿る
    for (final task in directlyAffected) {
      addDependentTasks(task.id);
    }

    // 開始日順にソート
    affectedTasks.sort((a, b) => a.originalStart.compareTo(b.originalStart));

    setState(() {
      _previewTasks = affectedTasks;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ja'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _calculatePreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年M月d日(E)', 'ja');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー
            _buildHeader(),

            // コンテンツ
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 日付選択
                    _buildDateSelector(dateFormat),
                    const SizedBox(height: 20),

                    // 遅延日数選択
                    _buildDelaySelector(),
                    const SizedBox(height: 20),

                    // プレビュートグル
                    _buildPreviewToggle(),

                    // 影響を受けるタスク一覧
                    if (_showPreview) ...[
                      const SizedBox(height: 16),
                      _buildAffectedTasksList(dateFormat),
                    ],
                  ],
                ),
              ),
            ),

            // アクションボタン
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '☔',
              style: TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '雨天中止',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '日程を一括スライドします',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(DateFormat dateFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '中止日を選択',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Text(
                  dateFormat.format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDelaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'スライド日数',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildDelayButton(1),
            const SizedBox(width: 8),
            _buildDelayButton(2),
            const SizedBox(width: 8),
            _buildDelayButton(3),
            const SizedBox(width: 8),
            _buildDelayButton(5),
            const SizedBox(width: 8),
            _buildDelayButton(7),
          ],
        ),
        const SizedBox(height: 12),
        // カスタム入力
        Row(
          children: [
            const Text(
              'または ',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            SizedBox(
              width: 60,
              child: TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  isDense: true,
                ),
                onChanged: (value) {
                  final days = int.tryParse(value);
                  if (days != null && days > 0 && days <= 365) {
                    setState(() {
                      _delayDays = days;
                    });
                    _calculatePreview();
                  }
                },
              ),
            ),
            const Text(
              ' 日',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDelayButton(int days) {
    final isSelected = _delayDays == days;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _delayDays = days;
          });
          _calculatePreview();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[700] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
            ),
          ),
          child: Text(
            '$days日',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewToggle() {
    final weekendCount = _previewTasks.where((t) => t.startsOnWeekend || t.endsOnWeekend).length;

    return InkWell(
      onTap: () {
        setState(() {
          _showPreview = !_showPreview;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: weekendCount > 0 ? Colors.amber[50] : Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: weekendCount > 0 ? Colors.amber[300]! : Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(
              weekendCount > 0 ? Icons.warning_amber : Icons.info_outline,
              color: weekendCount > 0 ? Colors.amber[700] : Colors.orange[700],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${_previewTasks.length}件のタスクが影響を受けます',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[900],
                        ),
                      ),
                      if (weekendCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber[600],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.weekend, size: 10, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '$weekendCount件土日',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${_previewTasks.where((t) => t.isDirect).length}件が直接、${_previewTasks.where((t) => !t.isDirect).length}件が依存関係により移動',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _showPreview ? Icons.expand_less : Icons.expand_more,
              color: weekendCount > 0 ? Colors.amber[700] : Colors.orange[700],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAffectedTasksList(DateFormat dateFormat) {
    final shortDateFormat = DateFormat('M/d(E)', 'ja');

    // 土日にかかるタスク数を計算
    final weekendTasks = _previewTasks.where((t) => t.startsOnWeekend || t.endsOnWeekend).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 土日警告
        if (weekendTasks > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.weekend, size: 16, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  '$weekendTasks件のタスクが土日にかかります',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.amber[900],
                  ),
                ),
              ],
            ),
          ),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: _previewTasks.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final info = _previewTasks[index];
              final hasWeekendIssue = info.startsOnWeekend || info.endsOnWeekend;
              return Container(
                padding: const EdgeInsets.all(12),
                color: hasWeekendIssue
                    ? Colors.amber[50]
                    : (info.isDirect ? Colors.blue[50] : null),
                child: Row(
                  children: [
                    // タスク種別アイコン
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: hasWeekendIssue
                            ? Colors.amber[100]
                            : (info.isDirect ? Colors.blue[100] : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        hasWeekendIssue
                            ? Icons.weekend
                            : (info.isDirect ? Icons.wb_cloudy : Icons.link),
                        size: 14,
                        color: hasWeekendIssue
                            ? Colors.amber[700]
                            : (info.isDirect ? Colors.blue[700] : Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // タスク名
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info.task.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hasWeekendIssue)
                            Text(
                              info.startsOnWeekend && info.endsOnWeekend
                                  ? '開始・終了が土日'
                                  : info.startsOnWeekend
                                      ? '開始が土日'
                                      : '終了が土日',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.amber[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 日程変更
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            shortDateFormat.format(info.newStart),
                            style: TextStyle(
                              fontSize: 11,
                              color: info.startsOnWeekend ? Colors.amber[700] : Colors.grey[600],
                              fontWeight: info.startsOnWeekend ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          Text(
                            '+${info.delayDays}日',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('キャンセル'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _previewTasks.isEmpty
                  ? null
                  : () {
                      Navigator.pop(
                        context,
                        RainCancelResult(
                          rainDate: _selectedDate,
                          delayDays: _delayDays,
                          affectedTasks: _previewTasks,
                        ),
                      );
                    },
              icon: const Text('☔', style: TextStyle(fontSize: 16)),
              label: Text('${_previewTasks.length}件のタスクをスライド'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 雨天中止結果サマリーダイアログ
class RainCancelSummaryDialog extends StatelessWidget {
  final RainCancelResult result;

  const RainCancelSummaryDialog({
    super.key,
    required this.result,
  });

  static Future<void> show({
    required BuildContext context,
    required RainCancelResult result,
  }) {
    return showDialog(
      context: context,
      builder: (context) => RainCancelSummaryDialog(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年M月d日(E)', 'ja');
    final directCount = result.affectedTasks.where((t) => t.isDirect).length;
    final dependentCount = result.affectedTasks.where((t) => !t.isDirect).length;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '日程変更完了',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  '中止日',
                  dateFormat.format(result.rainDate),
                  Icons.calendar_today,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'スライド日数',
                  '${result.delayDays}日',
                  Icons.arrow_forward,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  '変更タスク数',
                  '${result.affectedTasks.length}件',
                  Icons.task_alt,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildCountChip('直接影響', directCount, Colors.blue),
              const SizedBox(width: 8),
              _buildCountChip('依存関係', dependentCount, Colors.orange),
            ],
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCountChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count件',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
