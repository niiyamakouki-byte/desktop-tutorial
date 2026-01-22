import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import 'user_avatar.dart';

/// Message input field with attachment button and send functionality
/// Supports text input, file attachments, and reply-to functionality
class MessageInput extends StatefulWidget {
  final Function(String text, List<Attachment> attachments)? onSend;
  final Function(String)? onTyping;
  final VoidCallback? onAttachmentTap;
  final Message? replyingTo;
  final VoidCallback? onCancelReply;
  final User? currentUser;
  final bool enabled;
  final String? placeholder;
  final bool autoFocus;
  final VoidCallback? onMessageSent;

  const MessageInput({
    super.key,
    this.onSend,
    this.onTyping,
    this.onAttachmentTap,
    this.replyingTo,
    this.onCancelReply,
    this.currentUser,
    this.enabled = true,
    this.placeholder,
    this.autoFocus = false,
    this.onMessageSent,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Attachment> _pendingAttachments = [];
  bool _isComposing = false;
  bool _isSending = false;
  bool _showSentFeedback = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    // Auto-focus when widget is first built if autoFocus is true
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(MessageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Request focus when autoFocus changes from false to true
    if (widget.autoFocus && !oldWidget.autoFocus && widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isComposing = _textController.text.trim().isNotEmpty;
    if (_isComposing != isComposing) {
      setState(() {
        _isComposing = isComposing;
      });
    }
    widget.onTyping?.call(_textController.text);
  }

  void _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;
    if (_isSending) return; // Prevent double-send

    setState(() {
      _isSending = true;
    });

    // Call send callback
    widget.onSend?.call(text, List.from(_pendingAttachments));

    // Clear input
    _textController.clear();
    _pendingAttachments.clear();

    // Show sent feedback briefly
    setState(() {
      _isComposing = false;
      _isSending = false;
      _showSentFeedback = true;
    });

    // Notify parent that message was sent (for auto-scroll)
    widget.onMessageSent?.call();

    // Hide feedback after brief delay
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _showSentFeedback = false;
      });
    }

    // Keep focus on input for continuous typing
    _focusNode.requestFocus();
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter &&
          !HardwareKeyboard.instance.isShiftPressed) {
        _handleSend();
      }
    }
  }

  void _removeAttachment(Attachment attachment) {
    setState(() {
      _pendingAttachments.remove(attachment);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.chatInputBg,
        border: const Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.replyingTo != null) _buildReplyBanner(),
            if (_pendingAttachments.isNotEmpty) _buildAttachmentPreview(),
            _buildInputRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingS,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppConstants.paddingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.reply,
                      color: AppColors.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.replyingTo?.sender?.name ?? "不明"}に返信',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.replyingTo?.content ?? '',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onCancelReply,
            icon: const Icon(
              Icons.close,
              color: AppColors.iconDefault,
              size: 18,
            ),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: EdgeInsets.zero,
            tooltip: 'キャンセル',
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingS),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _pendingAttachments.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final attachment = _pendingAttachments[index];
            return _AttachmentPreviewItem(
              attachment: attachment,
              onRemove: () => _removeAttachment(attachment),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputRow() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAttachmentButton(),
          const SizedBox(width: AppConstants.paddingS),
          Expanded(child: _buildTextField()),
          const SizedBox(width: AppConstants.paddingS),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildAttachmentButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.enabled ? widget.onAttachmentTap : null,
        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.attach_file,
            color: widget.enabled ? AppColors.iconDefault : AppColors.textTertiary,
            size: AppConstants.iconSizeM,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 40,
        maxHeight: 120,
      ),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: _focusNode.hasFocus ? AppColors.borderFocused : AppColors.border,
        ),
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _handleKeyPress,
        child: TextField(
          controller: _textController,
          focusNode: _focusNode,
          enabled: widget.enabled,
          maxLines: null,
          maxLength: AppConstants.maxMessageLength,
          textInputAction: TextInputAction.newline,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: widget.placeholder ?? 'メッセージを入力...  (Enter送信 / Shift+Enter改行)',
            hintStyle: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingM,
              vertical: AppConstants.paddingS,
            ),
            counterText: '',
            suffixIcon: _textController.text.length > 4500
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '${_textController.text.length}/${AppConstants.maxMessageLength}',
                      style: TextStyle(
                        color: _textController.text.length > 4900
                            ? AppColors.error
                            : AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    final canSend = (_isComposing || _pendingAttachments.isNotEmpty) && !_isSending;

    // Show sent feedback (checkmark)
    if (_showSentFeedback) {
      return AnimatedContainer(
        duration: AppConstants.animationFast,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: AppConstants.iconSizeM,
          ),
        ),
      );
    }

    // Show loading state
    if (_isSending) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
        ),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: AppConstants.animationFast,
      child: Material(
        color: Colors.transparent,
        child: Tooltip(
          message: canSend ? '送信 (Enter)' : '',
          child: InkWell(
            onTap: canSend && widget.enabled ? _handleSend : null,
            borderRadius: BorderRadius.circular(AppConstants.radiusRound),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: canSend && widget.enabled
                    ? AppColors.primaryGradient
                    : null,
                color: canSend && widget.enabled ? null : AppColors.surfaceVariant,
                shape: BoxShape.circle,
                boxShadow: canSend && widget.enabled
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.send,
                color: canSend && widget.enabled
                    ? AppColors.textOnPrimary
                    : AppColors.textTertiary,
                size: AppConstants.iconSizeM,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentPreviewItem extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback onRemove;

  const _AttachmentPreviewItem({
    required this.attachment,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            border: Border.all(color: AppColors.border),
          ),
          child: _buildContent(),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surface,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.close,
                color: AppColors.textOnPrimary,
                size: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (attachment.isImage && attachment.thumbnailUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusM - 1),
        child: Image.network(
          attachment.thumbnailUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFileIcon(),
        ),
      );
    }
    return _buildFileIcon();
  }

  Widget _buildFileIcon() {
    final color = AppColors.getFileTypeColor(attachment.extension);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _getIcon(),
          color: color,
          size: 28,
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            attachment.name,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  IconData _getIcon() {
    switch (attachment.extension.toLowerCase()) {
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

/// Quick action buttons row above the message input
class QuickActionBar extends StatelessWidget {
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;
  final VoidCallback? onDocument;
  final VoidCallback? onLocation;

  const QuickActionBar({
    super.key,
    this.onCamera,
    this.onGallery,
    this.onDocument,
    this.onLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: AppConstants.paddingS,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _QuickActionButton(
            icon: Icons.camera_alt_outlined,
            label: 'カメラ',
            onTap: onCamera,
          ),
          _QuickActionButton(
            icon: Icons.photo_library_outlined,
            label: '写真',
            onTap: onGallery,
          ),
          _QuickActionButton(
            icon: Icons.description_outlined,
            label: 'ファイル',
            onTap: onDocument,
          ),
          _QuickActionButton(
            icon: Icons.location_on_outlined,
            label: '位置情報',
            onTap: onLocation,
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.paddingS,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: AppConstants.iconSizeL,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
