// lib/features/reports/presentation/widgets/export_button.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ExportButton extends StatelessWidget {
  final VoidCallback onExportPdf;
  final VoidCallback onExportExcel;
  final VoidCallback onPrint;

  const ExportButton({
    super.key,
    required this.onExportPdf,
    required this.onExportExcel,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildButton(
                Icons.picture_as_pdf, 'PDF', AppColors.error, onExportPdf),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildButton(
                Icons.table_chart, 'Excel', AppColors.success, onExportExcel),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                _buildButton(Icons.print, 'Print', AppColors.primary, onPrint),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: AppTextStyles.labelLarge
                    .copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
