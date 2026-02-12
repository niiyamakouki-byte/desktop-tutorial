import 'package:construction_project_manager/data/services/mock_data_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/project_model.dart';

/// Repository for managing project persistence with Hive
class ProjectRepository {
  static const String _boxName = 'projects';
  Box<String>? _box;
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;

  /// Initialize Hive box
  Future<void> initialize() async {
    _box = await Hive.openBox<String>(_boxName);

    // If no projects exist, seed with mock data
    if (_box!.isEmpty) {
      print('Seeding initial project data...');
      final mockProject = MockDataService().currentProject;
      await saveProject(mockProject);
      print('Initial project seeded: ${mockProject.name}');
    }

  }

  /// Get all projects from storage
  Future<List<Project>> getAllProjects() async {
    if (_box == null) throw StateError('Repository not initialized');
    
    final projects = <Project>[];
    for (var key in _box!.keys) {
      try {
        final jsonStr = _box!.get(key);
        if (jsonStr != null) {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          projects.add(Project.fromJson(json));
        }
      } catch (e) {
        // Skip corrupted entries
        print('Error loading project $key: $e');
      }
    }
    return projects;
  }

  /// Get single project by ID
  Future<Project?> getProject(String id) async {
    if (_box == null) throw StateError('Repository not initialized');
    
    final jsonStr = _box!.get(id);
    if (jsonStr == null) return null;
    
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Project.fromJson(json);
    } catch (e) {
      print('Error loading project $id: $e');
      return null;
    }
  }

  /// Save single project
  Future<void> saveProject(Project project) async {
    if (_box == null) throw StateError('Repository not initialized');
    
    final jsonStr = jsonEncode(project.toJson());
    await _box!.put(project.id, jsonStr);
    _markForAutoSave();
  }

  /// Save multiple projects
  Future<void> saveProjects(List<Project> projects) async {
    if (_box == null) throw StateError('Repository not initialized');
    
    final entries = <String, String>{};
    for (var project in projects) {
      entries[project.id] = jsonEncode(project.toJson());
    }
    await _box!.putAll(entries);
    _markForAutoSave();
  }

  /// Delete project by ID
  Future<void> deleteProject(String id) async {
    if (_box == null) throw StateError('Repository not initialized');
    await _box!.delete(id);
    _markForAutoSave();
  }

  /// Delete multiple projects
  Future<void> deleteProjects(List<String> ids) async {
    if (_box == null) throw StateError('Repository not initialized');
    await _box!.deleteAll(ids);
    _markForAutoSave();
  }

  /// Clear all projects
  Future<void> clearAll() async {
    if (_box == null) throw StateError('Repository not initialized');
    await _box!.clear();
  }

  /// Export all projects to JSON
  Future<String> exportToJson() async {
    final projects = await getAllProjects();
    final jsonList = projects.map((project) => project.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Import projects from JSON
  Future<void> importFromJson(String jsonStr, {bool clearFirst = false}) async {
    if (clearFirst) {
      await clearAll();
    }

    final jsonList = jsonDecode(jsonStr) as List;
    final projects = jsonList
        .map((json) => Project.fromJson(json as Map<String, dynamic>))
        .toList();
    
    await saveProjects(projects);
  }

  /// Get projects by status
  Future<List<Project>> getProjectsByStatus(String status) async {
    final allProjects = await getAllProjects();
    return allProjects.where((project) => project.status == status).toList();
  }

  /// Get active projects (not completed or cancelled)
  Future<List<Project>> getActiveProjects() async {
    final allProjects = await getAllProjects();
    return allProjects.where((project) => 
      project.status != ProjectStatus.completed && 
      project.status != ProjectStatus.cancelled
    ).toList();
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
      print('Auto-save completed for projects');
    } catch (e) {
      print('Auto-save failed: $e');
    }
  }

  /// Force immediate save
  Future<void> forceSave() async {
    _autoSaveTimer?.cancel();
    await _performAutoSave();
  }

  /// Get count of projects
  Future<int> getCount() async {
    if (_box == null) throw StateError('Repository not initialized');
    return _box!.length;
  }

  /// Check if project exists
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
