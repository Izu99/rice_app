import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class WeeklyActivityChart extends StatelessWidget {
  final Map<int, Map<String, double>> data; // day index -> {'buy': val, 'sell': val}
  final bool isLoading;

  const WeeklyActivityChart({
    super.key,
    required this.data,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Activity',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Sales & Purchases',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _buildLegend(),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: isLoading
                ? _buildLoadingState()
                : _buildBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final maxValue = _getMaxValue();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: AppColors.textPrimary,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String type = rodIndex == 0 ? 'Purchase' : 'Sale';
              return BarTooltipItem(
                '$type\nRs.${rod.toY.toStringAsFixed(0)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final date = DateTime.now().subtract(
                  Duration(days: 6 - value.toInt()),
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    DateFormat('E').format(date),
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.divider.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (index) {
          final dayData = data[index] ?? {'buy': 0.0, 'sell': 0.0};
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: dayData['buy'] ?? 0,
                color: AppColors.error,
                width: 10,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxValue,
                  color: AppColors.divider.withOpacity(0.1),
                ),
              ),
              BarChartRodData(
                toY: dayData['sell'] ?? 0,
                color: AppColors.success,
                width: 10,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxValue,
                  color: AppColors.divider.withOpacity(0.1),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _buildLegendItem('Buy', AppColors.error),
        const SizedBox(width: 12),
        _buildLegendItem('Sell', AppColors.success),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  double _getMaxValue() {
    double max = 0;
    data.forEach((_, value) {
      if ((value['buy'] ?? 0) > max) max = value['buy']!;
      if ((value['sell'] ?? 0) > max) max = value['sell']!;
    });
    return max == 0 ? 100 : max * 1.2;
  }
}

