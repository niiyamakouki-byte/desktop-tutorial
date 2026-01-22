/// Construction Photo Management Models
/// 工事写真管理モデル

import 'package:flutter/material.dart';

/// 写真カテゴリ（工種）
enum PhotoCategory {
  foundation,   // 基礎工事
  framing,      // 躯体工事
  electrical,   // 電気工事
  plumbing,     // 配管工事
  hvac,         // 空調工事
  interior,     // 内装工事
  exterior,     // 外装工事
  roofing,      // 屋根工事
  finishing,    // 仕上げ工事
  inspection,   // 検査
  safety,       // 安全管理
  other,        // その他
}

extension PhotoCategoryExtension on PhotoCategory {
  String get label {
    switch (this) {
      case PhotoCategory.foundation:
        return '基礎工事';
      case PhotoCategory.framing:
        return '躯体工事';
      case PhotoCategory.electrical:
        return '電気工事';
      case PhotoCategory.plumbing:
        return '配管工事';
      case PhotoCategory.hvac:
        return '空調工事';
      case PhotoCategory.interior:
        return '内装工事';
      case PhotoCategory.exterior:
        return '外装工事';
      case PhotoCategory.roofing:
        return '屋根工事';
      case PhotoCategory.finishing:
        return '仕上げ工事';
      case PhotoCategory.inspection:
        return '検査';
      case PhotoCategory.safety:
        return '安全管理';
      case PhotoCategory.other:
        return 'その他';
    }
  }

  IconData get icon {
    switch (this) {
      case PhotoCategory.foundation:
        return Icons.foundation;
      case PhotoCategory.framing:
        return Icons.apartment;
      case PhotoCategory.electrical:
        return Icons.electrical_services;
      case PhotoCategory.plumbing:
        return Icons.plumbing;
      case PhotoCategory.hvac:
        return Icons.air;
      case PhotoCategory.interior:
        return Icons.chair;
      case PhotoCategory.exterior:
        return Icons.home_work;
      case PhotoCategory.roofing:
        return Icons.roofing;
      case PhotoCategory.finishing:
        return Icons.format_paint;
      case PhotoCategory.inspection:
        return Icons.checklist;
      case PhotoCategory.safety:
        return Icons.health_and_safety;
      case PhotoCategory.other:
        return Icons.photo_library;
    }
  }

  Color get color {
    switch (this) {
      case PhotoCategory.foundation:
        return const Color(0xFF795548);
      case PhotoCategory.framing:
        return const Color(0xFF607D8B);
      case PhotoCategory.electrical:
        return const Color(0xFFFF9800);
      case PhotoCategory.plumbing:
        return const Color(0xFF2196F3);
      case PhotoCategory.hvac:
        return const Color(0xFF00BCD4);
      case PhotoCategory.interior:
        return const Color(0xFF9C27B0);
      case PhotoCategory.exterior:
        return const Color(0xFF4CAF50);
      case PhotoCategory.roofing:
        return const Color(0xFFE91E63);
      case PhotoCategory.finishing:
        return const Color(0xFFFFEB3B);
      case PhotoCategory.inspection:
        return const Color(0xFF3F51B5);
      case PhotoCategory.safety:
        return const Color(0xFFF44336);
      case PhotoCategory.other:
        return const Color(0xFF9E9E9E);
    }
  }
}

/// ビフォア・アフタータイプ
enum BeforeAfterType {
  before,  // 施工前
  after,   // 施工後
  during,  // 施工中
}

extension BeforeAfterTypeExtension on BeforeAfterType {
  String get label {
    switch (this) {
      case BeforeAfterType.before:
        return '施工前';
      case BeforeAfterType.after:
        return '施工後';
      case BeforeAfterType.during:
        return '施工中';
    }
  }

  Color get color {
    switch (this) {
      case BeforeAfterType.before:
        return const Color(0xFFFF9800);
      case BeforeAfterType.after:
        return const Color(0xFF4CAF50);
      case BeforeAfterType.during:
        return const Color(0xFF2196F3);
    }
  }
}

/// 写真メタデータ
class PhotoMetadata {
  final String? cameraModel;
  final String? resolution;
  final double? latitude;
  final double? longitude;
  final int? fileSize;
  final String? originalFileName;

  const PhotoMetadata({
    this.cameraModel,
    this.resolution,
    this.latitude,
    this.longitude,
    this.fileSize,
    this.originalFileName,
  });

  bool get hasLocation => latitude != null && longitude != null;

  String get fileSizeDisplay {
    if (fileSize == null) return '-';
    if (fileSize! < 1024) return '${fileSize}B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Map<String, dynamic> toJson() => {
    'cameraModel': cameraModel,
    'resolution': resolution,
    'latitude': latitude,
    'longitude': longitude,
    'fileSize': fileSize,
    'originalFileName': originalFileName,
  };

  factory PhotoMetadata.fromJson(Map<String, dynamic> json) => PhotoMetadata(
    cameraModel: json['cameraModel'],
    resolution: json['resolution'],
    latitude: json['latitude']?.toDouble(),
    longitude: json['longitude']?.toDouble(),
    fileSize: json['fileSize'],
    originalFileName: json['originalFileName'],
  );
}

/// 工事写真
class ConstructionPhoto {
  final String id;
  final String projectId;
  final String? taskId;
  final String imagePath;
  final String? thumbnailPath;
  final DateTime timestamp;
  final String photographerId;
  final String photographerName;
  final PhotoCategory category;
  final BeforeAfterType beforeAfterType;
  final String? location;
  final String? floor;
  final String? notes;
  final PhotoMetadata? metadata;
  final List<String> tags;
  final bool isApproved;

  const ConstructionPhoto({
    required this.id,
    required this.projectId,
    this.taskId,
    required this.imagePath,
    this.thumbnailPath,
    required this.timestamp,
    required this.photographerId,
    required this.photographerName,
    required this.category,
    required this.beforeAfterType,
    this.location,
    this.floor,
    this.notes,
    this.metadata,
    this.tags = const [],
    this.isApproved = false,
  });

  ConstructionPhoto copyWith({
    String? id,
    String? projectId,
    String? taskId,
    String? imagePath,
    String? thumbnailPath,
    DateTime? timestamp,
    String? photographerId,
    String? photographerName,
    PhotoCategory? category,
    BeforeAfterType? beforeAfterType,
    String? location,
    String? floor,
    String? notes,
    PhotoMetadata? metadata,
    List<String>? tags,
    bool? isApproved,
  }) {
    return ConstructionPhoto(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      taskId: taskId ?? this.taskId,
      imagePath: imagePath ?? this.imagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      timestamp: timestamp ?? this.timestamp,
      photographerId: photographerId ?? this.photographerId,
      photographerName: photographerName ?? this.photographerName,
      category: category ?? this.category,
      beforeAfterType: beforeAfterType ?? this.beforeAfterType,
      location: location ?? this.location,
      floor: floor ?? this.floor,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
      isApproved: isApproved ?? this.isApproved,
    );
  }

  String get dateDisplay {
    return '${timestamp.year}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.day.toString().padLeft(2, '0')}';
  }

  String get timeDisplay {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'taskId': taskId,
    'imagePath': imagePath,
    'thumbnailPath': thumbnailPath,
    'timestamp': timestamp.toIso8601String(),
    'photographerId': photographerId,
    'photographerName': photographerName,
    'category': category.name,
    'beforeAfterType': beforeAfterType.name,
    'location': location,
    'floor': floor,
    'notes': notes,
    'metadata': metadata?.toJson(),
    'tags': tags,
    'isApproved': isApproved,
  };

  factory ConstructionPhoto.fromJson(Map<String, dynamic> json) => ConstructionPhoto(
    id: json['id'],
    projectId: json['projectId'],
    taskId: json['taskId'],
    imagePath: json['imagePath'],
    thumbnailPath: json['thumbnailPath'],
    timestamp: DateTime.parse(json['timestamp']),
    photographerId: json['photographerId'],
    photographerName: json['photographerName'],
    category: PhotoCategory.values.firstWhere((e) => e.name == json['category']),
    beforeAfterType: BeforeAfterType.values.firstWhere((e) => e.name == json['beforeAfterType']),
    location: json['location'],
    floor: json['floor'],
    notes: json['notes'],
    metadata: json['metadata'] != null ? PhotoMetadata.fromJson(json['metadata']) : null,
    tags: List<String>.from(json['tags'] ?? []),
    isApproved: json['isApproved'] ?? false,
  );
}

/// ビフォア・アフターペア
class BeforeAfterPair {
  final String id;
  final ConstructionPhoto beforePhoto;
  final ConstructionPhoto afterPhoto;
  final String? taskId;
  final String? taskName;
  final DateTime completedDate;
  final String? notes;

  const BeforeAfterPair({
    required this.id,
    required this.beforePhoto,
    required this.afterPhoto,
    this.taskId,
    this.taskName,
    required this.completedDate,
    this.notes,
  });
}

/// 写真台帳エントリー
class PhotoLedgerEntry {
  final DateTime date;
  final PhotoCategory category;
  final List<ConstructionPhoto> photos;
  final String? workDescription;

  const PhotoLedgerEntry({
    required this.date,
    required this.category,
    required this.photos,
    this.workDescription,
  });

  int get photoCount => photos.length;

  int get beforeCount => photos.where((p) => p.beforeAfterType == BeforeAfterType.before).length;
  int get afterCount => photos.where((p) => p.beforeAfterType == BeforeAfterType.after).length;
}

/// 写真台帳
class PhotoLedger {
  final String projectId;
  final String projectName;
  final DateTime generatedDate;
  final DateTime startDate;
  final DateTime endDate;
  final List<PhotoLedgerEntry> entries;
  final int totalPhotos;

  const PhotoLedger({
    required this.projectId,
    required this.projectName,
    required this.generatedDate,
    required this.startDate,
    required this.endDate,
    required this.entries,
    required this.totalPhotos,
  });

  Map<PhotoCategory, int> get photosByCategory {
    final map = <PhotoCategory, int>{};
    for (final entry in entries) {
      map[entry.category] = (map[entry.category] ?? 0) + entry.photoCount;
    }
    return map;
  }
}
