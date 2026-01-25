import '../../../core/network/api_service.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../models/company_model.dart';

abstract class AdminRemoteDataSource {
  Future<Map<String, dynamic>> getDashboardStats();
  Future<List<CompanyModel>> getAllCompanies();
  Future<CompanyModel> createCompany({
    required String name,
    required String ownerName,
    required String email,
    required String phone,
    required String password,
    String? address,
    String? registrationNumber,
  });
  Future<CompanyModel> updateCompany(CompanyModel company);
  Future<bool> updateCompanyStatus(String companyId, String status);
  Future<bool> deleteCompany(String companyId);
  Future<bool> resetCompanyPassword(String companyId, String newPassword);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final ApiService apiService;

  AdminRemoteDataSourceImpl({required this.apiService});

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    final either = await apiService.get(ApiEndpoints.dashboardStats);
    return either.fold(
      (failure) => throw _mapFailureToException(failure),
      (response) {
        if (response.success && response.data != null) {
          return response.data;
        }
        throw ServerException(
            message: response.message ?? 'Failed to load stats');
      },
    );
  }

  @override
  Future<List<CompanyModel>> getAllCompanies() async {
    final either = await apiService.get(ApiEndpoints.companies);
    return either.fold(
      (failure) => throw _mapFailureToException(failure),
      (response) {
        if (response.success && response.data != null) {
          final List<dynamic> companiesJson = response.data['companies'] ?? [];
          return companiesJson
              .map(
                  (json) => CompanyModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        throw ServerException(
            message: response.message ?? 'Failed to load companies');
      },
    );
  }

  @override
  Future<CompanyModel> createCompany({
    required String name,
    required String ownerName,
    required String email,
    required String phone,
    required String password,
    String? address,
    String? registrationNumber,
  }) async {
    final either = await apiService.post(
      ApiEndpoints.companies,
      data: {
        'name': name,
        'ownerName': ownerName,
        'email': email,
        'phone': phone,
        'password': password,
        'address': address,
        'registrationNumber': registrationNumber,
      },
    );
    return either.fold(
      (failure) => throw _mapFailureToException(failure),
      (response) {
        if (response.success && response.data != null) {
          return CompanyModel.fromJson(response.data['company']);
        }
        throw ServerException(
            message: response.message ?? 'Failed to create company');
      },
    );
  }

  @override
  Future<CompanyModel> updateCompany(CompanyModel company) async {
    final either = await apiService.put(
      '${ApiEndpoints.companies}/${company.id}',
      data: company.toJson(),
    );
    return either.fold(
      (failure) => throw _mapFailureToException(failure),
      (response) {
        if (response.success && response.data != null) {
          return CompanyModel.fromJson(response.data['company']);
        }
        throw ServerException(
            message: response.message ?? 'Failed to update company');
      },
    );
  }

  @override
  Future<bool> updateCompanyStatus(String companyId, String status) async {
    final either = await apiService.patch(
      '${ApiEndpoints.companies}/$companyId/status',
      data: {'status': status},
    );
    return either.fold(
      (failure) => throw _mapFailureToException(failure),
      (response) => response.success,
    );
  }

  @override
  Future<bool> deleteCompany(String companyId) async {
    final either =
        await apiService.delete('${ApiEndpoints.companies}/$companyId');
    return either.fold(
      (failure) => throw _mapFailureToException(failure),
      (response) => response.success,
    );
  }

  @override
  Future<bool> resetCompanyPassword(
      String companyId, String newPassword) async {
    final either = await apiService.post(
      '${ApiEndpoints.companies}/$companyId/reset-password',
      data: {'newPassword': newPassword},
    );
    return either.fold(
      (failure) => throw _mapFailureToException(failure),
      (response) => response.success,
    );
  }

  Exception _mapFailureToException(Failure failure) {
    if (failure is NetworkFailure) {
      return NetworkException(message: failure.message);
    } else if (failure is ServerFailure) {
      return ServerException(
          message: failure.message, statusCode: failure.code);
    } else if (failure is AuthFailure) {
      return AuthException(message: failure.message, statusCode: failure.code);
    } else {
      return ServerException(message: failure.message);
    }
  }
}

