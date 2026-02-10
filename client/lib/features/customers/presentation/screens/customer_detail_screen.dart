// lib/features/customers/presentation/screens/customer_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/shared_widgets/confirmation_dialog.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../routes/route_names.dart';
import '../../../../data/models/customer_model.dart';
import '../../../../domain/entities/customer_entity.dart';
import '../cubit/customers_cubit.dart';
import '../cubit/customers_state.dart';
import '../../../buy/presentation/cubit/buy_cubit.dart';
import '../../../sell/presentation/cubit/sell_cubit.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);

    // Load customer detail
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomersCubit>().loadCustomerDetail(widget.customerId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<CustomersCubit>().loadCustomerDetail(widget.customerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomersCubit, CustomersState>(
      listenWhen: (previous, current) =>
          previous.formStatus != current.formStatus ||
          previous.detailStatus != current.detailStatus,
      listener: (context, state) {
        if (state.formStatus == CustomerFormStatus.success) {
          if (state.formSuccessMessage?.contains('deleted') == true) {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.customers);
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.formSuccessMessage ?? 'Success'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.detailStatus == CustomerDetailStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.detailStatus == CustomerDetailStatus.error ||
            state.selectedCustomer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Customer')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage ?? 'Customer not found',
                    style: AppTextStyles.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (GoRouter.of(context).canPop()) {
                        context.pop();
                      } else {
                        context.go(RouteNames.customers);
                      }
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        final customer = state.selectedCustomer!;

        return LoadingOverlay(
          isLoading: state.formStatus == CustomerFormStatus.submitting,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                _buildAppBar(customer),
                _buildQuickStats(customer),
                _buildTabBar(),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildInfoTab(customer),
                  _buildTransactionsTab(state),
                  _buildBalanceTab(customer),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomActions(customer),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(CustomerEntity customer) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          customer.name,
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                CircleAvatar(
                  radius: 35,
                  backgroundColor: AppColors.white.withOpacity(0.2),
                  child: Text(
                    customer.initials,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _editCustomer(customer),
          tooltip: 'Edit',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'delete':
                _deleteCustomer(customer);
                break;
              case 'share':
                _shareCustomer(customer);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 20),
                  SizedBox(width: 12),
                  Text('Share'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.error, size: 20),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(CustomerEntity customer) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.account_balance_wallet,
                label: 'Balance',
                value: customer.formattedBalance,
                valueColor:
                    customer.balance >= 0 ? AppColors.success : AppColors.error,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.divider,
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.timeline,
                label: 'Status',
                value: customer.balanceStatus,
                valueColor: _getBalanceStatusColor(customer.balance),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        child: Container(
          color: AppColors.background,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Info'),
              Tab(text: 'History'),
              Tab(text: 'Balance'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab(CustomerEntity customer) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          title: 'Contact Details',
          icon: Icons.contact_phone,
          children: [
            _buildInfoRow(
              icon: Icons.phone,
              label: 'Phone',
              value: customer.formattedPhone,
              onTap: () => _callCustomer(customer.phone),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.call, color: AppColors.success),
                    onPressed: () => _callCustomer(customer.phone),
                    iconSize: 20,
                  ),
                  IconButton(
                    icon: const Icon(Icons.message, color: AppColors.info),
                    onPressed: () => _messageCustomer(customer.phone),
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            if (customer.secondaryPhone != null &&
                customer.secondaryPhone!.isNotEmpty)
              _buildInfoRow(
                icon: Icons.phone_android,
                label: 'Secondary Phone',
                value: customer.secondaryPhone!,
              ),
            if (customer.email != null && customer.email!.isNotEmpty)
              _buildInfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: customer.email!,
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'Location',
          icon: Icons.location_on,
          children: [
            if (customer.address != null && customer.address!.isNotEmpty)
              _buildInfoRow(
                icon: Icons.map_outlined,
                label: 'Address',
                value: customer.address!,
                onTap: () => _copyToClipboard(customer.address!),
              ),
            if (customer.city != null && customer.city!.isNotEmpty)
              _buildInfoRow(
                icon: Icons.location_city,
                label: 'City',
                value: customer.city!,
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (customer.nic != null && customer.nic!.isNotEmpty) ...[
          _buildInfoCard(
            title: 'Additional Details',
            icon: Icons.info_outline,
            children: [
              _buildInfoRow(
                icon: Icons.badge_outlined,
                label: 'NIC Number',
                value: customer.nic!,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        _buildInfoCard(
          title: 'Account Settings',
          icon: Icons.settings_outlined,
          children: [
            _buildInfoRow(
              icon: Icons.category_outlined,
              label: 'Customer Role',
              value: customer.customerType.displayName,
              valueColor: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (customer.notes != null && customer.notes!.isNotEmpty) ...[
          _buildInfoCard(
            title: 'Internal Notes',
            icon: Icons.note_outlined,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(customer.notes!, style: AppTextStyles.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: valueColor ?? AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab(CustomersState state) {
    if (state.customerTransactions.isEmpty) {
      return const Center(
        child: Text('No transactions found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.customerTransactions.length,
      itemBuilder: (context, index) {
        final txn = state.customerTransactions[index];
        final type = txn['type']?.toString().toLowerCase() ?? 'buy';
        final isBuy = type == 'buy';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (isBuy ? AppColors.error : AppColors.success)
                  .withOpacity(0.1),
              child: Icon(
                isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                color: isBuy ? AppColors.error : AppColors.success,
                size: 20,
              ),
            ),
            title: Text(
              isBuy ? 'Purchase' : 'Sale',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
                DateFormat('MMM dd, yyyy').format(DateTime.parse(txn['date']))),
            trailing: Text(
              'Rs. ${txn['total_amount']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isBuy ? AppColors.error : AppColors.success,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceTab(CustomerEntity customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: customer.balance >= 0
                    ? [AppColors.success, AppColors.success.withOpacity(0.7)]
                    : [AppColors.error, AppColors.error.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('Current Balance',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                FittedBox(
                  child: Text(
                    customer.formattedBalance,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  customer.balanceStatus.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(CustomerEntity customer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (customer.customerType.canBuy)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _continueToBuy(customer),
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text('BUY',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),
            if (customer.customerType.canBuy && customer.customerType.canSell)
              const SizedBox(width: 12),
            if (customer.customerType.canSell)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _continueToSell(customer),
                  icon: const Icon(Icons.sell),
                  label: const Text('SELL',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardSell,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getBalanceStatusColor(double balance) {
    if (balance > 0) return AppColors.success;
    if (balance < 0) return AppColors.error;
    return AppColors.textSecondary;
  }

  void _callCustomer(String phone) {
    // Implement phone call logic
  }

  void _messageCustomer(String phone) {
    // Implement message logic
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _editCustomer(CustomerEntity customer) {
    context.pushNamed('customerEdit', pathParameters: {'id': customer.id});
  }

  Future<void> _deleteCustomer(CustomerEntity customer) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Customer?',
      message: 'Are you sure you want to delete ${customer.name}?',
      confirmLabel: 'Delete',
      isDangerous: true,
    );

    if (confirmed && mounted) {
      context.read<CustomersCubit>().deleteCustomer(customer.id);
    }
  }

  void _shareCustomer(CustomerEntity customer) {
    debugPrint('Sharing ${customer.name}');
  }

  void _continueToBuy(CustomerEntity customer) {
    final customerModel = CustomerModel.fromEntity(customer, 'current_company');
    context.read<BuyCubit>().selectCustomer(customerModel);
    context.pushNamed('buyProcess');
  }

  void _continueToSell(CustomerEntity customer) {
    final customerModel = CustomerModel.fromEntity(customer, 'current_company');
    context.read<SellCubit>().selectCustomer(customerModel);
    context.pushNamed('sellProcess');
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _TabBarDelegate({required this.child});

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  double get maxExtent => 48;
  @override
  double get minExtent => 48;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
