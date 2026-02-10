// lib/features/reports/presentation/cubit/reports_state.dart

import 'package:equatable/equatable.dart';
import '../../../../data/models/report_model.dart';

enum ReportsStatus { initial, loading, loaded, exporting, error }

class ReportsState extends Equatable {
  final ReportsStatus status;
  final ReportModel? dailyReport;
  final ReportModel? monthlyReport;
  final Map<String, dynamic>? dashboardSummary;
  final DateTime selectedDate;
  final int selectedMonth;
  final int selectedYear;
  final String? errorMessage;
  final String? exportedFilePath;

  ReportsState({
    this.status = ReportsStatus.initial,
    this.dailyReport,
    this.monthlyReport,
    this.dashboardSummary,
    DateTime? selectedDate,
    int? selectedMonth,
    int? selectedYear,
    this.errorMessage,
    this.exportedFilePath,
  })  : selectedDate = selectedDate ?? const _DefaultDate(),
        selectedMonth = selectedMonth ?? DateTime.now().month,
        selectedYear = selectedYear ?? DateTime.now().year;

  factory ReportsState.initial() => ReportsState(
        selectedDate: DateTime.now(),
        selectedMonth: DateTime.now().month,
        selectedYear: DateTime.now().year,
      );

  bool get isLoading => status == ReportsStatus.loading;
  bool get isExporting => status == ReportsStatus.exporting;

  double get todayProfit => dailyReport?.summary.grossProfit ?? 0;
  double get monthlyProfit => monthlyReport?.summary.grossProfit ?? 0;

  ReportsState copyWith({
    ReportsStatus? status,
    ReportModel? dailyReport,
    ReportModel? monthlyReport,
    Map<String, dynamic>? dashboardSummary,
    DateTime? selectedDate,
    int? selectedMonth,
    int? selectedYear,
    String? errorMessage,
    String? exportedFilePath,
    bool clearError = false,
  }) {
    return ReportsState(
      status: status ?? this.status,
      dailyReport: dailyReport ?? this.dailyReport,
      monthlyReport: monthlyReport ?? this.monthlyReport,
      dashboardSummary: dashboardSummary ?? this.dashboardSummary,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      exportedFilePath: exportedFilePath ?? this.exportedFilePath,
    );
  }

  @override
  List<Object?> get props => [
        status,
        dailyReport,
        monthlyReport,
        dashboardSummary,
        selectedDate,
        selectedMonth,
        selectedYear,
        errorMessage,
        exportedFilePath,
      ];
}

class _DefaultDate implements DateTime {
  const _DefaultDate();
  @override
  dynamic noSuchMethod(Invocation i) => DateTime.now();
}
