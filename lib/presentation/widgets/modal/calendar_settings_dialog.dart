import 'package:flutter/material.dart';
import '../../../data/models/calendar_settings_model.dart';

/// カレンダー設定ダイアログ
/// 土日祝日の除外設定を変更する
class CalendarSettingsDialog extends StatefulWidget {
  final CalendarSettings initialSettings;
  final Function(CalendarSettings) onSave;

  const CalendarSettingsDialog({
    Key? key,
    required this.initialSettings,
    required this.onSave,
  }) : super(key: key);

  @override
  State<CalendarSettingsDialog> createState() => _CalendarSettingsDialogState();
}

class _CalendarSettingsDialogState extends State<CalendarSettingsDialog> {
  late bool _excludeWeekends;
  late bool _excludeHolidays;
  late List<DateTime> _customHolidays;

  @override
  void initState() {
    super.initState();
    _excludeWeekends = widget.initialSettings.excludeWeekends;
    _excludeHolidays = widget.initialSettings.excludeHolidays;
    _customHolidays = List.from(widget.initialSettings.customHolidays);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.calendar_today, size: 24),
          SizedBox(width: 8),
          Text('営業日設定'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'タスク日程計算で考慮する休日を設定します',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            // 土日除外チェックボックス
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('土日を除外'),
              subtitle: const Text(
                '土曜日・日曜日を営業日から除外します',
                style: TextStyle(fontSize: 12),
              ),
              value: _excludeWeekends,
              onChanged: (value) {
                setState(() {
                  _excludeWeekends = value ?? true;
                });
              },
            ),
            
            const SizedBox(height: 8),
            
            // 祝日除外チェックボックス
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('祝日を除外'),
              subtitle: const Text(
                '日本の祝日（2026-2030年）を営業日から除外します',
                style: TextStyle(fontSize: 12),
              ),
              value: _excludeHolidays,
              onChanged: (value) {
                setState(() {
                  _excludeHolidays = value ?? true;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // カスタム休日セクション
            Row(
              children: [
                const Text(
                  'カスタム休日',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addCustomHoliday,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('追加'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
            
            if (_customHolidays.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'カスタム休日が設定されていません',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              )
            else
              ..._customHolidays.asMap().entries.map((entry) {
                final index = entry.key;
                final date = entry.value;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  dense: true,
                  leading: const Icon(Icons.event, size: 20),
                  title: Text(
                    '${date.year}年${date.month}月${date.day}日',
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () {
                      setState(() {
                        _customHolidays.removeAt(index);
                      });
                    },
                  ),
                );
              }).toList(),
              
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            
            // プレビュー
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        '適用例',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getPreviewText(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _addCustomHoliday() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2026),
      lastDate: DateTime(2030, 12, 31),
      locale: const Locale('ja', 'JP'),
      helpText: 'カスタム休日を選択',
    );
    
    if (date != null) {
      setState(() {
        // 日付のみを保存（時刻情報を削除）
        final dateOnly = DateTime(date.year, date.month, date.day);
        if (!_customHolidays.any((d) => 
            d.year == dateOnly.year && 
            d.month == dateOnly.month && 
            d.day == dateOnly.day)) {
          _customHolidays.add(dateOnly);
          _customHolidays.sort();
        }
      });
    }
  }

  String _getPreviewText() {
    if (!_excludeWeekends && !_excludeHolidays) {
      return '全ての日が営業日として計算されます。\n例: 10カレンダー日 = 10営業日';
    }
    
    final parts = <String>[];
    if (_excludeWeekends) parts.add('土日');
    if (_excludeHolidays) parts.add('祝日');
    if (_customHolidays.isNotEmpty) {
      parts.add('カスタム休日(${_customHolidays.length}件)');
    }
    
    final excluded = parts.join('、');
    return '${excluded}を除外して営業日を計算します。\n例: 2026/2/10(月) + 5営業日 → 2026/2/16(月)';
  }

  void _save() {
    final newSettings = CalendarSettings(
      excludeWeekends: _excludeWeekends,
      excludeHolidays: _excludeHolidays,
      customHolidays: _customHolidays,
    );
    widget.onSave(newSettings);
    Navigator.of(context).pop();
  }
}

/// カレンダー設定を表示するヘルパー関数
void showCalendarSettingsDialog({
  required BuildContext context,
  required CalendarSettings initialSettings,
  required Function(CalendarSettings) onSave,
}) {
  showDialog(
    context: context,
    builder: (context) => CalendarSettingsDialog(
      initialSettings: initialSettings,
      onSave: onSave,
    ),
  );
}
