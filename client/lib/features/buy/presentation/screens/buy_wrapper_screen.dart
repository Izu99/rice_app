// lib/features/buy/presentation/screens/buy_wrapper_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubit/buy_cubit.dart';
import '../cubit/buy_state.dart';

/// Buy module wrapper with custom bottom navigation
class BuyWrapperScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const BuyWrapperScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  State<BuyWrapperScreen> createState() => _BuyWrapperScreenState();
}

class _BuyWrapperScreenState extends State<BuyWrapperScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize buy cubit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BuyCubit>().initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<BuyCubit>().initialize();
    }
  }

  void _onDestinationSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BuyCubit, BuyState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.tempItems.length != current.tempItems.length,
      builder: (context, state) {
        return Scaffold(
          body: widget.navigationShell,
          bottomNavigationBar: _buildBottomNavBar(state),
        );
      },
    );
  }

  Widget _buildBottomNavBar(BuyState state) {
    final currentIndex = widget.navigationShell.currentIndex;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Buy tab
              _buildNavItem(
                index: 0,
                currentIndex: currentIndex,
                icon: Icons.shopping_cart_outlined,
                activeIcon: Icons.shopping_cart,
                label: 'Buy',
                sublabel: 'මිලදී ගැනීම',
                badge: state.tempItems.isNotEmpty
                    ? state.tempItems.length.toString()
                    : null,
              ),

              // Add Customer tab
              _buildNavItem(
                index: 1,
                currentIndex: currentIndex,
                icon: Icons.person_add_outlined,
                activeIcon: Icons.person_add,
                label: 'Customer',
                sublabel: 'පාරිභෝගිකයා',
              ),

              // Add Stock tab (Manual)
              _buildNavItem(
                index: 2,
                currentIndex: currentIndex,
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2,
                label: 'Stock',
                sublabel: 'තොගය',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String sublabel,
    String? badge,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onDestinationSelected(index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 26,
                  ),
                  if (badge != null)
                    Positioned(
                      right: -8,
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
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              Text(
                sublabel,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.7)
                      : AppColors.textHint,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
