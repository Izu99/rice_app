// lib/features/super_admin/presentation/screens/admin_reports_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadDashboard(); // Refresh stats for reports
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: BlocBuilder<AdminCubit, AdminState>(
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: state.status == AdminStatus.loading,
            child: CustomScrollView(
              slivers: [
                _buildStickyHeader(context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildSectionChip('System Insights'),
                        const SizedBox(height: 16),
                        _buildMainStats(state),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Price Reports'),
                        const SizedBox(height: 12),
                        _buildReportCard(
                          title: 'Global Price Trends',
                          subtitle: 'View average paddy and rice prices across all districts',
                          icon: Icons.trending_up_rounded,
                          color: Colors.teal,
                          onTap: () {
                            // Link to global prices for now, or a more detailed trend page if available
                            context.push('/admin/prices');
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildReportCard(
                          title: 'District-wise Price Analysis',
                          subtitle: 'Compare price differences between different regions',
                          icon: Icons.map_rounded,
                          color: Colors.blue,
                          onTap: () {
                            context.push('/prices');
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Company Reports'),
                        const SizedBox(height: 12),
                        _buildReportCard(
                          title: 'Company Growth Report',
                          subtitle: 'New registrations and active company metrics',
                          icon: Icons.business_center_rounded,
                          color: Colors.indigo,
                          onTap: () {
                            context.push('/admin/companies');
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildReportCard(
                          title: 'Activity Summary',
                          subtitle: 'Overview of system usage and company engagement',
                          icon: Icons.assessment_rounded,
                          color: Colors.orange,
                          onTap: () {
                            // Placeholder for activity summary
                          },
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStickyHeader(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black12,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Admin Reports',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF1C1C2E)),
          onPressed: () => context.read<AdminCubit>().loadDashboard(),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildSectionChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E8EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF444466),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Row(
      children: [
        _buildSectionChip(label),
      ],
    );
  }

  Widget _buildMainStats(AdminState state) {
    final stats = state.dashboardStats;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.adminPrimary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.adminPrimary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Companies', '${stats?.totalCompanies ?? 0}'),
          _buildSummaryDivider(),
          _buildSummaryItem('Active', '${stats?.activeCompanies ?? 0}'),
          _buildSummaryDivider(),
          _buildSummaryItem('Pending', '${stats?.pendingCompanies ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1C1C2E),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0B0C0)),
          ],
        ),
      ),
    );
  }
}
