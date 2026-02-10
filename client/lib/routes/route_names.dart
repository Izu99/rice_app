/// Centralized route names for the entire application
/// Use these constants instead of hardcoding route paths
class RouteNames {
  RouteNames._();

  // ==================== Auth Routes ====================
  static const String splash = '/';
  static const String login = '/login';
  static const String landing = '/landing';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // ==================== Main App Routes ====================
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String detailedDashboard = '/home/detailed-dashboard';

  // ==================== Buy Module Routes ====================
  static const String buy = '/buy';
  static const String buyAddCustomer = '/buy/add-customer';
  static const String buyTransaction = '/buy/transaction';
  static const String buyReceipt = '/buy/receipt';

  // ==================== Sell Module Routes ====================
  static const String sell = '/sell';
  static const String sellProcess = '/sell/process';
  static const String sellAddCustomer = '/sell/add-customer';
  static const String sellTransaction = '/sell/transaction';
  static const String sellReceipt = '/sell/receipt';

  // ==================== Stock Routes ====================
  static const String stock = '/stock';
  static const String stockDetail = '/stock/detail';
  static const String stockEdit = '/stock/edit';
  static const String milling = '/stock/milling';
  static const String millingHistory = '/stock/milling/history';

  // ==================== Customer Routes ====================
  static const String customers = '/customers';
  static const String customerDetail = '/customers/detail';
  static const String customerAdd = '/customers/add';
  static const String customerEdit = '/customers/edit';

  // ==================== Reports Routes ====================
  static const String reports = '/reports';
  static const String dailyReport = '/reports/daily';
  static const String monthlyReport = '/reports/monthly';
  static const String stockReport = '/reports/stock';
  static const String transactionReport = '/reports/transactions';

  // ==================== Expenses Routes ====================
  static const String expenses = '/expenses';
  static const String expenseAdd = '/expenses/add';

  // ==================== Profile Routes ====================
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String settings = '/settings';
  static const String changePassword = '/profile/change-password';

  // ==================== Super Admin Routes ====================
  static const String adminDashboard = '/admin';
  static const String adminCompanies = '/admin/companies';
  static const String adminCompanyDetail = '/admin/companies/detail';
  static const String adminCompanyAdd = '/admin/companies/add';
  static const String adminCompanyEdit = '/admin/companies/edit';
  static const String adminReports = '/admin/reports';
  static const String adminSettings = '/admin/settings';

  // ==================== Error Routes ====================
  static const String notFound = '/404';
  static const String error = '/error';

  // ==================== Helper Methods ====================

  /// Get stock detail route with id
  static String stockDetailById(String id) => '/stock/detail/$id';

  /// Get stock edit route with id
  static String stockEditById(String id) => '/stock/edit/$id';

  /// Get customer detail route with id
  static String customerDetailById(String id) => '/customers/detail/$id';

  /// Get customer edit route with id
  static String customerEditById(String id) => '/customers/edit/$id';

  /// Get admin company detail route with id
  static String adminCompanyDetailById(String id) => '/admin/companies/$id';

  /// Get admin company edit route with id
  static String adminCompanyEditById(String id) => '/admin/companies/edit/$id';

  /// Get buy receipt route with transaction id
  static String buyReceiptById(String id) => '/buy/receipt/$id';

  /// Get sell receipt route with transaction id
  static String sellReceiptById(String id) => '/sell/receipt/$id';
}

/// Route parameters keys
class RouteParams {
  RouteParams._();

  static const String id = 'id';
  static const String companyId = 'companyId';
  static const String customerId = 'customerId';
  static const String transactionId = 'transactionId';
  static const String date = 'date';
  static const String type = 'type';
}

/// Route query parameters keys
class RouteQueryParams {
  RouteQueryParams._();

  static const String redirect = 'redirect';
  static const String filter = 'filter';
  static const String search = 'search';
  static const String startDate = 'startDate';
  static const String endDate = 'endDate';
  static const String page = 'page';
}
