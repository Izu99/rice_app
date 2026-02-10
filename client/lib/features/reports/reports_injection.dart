// lib/features/reports/reports_injection.dart

import 'package:get_it/get_it.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import 'presentation/cubit/reports_cubit.dart';

class ReportsInjection {
  static final GetIt _sl = GetIt.instance;

  static Future<void> init() async {
    _sl.registerLazySingleton<ReportsCubit>(
      () => ReportsCubit(
        reportRepository: _sl<ReportRepository>(),
        authRepository: _sl<AuthRepository>(),
      ),
    );
  }

  static ReportsCubit get reportsCubit => _sl<ReportsCubit>();
}
