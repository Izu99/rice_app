import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';
import '../widgets/company_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadDashboard();
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
        },
        builder: (context, adminState) {
          return BlocListener<AuthCubit, AuthState>(
            listenWhen: (previous, current) =>
                previous.authStatus != current.authStatus,
            listener: (context, authState) {
              if (authState.authStatus == AuthStatus.unauthenticated) {
                context.go('/login');
              }
            },
            child: LoadingOverlay(
              isLoading: adminState.status == AdminStatus.loading,
              child: RefreshIndicator(
                onRefresh: () => context.read<AdminCubit>().loadDashboard(),
                color: AppColors.adminPrimary,
                child: ResponsiveUtils.constrainContent(
                  context,
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(
                      ResponsiveUtils.getResponsivePadding(
                        context,
                        mobile: AppDimensions.paddingM,
                        tablet: AppDimensions.paddingL,
                        desktop: AppDimensions.paddingXL,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Section
                        _buildWelcomeSection(context),
                        SizedBox(
                            height: ResponsiveUtils.getResponsiveSpacing(
                          context,
                          mobile: AppDimensions.paddingL,
                          tablet: AppDimensions.paddingXL,
                          desktop: 32.0,
                        )),

                        // Stats Grid
                        _buildStatsGrid(context, adminState),
                        SizedBox(
                            height: ResponsiveUtils.getResponsiveSpacing(
                          context,
                          mobile: AppDimensions.paddingL,
                          tablet: AppDimensions.paddingXL,
                          desktop: 32.0,
                        )),

                        // Quick Actions
                        _buildQuickActions(context),
                        SizedBox(
                            height: ResponsiveUtils.getResponsiveSpacing(
                          context,
                          mobile: AppDimensions.paddingL,
                          tablet: AppDimensions.paddingXL,
                          desktop: 32.0,
                        )),

                        // Recent Companies
                        _buildRecentCompanies(context, adminState),
                        const SizedBox(height: AppDimensions.paddingXL),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: ResponsiveUtils.isMobile(context)
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/admin/companies/add'),
              backgroundColor: AppColors.adminPrimary,
              icon: const Icon(Icons.add_business, color: Colors.white),
              label: const Text(
                'Add Company',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.admin_panel_settings,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Text('Super Admin'),
        ],
      ),
      backgroundColor: AppColors.adminPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // Show notifications
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'settings':
                context.push('/admin/settings');
                break;
              case 'logout':
                _showLogoutDialog();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 12),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        ResponsiveUtils.getResponsivePadding(
          context,
          mobile: AppDimensions.paddingL,
          tablet: AppDimensions.paddingXL,
          desktop: 32.0,
        ),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.adminPrimary,
            AppColors.adminPrimary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.adminPrimary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Admin!',
            style: ResponsiveUtils.scaleTextStyle(
              context,
              AppTextStyles.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              mobileFactor: 1.0,
              tabletFactor: 1.2,
              desktopFactor: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your rice mill companies from here',
            style: ResponsiveUtils.scaleTextStyle(
              context,
              AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Text(
            _getFormattedDate(),
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AdminState state) {
    final stats = state.dashboardStats;
    final crossAxisCount = ResponsiveUtils.getGridCrossAxisCount(
      context,
      mobile: 2,
      tablet: 4,
      desktop: 4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: ResponsiveUtils.scaleTextStyle(
            context,
            AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
            height: ResponsiveUtils.getResponsiveSpacing(
          context,
          mobile: AppDimensions.paddingM,
          tablet: AppDimensions.paddingL,
        )),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth -
                    (ResponsiveUtils.getResponsiveSpacing(context) *
                        (crossAxisCount - 1))) /
                crossAxisCount;
            // Increase card height to prevent overflow
            final cardHeight = ResponsiveUtils.isMobile(context)
                ? cardWidth * 0.95 // Taller on mobile
                : cardWidth * 0.85;

            return Wrap(
              spacing: ResponsiveUtils.getResponsiveSpacing(context),
              runSpacing: ResponsiveUtils.getResponsiveSpacing(context),
              children: [
                SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: _buildStatCard(
                    context,
                    title: 'Total Companies',
                    value: '${stats?.totalCompanies ?? state.totalCompanies}',
                    icon: Icons.business,
                    color: AppColors.adminPrimary,
                    onTap: () => context.push('/admin/companies'),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: _buildStatCard(
                    context,
                    title: 'Active',
                    value: '${stats?.activeCompanies ?? state.activeCompanies}',
                    icon: Icons.check_circle,
                    color: AppColors.success,
                    onTap: () {
                      context
                          .read<AdminCubit>()
                          .filterCompanies(CompanyFilter.active);
                      context.push('/admin/companies');
                    },
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: _buildStatCard(
                    context,
                    title: 'Inactive',
                    value:
                        '${stats?.inactiveCompanies ?? state.inactiveCompanies}',
                    icon: Icons.pause_circle,
                    color: AppColors.warning,
                    onTap: () {
                      context
                          .read<AdminCubit>()
                          .filterCompanies(CompanyFilter.inactive);
                      context.push('/admin/companies');
                    },
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: _buildStatCard(
                    context,
                    title: 'Pending',
                    value:
                        '${stats?.pendingCompanies ?? state.pendingCompanies}',
                    icon: Icons.pending,
                    color: Colors.orange,
                    onTap: () {
                      context
                          .read<AdminCubit>()
                          .filterCompanies(CompanyFilter.pending);
                      context.push('/admin/companies');
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: Container(
        padding: EdgeInsets.all(
          ResponsiveUtils.getResponsivePadding(
            context,
            mobile: 12.0,
            tablet: AppDimensions.paddingL,
          ),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon row - fixed height
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (onTap != null)
                  const Icon(Icons.arrow_forward_ios,
                      size: 12, color: AppColors.grey400),
              ],
            ),
            const SizedBox(height: 8),

            // Value and title - flexible space
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Value
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.isMobile(context) ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final crossAxisCount = ResponsiveUtils.getGridCrossAxisCount(
      context,
      mobile: 2,
      tablet: 4,
      desktop: 4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: ResponsiveUtils.scaleTextStyle(
            context,
            AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context),
          crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context),
          childAspectRatio: isDesktop ? 2.5 : 2.0,
          children: [
            _buildActionButton(
              context,
              icon: Icons.add_business,
              label: 'Add Company',
              color: AppColors.adminPrimary,
              onTap: () => context.push('/admin/companies/add'),
            ),
            _buildActionButton(
              context,
              icon: Icons.list_alt,
              label: 'All Companies',
              color: Colors.blue,
              onTap: () => context.push('/admin/companies'),
            ),
            _buildActionButton(
              context,
              icon: Icons.pending_actions,
              label: 'Pending',
              color: Colors.orange,
              onTap: () {
                context
                    .read<AdminCubit>()
                    .filterCompanies(CompanyFilter.pending);
                context.push('/admin/companies');
              },
            ),
            _buildActionButton(
              context,
              icon: Icons.analytics,
              label: 'Reports',
              color: Colors.purple,
              onTap: () => context.push('/admin/reports'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      elevation: 2,
      shadowColor: color.withOpacity(0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Padding(
          padding: EdgeInsets.all(
            ResponsiveUtils.getResponsivePadding(
              context,
              mobile: AppDimensions.paddingM,
              tablet: AppDimensions.paddingL,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: ResponsiveUtils.scaleTextStyle(
                    context,
                    AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    mobileFactor: 0.9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentCompanies(BuildContext context, AdminState state) {
    final recentCompanies = state.dashboardStats?.recentCompanies ??
        state.allCompanies.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Companies',
              style: ResponsiveUtils.scaleTextStyle(
                context,
                AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/admin/companies'),
              child: const Text(
                'View All',
                style: TextStyle(color: AppColors.adminPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingS),
        if (recentCompanies.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.paddingXL),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Column(
              children: [
                const Icon(Icons.business_outlined,
                    size: 48, color: AppColors.grey400),
                const SizedBox(height: AppDimensions.paddingM),
                Text(
                  'No companies yet',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ...recentCompanies.map((company) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
                child: CompanyCard(
                  company: company,
                  isCompact: true,
                  onTap: () {
                    context.read<AdminCubit>().selectCompany(company);
                    context.push('/admin/companies/${company.id}');
                  },
                ),
              )),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthCubit>().logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

