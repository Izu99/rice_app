import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../core/shared_widgets/h_app_bar.dart';
import '../../../../core/shared_widgets/confirmation_dialog.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';
import '../widgets/company_card.dart';
import '../../../../routes/route_names.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        _animationController.drive(CurveTween(curve: Curves.easeInOut));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
        context.read<AdminCubit>().loadDashboard();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
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
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: RefreshIndicator(
                  onRefresh: () => context.read<AdminCubit>().loadDashboard(),
                  color: AppColors.adminPrimary,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      _buildStickyHeader(context),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              // Welcome Banner
                              _buildWelcomeBanner(context, adminState),
                              const SizedBox(height: 24),

                              // Section: Stats Overview
                              _buildSectionChip('Stats Overview'),
                              const SizedBox(height: 14),
                              _buildTodayStrip(adminState),
                              const SizedBox(height: 24),

                              // Section: Quick Actions
                              _buildSectionChip('Quick Actions'),
                              const SizedBox(height: 14),
                              _buildIconGrid(context, _quickActions(context)),
                              const SizedBox(height: 24),

                              // Section: Recent Companies
                              _buildSectionHeader(
                                'Recent Companies',
                                onViewAll: () =>
                                    context.push('/admin/companies'),
                              ),
                              const SizedBox(height: 12),
                              _buildRecentCompaniesList(context, adminState),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: ResponsiveUtils.isMobile(context)
          ? FloatingActionButton(
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
            )
          : null,
    );
  }

  Widget _buildStickyHeader(BuildContext context) {
    return HSliverAppBar(
      pinned: true,
      showBack: false,
      onRefresh: () => context.read<AdminCubit>().loadDashboard(),
      title: 'Super Admin',
      subtitle: 'System management dashboard',
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
        ),
        BlocBuilder<AuthCubit, AuthState>(
          builder: (ctx, authState) {
            return GestureDetector(
              onTap: () => _showLogoutDialog(),
              child: Container(
                margin: const EdgeInsets.only(right: 8, top: 10, bottom: 10),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    authState.user?.initials ?? 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- Welcome Banner ---
  Widget _buildWelcomeBanner(BuildContext context, AdminState state) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (ctx, authState) {
        final stats = state.currentStats;
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.adminPrimary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.adminPrimary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${(authState.user?.name ?? 'Admin').split(' ').first}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'System Overview',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getFormattedDate(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${stats.totalCompanies}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Companies',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Section Chip ---
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

  // Section header with "View All"
  Widget _buildSectionHeader(String label, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionChip(label),
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

  // --- Today's Summary grid (replaced horizontal strip) ---
  Widget _buildTodayStrip(AdminState state) {
    final stats = state.currentStats;
    final items = [
      _StatItem('Total', '${stats.totalCompanies}', AppColors.adminPrimary,
          Icons.business_rounded),
      _StatItem('Active', '${stats.activeCompanies}', AppColors.success,
          Icons.check_circle_rounded),
      _StatItem('Inactive', '${stats.inactiveCompanies}', AppColors.warning,
          Icons.pause_circle_rounded),
      _StatItem('Pending', '${stats.pendingCompanies}', Colors.orange,
          Icons.pending_rounded),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(context, items[0])),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, items[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard(context, items[2])),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(context, items[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, _StatItem item) {
    return GestureDetector(
      onTap: () {
        if (item.label == 'Active') {
          context.read<AdminCubit>().filterCompanies(CompanyFilter.active);
        } else if (item.label == 'Inactive') {
          context.read<AdminCubit>().filterCompanies(CompanyFilter.inactive);
        } else if (item.label == 'Pending') {
          context.read<AdminCubit>().filterCompanies(CompanyFilter.pending);
        } else {
          context.read<AdminCubit>().filterCompanies(CompanyFilter.all);
        }
        context.push('/admin/companies');
      },
      child: Container(
        height: 70, // Fixed height for consistency
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(item.icon, color: item.color, size: 16),
                const SizedBox(width: 6),
                Text(
                  item.label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                item.value,
                style: TextStyle(
                  color: item.color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Icon Grid ---
  Widget _buildIconGrid(BuildContext context, List<_GridItem> items) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 6,
      mainAxisSpacing: 8,
      childAspectRatio: 0.63,
      children: items.map((item) => _buildGridItem(item)).toList(),
    );
  }

  Widget _buildGridItem(_GridItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: item.color.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(item.icon, color: item.color, size: 24),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C3E),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  List<_GridItem> _quickActions(BuildContext context) => [
        _GridItem(
          icon: Icons.add_business_rounded,
          label: 'Add\nCompany',
          color: AppColors.adminPrimary,
          onTap: () => context.push('/admin/companies/add'),
        ),
        _GridItem(
          icon: Icons.business_rounded,
          label: 'All\nCompanies',
          color: Colors.blue,
          onTap: () => context.push('/admin/companies'),
        ),
        _GridItem(
          icon: Icons.pending_actions_rounded,
          label: 'Pending\nAppr.',
          color: Colors.orange,
          onTap: () {
            context.read<AdminCubit>().filterCompanies(CompanyFilter.pending);
            context.push('/admin/companies');
          },
        ),
        _GridItem(
          icon: Icons.analytics_rounded,
          label: 'Reports',
          color: Colors.purple,
          onTap: () => context.push(RouteNames.adminReports),
        ),
        _GridItem(
          icon: Icons.price_change_rounded,
          label: 'Global\nPrices',
          color: Colors.teal,
          onTap: () => context.push('/admin/prices'),
        ),
        _GridItem(
          icon: Icons.settings_rounded,
          label: 'Settings',
          color: Colors.grey,
          onTap: () => context.push(RouteNames.adminSettings),
        ),
      ];

  Widget _buildRecentCompaniesList(BuildContext context, AdminState state) {
    final recentCompanies = state.dashboardStats?.recentCompanies ??
        state.allCompanies.take(5).toList();

    if (recentCompanies.isEmpty) {
      return Container(
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
      );
    }

    return Column(
      children: recentCompanies
          .map((company) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
                child: CompanyCard(
                  company: company,
                  isCompact: true,
                  onTap: () {
                    context.read<AdminCubit>().selectCompany(company);
                    context.push('/admin/companies/${company.id}');
                  },
                ),
              ))
          .toList(),
    );
  }

  void _showLogoutDialog() {
    ConfirmationDialog.show(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
      confirmColor: AppColors.error,
      icon: Icons.logout_rounded,
    ).then((confirmed) {
      if (confirmed && mounted) {
        context.read<AuthCubit>().logout();
      }
    });
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

// --- Helper models ---
class _GridItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _GridItem(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
}

class _StatItem {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatItem(this.label, this.value, this.color, this.icon);
}
