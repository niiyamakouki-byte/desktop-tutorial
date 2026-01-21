import 'user_model.dart';

/// Project model representing a construction project
class Project {
  final String id;
  final String name;
  final String description;
  final String clientName;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final double budget;
  final String status;
  final List<User> members;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.clientName,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.budget,
    required this.status,
    required this.members,
    this.thumbnailUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? clientName,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    String? status,
    List<User>? members,
    String? thumbnailUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      clientName: clientName ?? this.clientName,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      status: status ?? this.status,
      members: members ?? this.members,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get durationDays => endDate.difference(startDate).inDays;

  double get progress {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 1.0;
    final elapsed = now.difference(startDate).inDays;
    return elapsed / durationDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'clientName': clientName,
      'location': location,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'budget': budget,
      'status': status,
      'members': members.map((m) => m.toJson()).toList(),
      'thumbnailUrl': thumbnailUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      clientName: json['clientName'] as String,
      location: json['location'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      budget: (json['budget'] as num).toDouble(),
      status: json['status'] as String,
      members: (json['members'] as List)
          .map((m) => User.fromJson(m as Map<String, dynamic>))
          .toList(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Project status definitions
class ProjectStatus {
  static const String planning = 'planning';
  static const String inProgress = 'in_progress';
  static const String onHold = 'on_hold';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static const Map<String, String> labels = {
    planning: '計画中',
    inProgress: '進行中',
    onHold: '保留',
    completed: '完了',
    cancelled: '中止',
  };

  static String getLabel(String status) {
    return labels[status] ?? status;
  }
}
