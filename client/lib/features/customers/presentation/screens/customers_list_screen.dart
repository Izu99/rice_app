// lib/features/customers/presentation/screens/customers_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../../core/shared_widgets/h_app_bar.dart';
import '../../../../core/shared_widgets/empty_state_widget.dart';
import '../../../../domain/entities/customer_entity.dart'; // Added import
import '../../../../core/constants/enums.dart';
import '../cubit/customers_cubit.dart';
import '../cubit/customers_state.dart';
import '../widgets/customer_card.dart';
import '../widgets/customer_search.dart';
import '../../../../routes/route_names.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Tab starts at index 0 ("All") on every screen entry, but the cubit
      // is a singleton and may still carry a customerTypeFilter left over
      // from a previous visit (e.g. the Sellers tab). Clear it so the
      // "All (N)" count always matches what's actually rendered.
      context.read<CustomersCubit>().filterByType(null);
      context.read<CustomersCubit>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) {
      final cubit = context.read<CustomersCubit>();
      switch (_tabController.index) {
        case 0:
          cubit.filterByType(null);
          break;
        case 1:
          cubit.filterByType(CustomerType.seller);
          break;
        case 2:
          cubit.filterByType(CustomerType.buyer);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.select((ProfileCubit c) => c.state.language);
    return BlocConsumer<CustomersCubit, CustomersState>(
      listenWhen: (previous, current) =>
          previous.formStatus != current.formStatus,
      listener: (context, state) {
        if (state.formStatus == CustomerFormStatus.success &&
            state.formSuccessMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.formSuccessMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<CustomersCubit>().resetFormStatus();
        }
      },
      builder: (context, state) {
        final buyerCount = state.customers
            .where((c) =>
                c.customerType == CustomerType.buyer ||
                c.customerType == CustomerType.both)
            .length;
        final sellerCount = state.customers
            .where((c) =>
                c.customerType == CustomerType.seller ||
                c.customerType == CustomerType.both)
            .length;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FA),
          appBar: HAppBar(
            title: SiStrings.customers,
            subtitle: '${SiStrings.total} ${state.totalCustomers}',
            onRefresh: () => context.read<CustomersCubit>().loadCustomers(),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_rounded, color: Colors.white),
                onPressed: () => context.pushNamed('customerAdd'),
                tooltip: SiStrings.addNewCustomer,
              ),
            ],
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSearchAndFilter(state),
              _buildTabBar(state, buyerCount, sellerCount),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildBody(state, null),
                _buildBody(state, CustomerType.seller),
                _buildBody(state, CustomerType.buyer),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildToolbarAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: AppColors.textPrimary, size: 20),
                if (hasBadge)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFC107),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSearchAndFilter(CustomersState state) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingMedium,
          AppDimensions.paddingMedium,
          AppDimensions.paddingMedium,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomerSearch(
              initialQuery: state.searchQuery,
              hintText: SiStrings.searchHint,
              onSearch: (query) {
                context.read<CustomersCubit>().searchCustomers(query);
              },
              onClear: () {
                context.read<CustomersCubit>().searchCustomers('');
              },
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToolbarAction(
                    icon: Icons.sort_rounded,
                    label: SiStrings.sortByLabel,
                    onTap: () => _showSortOptions(context),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: const Color(0xFFE5E5EA),
                  ),
                  _buildToolbarAction(
                    icon: Icons.filter_list_rounded,
                    label: SiStrings.filterLabel,
                    hasBadge: state.hasActiveFilters,
                    onTap: () => _showFilterOptions(context, state),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(CustomersState state, int buyerCount, int sellerCount) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        tabBar: Container(
          color: const Color(0xFFF4F6FA),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF8E8E93),
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.primary,
            ),
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child:
                    Text('${SiStrings.customersAll} (${state.customers.length})'),
              )),
              Tab(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('${SiStrings.customersSellers} ($sellerCount)'),
              )),
              Tab(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('${SiStrings.customersBuyers} ($buyerCount)'),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(CustomersState state, CustomerType? type) {
    final customers = state.filteredCustomers.where((c) {
      if (type == null) return true;
      if (type == CustomerType.buyer) {
        return c.customerType == CustomerType.buyer ||
            c.customerType == CustomerType.both;
      }
      if (type == CustomerType.seller) {
        return c.customerType == CustomerType.seller ||
            c.customerType == CustomerType.both;
      }
      return false;
    }).toList();

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.hasError) {
      return Center(
        child: EmptyStateWidget(
          icon: Icons.error_outline,
          title: SiStrings.errorLoadingCustomers,
          subtitle: state.errorMessage ?? SiStrings.tryAgain,
          actionLabel: SiStrings.tryAgain,
          onAction: () => context.read<CustomersCubit>().loadCustomers(),
        ),
      );
    }

    if (customers.isEmpty) {
      if (state.isSearchActive || state.hasActiveFilters) {
        return Center(
          child: EmptyStateWidget(
            icon: Icons.search_off,
            title: SiStrings.noResultsFound,
            subtitle: SiStrings.tryDifferentSearch,
            actionLabel: SiStrings.clearFiltersAction,
            onAction: () => context.read<CustomersCubit>().clearFilters(),
          ),
        );
      }

      return Center(
        child: EmptyStateWidget(
          icon: Icons.people_outline,
          title: SiStrings.noCustomersYet,
          subtitle: SiStrings.addFirstCustomer,
          actionLabel: SiStrings.addNewCustomer,
          onAction: () => context.pushNamed('customerAdd'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<CustomersCubit>().refreshCustomers(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: customers.length,
        itemBuilder: (context, index) {
          final customer = customers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: CustomerCard(
              customer: customer,
              onTap: () {
                context.push(RouteNames.customerDetailById(customer.id));
              },
            ),
          );
        },
      ),
    );
  }


  void _showSortOptions(BuildContext context) {
    final cubit = context.read<CustomersCubit>();
    final state = cubit.state;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SiStrings.sortByTitle,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...CustomerSortBy.values.map((sortBy) {
                  final isSelected = state.sortBy == sortBy;
                  return ListTile(
                    leading: Icon(
                      sortBy.icon,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    title: Text(_getSortDisplayName(sortBy)),
                    trailing: isSelected
                        ? Icon(
                            state.sortAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: AppColors.primary,
                          )
                        : null,
                    selected: isSelected,
                    selectedTileColor: AppColors.primaryLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      cubit.sortCustomers(sortBy);
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getSortDisplayName(CustomerSortBy sortBy) {
    switch (sortBy) {
      case CustomerSortBy.name:
        return SiStrings.sortByNameLabel;
      case CustomerSortBy.balance:
        return SiStrings.sortByBalanceLabel;
      case CustomerSortBy.createdAt:
        return SiStrings.sortByDateAdded;
      case CustomerSortBy.phone:
        return SiStrings.isSinhala ? 'දුරකථන අංකය අනුව' : sortBy.displayName;
      case CustomerSortBy.totalPurchases:
        return SiStrings.isSinhala ? 'මුළු මිලදී ගැනීම් අනුව' : sortBy.displayName;
      case CustomerSortBy.totalSales:
        return SiStrings.isSinhala ? 'මුළු විකුණුම් අනුව' : sortBy.displayName;
    }
  }

  void _showFilterOptions(BuildContext context, CustomersState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  SiStrings.filtersTitle,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.hasActiveFilters)
                  TextButton(
                    onPressed: () {
                      context.read<CustomersCubit>().clearFilters();
                      Navigator.pop(context);
                    },
                    child: Text(SiStrings.clearAll),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Balance filters
            Text(
              SiStrings.balanceLabel,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: SiStrings.withBalance,
                  isSelected: state.showOnlyWithBalance,
                  onTap: () {
                    context.read<CustomersCubit>().toggleShowOnlyWithBalance();
                  },
                ),
                _FilterChip(
                  label: SiStrings.receivable,
                  isSelected: state.balanceFilter == BalanceType.receivable,
                  color: AppColors.success,
                  onTap: () {
                    context
                        .read<CustomersCubit>()
                        .filterByBalance(BalanceType.receivable);
                  },
                ),
                _FilterChip(
                  label: SiStrings.payable,
                  isSelected: state.balanceFilter == BalanceType.payable,
                  color: AppColors.error,
                  onTap: () {
                    context
                        .read<CustomersCubit>()
                        .filterByBalance(BalanceType.payable);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Customer type filters
            Text(
              SiStrings.customerRole,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: SiStrings.buyerLabel,
                  isSelected: state.customerTypeFilter == CustomerType.buyer,
                  onTap: () {
                    context
                        .read<CustomersCubit>()
                        .filterByType(CustomerType.buyer);
                  },
                ),
                _FilterChip(
                  label: SiStrings.sellerLabel,
                  isSelected: state.customerTypeFilter == CustomerType.seller,
                  onTap: () {
                    context
                        .read<CustomersCubit>()
                        .filterByType(CustomerType.seller);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(SiStrings.applyFilters),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _callCustomer(String phone) {
    // Implement phone call
    // You can use url_launcher package
    debugPrint('Calling $phone');
  }

  void _messageCustomer(String phone) {
    // Implement messaging
    debugPrint('Messaging $phone');
  }

}

/// Tab bar delegate for persistent header
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;

  _TabBarDelegate({required this.tabBar});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return tabBar;
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? effectiveColor : effectiveColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: effectiveColor.withOpacity(isSelected ? 0 : 0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? AppColors.white : effectiveColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
