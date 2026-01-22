import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/pdf_export_service.dart';

/// Export Options Dialog
/// Provides a comprehensive interface for selecting export options
/// including date range, format, content options, and export settings.
class ExportOptionsDialog extends StatefulWidget {
  final String exportType;
  final Function(PDFExportOptions, DateTimeRange?) onExport;
  final DateTimeRange? initialDateRange;
  final bool showDateRange;
  final bool showSignatureOption;
  final String? projectName;

  const ExportOptionsDialog({
    super.key,
    required this.exportType,
    required this.onExport,
    this.initialDateRange,
    this.showDateRange = true,
    this.showSignatureOption = false,
    this.projectName,
  });

  @override
  State<ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<ExportOptionsDialog> {
  late PDFExportFormat _selectedFormat;
  late DateTimeRange? _dateRange;
  bool _includeHeader = true;
  bool _includeFooter = true;
  bool _includePageNumbers = true;
  bool _includeLegend = true;
  bool _includeSignatureFields = false;
  bool _contractSubmissionMode = false;
  String? _companyName;

  @override
  void initState() {
    super.initState();
    _selectedFormat = PDFExportFormat.a4Landscape;
    _dateRange = widget.initialDateRange;
    _includeSignatureFields = widget.showSignatureOption;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormatSection(),
                    if (widget.showDateRange) ...[
                      const SizedBox(height: 20),
                      _buildDateRangeSection(context),
                    ],
                    const SizedBox(height: 20),
                    _buildContentOptionsSection(),
                    const SizedBox(height: 20),
                    _buildContractSubmissionSection(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.picture_as_pdf,
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
                'PDFエクスポート設定',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              if (widget.projectName != null)
                Text(
                  widget.projectName!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildFormatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('用紙サイズ'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PDFExportFormat.values.map((format) {
            final isSelected = _selectedFormat == format;
            return ChoiceChip(
              label: Text(format.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFormat = format);
                }
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRangeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('期間'),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDateRange(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _dateRange != null
                        ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                        : '期間を選択',
                    style: TextStyle(
                      color: _dateRange != null ? AppColors.textPrimary : AppColors.textTertiary,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildQuickDateButton('今週', _getThisWeekRange),
            _buildQuickDateButton('今月', _getThisMonthRange),
            _buildQuickDateButton('過去30日', _getLast30DaysRange),
            _buildQuickDateButton('全期間', () => null),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickDateButton(String label, DateTimeRange? Function() getRange) {
    return OutlinedButton(
      onPressed: () {
        setState(() => _dateRange = getRange());
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: const Size(0, 32),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildContentOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('出力オプション'),
        const SizedBox(height: 8),
        _buildCheckboxTile(
          'ヘッダーを含める',
          'プロジェクト情報と日付',
          _includeHeader,
          (value) => setState(() => _includeHeader = value ?? true),
        ),
        _buildCheckboxTile(
          'フッターを含める',
          'ページ番号と印刷日',
          _includeFooter,
          (value) => setState(() => _includeFooter = value ?? true),
        ),
        _buildCheckboxTile(
          'ページ番号',
          '各ページに番号を表示',
          _includePageNumbers,
          (value) => setState(() => _includePageNumbers = value ?? true),
        ),
        _buildCheckboxTile(
          '凡例を含める',
          'ステータスとカテゴリの説明',
          _includeLegend,
          (value) => setState(() => _includeLegend = value ?? true),
        ),
        if (widget.showSignatureOption)
          _buildCheckboxTile(
            '署名欄を含める',
            '承認者署名用のスペース',
            _includeSignatureFields,
            (value) => setState(() => _includeSignatureFields = value ?? false),
          ),
      ],
    );
  }

  Widget _buildContractSubmissionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '契約書提出用モード',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Switch(
                value: _contractSubmissionMode,
                onChanged: (value) {
                  setState(() {
                    _contractSubmissionMode = value;
                    if (value) {
                      _includeHeader = true;
                      _includeFooter = true;
                      _includePageNumbers = true;
                      _includeLegend = true;
                      _includeSignatureFields = true;
                    }
                  });
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (_contractSubmissionMode) ...[
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: '会社名',
                hintText: '株式会社XXX',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) => _companyName = value,
            ),
            const SizedBox(height: 8),
            Text(
              '正式な契約書提出に適したフォーマットで出力されます。',
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

  Widget _buildCheckboxTile(
    String title,
    String subtitle,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _handleExport,
          icon: const Icon(Icons.download, size: 20),
          label: const Text('エクスポート'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _dateRange,
      locale: const Locale('ja'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
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
      setState(() => _dateRange = picked);
    }
  }

  void _handleExport() {
    final options = _contractSubmissionMode
        ? PDFExportOptions.contractSubmission(companyName: _companyName)
        : PDFExportOptions(
            format: _selectedFormat,
            includeHeader: _includeHeader,
            includeFooter: _includeFooter,
            includePageNumbers: _includePageNumbers,
            includeLegend: _includeLegend,
            includeSignatureFields: _includeSignatureFields,
            contractSubmissionMode: _contractSubmissionMode,
            companyName: _companyName,
          );

    widget.onExport(options, _dateRange);
    Navigator.of(context).pop();
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  DateTimeRange _getThisWeekRange() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return DateTimeRange(
      start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      end: DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day),
    );
  }

  DateTimeRange _getThisMonthRange() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return DateTimeRange(start: startOfMonth, end: endOfMonth);
  }

  DateTimeRange _getLast30DaysRange() {
    final now = DateTime.now();
    return DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );
  }
}

/// PDF Preview Widget
/// Displays a preview of the generated PDF with zoom and navigation controls
class PDFPreviewWidget extends StatefulWidget {
  final Uint8List? pdfData;
  final bool isLoading;
  final String? error;
  final int pageCount;
  final String fileName;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;
  final VoidCallback? onPrint;

  const PDFPreviewWidget({
    super.key,
    this.pdfData,
    this.isLoading = false,
    this.error,
    this.pageCount = 0,
    this.fileName = '',
    this.onDownload,
    this.onShare,
    this.onPrint,
  });

  @override
  State<PDFPreviewWidget> createState() => _PDFPreviewWidgetState();
}

class _PDFPreviewWidgetState extends State<PDFPreviewWidget> {
  int _currentPage = 1;
  double _zoomLevel = 1.0;
  final _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: _buildPreviewArea(),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Text(
            widget.fileName,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          // Zoom controls
          IconButton(
            icon: const Icon(Icons.zoom_out, size: 20),
            onPressed: _zoomLevel > 0.5 ? _zoomOut : null,
            tooltip: '縮小',
            color: AppColors.textSecondary,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${(_zoomLevel * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, size: 20),
            onPressed: _zoomLevel < 3.0 ? _zoomIn : null,
            tooltip: '拡大',
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.fit_screen, size: 20),
            onPressed: _resetZoom,
            tooltip: 'リセット',
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea() {
    if (widget.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'プレビューを読み込み中...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (widget.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              widget.error!,
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (widget.pdfData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'プレビューがありません',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Mock PDF preview with page representation
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 3.0,
      onInteractionEnd: (_) {
        setState(() {
          _zoomLevel = _transformationController.value.getMaxScaleOnAxis();
        });
      },
      child: Center(
        child: Container(
          width: 500,
          height: 700,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Page content placeholder
              Positioned.fill(
                child: Column(
                  children: [
                    // Header
                    Container(
                      height: 60,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 12,
                                  width: 200,
                                  decoration: BoxDecoration(
                                    color: AppColors.textPrimary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 8,
                                  width: 150,
                                  decoration: BoxDecoration(
                                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: List.generate(
                            8,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.getCategoryColor(
                                        ['foundation', 'structure', 'electrical', 'plumbing'][index % 4],
                                      ).withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Page number
              Positioned(
                bottom: 16,
                right: 16,
                child: Text(
                  'ページ $_currentPage / ${widget.pageCount}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        children: [
          // Page navigation
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 ? _previousPage : null,
            color: AppColors.textSecondary,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$_currentPage / ${widget.pageCount}',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < widget.pageCount ? _nextPage : null,
            color: AppColors.textSecondary,
          ),
          const Spacer(),
          // Action buttons
          if (widget.onPrint != null)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: widget.onPrint,
              tooltip: '印刷',
              color: AppColors.textSecondary,
            ),
          if (widget.onShare != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: widget.onShare,
              tooltip: '共有',
              color: AppColors.textSecondary,
            ),
          if (widget.onDownload != null) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: widget.onDownload,
              icon: const Icon(Icons.download, size: 18),
              label: const Text('ダウンロード'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel + 0.25).clamp(0.5, 3.0);
      _transformationController.value = Matrix4.identity()..scale(_zoomLevel);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel - 0.25).clamp(0.5, 3.0);
      _transformationController.value = Matrix4.identity()..scale(_zoomLevel);
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
      _transformationController.value = Matrix4.identity();
    });
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() => _currentPage--);
    }
  }

  void _nextPage() {
    if (_currentPage < widget.pageCount) {
      setState(() => _currentPage++);
    }
  }
}

/// Export Progress Indicator
/// Shows the current progress of PDF generation with stage information
class ExportProgressIndicator extends StatelessWidget {
  final double progress;
  final String stage;
  final VoidCallback? onCancel;
  final bool showPercentage;

  const ExportProgressIndicator({
    super.key,
    required this.progress,
    required this.stage,
    this.onCancel,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated icon
          _buildAnimatedIcon(),
          const SizedBox(height: 20),

          // Progress bar
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 8,
                width: MediaQuery.of(context).size.width * 0.6 * progress,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stage,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              if (showPercentage) ...[
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),

          // Cancel button
          if (onCancel != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onCancel,
              child: const Text('キャンセル'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 4,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const Icon(
              Icons.picture_as_pdf,
              color: AppColors.primary,
              size: 28,
            ),
          ],
        );
      },
    );
  }
}

/// Export Success Dialog
/// Shows success message with options to download, share, or open the PDF
class ExportSuccessDialog extends StatelessWidget {
  final String fileName;
  final int pageCount;
  final DateTime generatedAt;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;
  final VoidCallback? onOpenFolder;
  final VoidCallback? onClose;

  const ExportSuccessDialog({
    super.key,
    required this.fileName,
    required this.pageCount,
    required this.generatedAt,
    this.onDownload,
    this.onShare,
    this.onOpenFolder,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success animation
            _buildSuccessIcon(),
            const SizedBox(height: 20),

            // Title
            const Text(
              'エクスポート完了',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'PDFファイルが正常に生成されました',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // File info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.filePdf.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf,
                      color: AppColors.filePdf,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$pageCount ページ | ${_formatTime(generatedAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                if (onOpenFolder != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onOpenFolder,
                      icon: const Icon(Icons.folder_open, size: 18),
                      label: const Text('フォルダを開く'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                if (onOpenFolder != null && onShare != null) const SizedBox(width: 12),
                if (onShare != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('共有'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Primary action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onDownload ?? onClose,
                icon: Icon(
                  onDownload != null ? Icons.download : Icons.check,
                  size: 18,
                ),
                label: Text(onDownload != null ? 'ダウンロード' : '閉じる'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_circle,
        color: AppColors.success,
        size: 48,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Export Type Selector Widget
/// Quick selector for different export types
class ExportTypeSelector extends StatelessWidget {
  final Function(String) onTypeSelected;
  final String? selectedType;

  const ExportTypeSelector({
    super.key,
    required this.onTypeSelected,
    this.selectedType,
  });

  static const exportTypes = [
    {
      'id': 'gantt',
      'title': 'ガントチャート',
      'titleJa': 'ガントチャート',
      'description': '工程表をPDFでエクスポート',
      'icon': Icons.view_timeline,
    },
    {
      'id': 'photo_ledger',
      'title': '写真台帳',
      'titleJa': '写真台帳',
      'description': '施工写真を整理してエクスポート',
      'icon': Icons.photo_library,
    },
    {
      'id': 'attendance',
      'title': '出勤簿',
      'titleJa': '出勤簿',
      'description': '作業員の出勤記録をエクスポート',
      'icon': Icons.people,
    },
    {
      'id': 'summary',
      'title': 'プロジェクトサマリー',
      'titleJa': 'プロジェクトサマリー',
      'description': 'プロジェクト全体のサマリー',
      'icon': Icons.summarize,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'エクスポート形式を選択',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...exportTypes.map((type) => _buildTypeOption(
              context,
              type['id'] as String,
              type['title'] as String,
              type['description'] as String,
              type['icon'] as IconData,
            )),
      ],
    );
  }

  Widget _buildTypeOption(
    BuildContext context,
    String id,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = selectedType == id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onTypeSelected(id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full Export Screen/Dialog combining all export widgets
class ExportScreen extends StatefulWidget {
  final String? projectName;
  final Function(String exportType, PDFExportOptions options, DateTimeRange? dateRange) onExport;

  const ExportScreen({
    super.key,
    this.projectName,
    required this.onExport,
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  String? _selectedType;
  PDFExportResult? _result;
  bool _isExporting = false;
  double _exportProgress = 0;
  String _exportStage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDFエクスポート'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isExporting
          ? Center(
              child: ExportProgressIndicator(
                progress: _exportProgress,
                stage: _exportStage,
                onCancel: () {
                  setState(() => _isExporting = false);
                },
              ),
            )
          : _result != null
              ? _buildResultView()
              : _buildSelectionView(),
    );
  }

  Widget _buildSelectionView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.projectName != null) ...[
            Text(
              widget.projectName!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'エクスポートするドキュメントを選択してください',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
          ],
          Expanded(
            child: ExportTypeSelector(
              selectedType: _selectedType,
              onTypeSelected: (type) {
                setState(() => _selectedType = type);
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedType != null ? _showOptionsDialog : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('次へ'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    if (_result!.success) {
      return Center(
        child: ExportSuccessDialog(
          fileName: _result!.fileName,
          pageCount: _result!.pageCount,
          generatedAt: _result!.generatedAt,
          onDownload: () {
            // Handle download
          },
          onClose: () {
            setState(() => _result = null);
          },
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _result!.error ?? 'エクスポートに失敗しました',
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() => _result = null);
              },
              child: const Text('戻る'),
            ),
          ],
        ),
      );
    }
  }

  void _showOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => ExportOptionsDialog(
        exportType: _selectedType!,
        projectName: widget.projectName,
        showDateRange: _selectedType != 'gantt',
        showSignatureOption: _selectedType == 'gantt' || _selectedType == 'summary',
        onExport: (options, dateRange) {
          _startExport(options, dateRange);
        },
      ),
    );
  }

  void _startExport(PDFExportOptions options, DateTimeRange? dateRange) {
    setState(() {
      _isExporting = true;
      _exportProgress = 0;
      _exportStage = '準備中...';
    });

    // Simulate export with progress updates
    _simulateExport(options, dateRange);
  }

  Future<void> _simulateExport(PDFExportOptions options, DateTimeRange? dateRange) async {
    for (int i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;

      setState(() {
        _exportProgress = i / 10;
        _exportStage = _getStageMessage(i);
      });
    }

    setState(() {
      _isExporting = false;
      _result = PDFExportResult.success(
        data: Uint8List(0),
        fileName: '${_selectedType}_export.pdf',
        pageCount: 5,
      );
    });

    widget.onExport(_selectedType!, options, dateRange);
  }

  String _getStageMessage(int step) {
    switch (step) {
      case 0:
      case 1:
        return 'データを読み込み中...';
      case 2:
      case 3:
        return 'レイアウトを計算中...';
      case 4:
      case 5:
      case 6:
        return 'ページを生成中...';
      case 7:
      case 8:
        return 'PDFを作成中...';
      case 9:
      case 10:
        return '完了処理中...';
      default:
        return '処理中...';
    }
  }
}
