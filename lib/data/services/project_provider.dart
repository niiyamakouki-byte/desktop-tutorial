import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'mock_data_service.dart';

/// Provider for project state management
class ProjectProvider extends ChangeNotifier {
  final MockDataService _dataService = MockDataService();

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
}
