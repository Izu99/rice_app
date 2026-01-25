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
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
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
            isLoading: state.status == AdminStatus.loading ||
                state.status == AdminStatus.deleting,
            child: Column(
              children: [
                // Search & Filter Section
                _buildSearchAndFilter(state),

                // Stats Bar
                _buildStatsBar(state),

                // Companies List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        context.read<AdminCubit>().refreshCompanies(),
                    color: AppColors.adminPrimary,
                    child: state.filteredCompanies.isEmpty
                        ? _buildEmptyState(state)
                        : _buildCompaniesList(state),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/companies/add'),
        backgroundColor: AppColors.adminPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Companies'),
      backgroundColor: AppColors.adminPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: _showSortOptions,
          tooltip: 'Sort',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
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

  Widget _buildSearchAndFilter(AdminState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (value) =>
                context.read<AdminCubit>().searchCompanies(value),
            decoration: InputDecoration(
              hintText: 'Search by name, owner, email, phone...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<AdminCubit>().searchCompanies('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.grey100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
                vertical: AppDimensions.paddingS,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),

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
      ),
    );
  }

  Widget _buildFilterChip(CompanyFilter filter, CompanyFilter currentFilter) {
    final isSelected = filter == currentFilter;
    final color = _getFilterColor(filter);

    return FilterChip(
      label: Text(
        _getFilterLabel(filter),
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => context.read<AdminCubit>().filterCompanies(filter),
      backgroundColor: color.withOpacity(0.1),
      selectedColor: color,
      checkmarkColor: Colors.white,
      side: BorderSide(color: color.withOpacity(0.3)),
      avatar: isSelected
          ? null
          : Icon(_getFilterIcon(filter), size: 18, color: color),
    );
  }

  Widget _buildStatsBar(AdminState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      color: AppColors.grey100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${state.filteredCompanies.length} of ${state.allCompanies.length} companies',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (state.searchQuery.isNotEmpty ||
              state.currentFilter != CompanyFilter.all)
            TextButton(
              onPressed: () {
                _searchController.clear();
                context.read<AdminCubit>().searchCompanies('');
                context.read<AdminCubit>().filterCompanies(CompanyFilter.all);
              },
              child: const Text('Clear Filters'),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reset password for ${company.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text.isNotEmpty) {
                Navigator.pop(context);
                context.read<AdminCubit>().resetCompanyPassword(
                      company.id,
                      passwordController.text,
                    );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminPrimary),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort By', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppDimensions.paddingM),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Name (A-Z)'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Recently Added'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.circle),
              title: const Text('Status'),
              onTap: () => Navigator.pop(context),
            ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingL),

                // Company Header
                Row(
                  children: [
                    _buildCompanyAvatar(),
                    const SizedBox(width: AppDimensions.paddingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name,
                            style: AppTextStyles.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildStatusBadge(),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingL),

                // Details
                _buildDetailSection('Company Information', [
                  _buildDetailRow(
                      Icons.person, 'Owner', company.ownerName ?? 'N/A'),
                  _buildDetailRow(Icons.email, 'Email', company.email ?? 'N/A'),
                  _buildDetailRow(Icons.phone, 'Phone', company.phone),
                  _buildDetailRow(
                      Icons.location_on, 'Address', company.address),
                  if (company.registrationNumber != null)
                    _buildDetailRow(
                        Icons.numbers, 'Reg. No', company.registrationNumber!),
                ]),

                const SizedBox(height: AppDimensions.paddingM),

                _buildDetailSection('Account Information', [
                  _buildDetailRow(
                    Icons.calendar_today,
                    'Created',
                    _formatDate(company.createdAt),
                  ),
                  _buildDetailRow(
                    Icons.people,
                    'Users',
                    '${company.currentUsers}/${company.maxUsers}',
                  ),
                  _buildDetailRow(
                    Icons.verified,
                    'Email Verified',
                    company.isEmailVerified ? 'Yes' : 'No',
                  ),
                ]),

                const SizedBox(height: AppDimensions.paddingL),

                // Status Change Options
                Text(
                  'Change Status',
                  style: AppTextStyles.titleMedium
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppDimensions.paddingS),
                Wrap(
                  spacing: 8,
                  children: CompanyStatus.values
                      .where((s) => s != company.status)
                      .map((status) => ActionChip(
                            label: Text(status.displayName),
                            avatar: Icon(_getStatusIcon(status), size: 18),
                            onPressed: () => onStatusChange(status),
                          ))
                      .toList(),
                ),

                const SizedBox(height: AppDimensions.paddingL),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingS),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onResetPassword,
                        icon: const Icon(Icons.lock_reset),
                        label: const Text('Reset Password'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingS),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onDelete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    icon: const Icon(Icons.delete, color: Colors.white),
                    label: const Text('Delete Company',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingL),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompanyAvatar() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.adminPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.adminPrimary.withOpacity(0.3)),
      ),
      child: company.logoUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              child: Image.network(company.logoUrl!, fit: BoxFit.cover),
            )
          : Center(
              child: Text(
                company.name.substring(0, 1).toUpperCase(),
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.adminPrimary,
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

