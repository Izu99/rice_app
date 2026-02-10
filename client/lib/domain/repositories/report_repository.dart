// lib/domain/repositories/report_repository.dart

import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../data/models/report_model.dart';

/// Abstract repository interface for report operations
/// Handles all report generation and export operations
abstract class ReportRepository {
  /// Generate daily report
  ///
  /// Parameters:
  /// - [date]: Date to generate report for
  /// - [companyId]: Company ID
  /// - [generatedById]: User generating the report
  ///
  /// Returns [ReportModel] with daily summary and transactions
  Future<Either<Failure, ReportModel>> generateDailyReport({
    required DateTime date,
    required String companyId,
    required String generatedById,
  });

  /// Generate monthly report
  ///
  /// Parameters:
  /// - [year]: Year
  /// - [month]: Month (1-12)
  /// - [companyId]: Company ID
  /// - [generatedById]: User generating the report
  ///
  /// Returns [ReportModel] with monthly summary and daily breakdown
  Future<Either<Failure, ReportModel>> generateMonthlyReport({
    required int year,
    required int month,
    required String companyId,
    required String generatedById,
  });

  /// Generate custom report
  ///
  /// Parameters:
  /// - [startDate]: Start of date range
  /// - [endDate]: End of date range
  /// - [category]: Report category (sales, purchases, stock, financial, customer)
  /// - [companyId]: Company ID
  /// - [generatedById]: User generating the report
  ///
  /// Returns [ReportModel] with data for the specified category and date range
  Future<Either<Failure, ReportModel>> generateCustomReport({
    required DateTime startDate,
    required DateTime endDate,
    required ReportCategory category,
    required String companyId,
    required String generatedById,
  });

  /// Get dashboard summary
  ///
  /// Returns summary data for dashboard display including:
  /// - Today's summary
  /// - Monthly summary
  /// - Stock summary
  /// - Customer count
  /// - Recent transactions
  Future<Either<Failure, Map<String, dynamic>>> getDashboardSummary();

  /// Get statistics
  ///
  /// Parameters:
  /// - [startDate]: Optional start date
  /// - [endDate]: Optional end date
  ///
  /// Returns statistical data including totals, counts, and averages
  Future<Either<Failure, Map<String, dynamic>>> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Export report to PDF
  ///
  /// Parameters:
  /// - [report]: Report model to export
  ///
  /// Returns file path to the generated PDF
  Future<Either<Failure, String>> exportReportToPdf(ReportModel report);

  /// Export report to Excel
  ///
  /// Parameters:
  /// - [report]: Report model to export
  ///
  /// Returns file path to the generated Excel file
  Future<Either<Failure, String>> exportReportToExcel(ReportModel report);

  /// Generate invoice PDF for a transaction
  ///
  /// Parameters:
  /// - [transactionId]: Transaction's unique identifier
  ///
  /// Returns file path to the generated invoice PDF
  Future<Either<Failure, String>> generateInvoicePdf(String transactionId);

  /// Get profit/loss report
  ///
  /// Parameters:
  /// - [startDate]: Start of date range
  /// - [endDate]: End of date range
  ///
  /// Returns profit/loss data with breakdown
  Future<Either<Failure, Map<String, dynamic>>> getProfitLossReport({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get stock report
  ///
  /// Parameters:
  /// - [date]: Date for stock valuation
  ///
  /// Returns stock data with quantities and values
  Future<Either<Failure, Map<String, dynamic>>> getStockReport({
    DateTime? date,
  });

  /// Get customer report
  ///
  /// Parameters:
  /// - [customerId]: Optional filter by customer
  /// - [startDate]: Optional start date
  /// - [endDate]: Optional end date
  ///
  /// Returns customer transaction and balance data
  Future<Either<Failure, Map<String, dynamic>>> getCustomerReport({
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get sales report
  ///
  /// Parameters:
  /// - [startDate]: Start of date range
  /// - [endDate]: End of date range
  /// - [groupBy]: Grouping ('day', 'week', 'month', 'variety', 'customer')
  ///
  /// Returns sales data with specified grouping
  Future<Either<Failure, Map<String, dynamic>>> getSalesReport({
    required DateTime startDate,
    required DateTime endDate,
    String groupBy = 'day',
  });

  /// Get purchase report
  ///
  /// Parameters:
  /// - [startDate]: Start of date range
  /// - [endDate]: End of date range
  /// - [groupBy]: Grouping ('day', 'week', 'month', 'variety', 'customer')
  ///
  /// Returns purchase data with specified grouping
  Future<Either<Failure, Map<String, dynamic>>> getPurchaseReport({
    required DateTime startDate,
    required DateTime endDate,
    String groupBy = 'day',
  });

  /// Get milling report
  ///
  /// Parameters:
  /// - [startDate]: Start of date range
  /// - [endDate]: End of date range
  ///
  /// Returns milling data with efficiency calculations
  Future<Either<Failure, Map<String, dynamic>>> getMillingReport({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get outstanding balances report
  ///
  /// Parameters:
  /// - [type]: 'receivable' or 'payable'
  ///
  /// Returns list of customers with outstanding balances
  Future<Either<Failure, Map<String, dynamic>>> getOutstandingBalancesReport({
    String? type,
  });

  /// Get top performers report
  ///
  /// Parameters:
  /// - [type]: 'customers', 'products', or 'varieties'
  /// - [startDate]: Start of date range
  /// - [endDate]: End of date range
  /// - [limit]: Maximum number of items
  ///
  /// Returns top performing items
  Future<Either<Failure, List<Map<String, dynamic>>>> getTopPerformersReport({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  });

  /// Get comparison report
  ///
  /// Compares two periods
  ///
  /// Parameters:
  /// - [period1Start]: Start of first period
  /// - [period1End]: End of first period
  /// - [period2Start]: Start of second period
  /// - [period2End]: End of second period
  ///
  /// Returns comparison data with percentage changes
  Future<Either<Failure, Map<String, dynamic>>> getComparisonReport({
    required DateTime period1Start,
    required DateTime period1End,
    required DateTime period2Start,
    required DateTime period2End,
  });

  /// Get trend report
  ///
  /// Parameters:
  /// - [months]: Number of months to include
  /// - [metric]: Metric to track ('sales', 'purchases', 'profit', 'stock')
  ///
  /// Returns trend data for the specified metric
  Future<Either<Failure, List<Map<String, dynamic>>>> getTrendReport({
    required int months,
    required String metric,
  });

  /// Get saved reports
  ///
  /// Parameters:
  /// - [type]: Optional filter by report type
  /// - [limit]: Maximum number of reports
  ///
  /// Returns list of previously generated reports
  Future<Either<Failure, List<ReportModel>>> getSavedReports({
    ReportType? type,
    int limit = 20,
  });

  /// Save report
  ///
  /// Parameters:
  /// - [report]: Report model to save
  ///
  /// Returns saved report
  Future<Either<Failure, ReportModel>> saveReport(ReportModel report);

  /// Delete saved report
  ///
  /// Parameters:
  /// - [reportId]: Report's unique identifier
  ///
  /// Returns true if successful
  Future<Either<Failure, bool>> deleteReport(String reportId);

  /// Share report
  ///
  /// Parameters:
  /// - [reportId]: Report's unique identifier
  /// - [method]: Share method ('email', 'whatsapp', 'print')
  /// - [recipient]: Optional recipient (email or phone)
  ///
  /// Returns true if successful
  Future<Either<Failure, bool>> shareReport({
    required String reportId,
    required String method,
    String? recipient,
  });

  /// Schedule report
  ///
  /// Parameters:
  /// - [type]: Report type
  /// - [frequency]: 'daily', 'weekly', 'monthly'
  /// - [recipients]: List of email recipients
  ///
  /// Returns schedule ID
  Future<Either<Failure, String>> scheduleReport({
    required ReportType type,
    required String frequency,
    required List<String> recipients,
  });

  /// Cancel scheduled report
  ///
  /// Parameters:
  /// - [scheduleId]: Schedule's unique identifier
  ///
  /// Returns true if successful
  Future<Either<Failure, bool>> cancelScheduledReport(String scheduleId);

  /// Get scheduled reports
  ///
  /// Returns list of scheduled reports
  Future<Either<Failure, List<Map<String, dynamic>>>> getScheduledReports();
}
