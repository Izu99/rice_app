import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/expense_model.dart';

class RecentExpenses extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final bool isLoading;

  const RecentExpenses({
    super.key,
    required this.expenses,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoadingState();
    if (expenses.isEmpty) return _buildEmptyState();

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
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: expenses.length,
        separatorBuilder: (context, index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 1,
          color: const Color(0xFFF0F0F5),
        ),
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return InkWell(
            onTap: () => context.push('/expenses'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withOpacity(0.12),
                        width: 1,
                      ),
                    ),
                    child: Icon(expense.category.icon,
                        color: AppColors.warning, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C2E),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM, yyyy').format(expense.date),
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '-Rs. ${expense.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.error,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
  
  Widget _buildEmptyState() => Container(
    padding: const EdgeInsets.all(20),
    child: Center(child: Text('No recent expenses', style: TextStyle(color: Colors.grey.shade400))),
  );
}
