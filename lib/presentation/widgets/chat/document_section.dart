import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import 'document_card.dart';

/// Document section widget displaying pinned/important documents
/// Chatwork "Stock" style - files that won't get lost in chat flow
class DocumentSection extends StatefulWidget {
  final List<Attachment> documents;
  final VoidCallback? onViewAll;
  final Function(Attachment)? onDocumentTap;
  final Function(Attachment)? onDocumentDownload;
  final Function(Attachment)? onDocumentUnpin;
  final bool isExpanded;
  final int maxVisibleDocuments;

  const DocumentSection({
    super.key,
    required this.documents,
    this.onViewAll,
    this.onDocumentTap,
    this.onDocumentDownload,
    this.onDocumentUnpin,
    this.isExpanded = true,
    this.maxVisibleDocuments = 3,
  });

  @override
  State<DocumentSection> createState() => _DocumentSectionState();
}

class _DocumentSectionState extends State<DocumentSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    _expandController = AnimationController(
      duration: AppConstants.animationNormal,
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _expandController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pinnedDocs = widget.documents.where((d) => d.isPinned).toList();
    final displayDocs = pinnedDocs.take(widget.maxVisibleDocuments).toList();
    final hasMore = pinnedDocs.length > widget.maxVisibleDocuments;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sidebarDocSection,
        border: const Border(
          bottom: BorderSide(
            color: AppColors.sidebarDivider,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(pinnedDocs.length),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                if (pinnedDocs.isEmpty)
                  _buildEmptyState()
                else
                  _buildDocumentList(displayDocs),
                if (hasMore || pinnedDocs.isNotEmpty) _buildFooter(hasMore),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return InkWell(
      onTap: _toggleExpanded,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingL,
          vertical: AppConstants.paddingM,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: const Icon(
                Icons.push_pin,
                color: AppColors.primary,
                size: AppConstants.iconSizeS,
              ),
            ),
            const SizedBox(width: AppConstants.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '最新ドキュメント',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$count件のピン留めファイル',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: _isExpanded ? 0 : -0.25,
              duration: AppConstants.animationFast,
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.iconDefault,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentList(List<Attachment> documents) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
      ),
      child: Column(
        children: documents
            .map((doc) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppConstants.paddingS,
                  ),
                  child: DocumentCard(
                    document: doc,
                    onTap: () => widget.onDocumentTap?.call(doc),
                    onDownload: () => widget.onDocumentDownload?.call(doc),
                    onUnpin: () => widget.onDocumentUnpin?.call(doc),
                    showActions: true,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.folder_outlined,
              color: AppColors.textTertiary,
              size: 40,
            ),
            const SizedBox(height: AppConstants.paddingS),
            const Text(
              'ピン留めされたドキュメントはありません',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingXS),
            const Text(
              'メッセージ内のファイルをピン留めして\nここに固定表示できます',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool hasMore) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingL,
        AppConstants.paddingXS,
        AppConstants.paddingL,
        AppConstants.paddingM,
      ),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: widget.onViewAll,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(
              vertical: AppConstants.paddingS,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              side: const BorderSide(
                color: AppColors.border,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.folder_open_outlined,
                size: AppConstants.iconSizeS,
              ),
              const SizedBox(width: AppConstants.paddingS),
              Text(
                hasMore ? '全て表示' : 'ドキュメント管理',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Document filter tabs for filtering by file type
class DocumentFilterTabs extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const DocumentFilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  static const filters = [
    {'key': 'all', 'label': '全て'},
    {'key': 'pdf', 'label': 'PDF'},
    {'key': 'cad', 'label': 'CAD'},
    {'key': 'document', 'label': '文書'},
    {'key': 'image', 'label': '画像'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter['key'];

          return FilterChip(
            selected: isSelected,
            label: Text(filter['label']!),
            onSelected: (_) => onFilterChanged(filter['key']!),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.primary,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingS,
            ),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}
