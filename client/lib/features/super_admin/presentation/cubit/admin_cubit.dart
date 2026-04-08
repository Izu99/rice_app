import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
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

    // Load both stats and companies list in parallel
    final results = await Future.wait([
      _adminRepository.getDashboardStats(),
      _adminRepository.getAllCompanies(),
    ]);

    // Cast results to their specific types
    final statsResult = results[0] as Either<Failure, Map<String, dynamic>>;
    final companiesResult = results[1] as Either<Failure, List<CompanyModel>>;

    statsResult.fold(
      (failure) => emit(state.copyWith(
        status: AdminStatus.error,
        errorMessage: failure.message,
      )),
      (statsMap) {
        final stats = AdminDashboardStats.fromJson(statsMap);

        companiesResult.fold(
          (failure) => emit(state.copyWith(
            status: AdminStatus.loaded,
            dashboardStats: stats,
          )),
          (companies) => emit(state.copyWith(
            status: AdminStatus.loaded,
            dashboardStats: stats,
            allCompanies: companies,
            filteredCompanies: _applyFilters(
                companies, state.currentFilter, state.searchQuery),
          )),
        );
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
    await loadDashboard();
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
    String? district,
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
      district: district,
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

  /// Update company details (optimistic)
  Future<bool> updateCompany(CompanyModel company) async {
    final previousList = state.allCompanies;

    // Update UI immediately
    final optimisticList =
        previousList.map((c) => c.id == company.id ? company : c).toList();
    emit(state.copyWith(
      allCompanies: optimisticList,
      filteredCompanies:
          _applyFilters(optimisticList, state.currentFilter, state.searchQuery),
      selectedCompany: company,
    ));

    final result = await _adminRepository.updateCompany(company);

    return result.fold(
      (failure) {
        // Revert on failure
        emit(state.copyWith(
          status: AdminStatus.error,
          allCompanies: previousList,
          filteredCompanies: _applyFilters(
              previousList, state.currentFilter, state.searchQuery),
          errorMessage: failure.message,
        ));
        return false;
      },
      (updatedCompany) {
        // Replace optimistic copy with server-confirmed version
        final confirmedList = state.allCompanies
            .map((c) => c.id == company.id ? updatedCompany : c)
            .toList();
        emit(state.copyWith(
          status: AdminStatus.success,
          allCompanies: confirmedList,
          filteredCompanies: _applyFilters(
              confirmedList, state.currentFilter, state.searchQuery),
          selectedCompany: updatedCompany,
          successMessage: 'Company updated successfully!',
        ));
        return true;
      },
    );
  }

  /// Update company status (optimistic)
  Future<bool> updateCompanyStatus(
      String companyId, CompanyStatus newStatus) async {
    final previousList = state.allCompanies;

    // Update UI immediately
    final optimisticList = previousList
        .map((c) => c.id == companyId
            ? c.copyWith(status: newStatus, updatedAt: DateTime.now())
            : c)
        .toList();
    emit(state.copyWith(
      allCompanies: optimisticList,
      filteredCompanies:
          _applyFilters(optimisticList, state.currentFilter, state.searchQuery),
    ));

    final result =
        await _adminRepository.updateCompanyStatus(companyId, newStatus.name);

    return result.fold(
      (failure) {
        // Revert on failure
        Log.e('Failed to update status for $companyId',
            error: failure.message, tag: 'COMPANY');
        emit(state.copyWith(
          status: AdminStatus.error,
          allCompanies: previousList,
          filteredCompanies: _applyFilters(
              previousList, state.currentFilter, state.searchQuery),
          errorMessage: failure.message,
        ));
        return false;
      },
      (success) {
        Log.s('Status updated for $companyId to ${newStatus.name}',
            tag: 'COMPANY');
        emit(state.copyWith(
          status: AdminStatus.success,
          successMessage: 'Company status updated to ${newStatus.displayName}!',
        ));
        return true;
      },
    );
  }

  /// Delete company (optimistic)
  Future<bool> deleteCompany(String companyId) async {
    final previousList = state.allCompanies;

    // Remove from UI immediately
    final optimisticList =
        previousList.where((c) => c.id != companyId).toList();
    emit(state.copyWith(
      allCompanies: optimisticList,
      filteredCompanies:
          _applyFilters(optimisticList, state.currentFilter, state.searchQuery),
      clearSelectedCompany: true,
    ));

    final result = await _adminRepository.deleteCompany(companyId);

    return result.fold(
      (failure) {
        // Revert on failure
        emit(state.copyWith(
          status: AdminStatus.error,
          allCompanies: previousList,
          filteredCompanies: _applyFilters(
              previousList, state.currentFilter, state.searchQuery),
          errorMessage: failure.message,
        ));
        return false;
      },
      (success) {
        emit(state.copyWith(
          status: AdminStatus.success,
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

  /// Reset admin state (on logout)
  void reset() {
    emit(AdminState.initial());
  }
}
