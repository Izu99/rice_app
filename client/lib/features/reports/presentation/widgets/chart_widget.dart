// lib/features/reports/presentation/widgets/chart_widget.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/report_model.dart';

class ChartWidget extends StatelessWidget {
  final ReportModel? report;

  const ChartWidget({super.key, this.report});

  @override
  Widget build(BuildContext context) {
    if (report == null) {
      return const SizedBox.shrink();
    }

    final chartData = report!.charts;
    if (chartData == null) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
            color: AppColors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            const Icon(Icons.bar_chart, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('No chart data available',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    // Simple bar representation
    final profits = (chartData['daily_profit'] as List?)?.cast<num>() ?? [];
    final maxProfit = profits.isEmpty
        ? 1.0
        : profits.reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Profit Trend',
              style: AppTextStyles.titleMedium
                  .copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(profits.length.clamp(0, 15), (i) {
                final value = profits[i].toDouble();
                final height = maxProfit > 0 ? (value / maxProfit) * 120 : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: height.clamp(4.0, 120.0),
                          decoration: BoxDecoration(
                            color: value >= 0
                                ? AppColors.success
                                : AppColors.error,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('${i + 1}',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.textHint)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
