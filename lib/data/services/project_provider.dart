import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/task_repository.dart';
import '../repositories/project_repository.dart';
import 'mock_data_service.dart';
import 'dependency_service.dart';
import 'schedule_calculator.dart';
import 'template_service.dart';
import '../../presentation/widgets/gantt/rain_cancel_dialog.dart';

/// Provider for project state management
class ProjectProvider extends ChangeNotifier {
  final TaskRepository taskRepository;
  final ProjectRepository projectRepository;
  final MockDataService _dataService = MockDataService();
  final DependencyService _dependencyService = DependencyService();

  ProjectProvider({
    required this.taskRepository,
    required this.projectRepository,
  });

  Project? _currentProject;
  List<Task> _tasks = [];
  List<Message> _messages = [];
  List<Attachment> _pinnedAttachments = [];
  List<User> _users = [];
  User? _currentUser;

  Task? _selectedTask;
  bool _isSidebarOpen = true;
  bool _isLoading = false;
  String? _error;
  bool _autoScheduleEnabled = true;
  bool _showCriticalPath = true;
  bool _largeProjectMode = false;

  // Getters
  Project? get currentProject => _currentProject;
  List<Task> get tasks => _tasks;
  List<Message> get messages => _messages;
  List<Attachment> get pinnedAttachments => _pinnedAttachments;
  List<User> get users => _users;
  User? get currentUser => _currentUser;
  Task? get selectedTask => _selectedTask;
  bool get isSidebarOpen => _isSidebarOpen;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get autoScheduleEnabled => _autoScheduleEnabled;
  bool get showCriticalPath => _showCriticalPath;
  bool get largeProjectMode => _largeProjectMode;
  bool get isLargeProject => _tasks.length >= 500;

  // Dependency service getters
  DependencyService get dependencyService => _dependencyService;
  List<TaskDependency> get dependencies => _dependencyService.dependencies;
  Set<String> get criticalPathIds => Set.from(_dependencyService.criticalPathIds);
  Map<String, ScheduleResult> get scheduleResults => _dependencyService.scheduleResults;

  // Get visible tasks (respecting expanded state)
  List<Task> get visibleTasks {
    return _tasks.getVisibleTasks();
  }

  // Get root tasks
  List<Task> get rootTasks {
    return _tasks.where((task) => task.parentId == null).toList();
  }

  // Initialize data
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Parallel loading for faster startup on large datasets.
      final loadResults = await Future.wait([
        projectRepository.getAllProjects(),
        taskRepository.getAllTasks(),
      ]);
      final savedProjects = loadResults[0] as List<Project>;
      final savedTasks = loadResults[1] as List<Task>;

      if (savedProjects.isNotEmpty) {
        // Load from Hive storage
        _currentProject = savedProjects.first;
        _tasks = savedTasks;
      } else {
        // Load mock data for first run
        _currentProject = _dataService.currentProject;
        _tasks = _dataService.getTasks();
        
        // Save mock data to Hive
        if (_currentProject != null) {
          await projectRepository.saveProject(_currentProject!);
        }
        await taskRepository.saveTasks(_tasks);
      }

      // Always load these from mock service (not persisted yet)
      _messages = _dataService.getMessages();
      _pinnedAttachments = _dataService.getPinnedAttachments();
      _users = _dataService.users;
      _currentUser = _dataService.currentUser;
      _largeProjectMode = isLargeProject;
      _error = null;
    } catch (e) {
      _setError('初期化に失敗しました: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Auto-save helper for tasks
  Future<void> _autoSaveTasks() async {
    try {
      await taskRepository.saveTasks(_tasks);
    } catch (e) {
      debugPrint('Failed to auto-save tasks: $e');
      _setError('タスク保存に失敗しました');
    }
  }

  // Auto-save helper for current project
  Future<void> _autoSaveProject() async {
    if (_currentProject == null) return;
    try {
      await projectRepository.saveProject(_currentProject!);
    } catch (e) {
      debugPrint('Failed to auto-save project: $e');
      _setError('プロジェクト保存に失敗しました');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    debugPrint(message);
  }

  // Toggle sidebar
  void toggleSidebar() {
    _isSidebarOpen = !_isSidebarOpen;
    notifyListeners();
  }

  void setSidebarOpen(bool isOpen) {
    _isSidebarOpen = isOpen;
    notifyListeners();
  }

  // Select task
  void selectTask(Task? task) {
    _selectedTask = task;
    notifyListeners();
  }

  // Toggle task expansion
  void toggleTaskExpansion(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        isExpanded: !_tasks[index].isExpanded,
      );
      _autoSaveTasks();
      notifyListeners();
    }
  }

  // Update task
  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask.copyWith(updatedAt: DateTime.now());
      _autoSaveTasks();
      notifyListeners();
    }
  }

  /// Update a task date range from Gantt drag/resize and auto-adjust dependents.
  void updateTaskScheduleFromGantt({
    required String taskId,
    required DateTime newStart,
    required DateTime newEnd,
  }) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index < 0) return;

    final normalizedStart = DateTime(newStart.year, newStart.month, newStart.day);
    var normalizedEnd = DateTime(newEnd.year, newEnd.month, newEnd.day);
    if (normalizedEnd.isBefore(normalizedStart)) {
      normalizedEnd = normalizedStart;
    }

    final currentTask = _tasks[index];
    if (currentTask.startDate == normalizedStart &&
        currentTask.endDate == normalizedEnd) {
      return;
    }

    _tasks[index] = currentTask.copyWith(
      startDate: normalizedStart,
      endDate: normalizedEnd,
      updatedAt: DateTime.now(),
    );

    if (_dependencyService.dependencies.isNotEmpty) {
      _applyDependencyCascade();
    } else {
      _recalculateSchedule();
    }

    _autoSaveTasks();
    _largeProjectMode = isLargeProject;
    notifyListeners();
  }

  void _applyDependencyCascade() {
    if (_hasDependencyCycle()) {
      _setError('循環依存を検出したため、依存タスクの自動調整をスキップしました');
      _recalculateSchedule();
      return;
    }
    _error = null;

    final adjustedTasks = _dependencyService.autoAdjustTasks(_tasks);
    for (var i = 0; i < _tasks.length; i++) {
      final adjusted = adjustedTasks.firstWhere(
        (task) => task.id == _tasks[i].id,
        orElse: () => _tasks[i],
      );
      if (_tasks[i].startDate != adjusted.startDate ||
          _tasks[i].endDate != adjusted.endDate) {
        _tasks[i] = _tasks[i].copyWith(
          startDate: adjusted.startDate,
          endDate: adjusted.endDate,
          updatedAt: DateTime.now(),
        );
      }
    }
    _recalculateSchedule();
  }

  bool _hasDependencyCycle() {
    final taskIds = _tasks.map((t) => t.id).toSet();
    final adjacency = <String, Set<String>>{
      for (final taskId in taskIds) taskId: <String>{},
    };
    final inDegree = <String, int>{for (final taskId in taskIds) taskId: 0};

    for (final dep in _dependencyService.dependencies) {
      if (!taskIds.contains(dep.fromTaskId) || !taskIds.contains(dep.toTaskId)) {
        continue;
      }
      if (adjacency[dep.fromTaskId]!.add(dep.toTaskId)) {
        inDegree[dep.toTaskId] = (inDegree[dep.toTaskId] ?? 0) + 1;
      }
    }

    final queue = <String>[
      for (final entry in inDegree.entries)
        if (entry.value == 0) entry.key,
    ];
    var visitedCount = 0;

    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      visitedCount++;
      for (final next in adjacency[current] ?? const <String>{}) {
        final nextInDegree = (inDegree[next] ?? 0) - 1;
        inDegree[next] = nextInDegree;
        if (nextInDegree == 0) {
          queue.add(next);
        }
      }
    }

    return visitedCount != taskIds.length;
  }

  // Get children of a task
  List<Task> getTaskChildren(String parentId) {
    return _tasks.where((task) => task.parentId == parentId).toList();
  }

  // Check if task has children
  bool taskHasChildren(String taskId) {
    return _tasks.any((task) => task.parentId == taskId);
  }

  // Add message
  void addMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }

  // Get messages grouped by date
  List<MessageGroup> get groupedMessages {
    return MessageGroup.groupByDate(_messages);
  }

  // Get unread message count
  int get unreadMessageCount {
    return _messages.where((m) => !m.isRead && m.senderId != _currentUser?.id).length;
  }

  // Mark message as read
  void markMessageAsRead(String messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final readBy = List<String>.from(_messages[index].readBy);
      if (_currentUser != null && !readBy.contains(_currentUser!.id)) {
        readBy.add(_currentUser!.id);
      }
      _messages[index] = _messages[index].copyWith(
        isRead: true,
        readBy: readBy,
        readAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  // Get task by ID
  Task? getTaskById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  // Get user by ID
  User? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  // Project date range
  DateTime get projectStartDate {
    if (_tasks.isEmpty) return DateTime.now();
    return _tasks.map((t) => t.startDate).reduce(
          (a, b) => a.isBefore(b) ? a : b,
        );
  }

  DateTime get projectEndDate {
    if (_tasks.isEmpty) return DateTime.now().add(const Duration(days: 365));
    return _tasks.map((t) => t.endDate).reduce(
          (a, b) => a.isAfter(b) ? a : b,
        );
  }

  // Get dependencies for a task
  List<Task> getTaskDependencies(String taskId) {
    final task = getTaskById(taskId);
    if (task == null) return [];
    return task.dependsOn
        .map((id) => getTaskById(id))
        .whereType<Task>()
        .toList();
  }

  // ============== Dependency Management ==============

  /// Add a new dependency between tasks
  bool addDependency({
    required String fromTaskId,
    required String toTaskId,
    DependencyType type = DependencyType.fs,
    int lagDays = 0,
  }) {
    final success = _dependencyService.addDependency(
      fromTaskId: fromTaskId,
      toTaskId: toTaskId,
      type: type,
      lagDays: lagDays,
    );

    if (success) {
      // Update task's dependsOn list for backward compatibility
      final index = _tasks.indexWhere((t) => t.id == toTaskId);
      if (index >= 0 && !_tasks[index].dependsOn.contains(fromTaskId)) {
        final newDependsOn = List<String>.from(_tasks[index].dependsOn)
          ..add(fromTaskId);
        _tasks[index] = _tasks[index].copyWith(dependsOn: newDependsOn);
      }

      // Recalculate schedule
      _recalculateSchedule();
      notifyListeners();
    }

    return success;
  }

  /// Remove a dependency
  void removeDependency(String dependencyId) {
    final dep = _dependencyService.dependencies.firstWhere(
      (d) => d.id == dependencyId,
      orElse: () => TaskDependency(id: '', fromTaskId: '', toTaskId: ''),
    );

    if (dep.id.isNotEmpty) {
      // Update task's dependsOn list
      final index = _tasks.indexWhere((t) => t.id == dep.toTaskId);
      if (index >= 0) {
        final newDependsOn = List<String>.from(_tasks[index].dependsOn)
          ..remove(dep.fromTaskId);
        _tasks[index] = _tasks[index].copyWith(dependsOn: newDependsOn);
      }

      _dependencyService.removeDependency(dependencyId);
      _recalculateSchedule();
      notifyListeners();
    }
  }

  /// Update dependency type
  void updateDependencyType(String dependencyId, DependencyType type) {
    _dependencyService.updateDependencyType(dependencyId, type);
    _recalculateSchedule();
    notifyListeners();
  }

  /// Update dependency lag
  void updateDependencyLag(String dependencyId, int lagDays) {
    _dependencyService.updateDependencyLag(dependencyId, lagDays);
    _recalculateSchedule();
    notifyListeners();
  }

  /// Check if task is on critical path
  bool isOnCriticalPath(String taskId) {
    return _dependencyService.isOnCriticalPath(taskId);
  }

  /// Get total float for a task
  int getTaskFloat(String taskId) {
    return _dependencyService.getTotalFloat(taskId);
  }

  /// Toggle auto-scheduling
  void toggleAutoSchedule() {
    _autoScheduleEnabled = !_autoScheduleEnabled;
    if (_autoScheduleEnabled) {
      _applyAutoSchedule();
    }
    notifyListeners();
  }

  /// Toggle critical path display
  void toggleCriticalPath() {
    _showCriticalPath = !_showCriticalPath;
    notifyListeners();
  }

  /// Apply auto-scheduling to adjust task dates
  void applyAutoSchedule() {
    if (!_autoScheduleEnabled) return;
    _applyAutoSchedule();
  }

  void _applyAutoSchedule() {
    final adjustedTasks = _dependencyService.autoAdjustTasks(_tasks);

    // Update tasks with adjusted dates
    for (int i = 0; i < _tasks.length; i++) {
      final adjusted = adjustedTasks.firstWhere(
        (t) => t.id == _tasks[i].id,
        orElse: () => _tasks[i],
      );
      if (adjusted.startDate != _tasks[i].startDate ||
          adjusted.endDate != _tasks[i].endDate) {
        _tasks[i] = _tasks[i].copyWith(
          startDate: adjusted.startDate,
          endDate: adjusted.endDate,
        );
      }
    }

    notifyListeners();
  }

  /// Recalculate schedule and critical path
  void _recalculateSchedule() {
    _dependencyService.recalculateSchedule(_tasks);
  }

  /// Calculate delay impact for a task
  DelayImpact? calculateDelayImpact(String taskId, int delayDays) {
    final task = getTaskById(taskId);
    if (task == null) return null;

    return ScheduleCalculator.calculateDelayImpact(
      delayedTask: task,
      delayDays: delayDays,
      tasks: _tasks,
      dependencies: _dependencyService.dependencies,
    );
  }

  /// Get all downstream tasks affected by a task
  Set<String> getDownstreamTasks(String taskId) {
    return _dependencyService.getDownstreamTaskIds(taskId);
  }

  /// Get all upstream tasks that a task depends on
  Set<String> getUpstreamTasks(String taskId) {
    return _dependencyService.getUpstreamTaskIds(taskId);
  }

  /// Initialize mock dependencies for demo
  void initializeMockDependencies() {
    _dependencyService.initializeMockDependencies(_tasks);
    notifyListeners();
  }

  /// Apply rain cancellation - slide affected tasks
  void applyRainCancellation(RainCancelResult result) {
    for (final slideInfo in result.affectedTasks) {
      final index = _tasks.indexWhere((t) => t.id == slideInfo.task.id);
      if (index >= 0) {
        _tasks[index] = _tasks[index].copyWith(
          startDate: slideInfo.newStart,
          endDate: slideInfo.newEnd,
          updatedAt: DateTime.now(),
        );
      }
    }

    // Recalculate schedule after moving tasks
    _recalculateSchedule();
    _autoSaveTasks();
    _largeProjectMode = isLargeProject;
    notifyListeners();
  }

  /// Apply a predefined project template.
  Future<bool> applyProjectTemplate(
    String templateId, {
    DateTime? startDate,
    bool replaceExisting = false,
  }) async {
    if (_currentProject == null) {
      _setError('プロジェクトが選択されていません');
      notifyListeners();
      return false;
    }

    try {
      final generatedTasks = TemplateService.buildTasksFromTemplate(
        templateId: templateId,
        projectId: _currentProject!.id,
        projectStartDate: startDate ?? DateTime.now(),
        availableUsers: _users,
      );

      if (replaceExisting) {
        _tasks = generatedTasks;
      } else {
        _tasks = [..._tasks, ...generatedTasks];
      }

      _recalculateSchedule();
      await _autoSaveTasks();
      _largeProjectMode = isLargeProject;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('テンプレート適用に失敗しました: $e');
      notifyListeners();
      return false;
    }
  }

  /// Team member management
  Future<bool> addTeamMember(User user) async {
    try {
      if (_users.any((u) => u.id == user.id)) {
        _setError('同じIDのメンバーが既に存在します');
        notifyListeners();
        return false;
      }

      _users = [..._users, user];
      if (_currentProject != null) {
        _currentProject = _currentProject!.copyWith(
          members: [..._currentProject!.members, user],
          updatedAt: DateTime.now(),
        );
        await _autoSaveProject();
      }
      notifyListeners();
      return true;
    } catch (e) {
      _setError('メンバー追加に失敗しました: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTeamMember(User user) async {
    try {
      final userIndex = _users.indexWhere((u) => u.id == user.id);
      if (userIndex < 0) {
        _setError('更新対象のメンバーが見つかりません');
        notifyListeners();
        return false;
      }

      _users[userIndex] = user;
      if (_currentProject != null) {
        final members = [..._currentProject!.members];
        final memberIndex = members.indexWhere((m) => m.id == user.id);
        if (memberIndex >= 0) {
          members[memberIndex] = user;
        }
        _currentProject = _currentProject!.copyWith(
          members: members,
          updatedAt: DateTime.now(),
        );
        await _autoSaveProject();
      }
      notifyListeners();
      return true;
    } catch (e) {
      _setError('メンバー更新に失敗しました: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeTeamMember(String userId) async {
    try {
      _users = _users.where((u) => u.id != userId).toList();
      if (_currentUser?.id == userId) {
        _currentUser = _users.isNotEmpty ? _users.first : null;
      }

      // Remove assignee links from tasks.
      _tasks = _tasks
          .map((task) => task.copyWith(
                assignees: task.assignees.where((a) => a.id != userId).toList(),
              ))
          .toList();

      if (_currentProject != null) {
        _currentProject = _currentProject!.copyWith(
          members: _currentProject!.members.where((m) => m.id != userId).toList(),
          updatedAt: DateTime.now(),
        );
      }

      await Future.wait([
        _autoSaveTasks(),
        _autoSaveProject(),
      ]);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('メンバー削除に失敗しました: $e');
      notifyListeners();
      return false;
    }
  }

  // === Data Export/Import Functions ===

  /// Export all data to JSON string
  Future<String> exportAllData() async {
    final data = {
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
      'project': _currentProject?.toJson(),
      'tasks': await taskRepository.exportToJson(),
      'tasksCount': _tasks.length,
    };
    return jsonEncode(data);
  }

  /// Import data from JSON string
  Future<bool> importAllData(String jsonStr, {bool clearFirst = false}) async {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      // Import tasks
      if (data['tasks'] != null) {
        await taskRepository.importFromJson(
          data['tasks'] as String,
          clearFirst: clearFirst,
        );
      }

      // Import project
      if (data['project'] != null) {
        final project = Project.fromJson(data['project'] as Map<String, dynamic>);
        await projectRepository.saveProject(project);
        _currentProject = project;
      }

      // Reload data
      await initialize();
      return true;
    } catch (e) {
      print('Failed to import data: $e');
      return false;
    }
  }

  /// Force save all data immediately
  Future<void> forceSaveAll() async {
    await taskRepository.forceSave();
    await projectRepository.forceSave();
  }

  @override
  void dispose() {
    taskRepository.dispose();
    projectRepository.dispose();
    super.dispose();
  }
}
