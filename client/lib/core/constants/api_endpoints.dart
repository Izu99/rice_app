/// API Endpoints for the Rice Mill ERP
class ApiEndpoints {
  ApiEndpoints._();

  // ==================== BASE URL ====================

  /// Production base URL
  static const String prodBaseUrl = 'https://api.ricemill.example.com/api/v1';

  /// Development base URL
  static const String devBaseUrl = 'http://localhost:5000/api';

  /// VPS base URL
  static const String vpsBaseUrl = 'http://4.1.8.2/rice/api';

  /// Staging base URL
  static const String stagingBaseUrl =
      'https://staging-api.ricemill.example.com/api/v1';

  /// Production base URL (Live)
  static const String liveBaseUrl = 'http://82.25.180.20/rice/api';

  /// Current base URL (change based on environment)
  // For Android Emulator, use 10.0.2.2 to reach your local machine
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // ==================== AUTH ====================

  /// Login endpoint
  static const String login = '/auth/login';

  /// Register endpoint
  static const String register = '/auth/register';

  /// Logout endpoint
  static const String logout = '/auth/logout';

  /// Refresh token endpoint
  static const String refreshToken = '/auth/refresh';

  /// Forgot password endpoint
  static const String forgotPassword = '/auth/forgot-password';

  /// Reset password endpoint
  static const String resetPassword = '/auth/reset-password';

  /// Verify OTP endpoint
  static const String verifyOtp = '/auth/verify-otp';

  /// Change password endpoint
  static const String changePassword = '/auth/change-password';

  /// Get profile endpoint
  static const String profile = '/auth/me';

  /// Update profile endpoint
  static const String updateProfile = '/auth/profile';

  // ==================== CUSTOMERS ====================

  /// Customers base endpoint
  static const String customers = '/customers';

  /// Get customer by ID
  static String customer(dynamic id) => '/customers/$id';

  /// Search customers
  static const String searchCustomers = '/customers/search';

  /// Customer by phone
  static const String customerByPhone = '/customers/phone';

  /// Customer sync endpoint
  static const String customerSync = '/customers/sync';

  /// Customer updates endpoint
  static const String customerUpdates = '/customers/updates';

  /// Customer batch endpoint
  static const String customerBatch = '/customers/batch';

  /// Customer check phone endpoint
  static const String customerCheckPhone = '/customers/check-phone';

  /// Customer transactions
  static String customerTransactions(dynamic id) =>
      '/customers/$id/transactions';

  /// Customer balance
  static String customerBalance(dynamic id) => '/customers/$id/balance';

  /// Customer statement
  static String customerStatement(dynamic id) => '/customers/$id/statement';

  // ==================== STOCK ====================

  /// Stock base endpoint
  static const String stock = '/stock';

  /// Get stock item by ID
  static String stockItem(dynamic id) => '/stock/$id';

  /// Search stock
  static const String searchStock = '/stock/search';

  /// Stock adjustment endpoint
  static const String stockAdjustment = '/stock/adjust';

  /// Low stock items
  static const String lowStock = '/stock/low-stock';

  /// Stock summary
  static const String stockSummary = '/stock/summary';

  /// Stock by type
  static String stockByType(String type) => '/stock/type/$type';

  /// Stock history
  static String stockHistory(dynamic id) => '/stock/$id/history';

  /// Add stock endpoint
  static const String stockAddStock = '/stock/add-stock';

  /// Deduct stock endpoint
  static const String stockDeductStock = '/stock/deduct-stock';

  /// Stock sync endpoint
  static const String stockSync = '/stock/sync';

  /// Stock updates endpoint
  static const String stockUpdates = '/stock/updates';

  /// Stock milling endpoint
  static const String stockMilling = '/stock/milling';

  /// Stock milling history endpoint
  static const String stockMillingHistory = '/stock/milling/history';

  // ==================== TRANSACTIONS ====================

  /// Transactions base endpoint
  static const String transactions = '/transactions';

  /// Get transaction by ID
  static String transaction(dynamic id) => '/transactions/$id';

  /// Buy transactions
  static const String buyTransactions = '/transactions';

  /// Sell transactions
  static const String sellTransactions = '/transactions';

  /// Transaction by transaction ID
  static String transactionByTxnId(String txnId) => '/transactions/txn/$txnId';

  /// Today's transactions
  static const String todayTransactions = '/transactions/today';

  /// Transaction summary
  static const String transactionSummary = '/transactions/summary';

  /// Cancel transaction
  static String cancelTransaction(dynamic id) => '/transactions/$id/cancel';

  /// Transactions by customer
  static String transactionsByCustomer(String customerId) =>
      '/customers/$customerId/transactions';

  /// Transaction sync endpoint
  static const String transactionSync = '/transactions/sync';

  /// Transaction updates endpoint
  static const String transactionUpdates = '/transactions/updates';

  /// Transaction search endpoint
  static const String transactionSearch = '/transactions/search';

  /// Pending transactions endpoint
  static const String transactionsPending = '/transactions/pending';

  /// Complete transaction
  static String completeTransaction(dynamic id) => '/transactions/$id/complete';

  // ==================== PAYMENTS ====================

  /// Payments base endpoint
  static const String payments = '/payments';

  /// Get payment by ID
  static String payment(dynamic id) => '/payments/$id';

  /// Add payment to transaction
  static String addPayment(dynamic transactionId) =>
      '/transactions/$transactionId/payments';

  /// Payment history
  static String paymentHistory(dynamic transactionId) =>
      '/transactions/$transactionId/payments/history';

  // ==================== MILLING ====================

  /// Milling base endpoint
  static const String milling = '/milling';

  /// Create milling record
  static const String createMilling = '/milling/create';

  /// Get milling by ID
  static String millingRecord(dynamic id) => '/milling/$id';

  /// Milling history
  static const String millingHistory = '/milling/history';

  /// Milling summary
  static const String millingSummary = '/milling/summary';

  // ==================== EXPENSES ====================

  /// Expenses base endpoint
  static const String expenses = '/expenses';

  /// Get expense by ID
  static String expense(dynamic id) => '/expenses/$id';

  /// Expense summary
  static const String expenseSummary = '/expenses/summary';

  // ==================== REPORTS ====================

  /// Reports base endpoint
  static const String reports = '/reports';

  /// Daily report
  static const String dailyReport = '/reports/daily';

  /// Weekly report
  static const String weeklyReport = '/reports/weekly';

  /// Monthly report
  static const String monthlyReport = '/reports/monthly';

  /// Stock report
  static const String stockReport = '/reports/stock';

  /// Customer report
  static const String customerReport = '/reports/customers';

  /// Transaction report
  static const String transactionReport = '/reports/transactions';

  /// Daily summary report
  static const String reportsDailySummary = '/reports/daily-summary';

  /// Monthly summary report
  static const String reportsMonthlySummary = '/reports/monthly-summary';

  /// Dashboard summary report
  static const String reportsDashboard = '/reports/dashboard';

  /// Statistics report
  static const String reportsStatistics = '/reports/statistics';

  /// Profit/Loss report
  static const String profitLossReport = '/reports/profit-loss';

  /// Export report
  static String exportReport(String type) => '/reports/export/$type';

  /// Custom date range report
  static const String customReport = '/reports/custom';

  // ==================== SYNC ====================

  /// Sync base endpoint
  static const String sync = '/sync';

  /// Push local changes
  static const String syncPush = '/sync/push';

  /// Pull server changes
  static const String syncPull = '/sync/pull';

  /// Full sync
  static const String syncFull = '/sync/full';

  /// Sync status
  static const String syncStatus = '/sync/status';

  /// Resolve conflicts
  static const String syncResolve = '/sync/resolve';

  // ==================== ADMIN ====================

  /// Admin base endpoint
  static const String admin = '/admin';

  /// Companies
  static const String companies = '/admin/companies';

  /// Get company by ID
  static String company(dynamic id) => '/admin/companies/$id';

  /// Create company
  static const String createCompany = '/admin/companies/create';

  /// Company users
  static String companyUsers(dynamic companyId) =>
      '/admin/companies/$companyId/users';

  /// Users
  static const String users = '/admin/users';

  /// Get user by ID
  static String user(dynamic id) => '/admin/users/$id';

  /// Create user
  static const String createUser = '/admin/users/create';

  /// User roles
  static const String roles = '/admin/roles';

  /// Dashboard stats
  static const String dashboardStats = '/admin/dashboard';

  /// System settings
  static const String settings = '/admin/settings';

  // ==================== NOTIFICATIONS ====================

  /// Notifications base endpoint
  static const String notifications = '/notifications';

  /// Mark notification as read
  static String markNotificationRead(dynamic id) => '/notifications/$id/read';

  /// Mark all as read
  static const String markAllNotificationsRead = '/notifications/read-all';

  /// Unread count
  static const String unreadNotificationsCount = '/notifications/unread-count';

  /// Register FCM token
  static const String registerFcmToken = '/notifications/fcm/register';

  /// Resend OTP
  static const String resendOtp = '/auth/resend-otp';

  /// Check phone registered
  static const String checkPhone = '/auth/check-phone';

  /// Deactivate account
  static const String deactivateAccount = '/auth/deactivate';

  /// Delete account
  static const String deleteAccount = '/auth/delete';

  // ==================== UTILITIES ====================

  /// Health check
  static const String health = '/health';

  /// Ping
  static const String ping = '/ping';

  /// App version check
  static const String versionCheck = '/version';

  /// Upload file
  static const String upload = '/upload';

  /// Download file
  static String download(String fileId) => '/download/$fileId';

  // ==================== HELPER METHODS ====================

  /// Build URL with query parameters
  static String withQuery(String endpoint, Map<String, dynamic> params) {
    if (params.isEmpty) return endpoint;

    final queryString = params.entries
        .where((e) => e.value != null)
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');

    return '$endpoint?$queryString';
  }

  /// Build paginated URL
  static String paginated(
    String endpoint, {
    int page = 1,
    int perPage = 20,
    Map<String, dynamic>? additionalParams,
  }) {
    final params = {
      'page': page,
      'per_page': perPage,
      ...?additionalParams,
    };
    return withQuery(endpoint, params);
  }

  /// Build date range URL
  static String withDateRange(
    String endpoint, {
    required DateTime startDate,
    required DateTime endDate,
    Map<String, dynamic>? additionalParams,
  }) {
    final params = {
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      ...?additionalParams,
    };
    return withQuery(endpoint, params);
  }
}
