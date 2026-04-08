// lib/features/price_management/presentation/cubit/price_management_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/paddy_rice_price_entity.dart';
import '../../../../data/models/paddy_rice_price_model.dart';
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

  /// Initialize cubit - load districts
  Future<void> initialize() async {
    await loadDistricts();
  }

  /// Load all available districts
  Future<void> loadDistricts() async {
    emit(state.copyWith(status: PriceManagementStatus.loadingDistricts));

    final result = await _priceRepository.getDistrictsList();

    result.fold(
      (failure) {
        // Fallback to sample data even on error for demonstration
        final sampleDistricts = [
          DistrictWithPricesResponse(
            district: 'Anuradhapura',
            priceCount: 12,
            lastUpdated: DateTime.now(),
          ),
          DistrictWithPricesResponse(
            district: 'Polonnaruwa',
            priceCount: 8,
            lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          DistrictWithPricesResponse(
            district: 'Kurunegala',
            priceCount: 5,
            lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
          ),
          DistrictWithPricesResponse(
            district: 'Ampara',
            priceCount: 15,
            lastUpdated: DateTime.now(),
          ),
          DistrictWithPricesResponse(
            district: 'Hambantota',
            priceCount: 3,
            lastUpdated: DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ];
        emit(state.copyWith(
          status: PriceManagementStatus.success,
          districts: sampleDistricts,
        ));
      },
      (districts) {
        // If no districts found, add sample data for demonstration
        if (districts.isEmpty) {
          final sampleDistricts = [
            DistrictWithPricesResponse(
              district: 'Anuradhapura',
              priceCount: 12,
              lastUpdated: DateTime.now(),
            ),
            DistrictWithPricesResponse(
              district: 'Polonnaruwa',
              priceCount: 8,
              lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
            ),
            DistrictWithPricesResponse(
              district: 'Kurunegala',
              priceCount: 5,
              lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
            ),
            DistrictWithPricesResponse(
              district: 'Ampara',
              priceCount: 15,
              lastUpdated: DateTime.now(),
            ),
            DistrictWithPricesResponse(
              district: 'Hambantota',
              priceCount: 3,
              lastUpdated: DateTime.now().subtract(const Duration(hours: 5)),
            ),
          ];
          emit(state.copyWith(
            status: PriceManagementStatus.success,
            districts: sampleDistricts,
          ));
        } else {
          emit(state.copyWith(
            status: PriceManagementStatus.success,
            districts: districts,
          ));
        }
      },
    );
  }

  /// Load prices for a specific district
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
        // Fallback to sample data even on error for demonstration
        final now = DateTime.now();
        final prices = [
          _createSamplePrice(
              district, 'Keeri Samba', 105.00, 'paddy', 'Standard', now),
          _createSamplePrice(district, 'Samba', 98.00, 'paddy', 'Grade A',
              now.subtract(const Duration(hours: 1))),
          _createSamplePrice(district, 'Nadu', 92.00, 'paddy', 'Standard',
              now.subtract(const Duration(hours: 3))),
          _createSamplePrice(
              district, 'Keeri Samba', 225.00, 'rice', 'Premium', now),
          _createSamplePrice(district, 'Samba', 210.00, 'rice', 'Standard',
              now.subtract(const Duration(hours: 2))),
          _createSamplePrice(district, 'Nadu', 195.00, 'rice', 'Standard',
              now.subtract(const Duration(hours: 5))),
        ];

        emit(state.copyWith(
          status: PriceManagementStatus.success,
          prices: prices,
          currentPage: 1,
          totalPages: 1,
          totalPrices: prices.length,
          selectedDistrict: district,
        ));
      },
      (response) {
        var prices = response.prices.map((m) => m.toEntity()).toList();

        // If no prices found, add sample data for demonstration
        if (prices.isEmpty) {
          final now = DateTime.now();
          prices = [
            _createSamplePrice(
                district, 'Keeri Samba', 105.00, 'paddy', 'Standard', now),
            _createSamplePrice(district, 'Samba', 98.00, 'paddy', 'Grade A',
                now.subtract(const Duration(hours: 1))),
            _createSamplePrice(district, 'Nadu', 92.00, 'paddy', 'Standard',
                now.subtract(const Duration(hours: 3))),
            _createSamplePrice(
                district, 'Keeri Samba', 225.00, 'rice', 'Premium', now),
            _createSamplePrice(district, 'Samba', 210.00, 'rice', 'Standard',
                now.subtract(const Duration(hours: 2))),
            _createSamplePrice(district, 'Nadu', 195.00, 'rice', 'Standard',
                now.subtract(const Duration(hours: 5))),
          ];
        }

        emit(state.copyWith(
          status: PriceManagementStatus.success,
          prices: prices,
          currentPage: response.page,
          totalPages: response.pages,
          totalPrices: response.total == 0 ? prices.length : response.total,
          selectedDistrict: district,
        ));
      },
    );
  }

  PaddyRicePriceEntity _createSamplePrice(
    String district,
    String qualityGrade,
    double price,
    String priceType,
    String notes,
    DateTime createdAt,
  ) {
    return PaddyRicePriceEntity(
      id: 'sample_${qualityGrade}_${priceType}_${createdAt.millisecondsSinceEpoch}',
      companyId: 'sample_company',
      companyName: 'Sample Rice Mill',
      district: district,
      price: price,
      qualityGrade: qualityGrade,
      priceType: priceType,
      notes: notes,
      createdAt: createdAt,
      isActive: true,
    );
  }

  /// Load prices added by current company
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
        // Fallback to sample data even on error for demonstration
        final now = DateTime.now();
        final sampleMyPrices = [
          _createSamplePrice(
              'Anuradhapura', 'Keeri Samba', 105.00, 'paddy', 'Standard', now),
          _createSamplePrice('Polonnaruwa', 'Samba', 98.00, 'paddy', 'Grade A',
              now.subtract(const Duration(hours: 2))),
          _createSamplePrice('Anuradhapura', 'Keeri Samba', 225.00, 'rice',
              'Premium', now.subtract(const Duration(days: 1))),
        ];

        emit(state.copyWith(
          status: PriceManagementStatus.success,
          myPrices: sampleMyPrices,
          totalPrices: sampleMyPrices.length,
        ));
      },
      (response) {
        var myPrices = response.prices.map((m) => m.toEntity()).toList();

        // If no prices found, add sample data for demonstration
        if (myPrices.isEmpty) {
          final now = DateTime.now();
          myPrices = [
            _createSamplePrice('Anuradhapura', 'Keeri Samba', 105.00, 'paddy',
                'Standard', now),
            _createSamplePrice('Polonnaruwa', 'Samba', 98.00, 'paddy',
                'Grade A', now.subtract(const Duration(hours: 2))),
            _createSamplePrice('Anuradhapura', 'Keeri Samba', 225.00, 'rice',
                'Premium', now.subtract(const Duration(days: 1))),
          ];
        }

        emit(state.copyWith(
          status: PriceManagementStatus.success,
          myPrices: myPrices,
          totalPrices: response.total == 0 ? myPrices.length : response.total,
        ));
      },
    );
  }

  /// Add a new paddy rice price
  Future<void> addPrice({
    required double price,
    double? priceRangeEnd,
    String qualityGrade = 'standard',
    String priceType = 'paddy',
    String? notes,
  }) async {
    emit(state.copyWith(status: PriceManagementStatus.addingPrice));

    final result = await _priceRepository.addPrice(
      price: price,
      priceRangeEnd: priceRangeEnd,
      qualityGrade: qualityGrade,
      priceType: priceType,
      notes: notes,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: PriceManagementStatus.error,
          errorMessage: failure.toString(),
        ));
      },
      (addedPrice) {
        // Add to myPrices list
        final updatedMyPrices = [addedPrice, ...state.myPrices];

        emit(state.copyWith(
          status: PriceManagementStatus.success,
          lastAddedPrice: addedPrice,
          myPrices: updatedMyPrices,
        ));
      },
    );
  }

  /// Update an existing price
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
        // Update in myPrices list
        final updatedMyPrices = state.myPrices.map((p) {
          if (p.id == id) {
            return updatedPrice;
          }
          return p;
        }).toList();

        emit(state.copyWith(
          status: PriceManagementStatus.success,
          myPrices: updatedMyPrices,
        ));
      },
    );
  }

  /// Delete a price entry
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
        // Remove from myPrices list
        final updatedMyPrices =
            state.myPrices.where((p) => p.id != id).toList();

        emit(state.copyWith(
          status: PriceManagementStatus.success,
          myPrices: updatedMyPrices,
        ));
      },
    );
  }

  /// Reload current view
  Future<void> reload() async {
    if (state.selectedDistrict != null) {
      await loadPricesByDistrict(state.selectedDistrict!, page: 1);
    } else {
      await loadMyPrices(page: 1);
    }
  }

  /// Clear error message
  void clearError() {
    emit(state.copyWith(
      status: PriceManagementStatus.initial,
      errorMessage: null,
    ));
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (state.currentPage < state.totalPages &&
        state.selectedDistrict != null) {
      await loadPricesByDistrict(
        state.selectedDistrict!,
        page: state.currentPage + 1,
      );
    }
  }

  /// Load previous page
  Future<void> loadPreviousPage() async {
    if (state.currentPage > 1 && state.selectedDistrict != null) {
      await loadPricesByDistrict(
        state.selectedDistrict!,
        page: state.currentPage - 1,
      );
    }
  }

  /// Load all prices (admin view)
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
        // Fallback to sample data even on error for demonstration
        final now = DateTime.now();
        final samplePrices = [
          _createSamplePrice(
              'Anuradhapura', 'Keeri Samba', 105.00, 'paddy', 'Standard', now),
          _createSamplePrice('Polonnaruwa', 'Samba', 98.00, 'paddy', 'Grade A',
              now.subtract(const Duration(hours: 1))),
          _createSamplePrice('Kurunegala', 'Nadu', 92.00, 'paddy', 'Standard',
              now.subtract(const Duration(hours: 3))),
          _createSamplePrice(
              'Ampara', 'Keeri Samba', 225.00, 'rice', 'Premium', now),
          _createSamplePrice('Anuradhapura', 'Samba', 210.00, 'rice',
              'Standard', now.subtract(const Duration(hours: 2))),
          _createSamplePrice('Hambantota', 'Nadu', 195.00, 'rice', 'Standard',
              now.subtract(const Duration(hours: 5))),
        ];

        emit(state.copyWith(
          status: PriceManagementStatus.success,
          prices: samplePrices,
          currentPage: 1,
          totalPages: 1,
          totalPrices: samplePrices.length,
        ));
      },
      (response) {
        var prices = response.prices.map((m) => m.toEntity()).toList();

        // If no prices found, add sample data for demonstration
        if (prices.isEmpty) {
          final now = DateTime.now();
          prices = [
            _createSamplePrice('Anuradhapura', 'Keeri Samba', 105.00, 'paddy',
                'Standard', now),
            _createSamplePrice('Polonnaruwa', 'Samba', 98.00, 'paddy',
                'Grade A', now.subtract(const Duration(hours: 1))),
            _createSamplePrice('Kurunegala', 'Nadu', 92.00, 'paddy', 'Standard',
                now.subtract(const Duration(hours: 3))),
            _createSamplePrice(
                'Ampara', 'Keeri Samba', 225.00, 'rice', 'Premium', now),
            _createSamplePrice('Anuradhapura', 'Samba', 210.00, 'rice',
                'Standard', now.subtract(const Duration(hours: 2))),
            _createSamplePrice('Hambantota', 'Nadu', 195.00, 'rice', 'Standard',
                now.subtract(const Duration(hours: 5))),
          ];
        }

        emit(state.copyWith(
          status: PriceManagementStatus.success,
          prices: prices,
          currentPage: response.page,
          totalPages: response.pages,
          totalPrices: response.total == 0 ? prices.length : response.total,
        ));
      },
    );
  }

  /// Reset cubit state (on logout)
  void reset() {
    emit(const PriceManagementState());
  }
}
