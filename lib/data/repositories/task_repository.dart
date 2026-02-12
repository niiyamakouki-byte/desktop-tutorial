import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';

/// Repository for managing task persistence with Hive
class TaskRepository {
  static const String _boxName = 'tasks';
  Box<String>? _box;
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;

  /// Initialize Hive box
  Future<void> initialize() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  /// Get all tasks from storage
  Future<List<Task>> getAllTasks() async {
    if (_box == null) throw StateError('Repository not initialized');
    
    final tasks = <Task>[];
    for (var key in _box!.keys) {
      try {
        final jsonStr = _box!.get(key);
        if (jsonStr != null) {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          tasks.add(Task.fromJson(json));
        }
      } catch (e) {
        // Skip corrupted entries
        print('Error loading task $key: $e');
      }
    }
    return tasks;
  }

  /// Get tasks by project ID
  Future<List<Task>> getTasksByProject(String projectId) async {
    final allTasks = await getAllTasks();
    return allTasks.where((task) => task.projectId == projectId).toList();
  }

  /// Get single task by ID
  Future<Task?> getTask(String id) async {
    if (_box == null) throw StateError('Repository not initialized');
    
    final jsonStr = _box!.get(id);
    if (jsonStr == null) return null;
    
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Task.fromJson(json);
    } catch (e) {
      print('Error loading task $id: $e');
      return null;
    }
  }

  /// Save single task
  Future<void> saveTask(Task task) async {
    if (_box == null) throw StateError('Repository not initialized');
    
    final jsonStr = jsonEncode(task.toJson());
    await _box!.put(task.id, jsonStr);
    _markForAutoSave();
  }

  /// Save multiple tasks
  Future<void> saveTasks(List<Task> tasks) async {
    if (_box == null) throw StateError('Repository not initialized');
    
    final entries = <String, String>{};
    for (var task in tasks) {
      entries[task.id] = jsonEncode(task.toJson());
    }
    await _box!.putAll(entries);
    _markForAutoSave();
  }

  /// Delete task by ID
  Future<void> deleteTask(String id) async {
    if (_box == null) throw StateError('Repository not initialized');
    await _box!.delete(id);
    _markForAutoSave();
  }

  /// Delete multiple tasks
  Future<void> deleteTasks(List<String> ids) async {
    if (_box == null) throw StateError('Repository not initialized');
    await _box!.deleteAll(ids);
    _markForAutoSave();
  }

  /// Delete all tasks for a project
  Future<void> deleteTasksByProject(String projectId) async {
    final tasks = await getTasksByProject(projectId);
    final ids = tasks.map((t) => t.id).toList();
    await deleteTasks(ids);
  }

  /// Clear all tasks
  Future<void> clearAll() async {
    if (_box == null) throw StateError('Repository not initialized');
    await _box!.clear();
  }

  /// Export all tasks to JSON
  Future<String> exportToJson() async {
    final tasks = await getAllTasks();
    final jsonList = tasks.map((task) => task.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Import tasks from JSON
  Future<void> importFromJson(String jsonStr, {bool clearFirst = false}) async {
    if (clearFirst) {
      await clearAll();
    }

    final jsonList = jsonDecode(jsonStr) as List;
    final tasks = jsonList
        .map((json) => Task.fromJson(json as Map<String, dynamic>))
        .toList();
    
    await saveTasks(tasks);
  }

  /// Mark data for auto-save (saves after 3 seconds of no changes)
  void _markForAutoSave() {
    _hasUnsavedChanges = true;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 3), () {
      if (_hasUnsavedChanges) {
        _performAutoSave();
      }
    });
  }

  /// Perform auto-save (flush to disk)
  Future<void> _performAutoSave() async {
    if (_box == null) return;
    
    try {
      await _box!.flush();
      _hasUnsavedChanges = false;
      print('Auto-save completed for tasks');
    } catch (e) {
      print('Auto-save failed: $e');
    }
  }

  /// Force immediate save
  Future<void> forceSave() async {
    _autoSaveTimer?.cancel();
    await _performAutoSave();
  }

  /// Get count of tasks
  Future<int> getCount() async {
    if (_box == null) throw StateError('Repository not initialized');
    return _box!.length;
  }

  /// Check if task exists
  Future<bool> exists(String id) async {
    if (_box == null) throw StateError('Repository not initialized');
    return _box!.containsKey(id);
  }

  /// Dispose resources
  void dispose() {
    _autoSaveTimer?.cancel();
    _box?.close();
  }
}
