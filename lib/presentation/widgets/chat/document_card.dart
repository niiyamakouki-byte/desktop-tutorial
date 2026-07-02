import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';

/// Individual document thumbnail card for the pinned documents section
/// Displays file icon, name, type badge, and upload info
class DocumentCard extends StatefulWidget {
  final Attachment document;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  final VoidCallback? onUnpin;
  final bool showActions;

  const DocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.onDownload,
    this.onUnpin,
    this.showActions = false,
  });

  @override
  State<DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<DocumentCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppConstants.animationFast,
          height: AppConstants.documentCardHeight,
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.surfaceVariant : AppColors.surface,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(
              color: _isHovered ? AppColors.borderFocused : AppColors.border,
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              _buildFileIcon(),
              Expanded(child: _buildFileInfo()),
              if (widget.showActions && _isHovered) _buildActions(),
              const SizedBox(width: AppConstants.paddingS),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
    final color = AppColors.getFileTypeColor(widget.document.extension);

    return Container(
      width: 56,
      height: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.radiusM - 1),
          bottomLeft: Radius.circular(AppConstants.radiusM - 1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getFileIcon(),
            color: color,
            size: AppConstants.iconSizeL,
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 1,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
            child: Text(
              widget.document.extension.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.document.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                widget.document.formattedSize,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                  color: AppColors.textTertiary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(widget.document.uploadedAt),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: Icons.download_outlined,
          onTap: widget.onDownload,
          tooltip: 'ダウンロード',
        ),
        if (widget.document.isPinned)
          _ActionButton(
            icon: Icons.push_pin,
            onTap: widget.onUnpin,
            tooltip: 'ピン留め解除',
            isActive: true,
          ),
      ],
    );
  }

  IconData _getFileIcon() {
    switch (widget.document.extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'dwg':
      case 'dxf':
        return Icons.architecture;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今日';
    } else if (diff.inDays == 1) {
      return '昨日';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}日前';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    this.onTap,
    required this.tooltip,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.paddingXS),
          child: Icon(
            icon,
            size: AppConstants.iconSizeS,
            color: isActive ? AppColors.primary : AppColors.iconDefault,
          ),
        ),
      ),
    );
  }
}

/// Compact document card for displaying in message attachments
class CompactDocumentCard extends StatelessWidget {
  final Attachment document;
  final VoidCallback? onTap;

  const CompactDocumentCard({
    super.key,
    required this.document,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getFileTypeColor(document.extension);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingS),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Icon(
                _getFileIcon(),
                color: color,
                size: AppConstants.iconSizeM,
              ),
            ),
            const SizedBox(width: AppConstants.paddingS),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    document.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    document.formattedSize,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.paddingS),
            Icon(
              Icons.download_outlined,
              color: AppColors.iconDefault,
              size: AppConstants.iconSizeS,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon() {
    switch (document.extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'dwg':
      case 'dxf':
        return Icons.architecture;
      default:
        return Icons.insert_drive_file;
    }
  }
}
