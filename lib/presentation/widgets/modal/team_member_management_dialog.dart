import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../data/services/project_provider.dart';

class TeamMemberManagementDialog extends StatefulWidget {
  final ProjectProvider provider;

  const TeamMemberManagementDialog({
    super.key,
    required this.provider,
  });

  static Future<void> show({
    required BuildContext context,
    required ProjectProvider provider,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => TeamMemberManagementDialog(provider: provider),
    );
  }

  @override
  State<TeamMemberManagementDialog> createState() =>
      _TeamMemberManagementDialogState();
}

class _TeamMemberManagementDialogState extends State<TeamMemberManagementDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  String _role = UserRole.engineer;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      return;
    }
    setState(() => _isSubmitting = true);

    final now = DateTime.now().millisecondsSinceEpoch;
    final user = User(
      id: 'user_$now',
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: _role,
      department: _departmentController.text.trim().isEmpty
          ? '未設定'
          : _departmentController.text.trim(),
      isOnline: false,
      avatarUrl: null,
    );

    final success = await widget.provider.addTeamMember(user);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _nameController.clear();
      _emailController.clear();
      _departmentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メンバーを追加しました')),
      );
      setState(() {});
    }
  }

  Future<void> _removeMember(User user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メンバーを削除'),
        content: Text('${user.name} をチームから削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await widget.provider.removeTeamMember(user.id);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.provider.users;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 720,
        height: 560,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.groups_2_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'チームメンバー管理',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final user = members[index];
                        return ListTile(
                          tileColor: AppColors.surfaceVariant.withOpacity(0.45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.15),
                            child: Text(user.initials),
                          ),
                          title: Text(user.name),
                          subtitle: Text(
                            '${UserRole.getLabel(user.role)} / ${user.department}',
                          ),
                          trailing: IconButton(
                            onPressed: () => _removeMember(user),
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            tooltip: '削除',
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemCount: members.length,
                    ),
                  ),
                  Container(width: 1, color: AppColors.border),
                  SizedBox(
                    width: 280,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '新規メンバー追加',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: '氏名'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'メール'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _departmentController,
                            decoration: const InputDecoration(labelText: '部署'),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _role,
                            decoration: const InputDecoration(labelText: '役割'),
                            items: UserRole.labels.entries
                                .map(
                                  (entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _role = value);
                              }
                            },
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : _addMember,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.person_add_alt_1),
                              label: const Text('追加'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
