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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: expenses.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.divider.withOpacity(0.5)),
        itemBuilder: (context, index) {
          final expense = expenses[index];
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(expense.category.icon, color: AppColors.warning, size: 20),
            ),
            title: Text(expense.title, style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('dd MMM').format(expense.date), style: AppTextStyles.labelSmall),
            trailing: Text(
              '-Rs. ${expense.amount.toStringAsFixed(0)}',
              style: AppTextStyles.titleSmall.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
            ),
            onTap: () => context.push('/expenses'),
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
