// lib/features/reports/presentation/screens/daily_report_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';
import '../widgets/export_button.dart';

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<ReportsCubit>().loadDailyReport();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Refresh daily report data when app comes to foreground
      context.read<ReportsCubit>().loadDailyReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        return LoadingOverlay(
          isLoading: state.isLoading,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Daily Report'),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context, state),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateHeader(state),
                  const SizedBox(height: 16),
                  _buildSummaryCards(state),
                  const SizedBox(height: 24),
                  _buildTransactionsList(state),
                ],
              ),
            ),
            bottomNavigationBar: ExportButton(
              onExportPdf: () => context.read<ReportsCubit>().exportToPdf(),
              onExportExcel: () {},
              onPrint: () {},
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateHeader(ReportsState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final prev = state.selectedDate.subtract(const Duration(days: 1));
              context.read<ReportsCubit>().changeDate(prev);
            },
          ),
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(state.selectedDate),
            style:
                AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final next = state.selectedDate.add(const Duration(days: 1));
              if (next.isBefore(DateTime.now().add(const Duration(days: 1)))) {
                context.read<ReportsCubit>().changeDate(next);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ReportsState state) {
    final summary = state.dailyReport?.summary;
    return Row(
      children: [
        Expanded(
            child: _buildSummaryCard('Purchases', summary?.totalPurchases ?? 0,
                AppColors.error, Icons.arrow_downward)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildSummaryCard('Sales', summary?.totalSales ?? 0,
                AppColors.success, Icons.arrow_upward)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildSummaryCard('Profit', summary?.grossProfit ?? 0,
                AppColors.primary, Icons.trending_up)),
      ],
    );
  }

  Widget _buildSummaryCard(
      String label, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          Text('Rs. ${_format(value)}',
              style: AppTextStyles.titleSmall
                  .copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(ReportsState state) {
    final items = state.dailyReport?.items ?? [];
    if (items.isEmpty) {
      return Center(
          child: Text('No transactions',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transactions',
            style: AppTextStyles.titleMedium
                .copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.label, style: AppTextStyles.bodyMedium),
                  Text('Rs. ${item.value.toStringAsFixed(0)}',
                      style: AppTextStyles.titleSmall
                          .copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            )),
      ],
    );
  }

  void _selectDate(BuildContext context, ReportsState state) async {
    final date = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null && context.mounted) {
      context.read<ReportsCubit>().changeDate(date);
    }
  }

  String _format(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}K' : v.toStringAsFixed(0);
}
