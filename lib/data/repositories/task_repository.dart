import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/task_model.dart';

/// Repository for managing task persistence with Hive
class TaskRepository {
  static const String _boxName = 'tasks';
  Box<String>? _box;
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;

  bool _cacheInitialized = false;
  final Map<String, Task> _taskCache = <String, Task>{};

  /// Initialize Hive box
  Future<void> initialize() async {
    _box = await Hive.openBox<String>(_boxName);
    await _ensureCacheLoaded();
  }

  Future<void> _ensureCacheLoaded() async {
    if (_cacheInitialized || _box == null) return;

    _taskCache.clear();
    for (final key in _box!.keys) {
      try {
        final id = key.toString();
        final jsonStr = _box!.get(id);
        if (jsonStr == null) continue;
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        _taskCache[id] = Task.fromJson(json);
      } catch (e) {
        debugPrint('Error loading task $key: $e');
      }
    }
    _cacheInitialized = true;
  }

  /// Get all tasks from storage
  Future<List<Task>> getAllTasks() async {
    if (_box == null) throw StateError('Repository not initialized');
    await _ensureCacheLoaded();
    return _taskCache.values.toList();
  }

  /// Get tasks by project ID
  Future<List<Task>> getTasksByProject(String projectId) async {
    await _ensureCacheLoaded();
    return _taskCache.values.where((task) => task.projectId == projectId).toList();
  }

  /// Get single task by ID
  Future<Task?> getTask(String id) async {
    if (_box == null) throw StateError('Repository not initialized');
    await _ensureCacheLoaded();
    return _taskCache[id];
  }

  /// Save single task
  Future<void> saveTask(Task task) async {
    if (_box == null) throw StateError('Repository not initialized');
    await _ensureCacheLoaded();

    final jsonStr = jsonEncode(task.toJson());
    await _box!.put(task.id, jsonStr);
    _taskCache[task.id] = task;
    _markForAutoSave();
  }

  /// Save multiple tasks
  Future<void> saveTasks(List<Task> tasks) async {
    if (_box == null) throw StateError('Repository not initialized');
    await _ensureCacheLoaded();

    final entries = <String, String>{};
    for (final task in tasks) {
      entries[task.id] = jsonEncode(task.toJson());
      _taskCache[task.id] = task;
    }
    await _box!.putAll(entries);
    _markForAutoSave();
  }

  /// Delete task by ID
  Future<void> deleteTask(String id) async {
    if (_box == null) throw StateError('Repository not initialized');
    await _ensureCacheLoaded();
    await _box!.delete(id);
    _taskCache.remove(id);
    _markForAutoSave();
  }

  /// Delete multiple tasks
  Future<void> deleteTasks(List<String> ids) async {
    if (_box == null) throw StateError('Repository not initialized');
    await _ensureCacheLoaded();
    await _box!.deleteAll(ids);
    for (final id in ids) {
      _taskCache.remove(id);
    }
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
    _taskCache.clear();
  }

  /// Export all tasks to JSON
  Future<String> exportToJson() async {
    await _ensureCacheLoaded();
    final jsonList = _taskCache.values.map((task) => task.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Import tasks from JSON
  Future<void> importFromJson(String jsonStr, {bool clearFirst = false}) async {
    if (_box == null) throw StateError('Repository not initialized');
    if (clearFirst) {
      await clearAll();
    }

    final dynamic decoded = jsonDecode(jsonStr);
    if (decoded is! List) {
      throw const FormatException('Import data must be a JSON array');
    }
    final tasks = decoded
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
      debugPrint('Auto-save completed for tasks');
    } catch (e) {
      debugPrint('Auto-save failed: $e');
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
