import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/shared_widgets/h_app_bar.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../core/shared_widgets/empty_state_widget.dart';
import '../../../../domain/entities/customer_entity.dart';
import '../../../../data/models/customer_model.dart';
import '../../../customers/presentation/cubit/customers_cubit.dart';
import '../../../customers/presentation/cubit/customers_state.dart';
import '../../../../core/constants/enums.dart';
import '../cubit/buy_cubit.dart';

class BuyCustomerSelectionScreen extends StatefulWidget {
  const BuyCustomerSelectionScreen({super.key});

  @override
  State<BuyCustomerSelectionScreen> createState() =>
      _BuyCustomerSelectionScreenState();
}

class _BuyCustomerSelectionScreenState
    extends State<BuyCustomerSelectionScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cubit = context.read<CustomersCubit>();
      // Clear any existing filters first to ensure a clean state
      cubit.clearFilters();
      await cubit.loadCustomers();
      cubit.filterByType(CustomerType.seller);
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
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: HAppBar(
        title: SiStrings.selectCustomer,
        subtitle: 'Select a seller to buy from',
      ),
      body: Column(
        children: [
          // Light info banner
          Container(
            width: double.infinity,
            color: Colors.white,
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
                          hintText: SiStrings.searchHint,
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
                              title: SiStrings.noCustomersFound,
                              subtitle: 'මිලදී ගැනීමක් ආරම්භ කිරීමට නව ගනුදෙනුකරුවෙකු එක් කරන්න',
                              actionLabel: SiStrings.addNewCustomer,
                              onAction: () =>
                                  context.pushNamed('buyAddCustomer'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('buyAddCustomer'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_rounded,
                color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(SiStrings.buyingFrom,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              Text(SiStrings.searchOrSelect,
                  style: AppTextStyles.titleSmall
                      .copyWith(fontWeight: FontWeight.bold)),
            ],
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
              icon: const Icon(Icons.info_outline, color: AppColors.primary),
              tooltip: SiStrings.viewProfile,
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
            // If we can't pop, it means this screen was reached directly (e.g. deep link)
            // We should select the customer and go to the buy process
            context.read<BuyCubit>().selectCustomer(customerModel);
            context.pushReplacementNamed('buyProcess');
          }
        },
      ),
    );
  }
}

