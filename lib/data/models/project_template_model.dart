/// Project template models
/// 標準工程テンプレート定義

class ProjectTemplateTask {
  final String id;
  final String name;
  final String category;
  final int durationDays;
  final int offsetDays;
  final List<String> dependsOn;
  final String priority;
  final String status;

  const ProjectTemplateTask({
    required this.id,
    required this.name,
    required this.category,
    required this.durationDays,
    required this.offsetDays,
    this.dependsOn = const [],
    this.priority = 'medium',
    this.status = 'not_started',
  });
}

class ProjectTemplate {
  final String id;
  final String name;
  final String description;
  final String industry;
  final List<ProjectTemplateTask> tasks;

  const ProjectTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.industry,
    required this.tasks,
  });
}
