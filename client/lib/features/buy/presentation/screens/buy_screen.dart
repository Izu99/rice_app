// lib/features/buy/presentation/screens/buy_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../core/shared_widgets/confirmation_dialog.dart';
import '../../../../core/constants/paddy_constants.dart';
import '../../../../data/models/customer_model.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../routes/route_names.dart';
import '../cubit/buy_cubit.dart';
import '../cubit/buy_state.dart';
import '../widgets/customer_selector.dart';
import '../widgets/temp_items_table.dart';
import '../widgets/price_input_dialog.dart';

class BuyScreen extends StatefulWidget {
  const BuyScreen({super.key});

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> with WidgetsBindingObserver {
  final TextEditingController _bagsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bagsController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Refresh data when app comes to foreground
      context.read<BuyCubit>().initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BuyCubit, BuyState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage ||
          previous.editingItemIndex != current.editingItemIndex,
      listener: (context, state) {
        // Update controllers if they differ from state (e.g. changed via keypad)
        final stateBags = state.currentBags.toString();
        if (_bagsController.text != stateBags && state.currentBags > 0) {
          _bagsController.text = stateBags;
        } else if (state.currentBags == 0) {
          _bagsController.clear();
        }

        final stateWeight = state.currentWeight.toStringAsFixed(2);
        if (_weightController.text != stateWeight && state.currentWeight > 0) {
          _weightController.text = stateWeight;
        } else if (state.currentWeight == 0) {
          _weightController.clear();
        }

        final statePrice = state.pricePerKg.toStringAsFixed(2);
        if (_priceController.text != statePrice && state.pricePerKg > 0) {
          _priceController.text = statePrice;
        } else if (state.pricePerKg == 0) {
          _priceController.clear();
        }

        // Handle errors
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.fixed,
            ),
          );
          context.read<BuyCubit>().clearError();
        }

        // Show price input dialog
        if (state.editingItemIndex != null) {
          _showPriceInputDialog(context, state);
        }

        // Handle success - show snackbar and reset
        if (state.status == BuyStatus.success && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${state.successMessage!}'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.fixed,
              duration: const Duration(seconds: 3),
            ),
          );
          // Reset form after showing message
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<BuyCubit>().resetForNewTransaction();
            _bagsController.clear();
            _weightController.clear();
            _priceController.clear();
          });
        }
      },
      builder: (context, state) {
        return LoadingOverlay(
          isLoading: state.isProcessing,
          message: 'Processing transaction...',
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: _buildAppBar(state),
            body: _buildBody(state),
            bottomNavigationBar: state.status == BuyStatus.reviewing
                ? _buildReviewBottomBar(state)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildPaddyDetailsSection(BuyState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(
          'වී විස්තර', // Paddy Details
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Modern Styled Dropdown
        GestureDetector(
          onTap: state.tempItems.isNotEmpty
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('තවදුරටත් අයිතම වෙනස් කිරීමට පෙර තිබෙන අයිතම ඉවත් කරන්න.'),
                      backgroundColor: AppColors.warning,
                      behavior: SnackBarBehavior.fixed,
                    ),
                  );
                }
              : null,
          child: AbsorbPointer(
            absorbing: state.tempItems.isNotEmpty,
            child: Opacity(
              opacity: state.tempItems.isNotEmpty ? 0.6 : 1.0,
              child: DropdownButtonFormField<String>(
                value: PaddyConstants.paddyVarieties.contains(state.selectedVariety) 
                    ? state.selectedVariety 
                    : null,
                decoration: InputDecoration(
                  labelText: 'වී වර්ගය', // Paddy Variety
                  prefixIcon:
                      const Icon(Icons.grass, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary),
                borderRadius: BorderRadius.circular(16),
                items: PaddyConstants.paddyVarieties.map((String variety) {
                  return DropdownMenuItem<String>(
                    value: variety,
                    child: Text(variety,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  );
                }).toList(),
                  onChanged: (value) {
                    if (value != null && value != state.selectedVariety) {
                      context.read<BuyCubit>().updateVariety(value);
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Price per kg
          TextFormField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.success),
            decoration: InputDecoration(
              labelText: 'මිල (රු/kg)', // Price per kg
              hintText: '0.00',
              prefixIcon:
                  const Icon(Icons.payments_outlined, color: AppColors.success),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (value) {
              final price = double.tryParse(value) ?? 0.0;
              context.read<BuyCubit>().setPricePerKg(price);
            },
          ),
          const SizedBox(height: 16),

          // Number of Bags (Full Row)
          TextFormField(
            controller: _bagsController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            decoration: InputDecoration(
              labelText: 'මලු ගණන', // Number of Bags
              hintText: '0',
              prefixIcon: const Icon(Icons.shopping_bag_outlined,
                  color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (value) {
              final bags = int.tryParse(value) ?? 0;
              context.read<BuyCubit>().updateBags(bags);
            },
          ),
          const SizedBox(height: 16),

          // Total Weight (Full Row)
          TextFormField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.primary),
            decoration: InputDecoration(
              labelText: 'මුළු බර', // Total Weight
              hintText: '0.00',
              suffixText: 'kg',
              prefixIcon:
                  const Icon(Icons.scale_outlined, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (value) {
              final weight = double.tryParse(value) ?? 0.0;
              context.read<BuyCubit>().updateWeight(weight);
            },
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              IconButton(
                onPressed: () {
                  context.read<BuyCubit>().clearCurrentBatch();
                  _bagsController.clear();
                  _weightController.clear();
                },
                icon: const Icon(Icons.delete_sweep_outlined),
                color: AppColors.error,
                tooltip: 'වත්මන් අයිතම ඉවත් කරන්න',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (state.currentBags > 0 && state.currentWeight > 0)
                      ? () {
                          context.read<BuyCubit>().addToTempList();
                          _bagsController.clear();
                          _weightController.clear();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('+',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 32)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuyState state) {
    String title;
    String subtitle;

    switch (state.status) {
      case BuyStatus.reviewing:
        title = 'ඇණවුම පරීක්ෂා කිරීම'; // Review Order
        subtitle = 'Review Order';
        break;
      case BuyStatus.success:
        title = 'ඇණවුම සාර්ථකයි'; // Order Complete
        subtitle = 'Order Complete';
        break;
      default:
        title = SiStrings.buyPaddy;
        subtitle = 'Buy Paddy';
    }

    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.white),
        onPressed: () {
          if (state.status == BuyStatus.reviewing) {
            context.read<BuyCubit>().backToAddingItems();
          } else if (state.hasItems) {
            _showExitConfirmation(context);
          } else {
            if (GoRouter.of(context).canPop()) {
              context.pop(true);
            } else {
              context.go(RouteNames.home);
            }
          }
        },
      ),
      title: Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
      actions: [
        if (state.hasItems && state.status != BuyStatus.reviewing)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.white),
            onPressed: () => _showClearConfirmation(context),
            tooltip: 'සියල්ල ඉවත් කරන්න',
          ),
      ],
    );
  }

  Widget _buildBody(BuyState state) {
    if (state.status == BuyStatus.reviewing) {
      return _buildReviewScreen(state);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Customer Selector
          CustomerSelector(
            title: 'විකුණුම්කරු (ගොවියා)', // Seller
            subtitle: '',
            selectedCustomer: state.selectedCustomer,
            onCustomerSelected: (customer) {
              context.read<BuyCubit>().selectCustomer(customer);
            },
            onAddNewCustomer: () => context.pushNamed('customerAdd'),
            onChangeCustomer: () async {
              final selectedCustomer =
                  await context.push<CustomerModel>('/buy');
              if (selectedCustomer != null && mounted) {
                context.read<BuyCubit>().selectCustomer(selectedCustomer);
              }
            },
            showBalance: false, // Hide customer balance on the buy page
          ),
          const SizedBox(height: 20),

          // Paddy Details Section
          if (state.selectedCustomer != null) ...[
            _buildPaddyDetailsSection(state),
            const SizedBox(height: 24),
          ],

          // Batch Table (Table 1)
          if (state.tempItems.isNotEmpty) ...[
            _buildSectionHeader(
                'දැනට ඇතුළත් කළ අයිතම', 'මලු ${state.totalBags} ක එකතුවක්'),
            const SizedBox(height: 12),
            TempItemsTable(
              items: state.tempItems,
              onRemove: (id) => context.read<BuyCubit>().removeTempItem(id),
            ),
            const SizedBox(height: 24),

            // Total Summary Card
            _buildBatchSummaryCard(state),
            const SizedBox(height: 24),

            // Add Batch Button (Saves to local database)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.canAddBatch
                    ? () => context.read<BuyCubit>().addBatchToSession()
                    : null,
                icon: const Icon(Icons.add_task),
                label: const Text('සැසියට එක් කරන්න'), // ADD BATCH TO SESSION
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Session Batches Table (Table 2)
          if (state.sessionBatches.isNotEmpty) ...[
            _buildSectionHeader('වත්මන් සැසියේ අයිතම', 'තහවුරු නොකළ බර ප්‍රමාණයන්'),
            const SizedBox(height: 12),
            _buildRecentTransactionsSection(state),
            const SizedBox(height: 24),

            // Finalize Session Button (Saves to MongoDB)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.canConfirmStock
                    ? () => context.read<BuyCubit>().finalizeSessionToStock()
                    : null,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('තොගයට එක් කර අවසන් කරන්න'), // FINALIZE & SAVE TO STOCK
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],

          const SizedBox(height: 100), // Bottom padding for nav bar
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppTextStyles.titleMedium
                    .copyWith(fontWeight: FontWeight.bold)),
            Text(subtitle,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsList(
      BuyState state, List<TransactionModel> customerTransactions) {
    // List - Grouped by Variety
    final Map<String, Map<String, dynamic>> groupedItems = {};
    for (var txn in customerTransactions) {
      for (var item in txn.items) {
        final variety = item.variety;
        if (!groupedItems.containsKey(variety)) {
          groupedItems[variety] = {
            'variety': variety,
            'bags': 0,
            'weight': 0.0,
            'amount': 0.0,
          };
        }
        groupedItems[variety]!['bags'] =
            (groupedItems[variety]!['bags'] as int) + item.bags;
        groupedItems[variety]!['weight'] =
            (groupedItems[variety]!['weight'] as double) + item.quantity;
        groupedItems[variety]!['amount'] =
            (groupedItems[variety]!['amount'] as double) + item.totalAmount;
      }
    }

    final displayGroupedItems = groupedItems.values.toList()
      ..sort(
          (a, b) => (a['variety'] as String).compareTo(b['variety'] as String));

    if (displayGroupedItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          state.selectedCustomer != null
              ? '${state.selectedCustomer!.name} සඳහා මෑත ගනුදෙනු නැත'
              : 'අද දින මෑත ගනුදෙනු නැත',
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayGroupedItems.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = displayGroupedItems[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(item['variety'] as String,
                    style: AppTextStyles.bodySmall
                        .copyWith(fontWeight: FontWeight.w500)),
              ),
              Expanded(
                flex: 2,
                child: Text('${item['bags']}',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center),
              ),
              Expanded(
                flex: 3,
                child: Text(
                    '${(item['weight'] as double).toStringAsFixed(2)} kg',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.right),
              ),
              Expanded(
                flex: 3,
                child: Text(
                    'Rs. ${(item['amount'] as double).toStringAsFixed(2)}',
                    style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold, color: AppColors.success),
                    textAlign: TextAlign.right),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentTransactionsSection(BuyState state) {
    // Show session batches (Table 2) in the middle table
    final customerTransactions = state.sessionBatches;

    // Calculate totals for the visible transactions
    final totalSessionWeight =
        customerTransactions.fold(0.0, (sum, t) => sum + t.totalWeight);
    final totalSessionAmount =
        customerTransactions.fold(0.0, (sum, t) => sum + t.totalAmount);

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
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('වර්ගය', // Type
                        style: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('මලු', // Bags
                        style: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center)),
                Expanded(
                    flex: 3,
                    child: Text('බර', // Weight
                        style: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right)),
                Expanded(
                    flex: 3,
                    child: Text('මුදල', // Amount
                        style: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right)),
              ],
            ),
          ),

          _buildRecentTransactionsList(state, customerTransactions),

          // Session Total Footer (Only if a customer is selected and has transactions)
          if (state.selectedCustomer != null &&
              customerTransactions.isNotEmpty) ...[
            const Divider(height: 1, thickness: 2),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      '${state.selectedCustomer!.name} හට ගෙවිය යුතු මුළු මුදල', // Total Payable to
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${totalSessionWeight.toStringAsFixed(2)} kg',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Rs. ${totalSessionAmount.toStringAsFixed(2)}',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBatchSummaryCard(BuyState state) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: Secondary Metrics
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'මුළු මලු ගණන', // Total Bags
                    state.totalBags.toString(),
                    Icons.shopping_bag_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.15),
                ),
                Expanded(
                  child: _buildMetricTile(
                    'මුළු බර', // Total Weight
                    '${state.totalPaddyWeight.toStringAsFixed(1)} kg',
                    Icons.scale_rounded,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors.white.withOpacity(0.1)),

          // Hero Section: Total Price
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Text(
                  'මුළු එකතුව (TOTAL AMOUNT)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Rs. ${state.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewScreen(BuyState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Customer info card
          _buildCustomerInfoCard(state),
          const SizedBox(height: 16),

          // Items summary
          _buildItemsSummaryCard(state),
          const SizedBox(height: 16),

          // Payment details
          _buildSummaryCard(state),
          const SizedBox(height: 16),

          // Additional info
          _buildAdditionalInfoCard(state),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard(BuyState state) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.selectedCustomer!.name,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  state.selectedCustomer!.formattedPhone,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (state.selectedCustomer!.address != null)
                  Text(
                    state.selectedCustomer!.address!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSummaryCard(BuyState state) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'අයිතම (${state.tempItems.length})', // Items
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'මලු ${state.totalBags} | ${state.totalWeight.toStringAsFixed(2)} kg',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...state.tempItems.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.itemType == ItemType.paddy
                            ? AppColors.warning.withOpacity(0.1)
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.itemType == ItemType.paddy
                            ? Icons.grass
                            : Icons.rice_bowl,
                        color: item.itemType == ItemType.paddy
                            ? AppColors.warning
                            : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.displayName,
                            style: AppTextStyles.titleSmall,
                          ),
                          Text(
                            'මලු ${item.bagsCount} × ${item.formattedWeight} @ ${item.formattedPrice}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item.formattedTotal,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'එකතුව', // Subtotal
                style: AppTextStyles.titleMedium,
              ),
              Text(
                state.formattedSubtotal,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuyState state) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ඇණවුම් සාරාංශය', // Order Summary
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('එකතුව', state.formattedSubtotal), // Subtotal
          _buildSummaryRow(
            'මුළු එකතුව', // Total
            state.formattedTotal,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? AppTextStyles.titleMedium
                    .copyWith(fontWeight: FontWeight.bold)
                : AppTextStyles.bodyMedium,
          ),
          Text(
            value,
            style:
                (isTotal ? AppTextStyles.titleLarge : AppTextStyles.titleSmall)
                    .copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoCard(BuyState state) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'අමතර විස්තර', // Additional Information
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'වාහන අංකය', // Vehicle Number
              prefixIcon: Icon(Icons.local_shipping),
              hintText: 'උදා: WP ABC-1234',
            ),
            onChanged: (value) {
              // TODO: context.read<BuyCubit>().updateVehicleNumber(value);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'සටහන්', // Notes
              prefixIcon: Icon(Icons.note),
              hintText: 'වෙනත් සටහන්...',
            ),
            maxLines: 3,
            onChanged: (value) {
              // TODO: context.read<BuyCubit>().updateNotes(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewBottomBar(BuyState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'මුළු එකතුව', // Total Amount
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    state.formattedTotal,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: state.isProcessing
                    ? null
                    : () {
                        context.read<BuyCubit>().finalizeSessionToStock();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle),
                    const SizedBox(width: 8),
                    Text(
                      'අවසන් කරන්න', // Complete
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPriceInputDialog(BuildContext context, BuyState state) async {
    if (state.editingItemIndex == null) return;
    final item = state.tempItems[state.editingItemIndex!];

    final double? returnedPrice = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PriceInputDialog(
        itemType: item.itemType,
        variety: item.variety,
        totalWeight: item.totalWeight,
        bags: item.bagsCount,
        initialPrice: item.pricePerKg,
      ),
    );

    if (returnedPrice != null) {
      context
          .read<BuyCubit>()
          .updateItemPrice(state.editingItemIndex!, returnedPrice);
    } else {
      // If dialog is dismissed without selecting a price, cancel editing
      context.read<BuyCubit>().cancelEditing();
    }
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => ConfirmationDialog(
        title: 'ගනුදෙනුව අත්හරින්නද?', // Discard Transaction?
        message: 'ඔබ තවමත් සුරැකී නැති අයිතම පවතී. ඔබට ඉවත් වීමට අවශ්‍යද?',
        confirmLabel: 'ඔව්, ඉවත් වන්න',
        cancelLabel: 'නැත',
        isDangerous: true,
        onConfirm: () {
          // Dialog closes itself automatically
          context.read<BuyCubit>().resetForNewTransaction();
          context.go(RouteNames.home); // Always go to home after discarding
        },
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'සියලු අයිතම ඉවත් කරන්නද?', // Clear All Items?
        message: 'මෙමඟින් වත්මන් ගනුදෙනුවේ සියලුම අයිතම මකා දැමෙනු ඇත.',
        confirmLabel: 'ඉවත් කරන්න',
        cancelLabel: 'අවලංගු කරන්න',
        isDangerous: true,
        onConfirm: () {
          // Dialog closes itself automatically
          context.read<BuyCubit>().resetForNewTransaction();
        },
      ),
    );
  }


}

