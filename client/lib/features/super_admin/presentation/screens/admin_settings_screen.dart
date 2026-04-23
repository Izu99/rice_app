// lib/features/super_admin/presentation/screens/admin_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/shared_widgets/h_app_bar.dart';
import '../cubit/admin_cubit.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: CustomScrollView(
        slivers: [
          _buildStickyHeader(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildSectionHeader('Global Price Settings'),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    title: 'System Reference Prices',
                    subtitle: 'Set base prices for different paddy varieties',
                    icon: Icons.settings_applications_rounded,
                    onTap: () {
                      // Action for reference prices
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    title: 'Price Alerts',
                    subtitle: 'Configure notifications for unusual price drops',
                    icon: Icons.notifications_active_rounded,
                    onTap: () {
                      // Action for price alerts
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('System Configuration'),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    title: 'Company Registration',
                    subtitle: 'Control self-registration and approval workflow',
                    icon: Icons.app_registration_rounded,
                    onTap: () {
                      // Action for registration settings
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    title: 'District Management',
                    subtitle: 'Add or modify supported operational districts',
                    icon: Icons.map_rounded,
                    onTap: () {
                      // Action for districts
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Account'),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    title: 'Change Password',
                    subtitle: 'Update your administrator password',
                    icon: Icons.lock_outline_rounded,
                    onTap: () {
                      context.push('/profile/change-password');
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
  }

  Widget _buildStickyHeader(BuildContext context) {
    return HSliverAppBar(
      pinned: true,
      title: 'Admin Settings',
      subtitle: 'System & global configurations',
    );
  }

  Widget _buildSectionHeader(String label) {
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

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
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
                color: AppColors.adminPrimary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.adminPrimary, size: 24),
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
