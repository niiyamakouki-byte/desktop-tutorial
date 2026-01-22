import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import 'message_bubble.dart';
import 'message_input.dart';

/// Chat section widget displaying timeline messages
/// Slack "Flow" style - messages flow in timeline order
class ChatSection extends StatefulWidget {
  final List<Message> messages;
  final User currentUser;
  final List<User> typingUsers;
  final Message? replyingTo;
  final Function(String text, List<Attachment> attachments)? onSendMessage;
  final Function(String)? onTyping;
  final VoidCallback? onAttachmentTap;
  final Function(Message)? onMessageTap;
  final Function(Message)? onMessageLongPress;
  final Function(Message)? onReply;
  final VoidCallback? onCancelReply;
  final Function(Attachment)? onAttachmentOpen;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;
  final bool hasMoreMessages;

  const ChatSection({
    super.key,
    required this.messages,
    required this.currentUser,
    this.typingUsers = const [],
    this.replyingTo,
    this.onSendMessage,
    this.onTyping,
    this.onAttachmentTap,
    this.onMessageTap,
    this.onMessageLongPress,
    this.onReply,
    this.onCancelReply,
    this.onAttachmentOpen,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.hasMoreMessages = false,
  });

  @override
  State<ChatSection> createState() => _ChatSectionState();
}

class _ChatSectionState extends State<ChatSection> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Show scroll to bottom button when scrolled up
    final showButton = _scrollController.offset > 200;
    if (_showScrollToBottom != showButton) {
      setState(() {
        _showScrollToBottom = showButton;
      });
    }

    // Load more messages when reaching top
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !widget.isLoadingMore &&
        widget.hasMoreMessages) {
      widget.onLoadMore?.call();
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: AppConstants.animationNormal,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.chatBackground,
      child: Column(
        children: [
          _buildChatHeader(),
          Expanded(child: _buildMessageList()),
          if (widget.typingUsers.isNotEmpty)
            TypingIndicator(typingUsers: widget.typingUsers),
          MessageInput(
            currentUser: widget.currentUser,
            replyingTo: widget.replyingTo,
            onSend: widget.onSendMessage,
            onTyping: widget.onTyping,
            onAttachmentTap: widget.onAttachmentTap,
            onCancelReply: widget.onCancelReply,
          ),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    final unreadCount = widget.messages.where((m) => !m.isRead && m.senderId != widget.currentUser.id).length;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingL,
        vertical: AppConstants.paddingM,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.primary,
              size: AppConstants.iconSizeM,
            ),
          ),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'プロジェクトチャット',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${widget.messages.length}件のメッセージ',
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.chatUnread,
                borderRadius: BorderRadius.circular(AppConstants.radiusRound),
              ),
              child: Text(
                '$unreadCount件の未読',
                style: const TextStyle(
                  color: AppColors.textOnPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: AppConstants.paddingS),
          IconButton(
            onPressed: () {
              // Search functionality
            },
            icon: const Icon(
              Icons.search,
              color: AppColors.iconDefault,
            ),
            tooltip: 'メッセージを検索',
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final messageGroups = MessageGroup.groupByDate(widget.messages);

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.paddingM,
          ),
          itemCount: _calculateItemCount(messageGroups),
          itemBuilder: (context, index) {
            return _buildListItem(messageGroups, index);
          },
        ),
        if (_showScrollToBottom)
          Positioned(
            right: AppConstants.paddingM,
            bottom: AppConstants.paddingM,
            child: _buildScrollToBottomButton(),
          ),
        if (widget.isLoadingMore)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }

  int _calculateItemCount(List<MessageGroup> groups) {
    int count = 0;
    for (final group in groups) {
      count += group.messages.length + 1; // +1 for date separator
    }
    return count;
  }

  Widget _buildListItem(List<MessageGroup> groups, int index) {
    // Navigate through reversed groups (newest first in reverse list)
    int currentIndex = 0;

    for (int i = groups.length - 1; i >= 0; i--) {
      final group = groups[i];
      final groupSize = group.messages.length + 1;

      if (index < currentIndex + groupSize) {
        final localIndex = index - currentIndex;

        if (localIndex == group.messages.length) {
          // Date separator (at the end of each group in reverse order)
          return DateSeparator(dateLabel: group.dateLabel);
        }

        // Message (reversed within group)
        final messageIndex = group.messages.length - 1 - localIndex;
        final message = group.messages[messageIndex];
        final previousMessage = messageIndex > 0
            ? group.messages[messageIndex - 1]
            : null;

        return _buildMessageBubble(message, previousMessage);
      }

      currentIndex += groupSize;
    }

    return const SizedBox.shrink();
  }

  Widget _buildMessageBubble(Message message, Message? previousMessage) {
    final isOwnMessage = message.senderId == widget.currentUser.id;
    final showAvatar = previousMessage == null ||
        previousMessage.senderId != message.senderId ||
        message.sentAt.difference(previousMessage.sentAt).inMinutes > 5;

    return MessageBubble(
      message: message,
      isOwnMessage: isOwnMessage,
      showAvatar: showAvatar,
      showSenderName: !isOwnMessage && showAvatar,
      onTap: () => widget.onMessageTap?.call(message),
      onLongPress: () => widget.onMessageLongPress?.call(message),
      onAttachmentTap: widget.onAttachmentOpen,
      onReply: () => widget.onReply?.call(message),
    );
  }

  Widget _buildScrollToBottomButton() {
    return GestureDetector(
      onTap: _scrollToBottom,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.keyboard_arrow_down,
          color: AppColors.iconDefault,
        ),
      ),
    );
  }
}

/// Empty state widget when there are no messages
class EmptyChatState extends StatelessWidget {
  final String projectName;
  final VoidCallback? onStartChat;

  const EmptyChatState({
    super.key,
    required this.projectName,
    this.onStartChat,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),
            Text(
              '$projectNameのチャット',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingS),
            const Text(
              'チームメンバーとコミュニケーションを\n始めましょう',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingXL),
            ElevatedButton.icon(
              onPressed: onStartChat,
              icon: const Icon(Icons.waving_hand),
              label: const Text('挨拶を送る'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingXL,
                  vertical: AppConstants.paddingM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Message action sheet for long press actions
class MessageActionSheet extends StatelessWidget {
  final Message message;
  final bool isOwnMessage;
  final VoidCallback? onReply;
  final VoidCallback? onCopy;
  final VoidCallback? onPin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MessageActionSheet({
    super.key,
    required this.message,
    required this.isOwnMessage,
    this.onReply,
    this.onCopy,
    this.onPin,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusL),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(
                vertical: AppConstants.paddingM,
              ),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _ActionItem(
              icon: Icons.reply,
              label: '返信',
              onTap: onReply,
            ),
            _ActionItem(
              icon: Icons.copy,
              label: 'コピー',
              onTap: onCopy,
            ),
            _ActionItem(
              icon: Icons.push_pin_outlined,
              label: 'ピン留め',
              onTap: onPin,
            ),
            if (isOwnMessage) ...[
              _ActionItem(
                icon: Icons.edit_outlined,
                label: '編集',
                onTap: onEdit,
              ),
              _ActionItem(
                icon: Icons.delete_outline,
                label: '削除',
                onTap: onDelete,
                isDestructive: true,
              ),
            ],
            const SizedBox(height: AppConstants.paddingM),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _ActionItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingL,
          vertical: AppConstants.paddingM,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? AppColors.error : AppColors.iconDefault,
              size: AppConstants.iconSizeL,
            ),
            const SizedBox(width: AppConstants.paddingM),
            Text(
              label,
              style: TextStyle(
                color: isDestructive ? AppColors.error : AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
