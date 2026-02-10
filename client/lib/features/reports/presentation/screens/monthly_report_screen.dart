// lib/features/reports/presentation/screens/monthly_report_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../core/constants/si_strings.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';
import '../widgets/chart_widget.dart';
import '../widgets/export_button.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<ReportsCubit>().loadMonthlyReport();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Refresh monthly report data when app comes to foreground
      context.read<ReportsCubit>().loadMonthlyReport();
    }
  }

  static const _months = [
    'ජනවාරි', // Jan
    'පෙබරවාරි', // Feb
    'මාර්තු', // Mar
    'අප්‍රේල්', // Apr
    'මැයි', // May
    'ජූනි', // Jun
    'ජූලි', // Jul
    'අගෝස්තු', // Aug
    'සැප්තැම්බර්', // Sep
    'ඔක්තෝබර්', // Oct
    'නොවැම්බර්', // Nov
    'දෙසැම්බර්' // Dec
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        return LoadingOverlay(
          isLoading: state.isLoading,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('මාසික වාර්තාව'), // Monthly Report
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMonthSelector(state),
                  const SizedBox(height: 16),
                  _buildSummary(state),
                  const SizedBox(height: 24),
                  ChartWidget(report: state.monthlyReport),
                ],
              ),
            ),
            bottomNavigationBar: ExportButton(
              onExportPdf: () {},
              onExportExcel: () {},
              onPrint: () {},
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthSelector(ReportsState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              var y = state.selectedYear;
              var m = state.selectedMonth - 1;
              if (m < 1) {
                m = 12;
                y--;
              }
              context.read<ReportsCubit>().changeMonth(y, m);
            },
          ),
          GestureDetector(
            onTap: () => _showMonthPicker(state),
            child: Text(
              '${_months[state.selectedMonth - 1]} ${state.selectedYear}',
              style: AppTextStyles.titleMedium
                  .copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final now = DateTime.now();
              var y = state.selectedYear;
              var m = state.selectedMonth + 1;
              if (m > 12) {
                m = 1;
                y++;
              }
              if (y < now.year || (y == now.year && m <= now.month)) {
                context.read<ReportsCubit>().changeMonth(y, m);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(ReportsState state) {
    final summary = state.monthlyReport?.summary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(SiStrings.buy, summary?.totalPurchases ?? 0),
              _buildStat(SiStrings.sell, summary?.totalSales ?? 0),
              _buildStat('ලාභය', summary?.grossProfit ?? 0),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCount('මිලදී ගැනීම්', summary?.purchaseCount ?? 0), // Buy Orders
              _buildCount('විකිණීම්', summary?.saleCount ?? 0), // Sell Orders
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, double value) {
    return Column(
      children: [
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.white.withOpacity(0.8))),
        Text('Rs. ${_format(value)}',
            style: AppTextStyles.titleSmall
                .copyWith(color: AppColors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCount(String label, int count) {
    return Column(
      children: [
        Text('$count',
            style: AppTextStyles.titleMedium
                .copyWith(color: AppColors.white, fontWeight: FontWeight.bold)),
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.white.withOpacity(0.8))),
      ],
    );
  }

  void _showMonthPicker(ReportsState state) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, childAspectRatio: 2), // Changed to 3 for longer Sinhala names
          itemCount: 12,
          itemBuilder: (ctx, i) {
            final isSelected = i + 1 == state.selectedMonth;
            return InkWell(
              onTap: () {
                context
                    .read<ReportsCubit>()
                    .changeMonth(state.selectedYear, i + 1);
                Navigator.pop(ctx);
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_months[i],
                    style:
                        TextStyle(color: isSelected ? AppColors.white : null, fontSize: 12)),
              ),
            );
          },
        ),
      ),
    );
  }

  String _format(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}K' : v.toStringAsFixed(0);
}

