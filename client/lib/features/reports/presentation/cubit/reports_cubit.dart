// lib/features/reports/presentation/cubit/reports_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/report_repository.dart';
import '../../../../domain/repositories/auth_repository.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  final ReportRepository _reportRepository;
  final AuthRepository _authRepository;

  ReportsCubit({
    required ReportRepository reportRepository,
    required AuthRepository authRepository,
  })  : _reportRepository = reportRepository,
        _authRepository = authRepository,
        super(ReportsState.initial());

  Future<void> loadDailyReport([DateTime? date]) async {
    emit(state.copyWith(
        status: ReportsStatus.loading, selectedDate: date ?? DateTime.now()));

    final userResult = await _authRepository.getCurrentUser();
    final user = userResult.fold((l) => null, (r) => r);
    if (user == null) return;

    final result = await _reportRepository.generateDailyReport(
      date: date ?? DateTime.now(),
      companyId: user.companyId,
      generatedById: user.id,
    );

    result.fold(
      (failure) => emit(state.copyWith(
          status: ReportsStatus.error, errorMessage: failure.message)),
      (report) => emit(
          state.copyWith(status: ReportsStatus.loaded, dailyReport: report)),
    );
  }

  Future<void> loadMonthlyReport({int? year, int? month}) async {
    final y = year ?? state.selectedYear;
    final m = month ?? state.selectedMonth;
    emit(state.copyWith(
        status: ReportsStatus.loading, selectedYear: y, selectedMonth: m));

    final userResult = await _authRepository.getCurrentUser();
    final user = userResult.fold((l) => null, (r) => r);
    if (user == null) return;

    final result = await _reportRepository.generateMonthlyReport(
      year: y,
      month: m,
      companyId: user.companyId,
      generatedById: user.id,
    );

    result.fold(
      (failure) => emit(state.copyWith(
          status: ReportsStatus.error, errorMessage: failure.message)),
      (report) => emit(
          state.copyWith(status: ReportsStatus.loaded, monthlyReport: report)),
    );
  }

  Future<void> loadDashboardSummary() async {
    emit(state.copyWith(status: ReportsStatus.loading));

    final result = await _reportRepository.getDashboardSummary();

    result.fold(
      (failure) => emit(state.copyWith(
          status: ReportsStatus.error, errorMessage: failure.message)),
      (summary) => emit(state.copyWith(
          status: ReportsStatus.loaded, dashboardSummary: summary)),
    );
  }

  Future<void> exportToPdf() async {
    if (state.dailyReport == null) return;
    emit(state.copyWith(status: ReportsStatus.exporting));

    final result =
        await _reportRepository.exportReportToPdf(state.dailyReport!);

    result.fold(
      (failure) => emit(state.copyWith(
          status: ReportsStatus.loaded, errorMessage: failure.message)),
      (path) => emit(
          state.copyWith(status: ReportsStatus.loaded, exportedFilePath: path)),
    );
  }

  void changeDate(DateTime date) {
    emit(state.copyWith(selectedDate: date));
    loadDailyReport(date);
  }

  void changeMonth(int year, int month) {
    loadMonthlyReport(year: year, month: month);
  }
}
