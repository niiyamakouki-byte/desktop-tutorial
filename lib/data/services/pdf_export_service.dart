/// PDF Export Service
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/construction_photo_model.dart';
import '../models/attendance_model.dart';

class PDFExportResult {
  final bool success;
  final String? filePath;
  final String? errorMessage;
  final int? pageCount;

  const PDFExportResult({required this.success, this.filePath, this.errorMessage, this.pageCount});
}

class PDFExportService {
  Future<PDFExportResult> exportGanttChartPDF({
    required List<Task> tasks,
    required String projectName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('Generating Gantt Chart PDF for $projectName');
    return PDFExportResult(
      success: true,
      filePath: '/downloads/gantt_${projectName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      pageCount: (tasks.length / 15).ceil() + 1,
    );
  }

  Future<PDFExportResult> exportPhotoLedgerPDF({
    required List<ConstructionPhoto> photos,
    required String projectName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return PDFExportResult(
      success: true,
      filePath: '/downloads/photo_ledger_${projectName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      pageCount: (photos.length / 6).ceil() + 1,
    );
  }

  Future<PDFExportResult> exportAttendanceReportPDF({
    required List<AttendanceRecord> records,
    required String projectName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return PDFExportResult(
      success: true,
      filePath: '/downloads/attendance_${projectName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      pageCount: (records.length / 30).ceil() + 1,
    );
  }
}

enum PDFTemplateType { ganttChart, photoLedger, attendanceReport, projectSummary }

extension PDFTemplateTypeExtension on PDFTemplateType {
  String get label {
    switch (this) {
      case PDFTemplateType.ganttChart: return '工程表';
      case PDFTemplateType.photoLedger: return '写真台帳';
      case PDFTemplateType.attendanceReport: return '入退場記録';
      case PDFTemplateType.projectSummary: return 'プロジェクト概要';
    }
  }
}
