// lib/features/reports/presentation/screens/reports_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/si_strings.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';
import '../widgets/report_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with WidgetsBindingObserver {
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
      // Refresh reports data when app comes to foreground
      context.read<ReportsCubit>().loadDashboardSummary();
      context.read<ReportsCubit>().loadDailyReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(SiStrings.reports),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          body: RefreshIndicator(
            onRefresh: () =>
                context.read<ReportsCubit>().loadDashboardSummary(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick stats
                  _buildQuickStats(state),
                  const SizedBox(height: 24),

                  // Report types
                  Text(SiStrings.reports,
                      style: AppTextStyles.titleMedium
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  ReportCard(
                    title: 'දෛනික වාර්තාව', // Daily Report
                    subtitle: 'Daily Report',
                    icon: Icons.today,
                    color: AppColors.primary,
                    onTap: () => context.push('/reports/daily'),
                  ),
                  const SizedBox(height: 12),

                  ReportCard(
                    title: 'මාසික වාර්තාව', // Monthly Report
                    subtitle: 'Monthly Report',
                    icon: Icons.calendar_month,
                    color: AppColors.success,
                    onTap: () => context.push('/reports/monthly'),
                  ),
                  const SizedBox(height: 12),

                  ReportCard(
                    title: 'තොග වාර්තාව', // Stock Report
                    subtitle: 'Stock Report',
                    icon: Icons.inventory,
                    color: AppColors.warning,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),

                  ReportCard(
                    title: 'පාරිභෝගික වාර්තාව', // Customer Report
                    subtitle: 'Customer Report',
                    icon: Icons.people,
                    color: AppColors.info,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
              _buildStatItem(SiStrings.sell, 'Rs. ${_format(today['totalSell'] ?? 0)}',
                  Icons.trending_up),
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
    return Column(
      children: [
        Icon(icon, color: AppColors.white.withOpacity(0.8), size: 20),
        const SizedBox(height: 4),
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.white.withOpacity(0.8))),
        Text(value,
            style: AppTextStyles.titleSmall
                .copyWith(color: AppColors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _format(dynamic value) {
    final v = (value as num?)?.toDouble() ?? 0;
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

