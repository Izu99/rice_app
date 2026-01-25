import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../routes/route_names.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Icon/Logo
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.rice_bowl,
                      size: 80,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Welcome Text
                  Text(
                    'Rice Mill ERP',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Manage your rice mill efficiently with our modern management system.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Navigation Buttons
                  _buildNavButton(
                    context,
                    icon: Icons.shopping_cart_outlined,
                    label: 'Buy',
                    route: RouteNames.buy,
                  ),
                  const SizedBox(height: 16),
                  _buildNavButton(
                    context,
                    icon: Icons.sell_outlined,
                    label: 'Sell',
                    route: RouteNames.sell,
                  ),
                  const SizedBox(height: 16),
                  _buildNavButton(
                    context,
                    icon: Icons.inventory_2_outlined,
                    label: 'Stock',
                    route: RouteNames.stock,
                  ),
                  const SizedBox(height: 16),
                  _buildNavButton(
                    context,
                    icon: Icons.analytics_outlined,
                    label: 'Detailed Dashboard',
                    route: RouteNames.detailedDashboard,
                  ),
                  const SizedBox(height: 16),
                  _buildNavButton(
                    context,
                    icon: Icons.dashboard_outlined,
                    label: 'Go to Summary',
                    route: RouteNames.home,
                  ),
                  const SizedBox(height: 16),
                  _buildNavButton(
                    context,
                    icon: Icons.bar_chart_outlined,
                    label: 'Reports',
                    route: RouteNames.reports,
                  ),

                  const SizedBox(height: 40),

                  // Version Info
                  Text(
                    'v1.0.0',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => context.push(route),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              label.toUpperCase(),
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
