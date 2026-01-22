/// PDF Export Widgets
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/pdf_export_service.dart';

class ExportButton extends StatelessWidget {
  final PDFTemplateType type;
  final VoidCallback onPressed;
  final bool isLoading;

  const ExportButton({
    super.key,
    required this.type,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading 
        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
        : const Icon(Icons.picture_as_pdf, size: 18),
      label: Text('${type.label}をPDF出力'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class ExportOptionsSheet extends StatelessWidget {
  final Function(PDFTemplateType) onExport;

  const ExportOptionsSheet({super.key, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PDF出力', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...PDFTemplateType.values.map((type) => ListTile(
            leading: const Icon(Icons.description, color: AppColors.primary),
            title: Text(type.label, style: const TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              onExport(type);
            },
          )),
        ],
      ),
    );
  }
}
