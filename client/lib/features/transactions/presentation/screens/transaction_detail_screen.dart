import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/enums.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../domain/repositories/transaction_repository.dart';
import '../../../../injection_container.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  TransactionModel? _transaction;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = sl<TransactionRepository>();
      final result = await repo.getFullTransactionById(widget.transactionId);
      
      if (mounted) {
        result.fold(
          (failure) => setState(() {
            _error = failure.message;
            _isLoading = false;
          }),
          (model) => setState(() {
            _transaction = model;
            _isLoading = false;
          }),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_transaction?.transactionNumber ?? 'Transaction Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_transaction != null)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () {
                // TODO: Implement printing
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildTransactionDetails(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(_error!, style: AppTextStyles.bodyLarge),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _loadTransaction, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails() {
    if (_transaction == null) return const Center(child: Text('No data found'));
    final t = _transaction!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusHeader(t),
          const SizedBox(height: 20),
          _buildCustomerCard(t),
          const SizedBox(height: 20),
          _buildItemsCard(t),
          const SizedBox(height: 20),
          _buildPaymentSummary(t),
          const SizedBox(height: 20),
          if (t.notes != null && t.notes!.isNotEmpty) _buildNotesCard(t),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(TransactionModel t) {
    final isBuy = t.type == TransactionType.buy;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isBuy ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isBuy ? AppColors.error.withOpacity(0.2) : AppColors.success.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isBuy ? Icons.arrow_downward : Icons.arrow_upward,
            color: isBuy ? AppColors.error : AppColors.success,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBuy ? 'Purchase Order' : 'Sales Invoice',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('dd MMMM yyyy, hh:mm a').format(t.transactionDate),
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(t.status),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              t.status.name.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(TransactionModel t) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Customer Information', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            Text(t.customerName ?? 'Walk-in Customer', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            if (t.customerPhone != null) Text(t.customerPhone!, style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(TransactionModel t) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.list_alt, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Itemized List', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 0),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: t.items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = t.items[index];
              return ListTile(
                title: Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${item.bags} bags • ${item.quantity.toStringAsFixed(2)} kg'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Rs. ${item.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('@ Rs. ${item.pricePerKg.toStringAsFixed(2)}/kg', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 0),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Weight', style: AppTextStyles.bodyMedium),
                Text('${t.totalWeight.toStringAsFixed(2)} kg', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(TransactionModel t) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payments_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Payment Summary', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            _buildAmountRow('Subtotal', t.subtotal),
            if (t.discount > 0) _buildAmountRow('Discount', -t.discount, color: AppColors.error),
            const Divider(),
            _buildAmountRow('Total Amount', t.totalAmount, isBold: true),
            _buildAmountRow('Amount Paid', t.paidAmount, color: AppColors.success),
            const Divider(),
            _buildAmountRow(
              t.dueAmount > 0 ? 'Balance Due' : 'Change Given',
              t.dueAmount.abs(),
              isBold: true,
              color: t.dueAmount > 0 ? AppColors.error : AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            'Rs. ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(TransactionModel t) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Notes', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(t.notes!, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed: return AppColors.success;
      case TransactionStatus.pending: return AppColors.warning;
      case TransactionStatus.cancelled: return AppColors.error;
      default: return Colors.grey;
    }
  }
}