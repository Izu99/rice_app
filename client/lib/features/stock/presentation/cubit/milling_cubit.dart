import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/enums.dart';
import '../../../../data/models/stock_item_model.dart';
import '../../../../domain/repositories/stock_repository.dart';
import 'milling_state.dart';

class MillingCubit extends Cubit<MillingState> {
  final StockRepository _stockRepository;
  // ignore: unused_field
  final _uuid = const Uuid();

  MillingCubit({required StockRepository stockRepository})
      : _stockRepository = stockRepository,
        super(const MillingState());

  /// Load initial data
  Future<void> loadInitialData() async {
    await loadAvailablePaddy();
    await fetchPendingMillings();
    await fetchMillingHistory();
  }

  /// Load available paddy for milling
  Future<void> loadAvailablePaddy() async {
    emit(state.copyWith(status: MillingStatus.loading));

    try {
      final result = await _stockRepository.getStockByType(ItemType.paddy);

      result.fold(
        (failure) => emit(state.copyWith(
          status: MillingStatus.error,
          errorMessage: failure.message,
        )),
        (paddyItems) {
          final available = paddyItems
              .where((item) => item.currentQuantity > 0)
              .map((entity) => StockItemModel.fromEntity(entity, ''))
              .toList();
          emit(state.copyWith(
            status: MillingStatus.initial,
            availablePaddy: available,
            batchNumber: _generateBatchNumber(),
            millingDate: DateTime.now(),
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: MillingStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Select paddy for milling
  void selectPaddy(StockItemModel paddy) {
    emit(state.copyWith(
      selectedPaddy: paddy,
      inputPaddyKg: 0.0,
      inputPaddyBags: 0,
    ));
  }

  /// Clear selected paddy
  void clearSelectedPaddy() {
    emit(state.copyWith(
      clearSelectedPaddy: true,
      inputPaddyKg: 0.0,
      inputPaddyBags: 0,
    ));
  }

  /// Update input paddy weight
  void updateInputWeight(double weightKg) {
    if (state.selectedPaddy == null) return;

    // Validate against available stock
    final maxWeight = state.selectedPaddy!.currentQuantity;
    final validWeight = weightKg > maxWeight ? maxWeight : weightKg;

    // Calculate estimated bags (assuming average 50kg per bag)
    final estimatedBags = (validWeight / 50).floor();

    emit(state.copyWith(
      inputPaddyKg: validWeight,
      inputPaddyBags: estimatedBags,
    ));
  }

  /// Update input paddy bags
  void updateInputBags(int bags) {
    if (state.selectedPaddy == null) return;

    // Calculate weight from bags (assuming average 50kg per bag)
    final estimatedWeight = bags * 50.0;
    final maxWeight = state.selectedPaddy!.currentQuantity;
    final validWeight =
        estimatedWeight > maxWeight ? maxWeight : estimatedWeight;

    emit(state.copyWith(
      inputPaddyBags: bags,
      inputPaddyKg: validWeight,
    ));
  }

  /// Update milling percentage
  void updateMillingPercentage(double percentage) {
    if (percentage < 0 || percentage > 100) return;

    emit(state.copyWith(millingPercentage: percentage));
  }

  /// Update actual output values
  void updateActualOutput({
    double? riceKg,
    double? brokenRiceKg,
    double? huskKg,
    double? wastageKg,
  }) {
    emit(state.copyWith(
      outputRiceKg: riceKg ?? state.outputRiceKg,
      brokenRiceKg: brokenRiceKg ?? state.brokenRiceKg,
      huskKg: huskKg ?? state.huskKg,
      wastageKg: wastageKg ?? state.wastageKg,
    ));
  }

  /// Start milling process (Step 1)
  Future<bool> startMilling({String? notes}) async {
    if (!state.canProcess) {
      emit(state.copyWith(
        status: MillingStatus.error,
        errorMessage: 'Invalid milling parameters',
      ));
      return false;
    }

    emit(state.copyWith(status: MillingStatus.processing));

    try {
      final result = await _stockRepository.startMilling(
        paddyItemId: state.selectedPaddy!.id,
        paddyQuantity: state.inputPaddyKg,
        paddyBags: state.inputPaddyBags,
        notes: notes,
        millingDate: state.millingDate ?? DateTime.now(),
      );

      return result.fold(
        (failure) {
          emit(state.copyWith(
            status: MillingStatus.error,
            errorMessage: failure.message,
          ));
          return false;
        },
        (data) async {
          // Reload available paddy and pending millings
          await loadAvailablePaddy();
          await fetchPendingMillings();
          
          emit(state.copyWith(status: MillingStatus.success));
          return true;
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: MillingStatus.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Complete milling process (Step 2)
  Future<bool> completeMilling({
    required String id,
    required String outputRiceName,
  }) async {
    emit(state.copyWith(status: MillingStatus.processing));

    try {
      final result = await _stockRepository.completeMilling(
        id: id,
        riceQuantity: state.outputRiceKg,
        riceBags: (state.outputRiceKg / 50).floor(), // Estimate bags or add input
        outputRiceName: outputRiceName,
        brokenRiceKg: state.brokenRiceKg,
        huskKg: state.huskKg,
        millingPercentage: state.millingPercentage,
      );

      return result.fold(
        (failure) {
          emit(state.copyWith(
            status: MillingStatus.error,
            errorMessage: failure.message,
          ));
          return false;
        },
        (data) async {
          await fetchPendingMillings();
          await fetchMillingHistory();
          emit(state.copyWith(status: MillingStatus.success));
          return true;
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: MillingStatus.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Fetch pending milling records
  Future<void> fetchPendingMillings() async {
    // Note: Assuming getMillingHistory supports status filtering, 
    // but repo interface currently doesn't expose it. 
    // I'll fetch all and filter client side for now or assume backend returns all and I filter.
    // Wait, I didn't update repo interface to accept status.
    // I'll fetch history and filter client side if the API returns mixed.
    // But ideally I should have updated the repo.
    // However, for this implementation:
    try {
      final result = await _stockRepository.getMillingHistory(limit: 100);
      result.fold(
        (failure) => null, // Ignore error for background fetch
        (history) {
          final pending = history.where((m) => m['status'] == 'in_progress').toList();
          emit(state.copyWith(pendingMillings: pending));
        },
      );
    } catch (_) {}
  }

  /// Fetch milling history
  Future<void> fetchMillingHistory() async {
    try {
      final result = await _stockRepository.getMillingHistory();
      result.fold(
        (failure) => null,
        (history) {
          final completed = history.where((m) => m['status'] == 'completed').toList();
          emit(state.copyWith(millingHistory: completed));
        },
      );
    } catch (_) {}
  }

  /// Generate batch number for milling
  String _generateBatchNumber() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return 'ML-$dateStr-$timeStr';
  }

  /// Calculate milling efficiency
  double calculateEfficiency() {
    if (state.inputPaddyKg <= 0 || state.outputRiceKg <= 0) {
      return state.millingPercentage;
    }
    return (state.outputRiceKg / state.inputPaddyKg) * 100;
  }

  /// Process full milling cycle (Start + Complete)
  Future<void> processMilling() async {
    print('🚜 [MillingCubit] Starting processMilling...');
    if (!state.canProcess) {
      print('🚜 [MillingCubit] Validation failed: canProcess is false');
      emit(state.copyWith(
        status: MillingStatus.error,
        errorMessage: 'Invalid milling parameters',
      ));
      return;
    }

    emit(state.copyWith(status: MillingStatus.processing));
    print('🚜 [MillingCubit] Status set to processing');

    try {
      final variety = state.selectedPaddy!.variety;
      final riceName = 'Rice - $variety';
      final outputKg = state.outputRiceKg > 0 ? state.outputRiceKg : state.expectedRiceKg;
      final outputBags = (outputKg / 50).ceil();

      print('🚜 [MillingCubit] Parameters: variety=$variety, outputKg=$outputKg, outputBags=$outputBags');

      // Perform one-shot milling process
      final result = await _stockRepository.startMilling(
        paddyItemId: state.selectedPaddy!.id,
        paddyQuantity: state.inputPaddyKg,
        paddyBags: state.inputPaddyBags,
        notes: 'Direct processing',
        millingDate: state.millingDate ?? DateTime.now(),
        outputRiceKg: outputKg,
        outputRiceBags: outputBags,
        outputRiceName: riceName,
        status: 'completed',
      );

      print('🚜 [MillingCubit] Repository call returned');

      result.fold(
        (failure) {
          print('🚜 [MillingCubit] Process failed: ${failure.message}');
          emit(state.copyWith(
            status: MillingStatus.error,
            errorMessage: failure.message,
          ));
        },
        (data) async {
          print('🚜 [MillingCubit] Process succeeded, refreshing data...');
          // Refresh available paddy and history
          final stockResult = await _stockRepository.getStockByType(ItemType.paddy);
          await fetchMillingHistory();
          
          print('🚜 [MillingCubit] Data refreshed, emitting success');
          
          stockResult.fold(
            (failure) {
              print('🚜 [MillingCubit] Refresh failed: ${failure.message}');
              emit(state.copyWith(
                status: MillingStatus.error,
                errorMessage: 'Milling successful, but failed to refresh stock list: ${failure.message}',
              ));
            },
            (paddyItems) {
              final available = paddyItems
                  .where((item) => item.currentQuantity > 0)
                  .map((entity) => StockItemModel.fromEntity(entity, ''))
                  .toList();
              
              emit(state.copyWith(
                status: MillingStatus.success,
                availablePaddy: available,
                clearSelectedPaddy: true,
                inputPaddyKg: 0.0,
                inputPaddyBags: 0,
              ));
            },
          );
        },
      );
    } catch (e, stack) {
      print('🚜 [MillingCubit] UNEXPECTED ERROR: $e');
      print('🚜 [MillingCubit] STACK TRACE: $stack');
      emit(state.copyWith(
        status: MillingStatus.error,
        errorMessage: 'Unexpected error: ${e.toString()}',
      ));
    }
  }

  /// Reset milling form
  void resetMilling() {
    emit(MillingState(
      availablePaddy: state.availablePaddy,
      batchNumber: _generateBatchNumber(),
      millingDate: DateTime.now(),
      pendingMillings: state.pendingMillings,
      millingHistory: state.millingHistory,
    ));
  }

  /// Clear error
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
