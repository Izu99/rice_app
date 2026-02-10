import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/company_model.dart';
import '../../../../domain/repositories/admin_repository.dart';
import '../../../../core/utils/logger_utils.dart';
import 'admin_state.dart';

class AdminCubit extends Cubit<AdminState> {
  final AdminRepository _adminRepository;

  AdminCubit({required AdminRepository adminRepository})
      : _adminRepository = adminRepository,
        super(const AdminState());

  /// Load dashboard data
  Future<void> loadDashboard() async {
    emit(state.copyWith(status: AdminStatus.loading));

    final result = await _adminRepository.getDashboardStats();

    result.fold(
      (failure) => emit(state.copyWith(
        status: AdminStatus.error,
        errorMessage: failure.message,
      )),
      (statsMap) {
        final stats = AdminDashboardStats.fromJson(statsMap);
        emit(state.copyWith(
          status: AdminStatus.loaded,
          dashboardStats: stats,
          allCompanies: stats.recentCompanies,
          filteredCompanies: stats.recentCompanies,
        ));
      },
    );
  }

  /// Load all companies
  Future<void> loadCompanies() async {
    emit(state.copyWith(status: AdminStatus.loading));

    final result = await _adminRepository.getAllCompanies();

    result.fold(
      (failure) => emit(state.copyWith(
        status: AdminStatus.error,
        errorMessage: failure.message,
      )),
      (companies) => emit(state.copyWith(
        status: AdminStatus.loaded,
        allCompanies: companies,
        filteredCompanies:
            _applyFilters(companies, state.currentFilter, state.searchQuery),
      )),
    );
  }

  /// Refresh companies
  Future<void> refreshCompanies() async {
    emit(state.copyWith(isRefreshing: true));
    await loadCompanies();
    emit(state.copyWith(isRefreshing: false));
  }

  /// Filter companies by status
  void filterCompanies(CompanyFilter filter) {
    final filtered =
        _applyFilters(state.allCompanies, filter, state.searchQuery);
    emit(state.copyWith(
      currentFilter: filter,
      filteredCompanies: filtered,
    ));
  }

  /// Search companies
  void searchCompanies(String query) {
    final filtered =
        _applyFilters(state.allCompanies, state.currentFilter, query);
    emit(state.copyWith(
      searchQuery: query,
      filteredCompanies: filtered,
    ));
  }

  /// Apply filters and search
  List<CompanyModel> _applyFilters(
    List<CompanyModel> companies,
    CompanyFilter filter,
    String query,
  ) {
    var filtered = companies;

    // Apply status filter
    switch (filter) {
      case CompanyFilter.active:
        filtered =
            filtered.where((c) => c.status == CompanyStatus.active).toList();
        break;
      case CompanyFilter.inactive:
        filtered =
            filtered.where((c) => c.status == CompanyStatus.inactive).toList();
        break;
      case CompanyFilter.pending:
        filtered =
            filtered.where((c) => c.status == CompanyStatus.pending).toList();
        break;
      case CompanyFilter.all:
        break;
    }

    // Apply search query
    if (query.isNotEmpty) {
      filtered = filtered.where((c) {
        final searchLower = query.toLowerCase();
        return c.name.toLowerCase().contains(searchLower) ||
            (c.ownerName?.toLowerCase().contains(searchLower) ?? false) ||
            (c.email?.toLowerCase().contains(searchLower) ?? false) ||
            c.phone.contains(query) ||
            (c.address.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }

    return filtered;
  }

  /// Select a company for viewing/editing
  void selectCompany(CompanyModel company) {
    emit(state.copyWith(selectedCompany: company));
  }

  /// Clear selected company
  void clearSelectedCompany() {
    emit(state.copyWith(clearSelectedCompany: true));
  }

  /// Create new company
  Future<bool> createCompany({
    required String name,
    required String ownerName,
    required String email,
    required String phone,
    required String password,
    String? address,
    String? registrationNumber,
    String? logoUrl,
  }) async {
    Log.company('Creating new company: $name');
    emit(state.copyWith(status: AdminStatus.creating));

    final result = await _adminRepository.createCompany(
      name: name,
      ownerName: ownerName,
      email: email,
      phone: phone,
      password: password,
      address: address,
      registrationNumber: registrationNumber,
    );

    return result.fold(
      (failure) {
        Log.e('Failed to create company: $name',
            error: failure.message, tag: 'COMPANY');
        emit(state.copyWith(
          status: AdminStatus.error,
          errorMessage: failure.message,
        ));
        return false;
      },
      (company) {
        Log.s('Company "${company.name}" created successfully', tag: 'COMPANY');
        final List<CompanyModel> updatedList = [...state.allCompanies, company];
        emit(state.copyWith(
          status: AdminStatus.success,
          allCompanies: updatedList,
          filteredCompanies: _applyFilters(
              updatedList, state.currentFilter, state.searchQuery),
          successMessage: 'Company "${company.name}" created successfully!',
          lastCreatedAdminCredentials: AdminCredentials(
            email: email,
            phone: phone,
            password: password,
            name: ownerName,
            role: 'admin',
          ),
        ));
        return true;
      },
    );
  }

  /// Update company details
  Future<bool> updateCompany(CompanyModel company) async {
    emit(state.copyWith(status: AdminStatus.updating));

    final result = await _adminRepository.updateCompany(company);

    return result.fold(
      (failure) {
        emit(state.copyWith(
          status: AdminStatus.error,
          errorMessage: failure.message,
        ));
        return false;
      },
      (updatedCompany) {
        final List<CompanyModel> updatedList = state.allCompanies.map((c) {
          return c.id == company.id ? updatedCompany : c;
        }).toList();

        emit(state.copyWith(
          status: AdminStatus.success,
          allCompanies: updatedList,
          filteredCompanies: _applyFilters(
              updatedList, state.currentFilter, state.searchQuery),
          selectedCompany: updatedCompany,
          successMessage: 'Company updated successfully!',
        ));
        return true;
      },
    );
  }

  /// Update company status
  Future<bool> updateCompanyStatus(
      String companyId, CompanyStatus newStatus) async {
    emit(state.copyWith(status: AdminStatus.updating));

    final result =
        await _adminRepository.updateCompanyStatus(companyId, newStatus.name);

    return result.fold(
      (failure) {
        Log.e('Failed to update status for $companyId',
            error: failure.message, tag: 'COMPANY');
        emit(state.copyWith(
          status: AdminStatus.error,
          errorMessage: failure.message,
        ));
        return false;
      },
      (success) {
        Log.s('Status updated for $companyId to ${newStatus.name}',
            tag: 'COMPANY');
        final List<CompanyModel> updatedList = state.allCompanies.map((c) {
          return c.id == companyId
              ? c.copyWith(status: newStatus, updatedAt: DateTime.now())
              : c;
        }).toList();

        emit(state.copyWith(
          status: AdminStatus.success,
          allCompanies: updatedList,
          filteredCompanies: _applyFilters(
              updatedList, state.currentFilter, state.searchQuery),
          successMessage: 'Company status updated to ${newStatus.displayName}!',
        ));
        return true;
      },
    );
  }

  /// Delete company
  Future<bool> deleteCompany(String companyId) async {
    emit(state.copyWith(status: AdminStatus.deleting));

    final result = await _adminRepository.deleteCompany(companyId);

    return result.fold(
      (failure) {
        emit(state.copyWith(
          status: AdminStatus.error,
          errorMessage: failure.message,
        ));
        return false;
      },
      (success) {
        final List<CompanyModel> updatedList =
            state.allCompanies.where((c) => c.id != companyId).toList();

        emit(state.copyWith(
          status: AdminStatus.success,
          allCompanies: updatedList,
          filteredCompanies: _applyFilters(
              updatedList, state.currentFilter, state.searchQuery),
          clearSelectedCompany: true,
          successMessage: 'Company deleted successfully!',
        ));
        return true;
      },
    );
  }

  /// Reset company password
  Future<bool> resetCompanyPassword(
      String companyId, String newPassword) async {
    final result =
        await _adminRepository.resetCompanyPassword(companyId, newPassword);

    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        return false;
      },
      (success) {
        emit(state.copyWith(successMessage: 'Password reset successfully!'));
        return true;
      },
    );
  }

  /// Get company by ID
  CompanyModel? getCompanyById(String id) {
    try {
      return state.allCompanies.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear messages
  void clearMessages() {
    emit(state.copyWith(clearMessages: true));
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(clearMessages: true));
  }
}
