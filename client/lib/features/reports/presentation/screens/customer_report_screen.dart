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

class CustomerReportScreen extends StatefulWidget {
  const CustomerReportScreen({super.key});

  @override
  State<CustomerReportScreen> createState() => _CustomerReportScreenState();
}

class _CustomerReportScreenState extends State<CustomerReportScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ReportsCubit>().loadCustomerReport();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        return LoadingOverlay(
          isLoading: state.status == ReportsStatus.loading,
          child: AppPageScaffold(
            title: SiStrings.customerReport,
            subtitle:
                SiStrings.isSinhala ? 'Customer Report' : 'පාරිභෝගික වාර්තාව',
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () =>
                    context.read<ReportsCubit>().loadCustomerReport(),
              ),
            ],
            bottomBar: AppSubBottomBar(),
            body: state.customerReport == null
                ? _buildEmptyState()
                : _buildReportContent(state.customerReport!),
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
          Icon(Icons.people_outline, size: 64, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            'පාරිභෝගික දත්ත පූරණය වෙමින් පවතී...',
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(Map<String, dynamic> report) {
    final List<dynamic> customers = report['customers'] ?? [];
    final double totalReceivables =
        (report['totalReceivable'] as num?)?.toDouble() ?? 0.0;
    final double totalPayables =
        (report['totalPayable'] as num?)?.toDouble() ?? 0.0;
    final int customerCount = (report['customerCount'] as num?)?.toInt() ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(totalReceivables, totalPayables, customerCount),
          const SizedBox(height: 24),
          Text(
            'පාරිභෝගික ශේෂ සාරාංශය', // Customer Balance Summary
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildCustomerTable(customers),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(double receivable, double payable, int count) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                SiStrings.totalReceivable,
                'Rs. ${receivable.toStringAsFixed(2)}',
                Icons.arrow_downward,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                SiStrings.totalPayable,
                'Rs. ${payable.toStringAsFixed(2)}',
                Icons.arrow_upward,
                AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.people, color: AppColors.primary, size: 28),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'මුළු පාරිභෝගිකයින් සංඛ්‍යාව', // KEEP for now or move
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$count',
                    style: AppTextStyles.titleLarge
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
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
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
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
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerTable(List<dynamic> customers) {
    if (customers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: Text('පාරිභෝගිකයින් නොමැත')),
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
          ...customers.map((c) => _buildTableRow(c)).toList(),
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
          Expanded(flex: 3, child: Text(SiStrings.name, style: _headerStyle())),
          Expanded(
              flex: 3,
              child: Text(SiStrings.balance,
                  textAlign: TextAlign.right, style: _headerStyle())),
        ],
      ),
    );
  }

  TextStyle _headerStyle() => AppTextStyles.bodySmall
      .copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary);

  Widget _buildTableRow(Map<String, dynamic> customer) {
    final String name = customer['name'] as String? ?? '';
    final double balance = (customer['balance'] as num?)?.toDouble() ?? 0.0;
    final bool isReceivable = balance >= 0;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  isReceivable ? 'ලැබිය යුතු' : 'ගෙවිය යුතු',
                  style: TextStyle(
                    fontSize: 12,
                    color: isReceivable ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Rs. ${balance.abs().toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: isReceivable ? AppColors.success : AppColors.error,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
