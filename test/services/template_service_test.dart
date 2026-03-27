import 'package:flutter_test/flutter_test.dart';
import 'package:construction_project_manager/data/models/models.dart';
import 'package:construction_project_manager/data/services/template_service.dart';

void main() {
  group('TemplateService', () {
    test('project templates are available', () {
      final templates = TemplateService.getProjectTemplates();
      expect(templates, isNotEmpty);
      expect(
        templates.any((template) => template.id == 'office_building_standard'),
        isTrue,
      );
    });

    test('buildTasksFromTemplate creates tasks with dependency mapping', () {
      final tasks = TemplateService.buildTasksFromTemplate(
        templateId: 'office_building_standard',
        projectId: 'proj_test',
        projectStartDate: DateTime(2026, 1, 1),
        availableUsers: const <User>[],
      );

      expect(tasks.length, greaterThanOrEqualTo(5));
      expect(tasks.first.projectId, 'proj_test');
      expect(tasks.any((task) => task.dependsOn.isNotEmpty), isTrue);
    });

    test('spreadsheet templates include progress report', () {
      final sheets = TemplateService.getAvailableSpreadsheets();
      expect(sheets.any((sheet) => sheet.id == 'progress_report'), isTrue);
    });
  });
}
