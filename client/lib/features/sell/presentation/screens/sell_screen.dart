// lib/features/sell/presentation/screens/sell_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../core/constants/enums.dart';
import '../../../../data/models/stock_item_model.dart';
import '../cubit/sell_cubit.dart';
import '../cubit/sell_state.dart';
import '../../../buy/presentation/widgets/customer_selector.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _bagsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SellCubit>().initialize();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _bagsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SellCubit, SellState>(
      listener: (context, state) {
        if (state.status == SellStatus.success &&
            state.generatedInvoiceId != null) {
          _showSuccessDialog(context, state);
        }

        // Auto-fill price when stock item is selected via dropdown
        if (state.selectedStockItem != null) {
          final p =
              state.selectedStockItem!.sellingPricePerKg?.toStringAsFixed(2) ??
                  '';
          if (_priceController.text != p && _priceController.text.isEmpty) {
            _priceController.text = p;
            context.read<SellCubit>().updatePrice(double.tryParse(p) ?? 0);
          }
        }

        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error),
          );
          context.read<SellCubit>().clearError();
        }
      },
      builder: (context, state) {
        return LoadingOverlay(
          isLoading: state.status == SellStatus.processing,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: _buildAppBar(state),
            body: _buildBody(state),
            bottomNavigationBar: state.currentStep == SellStep.review
                ? _buildReviewBottomBar(state)
                : null,
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(SellState state) {
    return AppBar(
      backgroundColor: AppColors.cardSell,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.white),
        onPressed: () {
          if (state.currentStep == SellStep.review) {
            context.read<SellCubit>().goBackToItems();
          } else {
            context.goNamed('dashboard');
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.currentStep == SellStep.review
                ? 'Review Sale'
                : 'Sell / Sales',
            style: AppTextStyles.titleMedium
                .copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            'විකුණුම්',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(SellState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Customer Selector (Buyer)
          CustomerSelector(
            title: 'Buyer',
            subtitle: 'පාරිභෝගිකයා (මිලදී ගන්නා)',
            color: AppColors.cardSell,
            colorDark: AppColors.cardSellDark,
            selectedCustomer: state.selectedCustomer,
            onCustomerSelected: (customer) =>
                context.read<SellCubit>().selectCustomer(customer),
            onAddNewCustomer: () => context.pushNamed('sellAddCustomer'),
            onChangeCustomer: () => context.read<SellCubit>().clearCustomer(),
            showBalance: false,
          ),
          const SizedBox(height: 20),

          // 2. Sell Details Section (Modeled after Buy Details)
          if (state.selectedCustomer != null) ...[
            _buildSellDetailsSection(state),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildSellDetailsSection(SellState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sell Details',
            style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          // Item Type Selector
          DropdownButtonFormField<ItemType>(
            initialValue: state.selectedItemType,
            decoration: InputDecoration(
              labelText: 'Item Type',
              prefixIcon: const Icon(Icons.category, color: AppColors.cardSell),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppColors.cardSell, width: 1)),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: const [
              DropdownMenuItem(
                value: ItemType.paddy,
                child: Text('Paddy'),
              ),
              DropdownMenuItem(
                value: ItemType.rice,
                child: Text('Rice'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                context.read<SellCubit>().updateItemType(value);
              }
            },
          ),
          const SizedBox(height: 16),
          // Variety Dropdown (Sourced from Stock)
          DropdownButtonFormField<StockItemModel>(
            initialValue: state.selectedStockItem,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Select Variety from Stock',
              prefixIcon: const Icon(Icons.grass, color: AppColors.cardSell),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppColors.cardSell, width: 1)),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.cardSell),
            items: state.availableStock.map((StockItemModel item) {
              return DropdownMenuItem<StockItemModel>(
                value: item,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.itemName} (${item.currentQuantity}kg avail)',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                context.read<SellCubit>().selectStockItem(value);
                _priceController
                    .clear(); // Clear so it auto-fills with new item price
              }
            },
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
              labelText: 'Selling Price (Rs/kg)',
              prefixIcon:
                  const Icon(Icons.payments_outlined, color: AppColors.success),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (v) =>
                context.read<SellCubit>().updatePrice(double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 16),

          // Total Weight
          TextFormField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.cardSell),
            decoration: InputDecoration(
              labelText: 'Total Weight to Sell',
              suffixText: 'kg',
              prefixIcon:
                  const Icon(Icons.scale_outlined, color: AppColors.cardSell),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (v) => context
                .read<SellCubit>()
                .updateQuantity(double.tryParse(v) ?? 0),
          ),
          const SizedBox(height: 16),

          // Auto-calculated Bag Info (Visual only, managed by Cubit)
          if (state.inputQuantity > 0 && state.selectedStockItem != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Note: Approx. ${((state.inputQuantity / (state.selectedStockItem!.currentQuantity / state.selectedStockItem!.currentBags))).round().clamp(1, state.selectedStockItem!.currentBags)} bags will be deducted.',
                style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),

          // Add / Complete Action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (state.inputQuantity > 0 && state.inputPrice > 0)
                  ? () => context.read<SellCubit>().quickSell()
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardSell,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('COMPLETE SALE',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewBottomBar(SellState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5))
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
                  const Text('Grand Total',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text('Rs. ${state.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppColors.cardSell)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.read<SellCubit>().finalizeSale(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Finalize',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, SellState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.check_circle,
                  color: AppColors.success, size: 64),
            ),
            const SizedBox(height: 24),
            const Text('Sale Complete!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<SellCubit>().resetForNewSale();
                _priceController.clear();
                _weightController.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardSell,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child:
                  const Text('NEW SALE', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => context.goNamed('dashboard'),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

