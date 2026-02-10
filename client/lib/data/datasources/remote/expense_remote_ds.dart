import '../../../core/network/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../models/expense_model.dart';

abstract class ExpenseRemoteDataSource {
  Future<List<ExpenseModel>> getExpenses({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
  });
  Future<ExpenseModel> createExpense(ExpenseModel expense);
  Future<Map<String, dynamic>> getExpenseSummary({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<bool> deleteExpense(String id);
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final ApiService apiService;

  ExpenseRemoteDataSourceImpl({required this.apiService});

  @override
  Future<List<ExpenseModel>> getExpenses({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
  }) async {
    final queryParams = {
      'page': page.toString(),
      if (category != null) 'category': category,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };

    final result = await apiService.get(
      ApiEndpoints.expenses,
      queryParameters: queryParams,
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (response) {
        final List<dynamic> list = response.data['expenses'] ?? [];
        return list.map((json) => ExpenseModel.fromJson(json)).toList();
      },
    );
  }

  @override
  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    final result = await apiService.post(
      ApiEndpoints.expenses,
      data: expense.toJson(),
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (response) => ExpenseModel.fromJson(response.data['expense']),
    );
  }

  @override
  Future<Map<String, dynamic>> getExpenseSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = {
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };

    final result = await apiService.get(
      ApiEndpoints.expenseSummary,
      queryParameters: queryParams,
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (response) => response.data,
    );
  }

  @override
  Future<bool> deleteExpense(String id) async {
    final result = await apiService.delete('${ApiEndpoints.expenses}/$id');
    return result.isRight();
  }
}
