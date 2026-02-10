import 'package:equatable/equatable.dart';
import '../../../../data/models/stock_item_model.dart';

enum MillingStatus { initial, loading, processing, success, error }

class MillingState extends Equatable {
  final MillingStatus status;
  final List<StockItemModel> availablePaddy;
  final StockItemModel? selectedPaddy;
  final double inputPaddyKg;
  final int inputPaddyBags;
  final double outputRiceKg;
  final double millingPercentage;
  final double brokenRiceKg;
  final double huskKg;
  final double wastageKg;
  final String? errorMessage;
  final DateTime? millingDate;
  final String? batchNumber;
  final List<Map<String, dynamic>> pendingMillings;
  final List<Map<String, dynamic>> millingHistory;

  const MillingState({
    this.status = MillingStatus.initial,
    this.availablePaddy = const [],
    this.selectedPaddy,
    this.inputPaddyKg = 0.0,
    this.inputPaddyBags = 0,
    this.outputRiceKg = 0.0,
    this.millingPercentage = 65.0, // Default milling percentage
    this.brokenRiceKg = 0.0,
    this.huskKg = 0.0,
    this.wastageKg = 0.0,
    this.errorMessage,
    this.millingDate,
    this.batchNumber,
    this.pendingMillings = const [],
    this.millingHistory = const [],
  });

  // Calculate expected outputs based on input
  double get expectedRiceKg => inputPaddyKg * (millingPercentage / 100);
  double get expectedBrokenRiceKg => inputPaddyKg * 0.08; // 8% broken rice
  double get expectedHuskKg => inputPaddyKg * 0.20; // 20% husk
  double get expectedWastageKg => inputPaddyKg * 0.07; // 7% wastage

  bool get canProcess =>
      selectedPaddy != null &&
      inputPaddyKg > 0 &&
      inputPaddyKg <= (selectedPaddy?.totalWeightKg ?? 0);

  MillingState copyWith({
    MillingStatus? status,
    List<StockItemModel>? availablePaddy,
    StockItemModel? selectedPaddy,
    double? inputPaddyKg,
    int? inputPaddyBags,
    double? outputRiceKg,
    double? millingPercentage,
    double? brokenRiceKg,
    double? huskKg,
    double? wastageKg,
    String? errorMessage,
    DateTime? millingDate,
    String? batchNumber,
    List<Map<String, dynamic>>? pendingMillings,
    List<Map<String, dynamic>>? millingHistory,
    bool clearSelectedPaddy = false,
  }) {
    return MillingState(
      status: status ?? this.status,
      availablePaddy: availablePaddy ?? this.availablePaddy,
      selectedPaddy:
          clearSelectedPaddy ? null : (selectedPaddy ?? this.selectedPaddy),
      inputPaddyKg: inputPaddyKg ?? this.inputPaddyKg,
      inputPaddyBags: inputPaddyBags ?? this.inputPaddyBags,
      outputRiceKg: outputRiceKg ?? this.outputRiceKg,
      millingPercentage: millingPercentage ?? this.millingPercentage,
      brokenRiceKg: brokenRiceKg ?? this.brokenRiceKg,
      huskKg: huskKg ?? this.huskKg,
      wastageKg: wastageKg ?? this.wastageKg,
      errorMessage: errorMessage,
      millingDate: millingDate ?? this.millingDate,
      batchNumber: batchNumber ?? this.batchNumber,
      pendingMillings: pendingMillings ?? this.pendingMillings,
      millingHistory: millingHistory ?? this.millingHistory,
    );
  }

  @override
  List<Object?> get props => [
        status,
        availablePaddy,
        selectedPaddy,
        inputPaddyKg,
        inputPaddyBags,
        outputRiceKg,
        millingPercentage,
        brokenRiceKg,
        huskKg,
        wastageKg,
        errorMessage,
        millingDate,
        batchNumber,
        pendingMillings,
        millingHistory,
      ];
}
