/// User model representing team members in the construction project
class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String role;
  final String department;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? phone;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.role,
    required this.department,
    this.isOnline = false,
    this.lastSeen,
    this.phone,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? role,
    String? department,
    bool? isOnline,
    DateTime? lastSeen,
    String? phone,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      department: department ?? this.department,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'role': role,
      'department': department,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'phone': phone,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String,
      department: json['department'] as String,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
      phone: json['phone'] as String?,
    );
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// User roles in construction projects
class UserRole {
  static const String projectManager = 'project_manager';
  static const String siteManager = 'site_manager';
  static const String engineer = 'engineer';
  static const String architect = 'architect';
  static const String subcontractor = 'subcontractor';
  static const String inspector = 'inspector';
  static const String client = 'client';

  static const Map<String, String> labels = {
    projectManager: 'プロジェクトマネージャー',
    siteManager: '現場監督',
    engineer: 'エンジニア',
    architect: '設計士',
    subcontractor: '下請け業者',
    inspector: '検査員',
    client: '施主',
  };

  static String getLabel(String role) {
    return labels[role] ?? role;
  }
}
