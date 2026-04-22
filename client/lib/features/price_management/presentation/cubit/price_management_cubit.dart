import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/paddy_rice_price_repository.dart';
import '../../../../domain/repositories/auth_repository.dart';
import 'price_management_state.dart';

class PriceManagementCubit extends Cubit<PriceManagementState> {
  final PaddyRicePriceRepository _priceRepository;
  final AuthRepository _authRepository;

  PriceManagementCubit({
    required PaddyRicePriceRepository priceRepository,
    required AuthRepository authRepository,
  })  : _priceRepository = priceRepository,
        _authRepository = authRepository,
        super(const PriceManagementState());

  Future<void> initialize() async {
    await loadDistricts();
  }

  Future<void> loadDistricts() async {
    emit(state.copyWith(status: PriceManagementStatus.loadingDistricts));

    final result = await _priceRepository.getDistrictsList();

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: PriceManagementStatus.error,
          errorMessage: failure.message,
          districts: const [],
        ));
      },
      (districts) {
        emit(state.copyWith(
          status: PriceManagementStatus.success,
          districts: districts,
        ));
      },
    );
  }

  Future<void> loadPricesByDistrict(
    String district, {
    int page = 1,
    int limit = 50,
  }) async {
    emit(state.copyWith(
      status: PriceManagementStatus.loadingPrices,
      selectedDistrict: district,
    ));

    final result = await _priceRepository.getPricesByDistrict(
      district,
      limit: limit,
      page: page,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: PriceManagementStatus.error,
          errorMessage: failure.message,
        ));
      },
      (response) {
        emit(state.copyWith(
          status: PriceManagementStatus.success,
          prices: response.prices.map((m) => m.toEntity()).toList(),
          currentPage: response.page,
          totalPages: response.pages,
          totalPrices: response.total,
          selectedDistrict: district,
        ));
      },
    );
  }

  Future<void> loadMyPrices({
    int page = 1,
    int limit = 50,
  }) async {
    emit(state.copyWith(status: PriceManagementStatus.loadingMyPrices));

    final result = await _priceRepository.getMyCompanyPrices(
      limit: limit,
      page: page,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: PriceManagementStatus.error,
          errorMessage: failure.message,
        ));
      },
      (response) {
        emit(state.copyWith(
          status: PriceManagementStatus.success,
          myPrices: response.prices.map((m) => m.toEntity()).toList(),
          totalPrices: response.total,
        ));
      },
    );
  }

  Future<void> addPrice({
    required double price,
    double? priceRangeEnd,
    String qualityGrade = 'standard',
    String priceType = 'paddy',
    String? notes,
    String? variety,
  }) async {
    emit(state.copyWith(status: PriceManagementStatus.addingPrice));

    final result = await _priceRepository.addPrice(
      price: price,
      priceRangeEnd: priceRangeEnd,
      qualityGrade: qualityGrade,
      priceType: priceType,
      notes: notes,
      variety: variety,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: PriceManagementStatus.error,
          errorMessage: failure.toString(),
        ));
      },
      (addedPrice) {
        final updatedMyPrices = [addedPrice, ...state.myPrices];
        emit(state.copyWith(
          status: PriceManagementStatus.success,
          lastAddedPrice: addedPrice,
          myPrices: updatedMyPrices,
        ));
      },
    );
  }

  Future<void> updatePrice(
    String id, {
    required double price,
    double? priceRangeEnd,
    String? qualityGrade,
    String? notes,
  }) async {
    emit(state.copyWith(status: PriceManagementStatus.updatingPrice));

    final result = await _priceRepository.updatePrice(
      id,
      price: price,
      priceRangeEnd: priceRangeEnd,
      qualityGrade: qualityGrade,
      notes: notes,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: PriceManagementStatus.error,
          errorMessage: failure.toString(),
        ));
      },
      (updatedPrice) {
        final updatedMyPrices = state.myPrices.map((p) => p.id == id ? updatedPrice : p).toList();
        emit(state.copyWith(
          status: PriceManagementStatus.success,
          myPrices: updatedMyPrices,
        ));
      },
    );
  }

  Future<void> deletePrice(String id) async {
    emit(state.copyWith(status: PriceManagementStatus.deletingPrice));

    final result = await _priceRepository.deletePrice(id);

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: PriceManagementStatus.error,
          errorMessage: failure.toString(),
        ));
      },
      (_) {
        final updatedMyPrices = state.myPrices.where((p) => p.id != id).toList();
        emit(state.copyWith(
          status: PriceManagementStatus.success,
          myPrices: updatedMyPrices,
        ));
      },
    );
  }

  Future<void> reload() async {
    if (state.selectedDistrict != null) {
      await loadPricesByDistrict(state.selectedDistrict!, page: 1);
    } else {
      await loadMyPrices(page: 1);
    }
  }

  void clearError() {
    emit(state.copyWith(status: PriceManagementStatus.initial, errorMessage: null));
  }

  Future<void> loadNextPage() async {
    if (state.currentPage < state.totalPages && state.selectedDistrict != null) {
      await loadPricesByDistrict(state.selectedDistrict!, page: state.currentPage + 1);
    }
  }

  Future<void> loadPreviousPage() async {
    if (state.currentPage > 1 && state.selectedDistrict != null) {
      await loadPricesByDistrict(state.selectedDistrict!, page: state.currentPage - 1);
    }
  }

  Future<void> loadAllPricesAdmin({
    int page = 1,
    int limit = 50,
    String? district,
    String? priceType,
  }) async {
    emit(state.copyWith(status: PriceManagementStatus.loadingPrices));

    final result = await _priceRepository.getAllPricesAdmin(
      limit: limit,
      page: page,
      district: district,
      priceType: priceType,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: PriceManagementStatus.error,
          errorMessage: failure.message,
        ));
      },
      (response) {
        emit(state.copyWith(
          status: PriceManagementStatus.success,
          prices: response.prices.map((m) => m.toEntity()).toList(),
          currentPage: response.page,
          totalPages: response.pages,
          totalPrices: response.total,
        ));
      },
    );
  }

  void reset() {
    emit(const PriceManagementState());
  }
}
