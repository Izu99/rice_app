import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../data/models/company_model.dart';

abstract class AdminRepository {
  Future<Either<Failure, Map<String, dynamic>>> getDashboardStats();
  Future<Either<Failure, List<CompanyModel>>> getAllCompanies();
  Future<Either<Failure, CompanyModel>> createCompany({
    required String name,
    required String ownerName,
    required String email,
    required String phone,
    required String password,
    String? address,
    String? registrationNumber,
  });
  Future<Either<Failure, CompanyModel>> updateCompany(CompanyModel company);
  Future<Either<Failure, bool>> updateCompanyStatus(
      String companyId, String status);
  Future<Either<Failure, bool>> deleteCompany(String companyId);
  Future<Either<Failure, bool>> resetCompanyPassword(
      String companyId, String newPassword);
}
