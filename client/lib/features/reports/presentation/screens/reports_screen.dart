// lib/features/reports/presentation/screens/reports_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../core/shared_widgets/h_app_bar.dart';
import '../../../../domain/repositories/transaction_repository.dart';
import '../../../../injection_container.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';
import '../widgets/report_card.dart';
import '../widgets/export_button.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with WidgetsBindingObserver {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoadingRange = false;
  double _rangeTotal = 0;
  int _rangeTransactions = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<ReportsCubit>().loadDashboardSummary();
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
      context.read<ReportsCubit>().loadDashboardSummary();
      context.read<ReportsCubit>().loadDailyReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    context.select((ProfileCubit c) => c.state.language);
    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        return LoadingOverlay(
          isLoading: _isLoadingRange,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: HAppBar(
              title: SiStrings.reports,
              subtitle: SiStrings.isSinhala ? 'Reports' : 'වාර්තා',
              showBack: false,
            ),
            body: RefreshIndicator(
              onRefresh: () =>
                  context.read<ReportsCubit>().loadDashboardSummary(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateRangeSelector(),
                    const SizedBox(height: 20),
                    if (_startDate != null && _endDate != null)
                      _buildRangeData(),
                    const SizedBox(height: 20),
                    _buildQuickStats(state),
                    const SizedBox(height: 24),
                    Text(SiStrings.reports,
                        style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w600, fontSize: 18)),
                    const SizedBox(height: 12),
                    ReportCard(
                      title: SiStrings.dailyReportTitle,
                      icon: Icons.assessment,
                      color: AppColors.primary,
                      onTap: () => context.push('/reports/daily'),
                    ),
                    const SizedBox(height: 12),
                    ReportCard(
                      title: SiStrings.stockReport,
                      icon: Icons.inventory,
                      color: AppColors.warning,
                      onTap: () => context.push('/reports/stock'),
                    ),
                    const SizedBox(height: 12),
                    ReportCard(
                      title: SiStrings.customerReport,
                      icon: Icons.people,
                      color: AppColors.info,
                      onTap: () => context.push('/reports/customer'),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: _startDate != null && _endDate != null
                ? ExportButton(
                    onExportPdf: _exportPdf,
                    onExportExcel: _exportExcel,
                    onPrint: _printReport,
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'වාර්තා කාල පරිමාණය',
            style:
                AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'ආරම්භ දිනය',
                  date: _startDate,
                  onTap: _selectStartDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  label: 'අවසාන දිනය',
                  date: _endDate,
                  onTap: _selectEndDate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall,
            ),
            const SizedBox(height: 6),
            Text(
              date != null
                  ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                  : 'තෝරන්න',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeData() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'කාල පරිමාණ සාරාංශය',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRangeStat('මුළු ගණන', '$_rangeTransactions'),
              _buildRangeStat('මුළු මුදල',
                  'Rs. ${NumberFormatter.formatInteger(_rangeTotal.toDouble())}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRangeStat(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.white.withOpacity(0.8))),
        Text(value,
            style: AppTextStyles.titleSmall
                .copyWith(color: AppColors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
      if (_endDate != null) {
        await _loadRangeData();
      }
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      await _loadRangeData();
    }
  }

  Future<void> _loadRangeData() async {
    if (_startDate == null || _endDate == null) return;

    setState(() => _isLoadingRange = true);

    try {
      final txnRepo = sl<TransactionRepository>();
      final result = await txnRepo.getAllTransactions();

      result.fold(
        (failure) {
          setState(() => _isLoadingRange = false);
        },
        (transactions) {
          final filtered = transactions.where((txn) {
            final txnDate = txn.transactionDate;
            return txnDate.isAfter(_startDate!) &&
                txnDate.isBefore(_endDate!.add(const Duration(days: 1)));
          }).toList();

          double total = 0;
          for (var txn in filtered) {
            total += txn.totalAmount;
          }

          setState(() {
            _rangeTransactions = filtered.length;
            _rangeTotal = total;
            _isLoadingRange = false;
          });
        },
      );
    } catch (e) {
      setState(() => _isLoadingRange = false);
    }
  }

  void _printReport() {
    if (_startDate == null || _endDate == null) return;

    final startStr =
        '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}';
    final endStr =
        '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('වාර්තා මුද්‍රණය: $startStr සිට $endStr දක්වා'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _exportPdf() {
    if (_startDate == null || _endDate == null) return;

    final startStr =
        '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}';
    final endStr =
        '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF බාගත කරමින්: $startStr සිට $endStr දක්වා'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _exportExcel() {
    if (_startDate == null || _endDate == null) return;

    final startStr =
        '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}';
    final endStr =
        '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Excel බාගත කරමින්: $startStr සිට $endStr දක්වා'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildQuickStats(ReportsState state) {
    final summary = state.dashboardSummary;
    final today = summary?['today'] ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(SiStrings.todaySummary,
              style:
                  AppTextStyles.titleMedium.copyWith(color: AppColors.white)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(SiStrings.sell,
                  'Rs. ${_format(today['totalSell'] ?? 0)}', Icons.trending_up),
              _buildStatItem(
                  SiStrings.buy,
                  'Rs. ${_format(today['totalBuy'] ?? 0)}',
                  Icons.trending_down),
              _buildStatItem('ලාභය', 'Rs. ${_format(today['profit'] ?? 0)}',
                  Icons.account_balance_wallet),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.white, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.white.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _format(dynamic value) {
    final v = (value as num?)?.toDouble() ?? 0;
    return NumberFormatter.formatInteger(v);
  }
}
