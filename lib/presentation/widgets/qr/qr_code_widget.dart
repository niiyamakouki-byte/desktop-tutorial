/// QR Code Display Widget
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/attendance_model.dart';

class QRCodeDisplay extends StatelessWidget {
  final QRCodeData qrData;
  final VoidCallback? onPrint;
  final VoidCallback? onShare;

  const QRCodeDisplay({super.key, required this.qrData, this.onPrint, this.onShare});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(qrData.projectName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_2, size: 120, color: Colors.black87),
                  const SizedBox(height: 8),
                  Text('ID: ${qrData.projectId}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onPrint != null)
                ElevatedButton.icon(
                  onPressed: onPrint,
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('印刷'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              const SizedBox(width: 12),
              if (onShare != null)
                OutlinedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('共有'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class QRScannerButton extends StatelessWidget {
  final VoidCallback onScan;

  const QRScannerButton({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onScan,
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text('QRスキャン'),
    );
  }
}
