/// Project Dashboard Screen - Multi-project support
/// プロジェクト一覧ダッシュボード

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/models.dart';
import '../../data/services/project_provider.dart';
import '../widgets/common/glass_container.dart';

class ProjectDashboardScreen extends StatefulWidget {
  final Function(Project) onProjectSelected;
  final VoidCallback? onCreateProject;

  const ProjectDashboardScreen({
    super.key,
    required this.onProjectSelected,
    this.onCreateProject,
  });

  @override
  State<ProjectDashboardScreen> createState() => _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState extends State<ProjectDashboardScreen> {
  final List<Project> _projects = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  ProjectStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Simulate loading delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock projects data
      final mockProjects = [
        Project(
          id: 'p1',
          name: '新宿オフィスビル建設',
          description: '地上20階、地下2階のオフィスビル新築工事',
          clientName: '新宿不動産開発株式会社',
          startDate: DateTime(2024, 4, 1),
          endDate: DateTime(2025, 9, 30),
          status: ProjectStatus.inProgress,
          progress: 0.45,
          budget: 2500000000,
          actualCost: 980000000,
          managerId: 'u1',
          managerName: '田中 太郎',
          teamMembers: ['u1', 'u2', 'u3', 'u4'],
          location: '東京都新宿区西新宿1-1-1',
          category: '商業施設',
        ),
        Project(
          id: 'p2',
          name: '渋谷マンション改修',
          description: '築30年マンションの大規模修繕工事',
          clientName: '渋谷マンション管理組合',
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 12, 31),
          status: ProjectStatus.inProgress,
          progress: 0.72,
          budget: 180000000,
          actualCost: 125000000,
          managerId: 'u2',
          managerName: '佐藤 次郎',
          teamMembers: ['u2', 'u5'],
          location: '東京都渋谷区道玄坂2-2-2',
          category: '住宅',
        ),
        Project(
          id: 'p3',
          name: '横浜倉庫新築',
          description: '物流センター新築工事（延床面積5,000㎡）',
          clientName: '横浜物流株式会社',
          startDate: DateTime(2024, 8, 1),
          endDate: DateTime(2025, 3, 31),
          status: ProjectStatus.planning,
          progress: 0.15,
          budget: 450000000,
          actualCost: 45000000,
          managerId: 'u3',
          managerName: '鈴木 三郎',
          teamMembers: ['u3', 'u6', 'u7'],
          location: '神奈川県横浜市鶴見区大黒町3-3-3',
          category: '物流施設',
        ),
        Project(
          id: 'p4',
          name: '品川駅前再開発',
          description: '駅前商業ビル建設プロジェクト',
          clientName: '品川開発コンソーシアム',
          startDate: DateTime(2024, 1, 15),
          endDate: DateTime(2026, 3, 31),
          status: ProjectStatus.inProgress,
          progress: 0.28,
          budget: 8500000000,
          actualCost: 2100000000,
          managerId: 'u1',
          managerName: '田中 太郎',
          teamMembers: ['u1', 'u2', 'u3', 'u4', 'u5', 'u6'],
          location: '東京都港区港南2-4-4',
          category: '商業施設',
        ),
        Project(
          id: 'p5',
          name: '千葉工場増築',
          description: '製造ライン増設に伴う工場棟増築',
          clientName: '千葉製造株式会社',
          startDate: DateTime(2024, 3, 1),
          endDate: DateTime(2024, 10, 31),
          status: ProjectStatus.completed,
          progress: 1.0,
          budget: 320000000,
          actualCost: 315000000,
          managerId: 'u4',
          managerName: '高橋 四郎',
          teamMembers: ['u4', 'u8'],
          location: '千葉県千葉市美浜区新港5-5-5',
          category: '工場',
        ),
      ];

      setState(() {
        _projects.clear();
        _projects.addAll(mockProjects);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'プロジェクトの読み込みに失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  List<Project> get _filteredProjects {
    return _projects.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.clientName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _filterStatus == null || p.status == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchAndFilter(),
            _buildSummaryCards(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                      ? _buildErrorState()
                      : _buildProjectGrid(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProjectDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('新規プロジェクト'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.industrialGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.construction,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'プロジェクト管理',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_projects.length}件のプロジェクト',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadProjects,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: '更新',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withOpacity(0.3)),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'プロジェクトを検索...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(null, 'すべて'),
                _buildFilterChip(ProjectStatus.inProgress, '進行中'),
                _buildFilterChip(ProjectStatus.planning, '計画中'),
                _buildFilterChip(ProjectStatus.completed, '完了'),
                _buildFilterChip(ProjectStatus.onHold, '保留'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(ProjectStatus? status, String label) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _filterStatus = status),
        backgroundColor: AppColors.surfaceDark,
        selectedColor: AppColors.primary.withOpacity(0.3),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final inProgress = _projects.where((p) => p.status == ProjectStatus.inProgress).length;
    final planning = _projects.where((p) => p.status == ProjectStatus.planning).length;
    final completed = _projects.where((p) => p.status == ProjectStatus.completed).length;
    final totalBudget = _projects.fold<double>(0, (sum, p) => sum + p.budget);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(child: _SummaryCard(
            icon: Icons.play_circle,
            label: '進行中',
            value: '$inProgress',
            color: AppColors.primary,
          )),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard(
            icon: Icons.schedule,
            label: '計画中',
            value: '$planning',
            color: AppColors.info,
          )),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard(
            icon: Icons.check_circle,
            label: '完了',
            value: '$completed',
            color: AppColors.success,
          )),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard(
            icon: Icons.account_balance_wallet,
            label: '総予算',
            value: _formatBudget(totalBudget),
            color: AppColors.industrialOrange,
          )),
        ],
      ),
    );
  }

  String _formatBudget(double amount) {
    if (amount >= 100000000) {
      return '${(amount / 100000000).toStringAsFixed(1)}億';
    } else if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(0)}万';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'プロジェクトを読み込み中...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(
            _error ?? 'エラーが発生しました',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadProjects,
            icon: const Icon(Icons.refresh),
            label: const Text('再試行'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectGrid() {
    final projects = _filteredProjects;

    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, color: Colors.white.withOpacity(0.3), size: 64),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? '検索結果がありません' : 'プロジェクトがありません',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 800 ? 2 : 1);

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            return _ProjectCard(
              project: projects[index],
              onTap: () => widget.onProjectSelected(projects[index]),
            );
          },
        );
      },
    );
  }

  void _showCreateProjectDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateProjectDialog(
        onCreated: (project) {
          setState(() {
            _projects.insert(0, project);
          });
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatefulWidget {
  final Project project;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.onTap,
  });

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final statusColor = _getStatusColor(project.status);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? AppColors.primary : AppColors.border.withOpacity(0.3),
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        project.status.label,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      project.category,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Title
                Text(
                  project.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  project.clientName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                // Progress
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '進捗',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${(project.progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: project.progress,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(project.progress),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Footer
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        project.managerName,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.group, size: 14, color: Colors.white.withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Text(
                      '${project.teamMembers.length}名',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning:
        return AppColors.info;
      case ProjectStatus.inProgress:
        return AppColors.primary;
      case ProjectStatus.completed:
        return AppColors.success;
      case ProjectStatus.onHold:
        return AppColors.safetyYellow;
      case ProjectStatus.cancelled:
        return AppColors.error;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return AppColors.success;
    if (progress >= 0.5) return AppColors.primary;
    if (progress >= 0.3) return AppColors.safetyYellow;
    return AppColors.industrialOrange;
  }
}

class _CreateProjectDialog extends StatefulWidget {
  final Function(Project) onCreated;

  const _CreateProjectDialog({required this.onCreated});

  @override
  State<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<_CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _clientController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  String _category = '商業施設';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _clientController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.add_business, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Text(
                    '新規プロジェクト作成',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(_nameController, 'プロジェクト名', Icons.business),
              const SizedBox(height: 16),
              _buildTextField(_clientController, '発注者名', Icons.person),
              const SizedBox(height: 16),
              _buildTextField(_descController, '概要', Icons.description, maxLines: 2),
              const SizedBox(height: 16),
              _buildTextField(_locationController, '所在地', Icons.location_on),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'カテゴリ',
                  labelStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.category, color: Colors.white54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border.withOpacity(0.3)),
                  ),
                ),
                dropdownColor: AppColors.surfaceDark,
                style: const TextStyle(color: Colors.white),
                items: ['商業施設', '住宅', '工場', '物流施設', 'インフラ', 'その他']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _createProject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('作成'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      validator: (v) => v == null || v.isEmpty ? '必須項目です' : null,
    );
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500));

    final project = Project(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text,
      description: _descController.text,
      clientName: _clientController.text,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 180)),
      status: ProjectStatus.planning,
      progress: 0.0,
      budget: 0,
      actualCost: 0,
      managerId: 'u1',
      managerName: '田中 太郎',
      teamMembers: ['u1'],
      location: _locationController.text,
      category: _category,
    );

    widget.onCreated(project);
    if (mounted) Navigator.pop(context);
  }
}

/// Project status enum
enum ProjectStatus {
  planning,
  inProgress,
  completed,
  onHold,
  cancelled,
}

extension ProjectStatusExtension on ProjectStatus {
  String get label {
    switch (this) {
      case ProjectStatus.planning:
        return '計画中';
      case ProjectStatus.inProgress:
        return '進行中';
      case ProjectStatus.completed:
        return '完了';
      case ProjectStatus.onHold:
        return '保留';
      case ProjectStatus.cancelled:
        return '中止';
    }
  }
}

/// Project model
class Project {
  final String id;
  final String name;
  final String description;
  final String clientName;
  final DateTime startDate;
  final DateTime endDate;
  final ProjectStatus status;
  final double progress;
  final double budget;
  final double actualCost;
  final String managerId;
  final String managerName;
  final List<String> teamMembers;
  final String location;
  final String category;

  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.clientName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.progress,
    required this.budget,
    required this.actualCost,
    required this.managerId,
    required this.managerName,
    required this.teamMembers,
    required this.location,
    required this.category,
  });
}
