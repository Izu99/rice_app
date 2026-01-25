import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/shared_widgets/empty_state_widget.dart';
import '../../../../core/constants/enums.dart';
import '../../../../domain/entities/customer_entity.dart';
import '../../../../data/models/customer_model.dart';
import '../../../customers/presentation/cubit/customers_cubit.dart';
import '../../../customers/presentation/cubit/customers_state.dart';

class SellCustomerSelectionScreen extends StatefulWidget {
  const SellCustomerSelectionScreen({super.key});

  @override
  State<SellCustomerSelectionScreen> createState() =>
      _SellCustomerSelectionScreenState();
}

class _SellCustomerSelectionScreenState
    extends State<SellCustomerSelectionScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<CustomersCubit>();
      cubit.loadCustomers().then((_) {
        cubit.filterByType(CustomerType.buyer);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Selling Customer'),
        backgroundColor: AppColors.cardSell,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Full width header background
          Container(
            width: double.infinity,
            color: AppColors.cardSell,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: _buildHeader(),
              ),
            ),
          ),

          // Constrained content area
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name or phone...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    context
                                        .read<CustomersCubit>()
                                        .searchCustomers('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) {
                          context.read<CustomersCubit>().searchCustomers(value);
                        },
                      ),
                    ),
                    Expanded(
                      child: BlocBuilder<CustomersCubit, CustomersState>(
                        builder: (context, state) {
                          if (state.isLoading) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (state.filteredCustomers.isEmpty) {
                            return EmptyStateWidget(
                              icon: Icons.person_off_outlined,
                              title: 'No Customers Found',
                              subtitle: 'Add a new selling customer to start',
                              actionLabel: 'Add New Customer',
                              onAction: () =>
                                  context.pushNamed('sellAddCustomer'),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: state.filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = state.filteredCustomers[index];
                              return _buildCustomerTile(customer);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('sellAddCustomer'),
        icon: const Icon(Icons.person_add),
        label: const Text('New Customer'),
        backgroundColor: AppColors.cardSell,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Who are you selling to?',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            'Search or select from list',
            style: AppTextStyles.headlineSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerTile(CustomerEntity customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.cardSell.withOpacity(0.1),
          child: Text(
            customer.initials,
            style: const TextStyle(
              color: AppColors.cardSell,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    customer.formattedPhone,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.info_outline, color: AppColors.cardSell),
              tooltip: 'View Profile',
              onPressed: () {
                context.pushNamed('customerDetail',
                    pathParameters: {'id': customer.id});
              },
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
        onTap: () {
          final customerModel =
              CustomerModel.fromEntity(customer, 'default_company');

          if (context.canPop()) {
            context.pop(customerModel);
          } else {
            // Need to implement SellCubit similar to BuyCubit
            // context.read<SellCubit>().selectCustomer(customerModel);
            // context.pushReplacementNamed('sellProcess');
          }
        },
      ),
    );
  }
}

