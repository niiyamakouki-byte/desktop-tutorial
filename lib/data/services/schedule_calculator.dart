/// Schedule Calculator Service
/// Implements Critical Path Method (CPM) for project scheduling
/// クリティカルパス法による工程計算エンジン

import '../models/dependency_model.dart';
import '../models/task_model.dart';

class ScheduleCalculator {
  /// Calculate schedule for all tasks using Critical Path Method
  /// Returns map of taskId -> ScheduleResult
  static Map<String, ScheduleResult> calculateSchedule({
    required List<Task> tasks,
    required List<TaskDependency> dependencies,
    DateTime? projectStart,
  }) {
    if (tasks.isEmpty) return {};

    final taskMap = {for (var t in tasks) t.id: t};
    final results = <String, ScheduleResult>{};

    // Build dependency graph
    final predecessors = <String, List<TaskDependency>>{};
    final successors = <String, List<TaskDependency>>{};

    for (final task in tasks) {
      predecessors[task.id] = [];
      successors[task.id] = [];
    }

    for (final dep in dependencies) {
      if (taskMap.containsKey(dep.fromTaskId) && taskMap.containsKey(dep.toTaskId)) {
        predecessors[dep.toTaskId]!.add(dep);
        successors[dep.fromTaskId]!.add(dep);
      }
    }

    // Forward pass - calculate earliest start and finish
    final earliestStart = <String, DateTime>{};
    final earliestFinish = <String, DateTime>{};

    // Topological sort for forward pass
    final sortedTasks = _topologicalSort(tasks, predecessors);

    final baseDate = projectStart ?? _findEarliestDate(tasks);

    for (final task in sortedTasks) {
      DateTime es = task.startDate;

      // Check all predecessors
      for (final dep in predecessors[task.id]!) {
        final predFinish = earliestFinish[dep.fromTaskId];
        if (predFinish == null) continue;

        final constraintDate = _calculateConstraintDate(
          predTask: taskMap[dep.fromTaskId]!,
          predEarliestStart: earliestStart[dep.fromTaskId]!,
          predEarliestFinish: predFinish,
          depType: dep.type,
          lagDays: dep.lagDays,
          isForward: true,
        );

        if (constraintDate.isAfter(es)) {
          es = constraintDate;
        }
      }

      earliestStart[task.id] = es;
      earliestFinish[task.id] = es.add(Duration(days: task.durationDays));
    }

    // Backward pass - calculate latest start and finish
    final latestStart = <String, DateTime>{};
    final latestFinish = <String, DateTime>{};

    // Find project end date (latest earliest finish)
    DateTime projectEnd = baseDate;
    for (final ef in earliestFinish.values) {
      if (ef.isAfter(projectEnd)) {
        projectEnd = ef;
      }
    }

    // Reverse topological order for backward pass
    final reversedTasks = sortedTasks.reversed.toList();

    for (final task in reversedTasks) {
      DateTime lf = projectEnd;

      // Check all successors
      for (final dep in successors[task.id]!) {
        final succStart = latestStart[dep.toTaskId];
        if (succStart == null) continue;

        final constraintDate = _calculateConstraintDate(
          predTask: task,
          predEarliestStart: earliestStart[task.id]!,
          predEarliestFinish: earliestFinish[task.id]!,
          depType: dep.type,
          lagDays: dep.lagDays,
          isForward: false,
          succLatestStart: succStart,
          succLatestFinish: latestFinish[dep.toTaskId]!,
          succTask: taskMap[dep.toTaskId]!,
        );

        if (constraintDate.isBefore(lf)) {
          lf = constraintDate;
        }
      }

      latestFinish[task.id] = lf;
      latestStart[task.id] = lf.subtract(Duration(days: task.durationDays));
    }

    // Calculate floats and identify critical path
    for (final task in tasks) {
      final es = earliestStart[task.id]!;
      final ef = earliestFinish[task.id]!;
      final ls = latestStart[task.id]!;
      final lf = latestFinish[task.id]!;

      final totalFloat = ls.difference(es).inDays;

      // Free float = Min(ES of successors) - EF of this task - lag
      int freeFloat = totalFloat;
      for (final dep in successors[task.id]!) {
        final succEs = earliestStart[dep.toTaskId];
        if (succEs != null) {
          final ff = succEs.difference(ef).inDays - dep.lagDays;
          if (ff < freeFloat) {
            freeFloat = ff;
          }
        }
      }

      results[task.id] = ScheduleResult(
        taskId: task.id,
        earliestStart: es,
        earliestFinish: ef,
        latestStart: ls,
        latestFinish: lf,
        totalFloat: totalFloat,
        freeFloat: freeFloat < 0 ? 0 : freeFloat,
        isCritical: totalFloat == 0,
      );
    }

    return results;
  }

  /// Get critical path tasks
  static List<Task> getCriticalPath({
    required List<Task> tasks,
    required List<TaskDependency> dependencies,
  }) {
    final schedule = calculateSchedule(tasks: tasks, dependencies: dependencies);
    return tasks.where((t) => schedule[t.id]?.isCritical ?? false).toList();
  }

  /// Get critical path as ordered list (following dependencies)
  static List<Task> getCriticalPathOrdered({
    required List<Task> tasks,
    required List<TaskDependency> dependencies,
  }) {
    final schedule = calculateSchedule(tasks: tasks, dependencies: dependencies);
    final criticalTasks = tasks.where((t) => schedule[t.id]?.isCritical ?? false).toList();

    // Sort by earliest start
    criticalTasks.sort((a, b) {
      final aEs = schedule[a.id]!.earliestStart;
      final bEs = schedule[b.id]!.earliestStart;
      return aEs.compareTo(bEs);
    });

    return criticalTasks;
  }

  /// Calculate impact of delaying a task
  static DelayImpact calculateDelayImpact({
    required Task delayedTask,
    required int delayDays,
    required List<Task> tasks,
    required List<TaskDependency> dependencies,
  }) {
    if (delayDays <= 0) {
      return DelayImpact(
        taskId: delayedTask.id,
        delayDays: 0,
        affectedTaskIds: [],
        projectDelayDays: 0,
        taskDelayMap: {},
      );
    }

    // Calculate original schedule
    final originalSchedule = calculateSchedule(tasks: tasks, dependencies: dependencies);

    // Create modified task list with delayed task
    final modifiedTasks = tasks.map((t) {
      if (t.id == delayedTask.id) {
        return t.copyWith(
          startDate: t.startDate.add(Duration(days: delayDays)),
          endDate: t.endDate.add(Duration(days: delayDays)),
        );
      }
      return t;
    }).toList();

    // Calculate new schedule
    final newSchedule = calculateSchedule(tasks: modifiedTasks, dependencies: dependencies);

    // Find affected tasks
    final affectedTaskIds = <String>[];
    final taskDelayMap = <String, int>{};

    for (final task in tasks) {
      if (task.id == delayedTask.id) continue;

      final originalEs = originalSchedule[task.id]!.earliestStart;
      final newEs = newSchedule[task.id]!.earliestStart;
      final delay = newEs.difference(originalEs).inDays;

      if (delay > 0) {
        affectedTaskIds.add(task.id);
        taskDelayMap[task.id] = delay;
      }
    }

    // Calculate project delay
    DateTime originalEnd = DateTime(1900);
    DateTime newEnd = DateTime(1900);

    for (final result in originalSchedule.values) {
      if (result.earliestFinish.isAfter(originalEnd)) {
        originalEnd = result.earliestFinish;
      }
    }

    for (final result in newSchedule.values) {
      if (result.earliestFinish.isAfter(newEnd)) {
        newEnd = result.earliestFinish;
      }
    }

    final projectDelay = newEnd.difference(originalEnd).inDays;

    return DelayImpact(
      taskId: delayedTask.id,
      delayDays: delayDays,
      affectedTaskIds: affectedTaskIds,
      projectDelayDays: projectDelay > 0 ? projectDelay : 0,
      taskDelayMap: taskDelayMap,
    );
  }

  /// Auto-adjust task dates based on dependencies
  /// Returns updated task list
  static List<Task> autoAdjustSchedule({
    required List<Task> tasks,
    required List<TaskDependency> dependencies,
    DateTime? projectStart,
  }) {
    final schedule = calculateSchedule(
      tasks: tasks,
      dependencies: dependencies,
      projectStart: projectStart,
    );

    return tasks.map((task) {
      final result = schedule[task.id];
      if (result == null) return task;

      // Only adjust if task dates don't match calculated earliest dates
      if (task.startDate != result.earliestStart ||
          task.endDate != result.earliestFinish) {
        return task.copyWith(
          startDate: result.earliestStart,
          endDate: result.earliestFinish,
        );
      }
      return task;
    }).toList();
  }

  /// Check if adding a dependency would create a cycle
  static bool wouldCreateCycle({
    required String fromTaskId,
    required String toTaskId,
    required List<TaskDependency> existingDependencies,
  }) {
    // Build adjacency list
    final adjacency = <String, Set<String>>{};

    for (final dep in existingDependencies) {
      adjacency.putIfAbsent(dep.fromTaskId, () => {});
      adjacency[dep.fromTaskId]!.add(dep.toTaskId);
    }

    // Add the new dependency temporarily
    adjacency.putIfAbsent(fromTaskId, () => {});
    adjacency[fromTaskId]!.add(toTaskId);

    // Check if there's a path from toTaskId back to fromTaskId (DFS)
    final visited = <String>{};
    final stack = <String>[toTaskId];

    while (stack.isNotEmpty) {
      final current = stack.removeLast();

      if (current == fromTaskId) {
        return true; // Cycle found
      }

      if (visited.contains(current)) continue;
      visited.add(current);

      final neighbors = adjacency[current] ?? {};
      for (final neighbor in neighbors) {
        if (!visited.contains(neighbor)) {
          stack.add(neighbor);
        }
      }
    }

    return false;
  }

  /// Get all tasks affected by a specific task (downstream dependencies)
  static Set<String> getDownstreamTasks({
    required String taskId,
    required List<TaskDependency> dependencies,
  }) {
    final downstream = <String>{};
    final adjacency = <String, Set<String>>{};

    for (final dep in dependencies) {
      adjacency.putIfAbsent(dep.fromTaskId, () => {});
      adjacency[dep.fromTaskId]!.add(dep.toTaskId);
    }

    final stack = <String>[taskId];

    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      final successors = adjacency[current] ?? {};

      for (final succ in successors) {
        if (!downstream.contains(succ)) {
          downstream.add(succ);
          stack.add(succ);
        }
      }
    }

    return downstream;
  }

  /// Get all tasks that a specific task depends on (upstream dependencies)
  static Set<String> getUpstreamTasks({
    required String taskId,
    required List<TaskDependency> dependencies,
  }) {
    final upstream = <String>{};
    final reverseAdjacency = <String, Set<String>>{};

    for (final dep in dependencies) {
      reverseAdjacency.putIfAbsent(dep.toTaskId, () => {});
      reverseAdjacency[dep.toTaskId]!.add(dep.fromTaskId);
    }

    final stack = <String>[taskId];

    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      final predecessors = reverseAdjacency[current] ?? {};

      for (final pred in predecessors) {
        if (!upstream.contains(pred)) {
          upstream.add(pred);
          stack.add(pred);
        }
      }
    }

    return upstream;
  }

  // Helper: Topological sort
  static List<Task> _topologicalSort(
    List<Task> tasks,
    Map<String, List<TaskDependency>> predecessors,
  ) {
    final result = <Task>[];
    final inDegree = <String, int>{};
    final taskMap = {for (var t in tasks) t.id: t};

    // Initialize in-degree
    for (final task in tasks) {
      inDegree[task.id] = predecessors[task.id]?.length ?? 0;
    }

    // Start with tasks that have no predecessors
    final queue = <String>[];
    for (final entry in inDegree.entries) {
      if (entry.value == 0) {
        queue.add(entry.key);
      }
    }

    // Sort queue by start date for deterministic order
    queue.sort((a, b) => taskMap[a]!.startDate.compareTo(taskMap[b]!.startDate));

    while (queue.isNotEmpty) {
      final taskId = queue.removeAt(0);
      result.add(taskMap[taskId]!);

      // Find successors and decrease their in-degree
      for (final task in tasks) {
        final deps = predecessors[task.id] ?? [];
        if (deps.any((d) => d.fromTaskId == taskId)) {
          inDegree[task.id] = (inDegree[task.id] ?? 1) - 1;
          if (inDegree[task.id] == 0) {
            queue.add(task.id);
          }
        }
      }

      // Keep queue sorted
      queue.sort((a, b) => taskMap[a]!.startDate.compareTo(taskMap[b]!.startDate));
    }

    // If we couldn't sort all tasks, there's a cycle
    // Add remaining tasks anyway
    for (final task in tasks) {
      if (!result.contains(task)) {
        result.add(task);
      }
    }

    return result;
  }

  // Helper: Calculate constraint date based on dependency type
  static DateTime _calculateConstraintDate({
    required Task predTask,
    required DateTime predEarliestStart,
    required DateTime predEarliestFinish,
    required DependencyType depType,
    required int lagDays,
    required bool isForward,
    DateTime? succLatestStart,
    DateTime? succLatestFinish,
    Task? succTask,
  }) {
    if (isForward) {
      // Forward pass - calculating earliest start of successor
      switch (depType) {
        case DependencyType.fs: // Finish-to-Start
          return predEarliestFinish.add(Duration(days: lagDays));
        case DependencyType.ss: // Start-to-Start
          return predEarliestStart.add(Duration(days: lagDays));
        case DependencyType.ff: // Finish-to-Finish
          // Successor's ES = Pred's EF + lag - Successor's duration
          // This ensures they finish together
          return predEarliestFinish.add(Duration(days: lagDays));
        case DependencyType.sf: // Start-to-Finish
          // Successor's ES = Pred's ES + lag - Successor's duration
          return predEarliestStart.add(Duration(days: lagDays));
      }
    } else {
      // Backward pass - calculating latest finish of predecessor
      if (succLatestStart == null || succLatestFinish == null || succTask == null) {
        return predEarliestFinish;
      }

      switch (depType) {
        case DependencyType.fs: // Finish-to-Start
          return succLatestStart.subtract(Duration(days: lagDays));
        case DependencyType.ss: // Start-to-Start
          return succLatestStart.subtract(Duration(days: lagDays))
              .add(Duration(days: predTask.durationDays));
        case DependencyType.ff: // Finish-to-Finish
          return succLatestFinish.subtract(Duration(days: lagDays));
        case DependencyType.sf: // Start-to-Finish
          return succLatestFinish.subtract(Duration(days: lagDays))
              .add(Duration(days: predTask.durationDays));
      }
    }
  }

  // Helper: Find earliest date among tasks
  static DateTime _findEarliestDate(List<Task> tasks) {
    if (tasks.isEmpty) return DateTime.now();

    DateTime earliest = tasks.first.startDate;
    for (final task in tasks) {
      if (task.startDate.isBefore(earliest)) {
        earliest = task.startDate;
      }
    }
    return earliest;
  }
}
