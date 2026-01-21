import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import 'sidebar_header.dart';
import 'document_section.dart';
import 'chat_section.dart';

/// Main communication sidebar combining Slack + Chatwork features
/// TOP SECTION: Chatwork "Stock" style - pinned documents
/// BOTTOM SECTION: Slack "Flow" style - timeline chat messages
class CommunicationSidebar extends StatefulWidget {
  final bool isOpen;
  final Project project;
  final User currentUser;
  final List<Message> messages;
  final List<Attachment> documents;
  final List<User> typingUsers;
  final Message? replyingTo;
  final VoidCallback? onClose;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onMembersTap;
  final Function(Attachment)? onDocumentTap;
  final Function(Attachment)? onDocumentDownload;
  final Function(Attachment)? onDocumentUnpin;
  final VoidCallback? onViewAllDocuments;
  final Function(String text, List<Attachment> attachments)? onSendMessage;
  final Function(String)? onTyping;
  final VoidCallback? onAttachmentTap;
  final Function(Message)? onMessageTap;
  final Function(Message)? onMessageLongPress;
  final Function(Message)? onReply;
  final VoidCallback? onCancelReply;
  final Function(Attachment)? onAttachmentOpen;
  final VoidCallback? onLoadMoreMessages;
  final bool isLoadingMoreMessages;
  final bool hasMoreMessages;

  const CommunicationSidebar({
    super.key,
    required this.isOpen,
    required this.project,
    required this.currentUser,
    required this.messages,
    required this.documents,
    this.typingUsers = const [],
    this.replyingTo,
    this.onClose,
    this.onSettingsTap,
    this.onMembersTap,
    this.onDocumentTap,
    this.onDocumentDownload,
    this.onDocumentUnpin,
    this.onViewAllDocuments,
    this.onSendMessage,
    this.onTyping,
    this.onAttachmentTap,
    this.onMessageTap,
    this.onMessageLongPress,
    this.onReply,
    this.onCancelReply,
    this.onAttachmentOpen,
    this.onLoadMoreMessages,
    this.isLoadingMoreMessages = false,
    this.hasMoreMessages = false,
  });

  @override
  State<CommunicationSidebar> createState() => _CommunicationSidebarState();
}

class _CommunicationSidebarState extends State<CommunicationSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.sidebarAnimationDuration,
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    if (widget.isOpen) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CommunicationSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        if (_animationController.value == 0) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            // Backdrop
            if (_fadeAnimation.value > 0)
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3 * _fadeAnimation.value),
                ),
              ),
            // Sidebar
            Positioned(
              top: 0,
              bottom: 0,
              right: -AppConstants.sidebarWidth * _slideAnimation.value,
              width: AppConstants.sidebarWidth,
              child: _buildSidebarContent(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSidebarContent() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: 20,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header section
          SidebarHeader(
            project: widget.project,
            onClose: widget.onClose,
            onSettingsTap: widget.onSettingsTap,
            onMembersTap: widget.onMembersTap,
          ),
          // Document section (Stock)
          DocumentSection(
            documents: widget.documents,
            onViewAll: widget.onViewAllDocuments,
            onDocumentTap: widget.onDocumentTap,
            onDocumentDownload: widget.onDocumentDownload,
            onDocumentUnpin: widget.onDocumentUnpin,
          ),
          // Chat section (Flow)
          Expanded(
            child: ChatSection(
              messages: widget.messages,
              currentUser: widget.currentUser,
              typingUsers: widget.typingUsers,
              replyingTo: widget.replyingTo,
              onSendMessage: widget.onSendMessage,
              onTyping: widget.onTyping,
              onAttachmentTap: widget.onAttachmentTap,
              onMessageTap: widget.onMessageTap,
              onMessageLongPress: widget.onMessageLongPress,
              onReply: widget.onReply,
              onCancelReply: widget.onCancelReply,
              onAttachmentOpen: widget.onAttachmentOpen,
              onLoadMore: widget.onLoadMoreMessages,
              isLoadingMore: widget.isLoadingMoreMessages,
              hasMoreMessages: widget.hasMoreMessages,
            ),
          ),
        ],
      ),
    );
  }
}

/// Toggle button for opening/closing the communication sidebar
class CommunicationSidebarToggle extends StatelessWidget {
  final bool isOpen;
  final int unreadCount;
  final VoidCallback? onToggle;

  const CommunicationSidebarToggle({
    super.key,
    required this.isOpen,
    this.unreadCount = 0,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            child: Container(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              decoration: BoxDecoration(
                color: isOpen ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(
                  color: isOpen ? AppColors.primary : AppColors.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOpen ? Icons.chat : Icons.chat_bubble_outline,
                    color: isOpen ? AppColors.textOnPrimary : AppColors.iconDefault,
                    size: AppConstants.iconSizeM,
                  ),
                  const SizedBox(width: AppConstants.paddingS),
                  Text(
                    'チャット',
                    style: TextStyle(
                      color: isOpen ? AppColors.textOnPrimary : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.chatUnread,
                borderRadius: BorderRadius.circular(AppConstants.radiusRound),
                border: Border.all(
                  color: AppColors.surface,
                  width: 2,
                ),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: AppColors.textOnPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Mini sidebar view for collapsed state
class MiniCommunicationSidebar extends StatelessWidget {
  final Project project;
  final int unreadCount;
  final List<Attachment> recentDocuments;
  final VoidCallback? onExpand;
  final Function(Attachment)? onDocumentTap;

  const MiniCommunicationSidebar({
    super.key,
    required this.project,
    this.unreadCount = 0,
    this.recentDocuments = const [],
    this.onExpand,
    this.onDocumentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          left: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildExpandButton(),
          const Divider(height: 1, color: AppColors.border),
          _buildChatButton(),
          if (recentDocuments.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.border),
            _buildDocumentIcons(),
          ],
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildExpandButton() {
    return InkWell(
      onTap: onExpand,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: const Icon(
          Icons.chevron_left,
          color: AppColors.iconDefault,
        ),
      ),
    );
  }

  Widget _buildChatButton() {
    return InkWell(
      onTap: onExpand,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.iconDefault,
            ),
            if (unreadCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.chatUnread,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentIcons() {
    return Column(
      children: recentDocuments.take(3).map((doc) {
        return InkWell(
          onTap: () => onDocumentTap?.call(doc),
          child: Tooltip(
            message: doc.name,
            child: Container(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              child: Icon(
                _getDocumentIcon(doc.extension),
                color: AppColors.getFileTypeColor(doc.extension),
                size: AppConstants.iconSizeM,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getDocumentIcon(String extension) {
    switch (extension.toLowerCase()) {
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
