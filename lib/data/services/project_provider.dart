import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/dependency_model.dart';
import 'mock_data_service.dart';
import 'dependency_service.dart';
import 'schedule_calculator.dart';

/// Provider for project state management
class ProjectProvider extends ChangeNotifier {
  final MockDataService _dataService = MockDataService();
  final DependencyService _dependencyService = DependencyService();

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
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      _currentProject = _dataService.currentProject;
      _tasks = _dataService.getTasks();
      _messages = _dataService.getMessages();
      _pinnedAttachments = _dataService.getPinnedAttachments();
      _users = _dataService.users;
      _currentUser = _dataService.currentUser;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      notifyListeners();
    }
  }

  // Update task
  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask.copyWith(updatedAt: DateTime.now());
      notifyListeners();
    }
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
}
