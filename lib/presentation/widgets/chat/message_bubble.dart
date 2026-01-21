import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import 'user_avatar.dart';
import 'document_card.dart';

/// Message bubble component for chat messages
/// Displays sender info, message content, attachments, and read status
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isOwnMessage;
  final bool showAvatar;
  final bool showSenderName;
  final bool showTimestamp;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(Attachment)? onAttachmentTap;
  final VoidCallback? onReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    this.showAvatar = true,
    this.showSenderName = true,
    this.showTimestamp = true,
    this.onTap,
    this.onLongPress,
    this.onAttachmentTap,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystemMessage) {
      return _buildSystemMessage();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingXS,
      ),
      child: Row(
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwnMessage && showAvatar) ...[
            _buildSenderAvatar(),
            const SizedBox(width: AppConstants.paddingS),
          ],
          if (!isOwnMessage && !showAvatar)
            const SizedBox(width: AppConstants.avatarSizeM + AppConstants.paddingS),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isOwnMessage && showSenderName && message.sender != null)
                  _buildSenderName(),
                _buildMessageContent(),
                if (showTimestamp) _buildTimestampRow(),
              ],
            ),
          ),
          if (isOwnMessage && showAvatar) ...[
            const SizedBox(width: AppConstants.paddingS),
            _buildSenderAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: AppConstants.paddingM,
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
            vertical: AppConstants.paddingS,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppConstants.radiusRound),
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildSenderAvatar() {
    if (message.sender == null) {
      return SizedBox(
        width: AppConstants.avatarSizeM,
        height: AppConstants.avatarSizeM,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            color: AppColors.textTertiary,
            size: AppConstants.iconSizeM,
          ),
        ),
      );
    }

    return UserAvatar(
      user: message.sender!,
      size: AppConstants.avatarSizeM,
      showOnlineIndicator: false,
    );
  }

  Widget _buildSenderName() {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppConstants.paddingXS,
        bottom: AppConstants.paddingXS,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.sender?.name ?? '不明なユーザー',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (message.sender?.role != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              child: Text(
                UserRole.getLabel(message.sender!.role),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: AppConstants.chatBubbleMaxWidth,
        ),
        decoration: BoxDecoration(
          color: isOwnMessage
              ? AppColors.chatBubbleSent
              : AppColors.chatBubbleReceived,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppConstants.radiusL),
            topRight: const Radius.circular(AppConstants.radiusL),
            bottomLeft: Radius.circular(
              isOwnMessage ? AppConstants.radiusL : AppConstants.radiusS,
            ),
            bottomRight: Radius.circular(
              isOwnMessage ? AppConstants.radiusS : AppConstants.radiusL,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.replyTo != null) _buildReplyPreview(),
            if (message.content.isNotEmpty) _buildTextContent(),
            if (message.hasAttachments) _buildAttachments(),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(
        left: AppConstants.paddingM,
        right: AppConstants.paddingM,
        top: AppConstants.paddingS,
      ),
      padding: const EdgeInsets.all(AppConstants.paddingS),
      decoration: BoxDecoration(
        color: isOwnMessage
            ? Colors.white.withValues(alpha: 0.15)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border(
          left: BorderSide(
            color: isOwnMessage ? Colors.white54 : AppColors.primary,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyTo?.sender?.name ?? '不明',
            style: TextStyle(
              color: isOwnMessage
                  ? Colors.white.withValues(alpha: 0.8)
                  : AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyTo?.content ?? '',
            style: TextStyle(
              color: isOwnMessage
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppColors.textSecondary,
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    return Padding(
      padding: EdgeInsets.only(
        left: AppConstants.paddingM,
        right: AppConstants.paddingM,
        top: message.replyTo != null
            ? AppConstants.paddingS
            : AppConstants.paddingM,
        bottom: message.hasAttachments
            ? AppConstants.paddingS
            : AppConstants.paddingM,
      ),
      child: Text(
        message.displayContent,
        style: TextStyle(
          color: isOwnMessage
              ? AppColors.chatTextSent
              : AppColors.chatTextReceived,
          fontSize: 14,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildAttachments() {
    return Padding(
      padding: EdgeInsets.only(
        left: AppConstants.paddingS,
        right: AppConstants.paddingS,
        top: message.content.isEmpty ? AppConstants.paddingS : 0,
        bottom: AppConstants.paddingS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: message.attachments.map((attachment) {
          if (attachment.isImage) {
            return _buildImageAttachment(attachment);
          }
          return Padding(
            padding: const EdgeInsets.only(top: AppConstants.paddingXS),
            child: CompactDocumentCard(
              document: attachment,
              onTap: () => onAttachmentTap?.call(attachment),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildImageAttachment(Attachment attachment) {
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.paddingXS),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: GestureDetector(
          onTap: () => onAttachmentTap?.call(attachment),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: AppConstants.chatBubbleMaxWidth - 24,
              maxHeight: 200,
            ),
            child: attachment.thumbnailUrl != null
                ? Image.network(
                    attachment.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder(attachment);
                    },
                  )
                : _buildImagePlaceholder(attachment),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(Attachment attachment) {
    return Container(
      width: 150,
      height: 100,
      color: AppColors.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image,
            color: AppColors.textTertiary,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            attachment.name,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampRow() {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppConstants.paddingXS,
        left: AppConstants.paddingXS,
        right: AppConstants.paddingXS,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.timeString,
            style: const TextStyle(
              color: AppColors.chatTimestamp,
              fontSize: 10,
            ),
          ),
          if (message.isEdited) ...[
            const SizedBox(width: 4),
            const Text(
              '(編集済み)',
              style: TextStyle(
                color: AppColors.chatTimestamp,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (isOwnMessage) ...[
            const SizedBox(width: 4),
            _buildReadStatus(),
          ],
        ],
      ),
    );
  }

  Widget _buildReadStatus() {
    if (message.isRead) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.done_all,
            color: AppColors.primary,
            size: 14,
          ),
          if (message.readBy.isNotEmpty) ...[
            const SizedBox(width: 2),
            Text(
              '${message.readBy.length}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 10,
              ),
            ),
          ],
        ],
      );
    }
    return const Icon(
      Icons.done,
      color: AppColors.chatTimestamp,
      size: 14,
    );
  }
}

/// Date separator between message groups
class DateSeparator extends StatelessWidget {
  final String dateLabel;

  const DateSeparator({
    super.key,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.paddingM,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.divider,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingM,
            ),
            child: Text(
              dateLabel,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.divider,
            ),
          ),
        ],
      ),
    );
  }
}

/// Typing indicator showing when other users are typing
class TypingIndicator extends StatefulWidget {
  final List<User> typingUsers;

  const TypingIndicator({
    super.key,
    required this.typingUsers,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: AppConstants.paddingS,
      ),
      child: Row(
        children: [
          if (widget.typingUsers.length == 1)
            UserAvatar(
              user: widget.typingUsers.first,
              size: 24,
              showOnlineIndicator: false,
            )
          else
            StackedAvatars(
              users: widget.typingUsers,
              avatarSize: 24,
              maxVisible: 3,
            ),
          const SizedBox(width: AppConstants.paddingS),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final animValue = (_controller.value - delay) % 1.0;
                  final opacity = animValue < 0.5
                      ? animValue * 2
                      : 2 - animValue * 2;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withValues(alpha: 0.3 + opacity * 0.7),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(width: AppConstants.paddingS),
          Flexible(
            child: Text(
              _getTypingText(),
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getTypingText() {
    if (widget.typingUsers.length == 1) {
      return '${widget.typingUsers.first.name}が入力中...';
    } else if (widget.typingUsers.length == 2) {
      return '${widget.typingUsers[0].name}と${widget.typingUsers[1].name}が入力中...';
    } else {
      return '${widget.typingUsers.length}人が入力中...';
    }
  }
}
