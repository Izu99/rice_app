// lib/features/home/presentation/widgets/recent_transactions.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/transaction_model.dart';

/// Recent transactions list widget
class RecentTransactions extends StatelessWidget {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final int maxItems;
  final VoidCallback? onViewAll;

  const RecentTransactions({
    super.key,
    required this.transactions,
    this.isLoading = false,
    this.maxItems = 5,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (transactions.isEmpty) {
      return _buildEmptyState();
    }

    final displayTransactions = transactions.take(maxItems).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE8E8EE), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Transaction list
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayTransactions.length,
            separatorBuilder: (context, index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 1,
              color: const Color(0xFFF0F0F5),
            ),
            itemBuilder: (context, index) {
              return TransactionListItem(
                transaction: displayTransactions[index],
                onTap: () {
                  context.pushNamed(
                    'transactionDetail',
                    pathParameters: {'id': displayTransactions[index].id},
                  );
                },
              );
            },
          ),

          // View all button
          if (transactions.length > maxItems) ...[
            Container(
              height: 1,
              color: const Color(0xFFF0F0F5),
            ),
            Material(
              color: const Color(0xFFF9FAFC),
              child: InkWell(
                onTap: onViewAll ?? () => context.push('/reports'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Detailed History',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppColors.primary,
                          size: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.divider.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.divider.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.divider.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No transactions yet',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your recent transactions will appear here',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Individual transaction list item
class TransactionListItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final bool showDate;
  final bool compact;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.showDate = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isBuy = transaction.type == TransactionType.buy;
    final color = isBuy ? AppColors.error : AppColors.success;
    final icon = isBuy ? Icons.call_received_rounded : Icons.call_made_rounded;
    final typeLabel = isBuy ? 'Buy' : 'Sell';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: compact ? 12 : 16,
        ),
        child: Row(
          children: [
            // Icon with subtle background
            Container(
              width: compact ? 40 : 48,
              height: compact ? 40 : 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: compact ? 20 : 24,
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.customerName ?? 'Walk-in Customer',
                    style: TextStyle(
                      fontSize: compact ? 13 : 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1C1C2E),
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(transaction.transactionDate),
                        style: const TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatAmount(transaction.totalAmount),
                  style: TextStyle(
                    fontSize: compact ? 14 : 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1C1C2E),
                    letterSpacing: -0.3,
                  ),
                ),
                if (transaction.dueAmount > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'DUE: ${_formatAmount(transaction.dueAmount)}',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                else
                  Text(
                    transaction.transactionNumber,
                    style: const TextStyle(
                      color: Color(0xFFAEB0B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txnDate = DateTime(date.year, date.month, date.day);

    if (txnDate == today) {
      return DateFormat('HH:mm').format(date);
    } else if (txnDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEE').format(date);
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  String _formatAmount(double amount) {
    return NumberFormatter.formatCurrency(amount);
  }
}

/// Transaction group by date
class TransactionGroup extends StatelessWidget {
  final String title;
  final List<TransactionModel> transactions;
  final void Function(TransactionModel)? onTransactionTap;

  const TransactionGroup({
    super.key,
    required this.title,
    required this.transactions,
    this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return TransactionListItem(
                transaction: transactions[index],
                showDate: false,
                onTap: onTransactionTap != null
                    ? () => onTransactionTap!(transactions[index])
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
