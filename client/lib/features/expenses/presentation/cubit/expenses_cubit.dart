import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/enums.dart';
import '../../../../domain/entities/expense_entity.dart';
import '../../../../domain/repositories/expense_repository.dart';
import 'expenses_state.dart';

class ExpensesCubit extends Cubit<ExpensesState> {
  final ExpenseRepository _repository;

  ExpensesCubit({required ExpenseRepository repository})
      : _repository = repository,
        super(const ExpensesState());

  Future<void> loadExpenses() async {
    emit(state.copyWith(status: ExpensesStatus.loading));

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    final result = await _repository.getExpenses(
      category: state.filterCategory?.value,
    );

    final summaryResult = await _repository.getExpenseSummary(
      startDate: firstDayOfMonth,
    );

    result.fold(
      (failure) => emit(state.copyWith(
          status: ExpensesStatus.error, errorMessage: failure.message)),
      (expenses) {
        summaryResult.fold(
          (l) => emit(state.copyWith(
              status: ExpensesStatus.loaded, expenses: expenses)),
          (summary) {
            final Map<String, double> breakdown = {};
            if (summary['categoryBreakdown'] != null) {
              for (var item in summary['categoryBreakdown']) {
                breakdown[item['_id']] =
                    (item['totalAmount'] as num).toDouble();
              }
            }

            emit(state.copyWith(
              status: ExpensesStatus.loaded,
              expenses: expenses,
              totalMonthlyExpenses:
                  (summary['totalExpenses'] as num?)?.toDouble() ?? 0.0,
              categoryBreakdown: breakdown,
            ));
          },
        );
      },
    );
  }

  Future<void> addExpense({
    required String title,
    required ExpenseCategory category,
    required double amount,
    required DateTime date,
    String? notes,
  }) async {
    emit(state.copyWith(status: ExpensesStatus.submitting));

    final expense = ExpenseEntity(
      id: '',
      title: title,
      category: category,
      amount: amount,
      date: date,
      notes: notes,
    );

    final result = await _repository.createExpense(expense);

    result.fold(
      (failure) => emit(state.copyWith(
          status: ExpensesStatus.error, errorMessage: failure.message)),
      (newExpense) {
        // Add to list immediately without a full reload
        final updatedExpenses = [newExpense, ...state.expenses];
        final updatedTotal = state.totalMonthlyExpenses + newExpense.amount;
        final updatedBreakdown =
            Map<String, double>.from(state.categoryBreakdown);
        updatedBreakdown[newExpense.category.value] =
            (updatedBreakdown[newExpense.category.value] ?? 0) +
                newExpense.amount;

        emit(state.copyWith(
          status: ExpensesStatus.success,
          expenses: updatedExpenses,
          totalMonthlyExpenses: updatedTotal,
          categoryBreakdown: updatedBreakdown,
        ));
      },
    );
  }

  void filterByCategory(ExpenseCategory? category) {
    if (category == null) {
      emit(state.copyWith(clearCategory: true));
    } else {
      emit(state.copyWith(filterCategory: category));
    }
    loadExpenses();
  }

  Future<void> deleteExpense(String id) async {
    final previousExpenses = state.expenses;
    final deleted = previousExpenses.firstWhere(
      (e) => e.id == id,
      orElse: () => ExpenseEntity.empty(),
    );

    // Remove from UI immediately
    final optimisticExpenses =
        previousExpenses.where((e) => e.id != id).toList();
    final updatedTotal = state.totalMonthlyExpenses - deleted.amount;
    final updatedBreakdown = Map<String, double>.from(state.categoryBreakdown);
    if (deleted.id.isNotEmpty) {
      updatedBreakdown[deleted.category.value] =
          ((updatedBreakdown[deleted.category.value] ?? 0) - deleted.amount)
              .clamp(0, double.infinity);
    }

    emit(state.copyWith(
      expenses: optimisticExpenses,
      totalMonthlyExpenses: updatedTotal < 0 ? 0 : updatedTotal,
      categoryBreakdown: updatedBreakdown,
    ));

    final result = await _repository.deleteExpense(id);
    result.fold(
      (failure) {
        // Revert on failure
        emit(state.copyWith(
          status: ExpensesStatus.error,
          expenses: previousExpenses,
          totalMonthlyExpenses: state.totalMonthlyExpenses,
          errorMessage: failure.message,
        ));
      },
      (_) => emit(state.copyWith(status: ExpensesStatus.loaded)),
    );
  }

  void resetStatus() {
    emit(state.copyWith(status: ExpensesStatus.loaded));
  }

  void reset() {
    emit(const ExpensesState());
  }
}
