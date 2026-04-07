import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/remote/expense_remote_ds.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource remoteDataSource;

  ExpenseRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ExpenseEntity>>> getExpenses({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
  }) async {
    try {
      final models = await remoteDataSource.getExpenses(
        category: category,
        startDate: startDate,
        endDate: endDate,
        page: page,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpenseEntity>> createExpense(ExpenseEntity expense) async {
    try {
      final model = await remoteDataSource.createExpense(
        ExpenseModel(
          id: expense.id,
          title: expense.title,
          category: expense.category,
          amount: expense.amount,
          date: expense.date,
          notes: expense.notes,
        ),
      );
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getExpenseSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final summary = await remoteDataSource.getExpenseSummary(
        startDate: startDate,
        endDate: endDate,
      );
      return Right(summary);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteExpense(String id) async {
    try {
      final success = await remoteDataSource.deleteExpense(id);
      return Right(success);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
