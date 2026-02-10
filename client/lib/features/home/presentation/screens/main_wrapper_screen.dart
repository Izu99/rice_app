// lib/features/home/presentation/screens/main_wrapper_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../routes/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../profile/presentation/cubit/profile_state.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';

/// Main wrapper with bottom navigation
class MainWrapperScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainWrapperScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data when wrapper is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardCubit>().loadDashboard();
    });
  }

  void _onDestinationSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );

    // Automatically refresh dashboard when navigating back to home
    if (index == 0) {
      context.read<DashboardCubit>().loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.authStatus != current.authStatus,
      listener: (context, state) {
        if (state.authStatus == AuthStatus.unauthenticated) {
          context.go('/login');
        }
      },
      child: BlocBuilder<ProfileCubit, ProfileState>(
        buildWhen: (previous, current) => previous.language != current.language,
        builder: (context, profileState) {
          return BlocBuilder<AuthCubit, AuthState>(
            buildWhen: (previous, current) => previous.user != current.user,
            builder: (context, authState) {
              final isAdmin = authState.user?.isAdmin ?? false;

              return Scaffold(
                body: widget.navigationShell,
                bottomNavigationBar:
                    !isAdmin ? _buildBottomNavigationBar(isAdmin) : null,
                floatingActionButton: isAdmin ? null : _buildSyncFab(),
                floatingActionButtonLocation:
                    isAdmin ? null : FloatingActionButtonLocation.centerDocked,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigationBar(bool isAdmin) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      buildWhen: (previous, current) =>
          previous.isSynced != current.isSynced ||
          previous.pendingSyncCount != current.pendingSyncCount,
      builder: (context, dashboardState) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: LucideIcons.house,
                        activeIcon: LucideIcons.house,
                        label: 'මුල් පිටුව', // Home
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: LucideIcons.package,
                        activeIcon: LucideIcons.package,
                        label: SiStrings.stock,
                      ),
                      if (!isAdmin) const SizedBox(width: 48), // Space for FAB
                      _buildNavItem(
                        index: 2,
                        icon: LucideIcons.activity,
                        activeIcon: LucideIcons.activity,
                        label: SiStrings.reports,
                      ),
                      _buildNavItem(
                        index: 3,
                        icon: LucideIcons.receipt,
                        activeIcon: LucideIcons.receipt,
                        label: SiStrings.expenses,
                      ),
                      _buildNavItem(
                        index: 4,
                        icon: LucideIcons.user,
                        activeIcon: LucideIcons.user,
                        label: SiStrings.profile,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    String? badge,
  }) {
    final isSelected = widget.navigationShell.currentIndex == index;

    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: () => _onDestinationSelected(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
              if (badge != null)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.white,
                        fontSize: 8,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncFab() {
    return BlocBuilder<DashboardCubit, DashboardState>(
      buildWhen: (previous, current) =>
          previous.isSynced != current.isSynced ||
          previous.status != current.status,
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12), // Align with floating bar
          child: FloatingActionButton(
            mini: true,
            onPressed: state.isRefreshing
                ? null
                : () {
                    _showQuickActionsSheet(context);
                  },
            backgroundColor: AppColors.primary,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: state.isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : const Icon(
                    LucideIcons.plus,
                    color: AppColors.white,
                    size: 22,
                  ),
          ),
        );
      },
    );
  }

  void _showQuickActionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allow sheet to expand if needed
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                SiStrings.quickActions,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.shopping_cart,
                      label: SiStrings.buy,
                      sublabel: 'Buy',
                      color: AppColors.success,
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await context.push<bool>('/buy');
                        if (result == true && mounted) {
                          context.read<DashboardCubit>().loadDashboard();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.sell,
                      label: SiStrings.sell,
                      sublabel: 'Sell',
                      color: AppColors.info,
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await context.push<bool>('/sell');
                        if (result == true && mounted) {
                          context.read<DashboardCubit>().loadDashboard();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.person_add,
                      label: 'නව ගනුදෙනුකරු', // New Customer
                      sublabel: 'Add Customer',
                      color: AppColors.warning,
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await context.push<bool>(RouteNames.customerAdd);
                        if (result == true && mounted) {
                          context.read<DashboardCubit>().loadDashboard();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.inventory,
                      label: 'තොග එක් කරන්න', // Add Stock
                      sublabel: 'Add Stock',
                      color: AppColors.primary,
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await context.push<bool>('/stock/milling');
                        if (result == true && mounted) {
                          context.read<DashboardCubit>().loadDashboard();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.receipt_long,
                      label: 'වියදම් එක් කරන්න', // Add Expense
                      sublabel: 'Add Expense',
                      color: AppColors.error,
                      onTap: () async {
                        Navigator.pop(context);
                        final result = await context.push<bool>('/expenses/add');
                        if (result == true && mounted) {
                          context.read<DashboardCubit>().loadDashboard();
                        }
                      },
                    ),
                  ),
                  const Spacer(),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick action button widget
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sublabel,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
