import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/shared_widgets/h_app_bar.dart';
import '../../../../core/shared_widgets/app_fab.dart';
import '../../../../core/shared_widgets/confirmation_dialog.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../routes/route_names.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../../domain/entities/expense_entity.dart';
import '../cubit/expenses_cubit.dart';
import '../cubit/expenses_state.dart';

class ExpensesListScreen extends StatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  State<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends State<ExpensesListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ExpensesCubit>().loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    context.select((ProfileCubit c) => c.state.language);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HAppBar(
        title: SiStrings.expenses,
        subtitle: SiStrings.operationalExpenses,
        onBack: () => context.go(RouteNames.home),
        onRefresh: () => context.read<ExpensesCubit>().loadExpenses(),
      ),
      body: BlocBuilder<ExpensesCubit, ExpensesState>(
        builder: (context, state) {
          if (state.status == ExpensesStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildSummaryHeader(state),
              _buildCategoryFilter(state),
              Expanded(
                child: state.expenses.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: state.expenses.length,
                        itemBuilder: (context, index) {
                          final expense = state.expenses[index];
                          return _buildExpenseCard(expense);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: AppFab(
        label: SiStrings.addExpense,
        onPressed: () => context.pushNamed('expenseAdd'),
      ),
    );
  }

  Widget _buildCategoryFilter(ExpensesState state) {
    return Container(
      height: 54,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(
            label: SiStrings.all,
            isSelected: state.filterCategory == null,
            onSelected: () =>
                context.read<ExpensesCubit>().filterByCategory(null),
          ),
          const SizedBox(width: 8),
          ...ExpenseCategory.values.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(
                  label: cat.displayNameLocal,
                  isSelected: state.filterCategory == cat,
                  onSelected: () =>
                      context.read<ExpensesCubit>().filterByCategory(cat),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildSummaryHeader(ExpensesState state) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: AppColors.error, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(SiStrings.totalMonthlyExpenses,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(
                'Rs. ${state.totalMonthlyExpenses.toStringAsFixed(0)}',
                style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.error, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseEntity expense) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: InkWell(
        onLongPress: () => _showDeleteConfirmation(expense.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(expense.category.icon,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${expense.category.displayNameLocal} • ${DateFormat('yyyy-MM-dd').format(expense.date)}',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs. ${expense.amount.toStringAsFixed(0)}',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (expense.notes != null && expense.notes!.isNotEmpty)
                    Text(
                      SiStrings.hasNote,
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade400),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(SiStrings.noExpensesFound,
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String id) async {
    final confirmed = await ConfirmationDialog.showDelete(
      context,
      title: SiStrings.deleteExpenseConfirm,
      itemName: SiStrings.expenseRecord,
    );
    if (confirmed && mounted) {
      context.read<ExpensesCubit>().deleteExpense(id);
    }
  }
}
