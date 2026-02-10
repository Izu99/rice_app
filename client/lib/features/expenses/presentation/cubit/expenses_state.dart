import 'package:equatable/equatable.dart';
import '../../../../domain/entities/expense_entity.dart';
import '../../../../core/constants/enums.dart';

enum ExpensesStatus { initial, loading, loaded, error, submitting, success }

class ExpensesState extends Equatable {
  final ExpensesStatus status;
  final List<ExpenseEntity> expenses;
  final String? errorMessage;
  final double totalMonthlyExpenses;
  final Map<String, double> categoryBreakdown;
  final ExpenseCategory? filterCategory;

  const ExpensesState({
    this.status = ExpensesStatus.initial,
    this.expenses = const [],
    this.errorMessage,
    this.totalMonthlyExpenses = 0,
    this.categoryBreakdown = const {},
    this.filterCategory,
  });

  ExpensesState copyWith({
    ExpensesStatus? status,
    List<ExpenseEntity>? expenses,
    String? errorMessage,
    double? totalMonthlyExpenses,
    Map<String, double>? categoryBreakdown,
    ExpenseCategory? filterCategory,
    bool clearCategory = false,
  }) {
    return ExpensesState(
      status: status ?? this.status,
      expenses: expenses ?? this.expenses,
      errorMessage: errorMessage ?? this.errorMessage,
      totalMonthlyExpenses: totalMonthlyExpenses ?? this.totalMonthlyExpenses,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      filterCategory: clearCategory ? null : (filterCategory ?? this.filterCategory),
    );
  }

  @override
  List<Object?> get props => [
    status, 
    expenses, 
    errorMessage, 
    totalMonthlyExpenses, 
    categoryBreakdown, 
    filterCategory
  ];
}
