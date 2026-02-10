import 'package:equatable/equatable.dart';
import '../../../../data/models/company_model.dart';

enum AdminStatus {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  success,
  error
}

enum CompanyFilter { all, active, inactive, pending }

/// Admin credentials for newly created company admin
class AdminCredentials extends Equatable {
  final String email;
  final String phone;
  final String password;
  final String name;
  final String role;

  const AdminCredentials({
    required this.email,
    required this.phone,
    required this.password,
    required this.name,
    required this.role,
  });

  @override
  List<Object?> get props => [email, phone, password, name, role];
}

class AdminState extends Equatable {
  final AdminStatus status;
  final List<CompanyModel> allCompanies;
  final List<CompanyModel> filteredCompanies;
  final CompanyFilter currentFilter;
  final String searchQuery;
  final CompanyModel? selectedCompany;
  final AdminDashboardStats? dashboardStats;
  final String? errorMessage;
  final String? successMessage;
  final bool isRefreshing;
  final AdminCredentials? lastCreatedAdminCredentials;

  const AdminState({
    this.status = AdminStatus.initial,
    this.allCompanies = const [],
    this.filteredCompanies = const [],
    this.currentFilter = CompanyFilter.all,
    this.searchQuery = '',
    this.selectedCompany,
    this.dashboardStats,
    this.errorMessage,
    this.successMessage,
    this.isRefreshing = false,
    this.lastCreatedAdminCredentials,
  });

  // Computed properties
  int get totalCompanies => allCompanies.length;
  int get activeCompanies =>
      allCompanies.where((c) => c.status == CompanyStatus.active).length;
  int get inactiveCompanies =>
      allCompanies.where((c) => c.status == CompanyStatus.inactive).length;
  int get pendingCompanies =>
      allCompanies.where((c) => c.status == CompanyStatus.pending).length;

  AdminState copyWith({
    AdminStatus? status,
    List<CompanyModel>? allCompanies,
    List<CompanyModel>? filteredCompanies,
    CompanyFilter? currentFilter,
    String? searchQuery,
    CompanyModel? selectedCompany,
    AdminDashboardStats? dashboardStats,
    String? errorMessage,
    String? successMessage,
    bool? isRefreshing,
    AdminCredentials? lastCreatedAdminCredentials,
    bool clearSelectedCompany = false,
    bool clearMessages = false,
  }) {
    return AdminState(
      status: status ?? this.status,
      allCompanies: allCompanies ?? this.allCompanies,
      filteredCompanies: filteredCompanies ?? this.filteredCompanies,
      currentFilter: currentFilter ?? this.currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCompany: clearSelectedCompany
          ? null
          : (selectedCompany ?? this.selectedCompany),
      dashboardStats: dashboardStats ?? this.dashboardStats,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastCreatedAdminCredentials:
          lastCreatedAdminCredentials ?? this.lastCreatedAdminCredentials,
    );
  }

  @override
  List<Object?> get props => [
        status,
        allCompanies,
        filteredCompanies,
        currentFilter,
        searchQuery,
        selectedCompany,
        dashboardStats,
        errorMessage,
        successMessage,
        isRefreshing,
        lastCreatedAdminCredentials,
      ];
}

/// Dashboard statistics for super admin
class AdminDashboardStats extends Equatable {
  final int totalCompanies;
  final int activeCompanies;
  final int inactiveCompanies;
  final int pendingCompanies;
  final int totalUsers;
  final int todayTransactions;
  final double totalRevenue;
  final List<CompanyModel> recentCompanies;
  final Map<String, int> companiesPerMonth;

  const AdminDashboardStats({
    this.totalCompanies = 0,
    this.activeCompanies = 0,
    this.inactiveCompanies = 0,
    this.pendingCompanies = 0,
    this.totalUsers = 0,
    this.todayTransactions = 0,
    this.totalRevenue = 0.0,
    this.recentCompanies = const [],
    this.companiesPerMonth = const {},
  });

  factory AdminDashboardStats.fromCompanies(List<CompanyModel> companies) {
    return AdminDashboardStats(
      totalCompanies: companies.length,
      activeCompanies:
          companies.where((c) => c.status == CompanyStatus.active).length,
      inactiveCompanies:
          companies.where((c) => c.status == CompanyStatus.inactive).length,
      pendingCompanies:
          companies.where((c) => c.status == CompanyStatus.pending).length,
      recentCompanies: companies.take(5).toList(),
    );
  }

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      totalCompanies: json['totalCompanies'] ?? 0,
      activeCompanies: json['activeCompanies'] ?? 0,
      inactiveCompanies: json['inactiveCompanies'] ?? 0,
      pendingCompanies: json['pendingCompanies'] ?? 0,
      totalUsers: json['totalUsers'] ?? 0,
      todayTransactions: json['totalTransactionsToday'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      recentCompanies: json['recentCompanies'] != null
          ? (json['recentCompanies'] as List)
              .map((c) => CompanyModel.fromJson(c))
              .toList()
          : [],
      companiesPerMonth: Map<String, int>.from(json['companiesPerMonth'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        totalCompanies,
        activeCompanies,
        inactiveCompanies,
        pendingCompanies,
        totalUsers,
        todayTransactions,
        totalRevenue,
        recentCompanies,
        companiesPerMonth,
      ];
}
