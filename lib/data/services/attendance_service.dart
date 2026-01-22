/// Attendance Service for QR Code Entry/Exit Management
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/attendance_model.dart';

class AttendanceService extends ChangeNotifier {
  final List<AttendanceRecord> _records = [];
  final List<WorkerInfo> _workers = [];

  List<AttendanceRecord> get records => List.unmodifiable(_records);
  List<WorkerInfo> get workers => List.unmodifiable(_workers);

  AttendanceService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    final mockWorkers = [
      WorkerInfo(id: 'w1', name: '田中 太郎', company: '田中建設', role: '現場監督', certifications: ['1級建築施工管理技士'], registeredDate: DateTime(2024, 1, 1)),
      WorkerInfo(id: 'w2', name: '佐藤 次郎', company: '佐藤電気', role: '電気工', certifications: ['第一種電気工事士'], registeredDate: DateTime(2024, 1, 5)),
      WorkerInfo(id: 'w3', name: '鈴木 三郎', company: '鈴木設備', role: '配管工', registeredDate: DateTime(2024, 1, 10)),
      WorkerInfo(id: 'w4', name: '高橋 四郎', company: '田中建設', role: '大工', registeredDate: DateTime(2024, 2, 1)),
      WorkerInfo(id: 'w5', name: '伊藤 五郎', company: '伊藤塗装', role: '塗装工', registeredDate: DateTime(2024, 2, 15)),
      WorkerInfo(id: 'w6', name: '渡辺 六郎', company: '渡辺工業', role: '鉄筋工', registeredDate: DateTime(2024, 3, 1)),
    ];
    _workers.addAll(mockWorkers);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final mockRecords = [
      AttendanceRecord(id: 'r1', workerId: 'w1', workerName: '田中 太郎', company: '田中建設', projectId: 'p1', type: AttendanceType.entry, timestamp: today.add(const Duration(hours: 7, minutes: 30))),
      AttendanceRecord(id: 'r2', workerId: 'w2', workerName: '佐藤 次郎', company: '佐藤電気', projectId: 'p1', type: AttendanceType.entry, timestamp: today.add(const Duration(hours: 7, minutes: 45))),
      AttendanceRecord(id: 'r3', workerId: 'w3', workerName: '鈴木 三郎', company: '鈴木設備', projectId: 'p1', type: AttendanceType.entry, timestamp: today.add(const Duration(hours: 8, minutes: 0))),
      AttendanceRecord(id: 'r4', workerId: 'w4', workerName: '高橋 四郎', company: '田中建設', projectId: 'p1', type: AttendanceType.entry, timestamp: today.add(const Duration(hours: 8, minutes: 15))),
      AttendanceRecord(id: 'r5', workerId: 'w5', workerName: '伊藤 五郎', company: '伊藤塗装', projectId: 'p1', type: AttendanceType.entry, timestamp: today.add(const Duration(hours: 8, minutes: 30))),
    ];
    _records.addAll(mockRecords);
  }

  QRCodeData generateProjectQRCode(String projectId, String projectName) {
    final data = {'projectId': projectId, 'projectName': projectName, 'generated': DateTime.now().toIso8601String()};
    final encodedData = base64Encode(utf8.encode(jsonEncode(data)));
    return QRCodeData(projectId: projectId, projectName: projectName, encodedData: encodedData, generatedDate: DateTime.now());
  }

  AttendanceRecord recordEntry(String workerId, String projectId) {
    final worker = _workers.firstWhere((w) => w.id == workerId);
    final record = AttendanceRecord(
      id: 'r\${DateTime.now().millisecondsSinceEpoch}',
      workerId: workerId, workerName: worker.name, company: worker.company,
      projectId: projectId, type: AttendanceType.entry, timestamp: DateTime.now(),
    );
    _records.add(record);
    notifyListeners();
    return record;
  }

  List<AttendanceRecord> getTodayAttendance(String projectId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _records.where((r) => r.projectId == projectId && r.timestamp.isAfter(today)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<WorkerDailyAttendance> getWorkersOnSite(String projectId) {
    final todayRecords = getTodayAttendance(projectId);
    final workerMap = <String, WorkerDailyAttendance>{};
    for (final record in todayRecords.reversed) {
      if (record.type == AttendanceType.entry) {
        workerMap[record.workerId] = WorkerDailyAttendance(
          workerId: record.workerId, workerName: record.workerName, company: record.company,
          entryTime: record.timestamp, isCurrentlyOnSite: true,
        );
      }
    }
    return workerMap.values.toList();
  }
}
