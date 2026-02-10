import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../entities/expense_entity.dart';

abstract class ExpenseRepository {
  Future<Either<Failure, List<ExpenseEntity>>> getExpenses({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
  });
  Future<Either<Failure, ExpenseEntity>> createExpense(ExpenseEntity expense);
  Future<Either<Failure, Map<String, dynamic>>> getExpenseSummary({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, bool>> deleteExpense(String id);
}
