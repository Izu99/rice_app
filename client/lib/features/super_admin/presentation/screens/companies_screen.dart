import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/shared_widgets/empty_state_widget.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../core/shared_widgets/confirmation_dialog.dart';
import '../../../../data/models/company_model.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';
import '../widgets/company_card.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _StatGridItem {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  _StatGridItem(this.label, this.value, this.color, this.icon);
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadCompanies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: BlocConsumer<AdminCubit, AdminState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
            context.read<AdminCubit>().clearError();
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.success,
              ),
            );
            context.read<AdminCubit>().clearMessages();
          }
        },
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: state.status == AdminStatus.loading,
            child: RefreshIndicator(
              onRefresh: () => context.read<AdminCubit>().refreshCompanies(),
              color: AppColors.adminPrimary,
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
                          _buildSearchAndFilter(state),
                          const SizedBox(height: 24),
                          _buildSectionChip('Company Statistics'),
                          const SizedBox(height: 14),
                          _buildStatsGrid(state),
                          const SizedBox(height: 24),
                          _buildSectionHeader(
                            'Company List',
                            subtitle:
                                '${state.filteredCompanies.length} showing',
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  if (state.filteredCompanies.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(state),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final company = state.filteredCompanies[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CompanyCard(
                                company: company,
                                onTap: () => _showCompanyDetails(company),
                                onStatusChange: (status) =>
                                    _updateCompanyStatus(company, status),
                                onEdit: () => _editCompany(company),
                                onDelete: () => _deleteCompany(company),
                              ),
                            );
                          },
                          childCount: state.filteredCompanies.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/companies/add'),
        backgroundColor: AppColors.adminPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
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
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1C2E)),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Companies',
        style: TextStyle(
          color: Color(0xFF1C1C2E),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.sort, color: Color(0xFF1C1C2E)),
          onPressed: _showSortOptions,
          tooltip: 'Sort',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF1C1C2E)),
          onSelected: (value) {
            switch (value) {
              case 'export':
                _exportCompanies();
                break;
              case 'refresh':
                context.read<AdminCubit>().refreshCompanies();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, size: 20),
                  SizedBox(width: 12),
                  Text('Export List'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 12),
                  Text('Refresh'),
                ],
              ),
            ),
          ],
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

  Widget _buildSectionHeader(String label,
      {String? subtitle, VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionChip(label),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: const Text(
              'View All →',
              style: TextStyle(
                color: AppColors.adminPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchAndFilter(AdminState state) {
    return Column(
      children: [
        // Search Field
        Container(
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
          child: TextField(
            controller: _searchController,
            onChanged: (value) =>
                context.read<AdminCubit>().searchCompanies(value),
            decoration: InputDecoration(
              hintText: 'Search by name, owner, email...',
              hintStyle:
                  TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF444466)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<AdminCubit>().searchCompanies('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: CompanyFilter.values.map((filter) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(filter, state.currentFilter),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(CompanyFilter filter, CompanyFilter currentFilter) {
    final isSelected = filter == currentFilter;
    final color = _getFilterColor(filter);

    return GestureDetector(
      onTap: () => context.read<AdminCubit>().filterCompanies(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE8E8EE),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getFilterIcon(filter),
              size: 16,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              _getFilterLabel(filter),
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF444466),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AdminState state) {
    final stats = state.currentStats;
    final items = [
      _StatGridItem('Total', '${stats.totalCompanies}', AppColors.adminPrimary,
          Icons.business_rounded),
      _StatGridItem('Active', '${stats.activeCompanies}', AppColors.success,
          Icons.check_circle_rounded),
      _StatGridItem('Inactive', '${stats.inactiveCompanies}', AppColors.warning,
          Icons.pause_circle_rounded),
      _StatGridItem('Pending', '${stats.pendingCompanies}', Colors.orange,
          Icons.pending_rounded),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(items[0])),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(items[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard(items[2])),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(items[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(_StatGridItem item) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.value,
                style: const TextStyle(
                  color: Color(0xFF1C1C2E),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              Text(
                item.label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AdminState state) {
    if (state.searchQuery.isNotEmpty ||
        state.currentFilter != CompanyFilter.all) {
      return EmptyStateWidget(
        icon: Icons.search_off,
        title: 'No Companies Found',
        subtitle: 'Try adjusting your search or filter criteria',
        actionLabel: 'Clear Filters',
        onAction: () {
          _searchController.clear();
          context.read<AdminCubit>().searchCompanies('');
          context.read<AdminCubit>().filterCompanies(CompanyFilter.all);
        },
      );
    }

    return EmptyStateWidget(
      icon: Icons.business_outlined,
      title: 'No Companies Yet',
      subtitle: 'Add your first rice mill company to get started',
      actionLabel: 'Add Company',
      onAction: () => context.push('/admin/companies/add'),
    );
  }

  Widget _buildCompaniesList(AdminState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      itemCount: state.filteredCompanies.length,
      itemBuilder: (context, index) {
        final company = state.filteredCompanies[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
          child: CompanyCard(
            company: company,
            onTap: () => _showCompanyDetails(company),
            onStatusChange: (status) => _updateCompanyStatus(company, status),
            onEdit: () => _editCompany(company),
            onDelete: () => _deleteCompany(company),
          ),
        );
      },
    );
  }

  void _showCompanyDetails(CompanyModel company) {
    context.read<AdminCubit>().selectCompany(company);
    _showCompanyBottomSheet(company);
  }

  void _showCompanyBottomSheet(CompanyModel company) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CompanyDetailsSheet(
        company: company,
        onEdit: () {
          Navigator.pop(context);
          _editCompany(company);
        },
        onStatusChange: (status) {
          Navigator.pop(context);
          _updateCompanyStatus(company, status);
        },
        onResetPassword: () {
          Navigator.pop(context);
          _showResetPasswordDialog(company);
        },
        onDelete: () {
          Navigator.pop(context);
          _deleteCompany(company);
        },
      ),
    );
  }

  void _editCompany(CompanyModel company) {
    context.read<AdminCubit>().selectCompany(company);
    context.push('/admin/companies/edit/${company.id}');
  }

  void _updateCompanyStatus(CompanyModel company, CompanyStatus newStatus) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Update Status',
        message: 'Change company status to "${newStatus.displayName}"?',
        confirmLabel: 'Update',
        confirmColor: _getStatusColor(newStatus),
        onConfirm: () {
          Navigator.pop(context);
          context.read<AdminCubit>().updateCompanyStatus(company.id, newStatus);
        },
      ),
    );
  }

  void _deleteCompany(CompanyModel company) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Company',
        message:
            'Are you sure you want to delete "${company.name}"? This action cannot be undone.',
        confirmLabel: 'Delete',
        confirmColor: AppColors.error,
        onConfirm: () {
          Navigator.pop(context);
          context.read<AdminCubit>().deleteCompany(company.id);
        },
      ),
    );
  }

  void _showResetPasswordDialog(CompanyModel company) {
    final passwordController = TextEditingController();

    ConfirmationDialog.show(
      context,
      title: 'Reset Password',
      message: 'Set a new password for ${company.name}',
      confirmLabel: 'Reset',
      confirmColor: AppColors.adminPrimary,
      icon: Icons.lock_reset_rounded,
      customContent: TextField(
        controller: passwordController,
        obscureText: true,
        decoration: InputDecoration(
          labelText: 'New Password',
          prefixIcon: const Icon(Icons.lock_outline),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ).then((confirmed) {
      if (confirmed && mounted && passwordController.text.isNotEmpty) {
        context.read<AdminCubit>().resetCompanyPassword(
              company.id,
              passwordController.text,
            );
      }
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8EE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sort By',
              style: TextStyle(
                color: Color(0xFF1C1C2E),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSortTile(Icons.sort_by_alpha, 'Name (A-Z)',
                () => Navigator.pop(context)),
            _buildSortTile(Icons.access_time, 'Recently Added',
                () => Navigator.pop(context)),
            _buildSortTile(
                Icons.circle_outlined, 'Status', () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSortTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8EE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF444466)),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1C1C2E),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Color(0xFFB0B0C0), size: 20),
          ],
        ),
      ),
    );
  }

  void _exportCompanies() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting companies list...')),
    );
  }

  Color _getFilterColor(CompanyFilter filter) {
    switch (filter) {
      case CompanyFilter.all:
        return AppColors.adminPrimary;
      case CompanyFilter.active:
        return AppColors.success;
      case CompanyFilter.inactive:
        return AppColors.warning;
      case CompanyFilter.pending:
        return Colors.orange;
    }
  }

  String _getFilterLabel(CompanyFilter filter) {
    switch (filter) {
      case CompanyFilter.all:
        return 'All';
      case CompanyFilter.active:
        return 'Active';
      case CompanyFilter.inactive:
        return 'Inactive';
      case CompanyFilter.pending:
        return 'Pending';
    }
  }

  IconData _getFilterIcon(CompanyFilter filter) {
    switch (filter) {
      case CompanyFilter.all:
        return Icons.list;
      case CompanyFilter.active:
        return Icons.check_circle;
      case CompanyFilter.inactive:
        return Icons.pause_circle;
      case CompanyFilter.pending:
        return Icons.pending;
    }
  }

  Color _getStatusColor(CompanyStatus status) {
    switch (status) {
      case CompanyStatus.active:
        return AppColors.success;
      case CompanyStatus.inactive:
        return AppColors.warning;
      case CompanyStatus.pending:
        return Colors.orange;
      case CompanyStatus.suspended:
        return AppColors.error;
    }
  }
}

/// Company Details Bottom Sheet
class _CompanyDetailsSheet extends StatelessWidget {
  final CompanyModel company;
  final VoidCallback onEdit;
  final Function(CompanyStatus) onStatusChange;
  final VoidCallback onResetPassword;
  final VoidCallback onDelete;

  const _CompanyDetailsSheet({
    required this.company,
    required this.onEdit,
    required this.onStatusChange,
    required this.onResetPassword,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8EE),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Company Header
                Row(
                  children: [
                    _buildCompanyAvatar(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name,
                            style: const TextStyle(
                              color: Color(0xFF1C1C2E),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildStatusBadge(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Details
                _buildDetailSection('Company Information', [
                  _buildDetailRow(Icons.person_outline_rounded, 'Owner',
                      company.ownerName ?? 'N/A'),
                  _buildDetailRow(
                      Icons.email_outlined, 'Email', company.email ?? 'N/A'),
                  _buildDetailRow(Icons.phone_outlined, 'Phone', company.phone),
                  _buildDetailRow(
                      Icons.location_on_outlined, 'Address', company.address),
                  if (company.registrationNumber != null)
                    _buildDetailRow(Icons.numbers_rounded, 'Reg. No',
                        company.registrationNumber!),
                ]),

                const SizedBox(height: 20),

                _buildDetailSection('Account Information', [
                  _buildDetailRow(
                    Icons.calendar_today_rounded,
                    'Created',
                    _formatDate(company.createdAt),
                  ),
                  _buildDetailRow(
                    Icons.people_outline_rounded,
                    'Users',
                    '${company.currentUsers}/${company.maxUsers}',
                  ),
                  _buildDetailRow(
                    Icons.verified_outlined,
                    'Email Verified',
                    company.isEmailVerified ? 'Yes' : 'No',
                  ),
                ]),

                const SizedBox(height: 28),

                // Status Change Options
                const Text(
                  'Change Status',
                  style: TextStyle(
                    color: Color(0xFF1C1C2E),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: CompanyStatus.values
                      .where((s) => s != company.status)
                      .map((status) => InkWell(
                            onTap: () => onStatusChange(status),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status)
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColor(status)
                                      .withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getStatusIcon(status),
                                      size: 16, color: _getStatusColor(status)),
                                  const SizedBox(width: 8),
                                  Text(
                                    status.displayName,
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF444466),
                          side: const BorderSide(color: Color(0xFFE8E8EE)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onResetPassword,
                        icon: const Icon(Icons.lock_reset_rounded, size: 18),
                        label: const Text('Password'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF444466),
                          side: const BorderSide(color: Color(0xFFE8E8EE)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onDelete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error.withValues(alpha: 0.08),
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete Company',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompanyAvatar() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8EE)),
      ),
      child: company.logoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(company.logoUrl!, fit: BoxFit.cover),
            )
          : Center(
              child: Text(
                company.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF1C1C2E),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  Widget _buildStatusBadge() {
    final color = _getStatusColor(company.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(company.status), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            company.status.displayName,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppDimensions.paddingS),
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(CompanyStatus status) {
    switch (status) {
      case CompanyStatus.active:
        return AppColors.success;
      case CompanyStatus.inactive:
        return AppColors.warning;
      case CompanyStatus.pending:
        return Colors.orange;
      case CompanyStatus.suspended:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(CompanyStatus status) {
    switch (status) {
      case CompanyStatus.active:
        return Icons.check_circle;
      case CompanyStatus.inactive:
        return Icons.pause_circle;
      case CompanyStatus.pending:
        return Icons.pending;
      case CompanyStatus.suspended:
        return Icons.block;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
