import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/template_service.dart';

/// Panel for displaying and using AI prompts and templates
class TemplatePanel extends StatefulWidget {
  final Function(String content)? onExportCsv;

  const TemplatePanel({
    super.key,
    this.onExportCsv,
  });

  @override
  State<TemplatePanel> createState() => _TemplatePanelState();
}

class _TemplatePanelState extends State<TemplatePanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedPromptId;
  String? _selectedSpreadsheetId;
  bool _showPromptPreview = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          // Tab bar
          _buildTabBar(),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPromptsTab(),
                _buildSpreadsheetsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome,
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
                  'AIテンプレート & エクスポート',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'お使いのAI (ChatGPT, Claude等) で使えるプロンプトと出力テンプレート',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_outlined, size: 18),
                SizedBox(width: 8),
                Text('AIプロンプト'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.table_chart_outlined, size: 18),
                SizedBox(width: 8),
                Text('スプレッドシート'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptsTab() {
    final prompts = TemplateService.getAvailablePrompts();

    return Row(
      children: [
        // Prompt list
        SizedBox(
          width: 280,
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.paddingS),
            itemCount: prompts.length,
            itemBuilder: (context, index) {
              final prompt = prompts[index];
              final isSelected = prompt.id == _selectedPromptId;

              return _PromptCard(
                prompt: prompt,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedPromptId = prompt.id;
                    _showPromptPreview = true;
                  });
                },
              );
            },
          ),
        ),
        // Divider
        Container(
          width: 1,
          color: AppColors.border,
        ),
        // Preview/Detail
        Expanded(
          child: _selectedPromptId != null && _showPromptPreview
              ? _PromptPreview(
                  promptId: _selectedPromptId!,
                  onCopy: () => _copyPromptToClipboard(_selectedPromptId!),
                )
              : _buildPromptEmptyState(),
        ),
      ],
    );
  }

  Widget _buildPromptEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 48,
            color: AppColors.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'プロンプトを選択してください',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'コピーしてChatGPTやClaudeで使用できます',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpreadsheetsTab() {
    final templates = TemplateService.getAvailableSpreadsheets();

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];

        return _SpreadsheetCard(
          template: template,
          onExport: () => _exportSpreadsheet(template.id),
          onPreview: () => _previewSpreadsheet(template.id),
        );
      },
    );
  }

  void _copyPromptToClipboard(String promptId) {
    final content = TemplateService.getPromptContent(promptId);
    Clipboard.setData(ClipboardData(text: content));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('プロンプトをコピーしました'),
          ],
        ),
        backgroundColor: AppColors.constructionGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _exportSpreadsheet(String templateId) {
    String content;
    String filename;

    switch (templateId) {
      case 'material_list':
        content = SpreadsheetTemplates.getMaterialListCsv();
        filename = 'material_list.csv';
        break;
      case 'order_sheet':
        content = SpreadsheetTemplates.getOrderSheetCsv();
        filename = 'order_sheet.csv';
        break;
      default:
        content = '';
        filename = 'export.csv';
    }

    widget.onExportCsv?.call(content);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('$filename をエクスポートしました'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _previewSpreadsheet(String templateId) {
    String content;
    switch (templateId) {
      case 'material_list':
        content = SpreadsheetTemplates.getMaterialListCsv();
        break;
      case 'order_sheet':
        content = SpreadsheetTemplates.getOrderSheetCsv();
        break;
      default:
        content = '';
    }

    showDialog(
      context: context,
      builder: (context) => _SpreadsheetPreviewDialog(
        title: TemplateService.getAvailableSpreadsheets()
            .firstWhere((t) => t.id == templateId)
            .name,
        content: content,
        onCopy: () {
          Clipboard.setData(ClipboardData(text: content));
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSVをコピーしました')),
          );
        },
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final PromptTemplate prompt;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PromptCard({
    required this.prompt,
    this.isSelected = false,
    this.onTap,
  });

  IconData get _icon {
    switch (prompt.icon) {
      case 'description':
        return Icons.description_outlined;
      case 'calculate':
        return Icons.calculate_outlined;
      case 'schedule':
        return Icons.schedule_outlined;
      case 'receipt_long':
        return Icons.receipt_long_outlined;
      case 'compare':
        return Icons.compare_outlined;
      default:
        return Icons.chat_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.2)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prompt.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prompt.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptPreview extends StatelessWidget {
  final String promptId;
  final VoidCallback? onCopy;

  const _PromptPreview({
    required this.promptId,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final content = TemplateService.getPromptContent(promptId);
    final prompts = TemplateService.getAvailablePrompts();
    final prompt = prompts.firstWhere((p) => p.id == promptId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            border: Border(
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prompt.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prompt.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('コピー'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: SelectableText(
                content,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        // Usage hint
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingS),
          margin: const EdgeInsets.all(AppConstants.paddingM),
          decoration: BoxDecoration(
            color: AppColors.infoLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.info, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '「コピー」ボタンでクリップボードにコピーし、ChatGPTやClaudeに貼り付けて使用してください',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpreadsheetCard extends StatelessWidget {
  final SpreadsheetTemplate template;
  final VoidCallback? onExport;
  final VoidCallback? onPreview;

  const _SpreadsheetCard({
    required this.template,
    this.onExport,
    this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.constructionGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.table_chart,
                color: AppColors.constructionGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      template.format.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onPreview,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('プレビュー'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onExport,
              icon: const Icon(Icons.download, size: 16),
              label: const Text('ダウンロード'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.constructionGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpreadsheetPreviewDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback? onCopy;

  const _SpreadsheetPreviewDialog({
    required this.title,
    required this.content,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: SelectableText(
                      content,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('閉じる'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('コピー'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
