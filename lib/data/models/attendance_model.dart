/// Attendance & QR Code Models for Construction Site Entry/Exit Management
/// 建設現場入退場管理モデル

import 'package:flutter/material.dart';

/// 入退場タイプ
enum AttendanceType {
  entry,  // 入場
  exit,   // 退場
}

extension AttendanceTypeExtension on AttendanceType {
  String get label {
    switch (this) {
      case AttendanceType.entry:
        return '入場';
      case AttendanceType.exit:
        return '退場';
    }
  }

  IconData get icon {
    switch (this) {
      case AttendanceType.entry:
        return Icons.login;
      case AttendanceType.exit:
        return Icons.logout;
    }
  }

  Color get color {
    switch (this) {
      case AttendanceType.entry:
        return const Color(0xFF4CAF50);
      case AttendanceType.exit:
        return const Color(0xFFF44336);
    }
  }
}

/// 作業員情報
class WorkerInfo {
  final String id;
  final String name;
  final String company;
  final String role;
  final List<String> certifications;
  final String? photoUrl;
  final DateTime registeredDate;
  final bool isActive;

  const WorkerInfo({
    required this.id,
    required this.name,
    required this.company,
    required this.role,
    this.certifications = const [],
    this.photoUrl,
    required this.registeredDate,
    this.isActive = true,
  });
}

/// 入退場記録
class AttendanceRecord {
  final String id;
  final String workerId;
  final String workerName;
  final String company;
  final String projectId;
  final AttendanceType type;
  final DateTime timestamp;
  final String? notes;

  const AttendanceRecord({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.company,
    required this.projectId,
    required this.type,
    required this.timestamp,
    this.notes,
  });
}

/// QRコードデータ
class QRCodeData {
  final String projectId;
  final String projectName;
  final String encodedData;
  final DateTime generatedDate;

  const QRCodeData({
    required this.projectId,
    required this.projectName,
    required this.encodedData,
    required this.generatedDate,
  });
}

/// 作業員の日次勤務情報
class WorkerDailyAttendance {
  final String workerId;
  final String workerName;
  final String company;
  final DateTime? entryTime;
  final DateTime? exitTime;
  final bool isCurrentlyOnSite;

  const WorkerDailyAttendance({
    required this.workerId,
    required this.workerName,
    required this.company,
    this.entryTime,
    this.exitTime,
    this.isCurrentlyOnSite = false,
  });

  String get workedHoursDisplay {
    if (entryTime == null) return '-';
    final end = exitTime ?? DateTime.now();
    final duration = end.difference(entryTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}時間${minutes}分';
  }
}
