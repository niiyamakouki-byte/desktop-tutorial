import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';

/// Assignee selector widget for selecting task assignees
/// Displays user avatars with selection capabilities
class AssigneeSelector extends StatefulWidget {
  /// List of all available users
  final List<User> availableUsers;

  /// List of currently selected users
  final List<User> selectedUsers;

  /// Callback when selection changes
  final ValueChanged<List<User>> onChanged;

  /// Whether the selector is enabled
  final bool enabled;

  /// Optional label text
  final String? label;

  /// Maximum number of assignees allowed
  final int? maxAssignees;

  const AssigneeSelector({
    super.key,
    required this.availableUsers,
    required this.selectedUsers,
    required this.onChanged,
    this.enabled = true,
    this.label,
    this.maxAssignees,
  });

  @override
  State<AssigneeSelector> createState() => _AssigneeSelectorState();
}

class _AssigneeSelectorState extends State<AssigneeSelector> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (!widget.enabled) return;

    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
    Future.delayed(AppConstants.animationFast, () {
      _searchFocusNode.requestFocus();
    });
  }

  void _closeDropdown() {
    _removeOverlay();
    _searchController.clear();
    _searchQuery = '';
    setState(() => _isOpen = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleUser(User user) {
    final isSelected = widget.selectedUsers.any((u) => u.id == user.id);
    List<User> newSelection;

    if (isSelected) {
      newSelection = widget.selectedUsers.where((u) => u.id != user.id).toList();
    } else {
      if (widget.maxAssignees != null &&
          widget.selectedUsers.length >= widget.maxAssignees!) {
        // Remove first user if max reached
        newSelection = [...widget.selectedUsers.skip(1), user];
      } else {
        newSelection = [...widget.selectedUsers, user];
      }
    }

    widget.onChanged(newSelection);
    _overlayEntry?.markNeedsBuild();
  }

  void _removeUser(User user) {
    final newSelection =
        widget.selectedUsers.where((u) => u.id != user.id).toList();
    widget.onChanged(newSelection);
  }

  List<User> get _filteredUsers {
    if (_searchQuery.isEmpty) return widget.availableUsers;
    final query = _searchQuery.toLowerCase();
    return widget.availableUsers.where((user) {
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.role.toLowerCase().contains(query);
    }).toList();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Dropdown
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 4),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                shadowColor: AppColors.shadow,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 320),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search input
                      Padding(
                        padding: const EdgeInsets.all(AppConstants.paddingM),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: (value) {
                            _searchQuery = value;
                            _overlayEntry?.markNeedsBuild();
                          },
                          decoration: InputDecoration(
                            hintText: 'メンバーを検索...',
                            hintStyle: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.iconDefault,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: AppColors.inputBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusM,
                              ),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingM,
                              vertical: AppConstants.paddingS,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),

                      const Divider(height: 1, color: AppColors.divider),

                      // User list
                      Flexible(
                        child: Builder(
                          builder: (context) {
                            final filteredUsers = _filteredUsers;
                            if (filteredUsers.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(AppConstants.paddingXL),
                                child: Text(
                                  'メンバーが見つかりません',
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppConstants.paddingS,
                              ),
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                final isSelected = widget.selectedUsers
                                    .any((u) => u.id == user.id);
                                return _UserListTile(
                                  user: user,
                                  isSelected: isSelected,
                                  onTap: () => _toggleUser(user),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              if (widget.selectedUsers.isNotEmpty) ...[
                const SizedBox(width: AppConstants.paddingS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  child: Text(
                    '${widget.selectedUsers.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppConstants.paddingM),
        ],

        // Selected users display
        if (widget.selectedUsers.isNotEmpty) ...[
          Wrap(
            spacing: AppConstants.paddingS,
            runSpacing: AppConstants.paddingS,
            children: widget.selectedUsers.map((user) {
              return _SelectedUserChip(
                user: user,
                onRemove: widget.enabled ? () => _removeUser(user) : null,
              );
            }).toList(),
          ),
          const SizedBox(height: AppConstants.paddingM),
        ],

        // Add assignee button
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggleDropdown,
            child: AnimatedContainer(
              duration: AppConstants.animationFast,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingM,
                vertical: AppConstants.paddingM,
              ),
              decoration: BoxDecoration(
                color: widget.enabled
                    ? AppColors.inputBackground
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                border: Border.all(
                  color: _isOpen ? AppColors.primary : AppColors.border,
                  width: _isOpen ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: Text(
                      widget.selectedUsers.isEmpty
                          ? '担当者を追加'
                          : '担当者を追加・変更',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.enabled
                            ? AppColors.textSecondary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: widget.enabled
                        ? AppColors.iconDefault
                        : AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Selected user chip with remove option
class _SelectedUserChip extends StatelessWidget {
  final User user;
  final VoidCallback? onRemove;

  const _SelectedUserChip({
    required this.user,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingS,
        vertical: AppConstants.paddingXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusRound),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UserAvatar(user: user, size: 24),
          const SizedBox(width: AppConstants.paddingS),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: AppConstants.paddingXS),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// User list tile in dropdown
class _UserListTile extends StatefulWidget {
  final User user;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserListTile({
    required this.user,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_UserListTile> createState() => _UserListTileState();
}

class _UserListTileState extends State<_UserListTile> {
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
            vertical: AppConstants.paddingS,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primary.withOpacity(0.08)
                : _isHovered
                    ? AppColors.surfaceVariant
                    : Colors.transparent,
          ),
          child: Row(
            children: [
              // Avatar
              _UserAvatar(user: widget.user, size: 36),
              const SizedBox(width: AppConstants.paddingM),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      UserRole.getLabel(widget.user.role),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              // Online indicator
              if (widget.user.isOnline)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: AppConstants.paddingS),
                  decoration: const BoxDecoration(
                    color: AppColors.chatOnline,
                    shape: BoxShape.circle,
                  ),
                ),

              // Selection indicator
              AnimatedContainer(
                duration: AppConstants.animationFast,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        widget.isSelected ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: widget.isSelected
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// User avatar widget with initials fallback
class _UserAvatar extends StatelessWidget {
  final User user;
  final double size;

  const _UserAvatar({
    required this.user,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        shape: BoxShape.circle,
        image: user.avatarUrl != null
            ? DecorationImage(
                image: NetworkImage(user.avatarUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: user.avatarUrl == null
          ? Center(
              child: Text(
                user.initials,
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            )
          : null,
    );
  }
}

/// Public user avatar widget for external use
class UserAvatar extends StatelessWidget {
  final User user;
  final double size;
  final bool showOnlineStatus;

  const UserAvatar({
    super.key,
    required this.user,
    this.size = 32,
    this.showOnlineStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            shape: BoxShape.circle,
            image: user.avatarUrl != null
                ? DecorationImage(
                    image: NetworkImage(user.avatarUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: user.avatarUrl == null
              ? Center(
                  child: Text(
                    user.initials,
                    style: TextStyle(
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : null,
        ),
        if (showOnlineStatus && user.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: AppColors.chatOnline,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
