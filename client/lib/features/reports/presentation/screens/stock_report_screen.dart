import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../core/shared_widgets/h_app_bar.dart';
import '../../../../core/shared_widgets/app_page_scaffold.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';

class StockReportScreen extends StatefulWidget {
  const StockReportScreen({super.key});

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ReportsCubit>().loadStockReport();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        return LoadingOverlay(
          isLoading: state.status == ReportsStatus.loading,
          child: AppPageScaffold(
            title: SiStrings.stockReport,
            subtitle: SiStrings.isSinhala ? 'Stock Report' : 'තොග වාර්තාව',
            onRefresh: () => context.read<ReportsCubit>().loadStockReport(),
            body: state.stockReport == null
                ? _buildEmptyState()
                : _buildReportContent(state.stockReport!),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            'තොග දත්ත පූරණය වෙමින් පවතී...',
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(Map<String, dynamic> report) {
    // Assuming report structure based on common patterns
    final List<dynamic> items = report['items'] ?? [];
    final double totalValue = (report['totalValue'] as num?)?.toDouble() ?? 0.0;
    final int lowStockCount = (report['lowStockCount'] as num?)?.toInt() ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(totalValue, lowStockCount),
          const SizedBox(height: 24),
          Text(
            'දැනට පවතින තොග විස්තරය', // Current Stock Details
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildStockTable(items),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(double totalValue, int lowStockCount) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            SiStrings.inventoryValue,
            'Rs. ${totalValue.toStringAsFixed(2)}',
            Icons.account_balance_wallet,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            SiStrings.lowStockAlerts,
            '$lowStockCount',
            Icons.warning_amber_rounded,
            AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockTable(List<dynamic> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: Text('තොග අයිතම නොමැත')),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          const Divider(height: 1),
          ...items.map((item) => _buildTableRow(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 3, child: Text(SiStrings.variety, style: _headerStyle())),
          Expanded(
              flex: 2,
              child: Text(SiStrings.bags,
                  textAlign: TextAlign.center, style: _headerStyle())),
          Expanded(
              flex: 3,
              child: Text(SiStrings.weight,
                  textAlign: TextAlign.right, style: _headerStyle())),
        ],
      ),
    );
  }

  TextStyle _headerStyle() => AppTextStyles.bodySmall
      .copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary);

  Widget _buildTableRow(Map<String, dynamic> item) {
    final String variety = (item['variety'] as String? ?? '')
        .replaceAll('Rice - ', '')
        .replaceAll('Paddy - ', '');
    final int bags = (item['bags'] as num?)?.toInt() ?? 0;
    final double weight = (item['weight'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: AppColors.grey200, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              variety,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$bags',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${weight.toStringAsFixed(2)} kg',
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
