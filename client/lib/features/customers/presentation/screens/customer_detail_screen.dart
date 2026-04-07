import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/shared_widgets/h_app_bar.dart';
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
              content: Text(state.formSuccessMessage ?? 'සාර්ථකයි'),
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
            appBar: AppBar(title: const Text('ගනුදෙනුකරු')), // Customer
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
                    state.errorMessage ?? 'ගනුදෙනුකරු හමු නොවීය', // Customer not found
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
                    child: const Text('ආපසු යන්න'), // Go Back
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
            backgroundColor: const Color(0xFFF4F6FA),
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
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -30,
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.white.withOpacity(0.04),
                ),
              ),
              Positioned(
                bottom: 40,
                left: -20,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withOpacity(0.03),
                ),
              ),
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.white.withOpacity(0.12),
                        child: Text(
                          customer.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      customer.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        customer.customerType.sinhalaName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        _buildAppBarAction(
          icon: Icons.edit_rounded,
          onTap: () => _editCustomer(customer),
        ),
        const SizedBox(width: 8),
        _buildAppBarAction(
          icon: Icons.more_vert_rounded,
          onTap: () => _showMoreOptions(context, customer),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildAppBarAction({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, CustomerEntity customer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8EE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(
              icon: Icons.share_rounded,
              title: 'බෙදාගන්න', // Share
              onTap: () {
                Navigator.pop(context);
                _shareCustomer(customer);
              },
            ),
            _buildOptionTile(
              icon: Icons.delete_outline_rounded,
              title: 'මකා දමන්න', // Delete
              color: const Color(0xFFE53935),
              onTap: () {
                Navigator.pop(context);
                _deleteCustomer(customer);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: effectiveColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: effectiveColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: effectiveColor,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildQuickStats(CustomerEntity customer) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFE8E8EE), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.account_balance_wallet_rounded,
                label: 'ශේෂය (Balance)',
                value: customer.formattedBalance,
                valueColor:
                    customer.balance >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: const Color(0xFFF0F0F5),
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.insights_rounded,
                label: 'තත්ත්වය (Status)',
                value: _getSinhalaBalanceStatus(customer.balance),
                valueColor: _getBalanceStatusColor(customer.balance),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSinhalaBalanceStatus(double balance) {
    if (balance > 0) return 'ලැබිය යුතුයි';
    if (balance < 0) return 'ගෙවිය යුතුයි';
    return 'ශේෂයක් නැත';
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF8E8E93), size: 20),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 10,
            fontWeight: FontWeight.w600,
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
          color: const Color(0xFFF4F6FA),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF8E8E93),
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.primary,
            ),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(child: Text('විස්තර', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))), // Info
              Tab(child: Text('ඉතිහාසය', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))), // History
              Tab(child: Text('ශේෂය', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))), // Balance
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
          title: 'සම්බන්ධ කර ගැනීමට', // Contact Details
          icon: Icons.contact_phone,
          children: [
            _buildInfoRow(
              icon: Icons.phone,
              label: 'දුරකථන අංකය',
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
                label: 'අමතර දුරකථන අංකය',
                value: customer.secondaryPhone!,
              ),
            if (customer.email != null && customer.email!.isNotEmpty)
              _buildInfoRow(
                icon: Icons.email_outlined,
                label: 'විද්‍යුත් තැපෑල',
                value: customer.email!,
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'ලිපිනය', // Location
          icon: Icons.location_on,
          children: [
            if (customer.address != null && customer.address!.isNotEmpty)
              _buildInfoRow(
                icon: Icons.map_outlined,
                label: 'ලිපිනය',
                value: customer.address!,
                onTap: () => _copyToClipboard(customer.address!),
              ),
            if (customer.city != null && customer.city!.isNotEmpty)
              _buildInfoRow(
                icon: Icons.location_city,
                label: 'නගරය',
                value: customer.city!,
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          title: 'ගිණුමේ තොරතුරු', // Account Settings
          icon: Icons.settings_outlined,
          children: [
            _buildInfoRow(
              icon: Icons.category_outlined,
              label: 'භූමිකාව',
              value: customer.customerType.sinhalaName,
              valueColor: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (customer.notes != null && customer.notes!.isNotEmpty) ...[
          _buildInfoCard(
            title: 'සටහන්', // Internal Notes
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ගනුදෙනු කිසිවක් හමු නොවීය', // No transactions found
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.customerTransactions.length,
      itemBuilder: (context, index) {
        final txn = state.customerTransactions[index];
        final type = txn['type']?.toString().toLowerCase() ?? 'buy';
        final isBuy = type == 'buy';
        final color = isBuy ? const Color(0xFFE53935) : const Color(0xFF4CAF50);
        final balance = (txn['balance'] as num?)?.toDouble() ?? 0.0;
        final hasBalance = balance > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8E8EE), width: 1),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isBuy ? Icons.call_received_rounded : Icons.call_made_rounded,
                    color: color,
                    size: 24,
                  ),
                ),
                title: Text(
                  isBuy ? 'මිලදී ගැනීම' : 'විකිණීම', // Purchase / Sale
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('yyyy MMM dd').format(DateTime.parse(txn['date'] ?? txn['transactionDate'])),
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (hasBalance) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'හිඟ මුදල: Rs. $balance', // Due Amount
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Text(
                  'Rs. ${txn['total_amount']}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontSize: 16,
                  ),
                ),
              ),
              if (hasBalance)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _showPaymentDialog(context, txn),
                        icon: Icon(isBuy ? Icons.payments_rounded : Icons.move_to_inbox_rounded, size: 16),
                        label: Text(isBuy ? 'ගෙවන්න' : 'ලබාගන්න'), // Pay / Receive
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isBuy ? AppColors.error : AppColors.success,
                          side: BorderSide(color: isBuy ? AppColors.error : AppColors.success),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                const Text('වත්මන් ශේෂය', // Current Balance
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
                  _getSinhalaBalanceStatus(customer.balance).toUpperCase(),
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
    final hasPayableBalance = customer.balance < 0;
    final hasReceivableBalance = customer.balance > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasPayableBalance || hasReceivableBalance) ...[
              _buildActionBtn(
                label: hasPayableBalance ? 'හිඟ මුදල ගෙවන්න' : 'හිඟ මුදල ලබාගන්න', // Pay / Receive Due
                icon: hasPayableBalance ? Icons.payments_rounded : Icons.move_to_inbox_rounded,
                color: hasPayableBalance ? AppColors.error : AppColors.success,
                onTap: () {
                  // If we have transactions, pay the most recent one with balance
                  final cubit = context.read<CustomersCubit>();
                  final txnsWithBalance = cubit.state.customerTransactions
                      .where((t) => ((t['balance'] as num?)?.toDouble() ?? 0.0) > 0)
                      .toList();
                  
                  if (txnsWithBalance.isNotEmpty) {
                    _showPaymentDialog(context, txnsWithBalance.first);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ගෙවීමට හිඟ ගනුදෙනු කිසිවක් නැත')), // No pending transactions
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                if (customer.customerType.canBuy)
                  Expanded(
                    child: _buildActionBtn(
                      label: 'මිලදී ගැනීම',
                      icon: Icons.shopping_bag_rounded,
                      color: const Color(0xFF4CAF50),
                      onTap: () => _continueToBuy(customer),
                    ),
                  ),
                if (customer.customerType.canBuy && customer.customerType.canSell)
                  const SizedBox(width: 12),
                if (customer.customerType.canSell)
                  Expanded(
                    child: _buildActionBtn(
                      label: 'විකිණීම',
                      icon: Icons.sell_rounded,
                      color: const Color(0xFF2196F3),
                      onTap: () => _continueToSell(customer),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Map<String, dynamic> txn) {
    final balance = (txn['balance'] as num?)?.toDouble() ?? 0.0;
    final type = txn['type']?.toString().toLowerCase() ?? 'buy';
    final isBuy = type == 'buy';
    final transactionId = txn['id'] ?? txn['_id'];
    
    final TextEditingController amountController = TextEditingController(text: balance.toString());
    final TextEditingController notesController = TextEditingController();
    PaymentMethod selectedMethod = PaymentMethod.cash;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isBuy ? 'ගෙවීම සිදු කරන්න' : 'මුදල් ලබාගන්න'), // Make Payment / Receive Money
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ගනුදෙනු අංකය: ${txn['transactionNumber'] ?? txn['transaction_number'] ?? 'N/A'}',
                style: AppTextStyles.labelSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'මුදල (Amount)',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMethod>(
                value: selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'ගෙවීම් ක්‍රමය', // Payment Method
                  border: OutlineInputBorder(),
                ),
                items: PaymentMethod.values.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method.sinhalaName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) selectedMethod = value;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'සටහන් (Notes)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('අවලංගු කරන්න'), // Cancel
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('කරුණාකර වලංගු මුදලක් ඇතුළත් කරන්න')), // Valid amount
                );
                return;
              }
              
              Navigator.pop(context);
              context.read<CustomersCubit>().addPayment(
                transactionId: transactionId,
                amount: amount,
                method: selectedMethod,
                notes: notesController.text,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isBuy ? AppColors.error : AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('තහවුරු කරන්න'), // Confirm
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      elevation: 4,
      shadowColor: color.withOpacity(0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
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
    _launchUrl('tel:$phone');
  }

  void _messageCustomer(String phone) {
    _launchUrl('sms:$phone');
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch dialer')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('පිටපත් කරන ලදී')), // Copied to clipboard
    );
  }

  void _editCustomer(CustomerEntity customer) {
    context.pushNamed('customerEdit', pathParameters: {'id': customer.id});
  }

  Future<void> _deleteCustomer(CustomerEntity customer) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'ගනුදෙනුකරු මකා දමන්නද?', // Delete Customer?
      message: '${customer.name} මකා දැමීමට ඔබට විශ්වාසද?',
      confirmLabel: 'මකා දමන්න',
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
