// lib/features/price_management/presentation/cubit/price_management_state.dart

import 'package:equatable/equatable.dart';
import '../../../../domain/entities/paddy_rice_price_entity.dart';
import '../../../../data/models/paddy_rice_price_model.dart';
import '../../../../data/models/paddy_rice_price_model.dart'
    show DistrictWithPricesResponse;

enum PriceManagementStatus {
  initial,
  loading,
  addingPrice,
  updatingPrice,
  deletingPrice,
  loadingDistricts,
  loadingPrices,
  loadingMyPrices,
  success,
  error,
}

class PriceManagementState extends Equatable {
  final PriceManagementStatus status;
  final List<PaddyRicePriceEntity> prices;
  final List<DistrictWithPricesResponse> districts;
  final List<PaddyRicePriceEntity> myPrices;
  final String? errorMessage;
  final PaddyRicePriceEntity? lastAddedPrice;
  final int currentPage;
  final int totalPages;
  final int totalPrices;
  final String? selectedDistrict;
  // True when silently refreshing in background while showing existing data
  final bool isRefreshing;

  const PriceManagementState({
    this.status = PriceManagementStatus.initial,
    this.prices = const [],
    this.districts = const [],
    this.myPrices = const [],
    this.errorMessage,
    this.lastAddedPrice,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalPrices = 0,
    this.selectedDistrict,
    this.isRefreshing = false,
  });

  PriceManagementState copyWith({
    PriceManagementStatus? status,
    List<PaddyRicePriceEntity>? prices,
    List<DistrictWithPricesResponse>? districts,
    List<PaddyRicePriceEntity>? myPrices,
    String? errorMessage,
    PaddyRicePriceEntity? lastAddedPrice,
    int? currentPage,
    int? totalPages,
    int? totalPrices,
    String? selectedDistrict,
    bool? isRefreshing,
  }) {
    return PriceManagementState(
      status: status ?? this.status,
      prices: prices ?? this.prices,
      districts: districts ?? this.districts,
      myPrices: myPrices ?? this.myPrices,
      errorMessage: errorMessage ?? this.errorMessage,
      lastAddedPrice: lastAddedPrice ?? this.lastAddedPrice,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalPrices: totalPrices ?? this.totalPrices,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        prices,
        districts,
        myPrices,
        errorMessage,
        lastAddedPrice,
        currentPage,
        totalPages,
        totalPrices,
        selectedDistrict,
        isRefreshing,
      ];
}
