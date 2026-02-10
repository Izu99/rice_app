// lib/features/sell/presentation/screens/sell_wrapper_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../core/shared_widgets/sync_status_indicator.dart';
import '../../../../core/sync/sync_status.dart';
import '../cubit/sell_cubit.dart';
import '../cubit/sell_state.dart';

class SellWrapperScreen extends StatefulWidget {
  final Widget child;

  const SellWrapperScreen({
    super.key,
    required this.child,
  });

  @override
  State<SellWrapperScreen> createState() => _SellWrapperScreenState();
}

class _SellWrapperScreenState extends State<SellWrapperScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<SellCubit>().initialize();
    }
  }

  final List<_SellNavItem> _navItems = [
    _SellNavItem(
      icon: Icons.point_of_sale,
      label: SiStrings.sell,
      route: '/sell',
    ),
    _SellNavItem(
      icon: Icons.inventory_2_outlined,
      label: SiStrings.stock,
      route: '/sell/stock',
    ),
    _SellNavItem(
      icon: Icons.receipt_long_outlined,
      label: SiStrings.history,
      route: '/sell/history',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SellCubit, SellState>(
      listener: (context, state) {
        // Show error snackbar
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'ඉවත් කරන්න',
                textColor: Colors.white,
                onPressed: () {
                  context.read<SellCubit>().clearError();
                },
              ),
            ),
          );
        }

        // Show success snackbar
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          context.read<SellCubit>().clearSuccess();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: _buildAppBar(context, state),
          body: widget.child,
          bottomNavigationBar: _buildBottomNavBar(context, state),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, SellState state) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => _handleBackPress(context, state),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SiStrings.sell,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (state.selectedCustomer != null)
            Text(
              state.selectedCustomer!.name,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
        ],
      ),
      actions: [
        // Sync status indicator
        SyncStatusIndicator(
          status: state.isSynced
              ? SyncStatusModel.success()
              : SyncStatusModel.idle(),
        ),

        // Cart badge
        if (state.sellItems.isNotEmpty)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () => _showCartSummary(context, state),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${state.sellItems.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

        // More options
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'refresh',
              child: ListTile(
                leading: const Icon(Icons.refresh),
                title: Text(SiStrings.refreshStock),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'clear',
              child: ListTile(
                leading: const Icon(Icons.clear_all),
                title: Text(SiStrings.clearAll),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavBar(BuildContext context, SellState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = _currentIndex == index;

              return _buildNavItem(
                context: context,
                item: item,
                isSelected: isSelected,
                onTap: () => _onNavItemTap(context, index),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required _SellNavItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final backgroundColor =
        isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingS,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNavItemTap(BuildContext context, int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    context.go(_navItems[index].route);
  }

  void _handleBackPress(BuildContext context, SellState state) {
    if (state.sellItems.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(SiStrings.discardChanges),
          content: const Text(
            'ඔබේ කාඩ්පතේ අයිතම පවතී. ඔබට විශ්වාසද?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(SiStrings.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<SellCubit>().resetForNewSale();
                context.go('/home');
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('ඉවත් කරන්න'),
            ),
          ],
        ),
      );
    } else {
      context.go('/home');
    }
  }

  void _showCartSummary(BuildContext context, SellState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusL),
        ),
      ),
      builder: (context) => _CartSummarySheet(state: state),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'refresh':
        context.read<SellCubit>().loadAvailableStock();
        break;
      case 'clear':
        _showClearConfirmation(context);
        break;
    }
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('සියලු අයිතම ඉවත් කරන්නද?'),
        content: const Text('මෙමඟින් ඔබේ කාඩ්පතේ සියලුම අයිතම මකා දැමෙනු ඇත.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(SiStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SellCubit>().clearAllItems();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('ඉවත් කරන්න'),
          ),
        ],
      ),
    );
  }
}

class _SellNavItem {
  final IconData icon;
  final String label;
  final String route;

  _SellNavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class _CartSummarySheet extends StatelessWidget {
  final SellState state;

  const _CartSummarySheet({required this.state});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingMedium),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    SiStrings.cartSummary,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${state.sellItems.length} ${SiStrings.items}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              const Divider(),

              // Items list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: state.sellItems.length,
                  itemBuilder: (context, index) {
                    final item = state.sellItems[index];
                    return ListTile(
                      title: Text(item.itemName),
                      subtitle: Text(
                        '${item.quantity.toStringAsFixed(2)} kg × Rs.${item.pricePerKg.toStringAsFixed(2)}',
                      ),
                      trailing: Text(
                        'Rs.${item.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Divider(),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${SiStrings.total}:',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Rs.${state.grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.paddingMedium),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.read<SellCubit>().goToReview();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    SiStrings.continueToCheckout,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
