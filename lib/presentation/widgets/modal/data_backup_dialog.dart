import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/services/project_provider.dart';

/// Dialog for data backup (export/import)
class DataBackupDialog extends StatefulWidget {
  const DataBackupDialog({super.key});

  @override
  State<DataBackupDialog> createState() => _DataBackupDialogState();
}

class _DataBackupDialogState extends State<DataBackupDialog> {
  bool _isLoading = false;
  String? _statusMessage;
  String? _exportedData;

  Future<void> _exportData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'データをエクスポート中...';
    });

    try {
      final provider = context.read<ProjectProvider>();
      final jsonData = await provider.exportAllData();
      
      setState(() {
        _exportedData = jsonData;
        _statusMessage = 'エクスポート完了！下のテキストをコピーしてください。';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'エクスポート失敗: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _importData(String jsonData) async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データインポート確認'),
        content: const Text(
          '既存のデータは上書きされます。\n'
          'バックアップを取っていない場合は、先にエクスポートしてください。\n\n'
          '続行しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('上書きインポート'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'データをインポート中...';
    });

    try {
      final provider = context.read<ProjectProvider>();
      final success = await provider.importAllData(
        jsonData,
        clearFirst: true,
      );
      
      if (success) {
        setState(() {
          _statusMessage = 'インポート完了！アプリを再起動してください。';
          _isLoading = false;
        });
        
        // Show success snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('データのインポートに成功しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _statusMessage = 'インポート失敗: データ形式が不正です';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'インポート失敗: $e';
        _isLoading = false;
      });
    }
  }

  void _showImportDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データインポート'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('バックアップしたJSONデータを貼り付けてください:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 10,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '{"exportDate": "...", ...}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _importData(controller.text);
            },
            child: const Text('インポート'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.backup, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'データバックアップ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),

            // Description
            const Text(
              'プロジェクトとタスクのデータをエクスポート・インポートできます。',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Export section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.file_download, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'エクスポート',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '現在のデータをJSON形式でバックアップします',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _exportData,
                      icon: const Icon(Icons.download),
                      label: const Text('データをエクスポート'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Import section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.file_upload, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'インポート',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'バックアップしたJSONデータから復元します（既存データは上書き）',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _showImportDialog,
                      icon: const Icon(Icons.upload),
                      label: const Text('データをインポート'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Status message
            if (_statusMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusMessage!.contains('失敗')
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusMessage!.contains('失敗')
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
                child: Text(_statusMessage!),
              ),
            ],

            // Exported data display
            if (_exportedData != null) ...[
              const SizedBox(height: 16),
              const Text(
                'エクスポートされたデータ:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _exportedData!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _exportedData!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('クリップボードにコピーしました'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('クリップボードにコピー'),
              ),
            ],

            // Loading indicator
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
