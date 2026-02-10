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
      (failure) => emit(state.copyWith(status: ExpensesStatus.error, errorMessage: failure.message)),
      (expenses) {
        summaryResult.fold(
          (l) => emit(state.copyWith(status: ExpensesStatus.loaded, expenses: expenses)),
          (summary) {
            final Map<String, double> breakdown = {};
            if (summary['categoryBreakdown'] != null) {
              for (var item in summary['categoryBreakdown']) {
                breakdown[item['_id']] = (item['totalAmount'] as num).toDouble();
              }
            }

            emit(state.copyWith(
              status: ExpensesStatus.loaded,
              expenses: expenses,
              totalMonthlyExpenses: (summary['totalExpenses'] as num?)?.toDouble() ?? 0.0,
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
      (failure) => emit(state.copyWith(status: ExpensesStatus.error, errorMessage: failure.message)),
      (newExpense) {
        emit(state.copyWith(status: ExpensesStatus.success));
        loadExpenses();
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
    final result = await _repository.deleteExpense(id);
    result.fold(
      (failure) => emit(state.copyWith(status: ExpensesStatus.error, errorMessage: failure.message)),
      (success) => loadExpenses(),
    );
  }

  void resetStatus() {
    emit(state.copyWith(status: ExpensesStatus.loaded));
  }
}
