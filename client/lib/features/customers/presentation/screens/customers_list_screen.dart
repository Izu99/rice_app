// lib/features/customers/presentation/screens/customers_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../core/shared_widgets/empty_state_widget.dart';
import '../../../../domain/entities/customer_entity.dart'; // Added import
import '../../../../core/constants/enums.dart';
import '../cubit/customers_cubit.dart';
import '../cubit/customers_state.dart';
import '../widgets/customer_card.dart';
import '../widgets/customer_search.dart';

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
          backgroundColor: AppColors.background,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildAppBar(state, innerBoxIsScrolled),
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
          floatingActionButton: _buildFab(),
        );
      },
    );
  }

  Widget _buildAppBar(CustomersState state, bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      snap: false,
      forceElevated: innerBoxIsScrolled,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${state.totalCustomers}',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'මුළු ගනුදෙනුකරුවන්', // Total Customers
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildHeaderStat(
                        'ලැබිය යුතු', // Receivable
                        'Rs.${_formatNumber(state.totalReceivables)}',
                        AppColors.success,
                      ),
                      const SizedBox(width: 16),
                      _buildHeaderStat(
                        'ගෙවිය යුතු', // Payable
                        'Rs.${_formatNumber(state.totalPayables)}',
                        AppColors.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      title: Text(SiStrings.customers),
      actions: [
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: () => _showSortOptions(context),
          tooltip: 'පිළිවෙල සකසන්න', // Sort
        ),
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.filter_list),
              if (state.hasActiveFilters)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () => _showFilterOptions(context, state),
          tooltip: 'පෙරහන්', // Filter
        ),
      ],
    );
  }

  Widget _buildHeaderStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(CustomersState state) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMedium),
        child: CustomerSearch(
          initialQuery: state.searchQuery,
          onSearch: (query) {
            context.read<CustomersCubit>().searchCustomers(query);
          },
          onClear: () {
            context.read<CustomersCubit>().searchCustomers('');
          },
        ),
      ),
    );
  }

  Widget _buildTabBar(
      CustomersState state, int buyerCount, int sellerCount) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        tabBar: Container(
          color: AppColors.background,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(text: 'සියල්ල (${state.customers.length})'), // All
              Tab(text: 'සැපයුම්කරුවන් ($sellerCount)'), // Sellers
              Tab(text: 'ගැනුම්කරුවන් ($buyerCount)'), // Buyers
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
          title: 'දෝෂයක් සිදු විය', // Error Loading Customers
          subtitle: state.errorMessage ?? 'නැවත උත්සාහ කරන්න',
          actionLabel: 'නැවත උත්සාහ කරන්න',
          onAction: () => context.read<CustomersCubit>().loadCustomers(),
        ),
      );
    }

    if (customers.isEmpty) {
      if (state.isSearchActive || state.hasActiveFilters) {
        return Center(
          child: EmptyStateWidget(
            icon: Icons.search_off,
            title: 'ප්‍රතිඵල නැත', // No Results Found
            subtitle: 'සෙවුම් පද වෙනස් කර නැවත උත්සාහ කරන්න',
            actionLabel: 'පෙරහන් ඉවත් කරන්න',
            onAction: () => context.read<CustomersCubit>().clearFilters(),
          ),
        );
      }

      return Center(
        child: EmptyStateWidget(
          icon: Icons.people_outline,
          title: 'ගනුදෙනුකරුවන් නැත', // No Customers Yet
          subtitle: 'පළමු ගනුදෙනුකරු එක් කර ආරම්භ කරන්න',
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
                context.pushNamed(
                  'customerDetail',
                  pathParameters: {'id': customer.id},
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () => context.pushNamed('customerAdd'),
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.person_add),
      label: Text(SiStrings.addNewCustomer),
    );
  }

  void _showSortOptions(BuildContext context) {
    final cubit = context.read<CustomersCubit>();
    final state = cubit.state;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
            Text(
              'පිළිවෙල සකසන්න', // Sort By
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
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
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
    );
  }

  String _getSortDisplayName(CustomerSortBy sortBy) {
    switch (sortBy) {
      case CustomerSortBy.name:
        return 'නම අනුව';
      case CustomerSortBy.balance:
        return 'ශේෂය අනුව';
      case CustomerSortBy.createdAt:
        return 'එක් කළ දිනය අනුව';
      default:
        return sortBy.displayName;
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
                  'පෙරහන්', // Filters
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
                    child: const Text('සියල්ල ඉවත් කරන්න'), // Clear All
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Balance filters
            Text(
              'ශේෂය', // Balance
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
                  label: 'ශේෂයක් සහිත', // With Balance
                  isSelected: state.showOnlyWithBalance,
                  onTap: () {
                    context.read<CustomersCubit>().toggleShowOnlyWithBalance();
                  },
                ),
                _FilterChip(
                  label: 'ලැබිය යුතු', // Receivable
                  isSelected: state.balanceFilter == BalanceType.receivable,
                  color: AppColors.success,
                  onTap: () {
                    context
                        .read<CustomersCubit>()
                        .filterByBalance(BalanceType.receivable);
                  },
                ),
                _FilterChip(
                  label: 'ගෙවිය යුතු', // Payable
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
              'ගනුදෙනුකරුගේ භූමිකාව', // Customer Role
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
                  label: 'මිලදී ගන්නා (Buyer)',
                  isSelected: state.customerTypeFilter == CustomerType.buyer,
                  onTap: () {
                    context
                        .read<CustomersCubit>()
                        .filterByType(CustomerType.buyer);
                  },
                ),
                _FilterChip(
                  label: 'විකුණුම්කරු (Seller)',
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
                child: const Text('තහවුරු කරන්න'), // Apply Filters
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

  String _formatNumber(double value) {
    return NumberFormatter.formatInteger(value);
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
