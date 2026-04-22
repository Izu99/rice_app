import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/store_listing_entity.dart';
import '../../../../domain/repositories/store_listing_repository.dart';
import 'store_state.dart';

class StoreCubit extends Cubit<StoreState> {
  final StoreListingRepository _repository;

  StoreCubit({required StoreListingRepository repository})
      : _repository = repository,
        super(const StoreState());

  Future<void> loadStats() async {
    emit(state.copyWith(status: StoreStatus.loading));

    final result = await _repository.getStats();
    result.fold(
      (failure) => emit(state.copyWith(
        status: StoreStatus.error,
        errorMessage: failure.message,
      )),
      (data) {
        final counts = data['counts'] as Map<String, dynamic>? ?? {};
        emit(state.copyWith(
          status: StoreStatus.success,
          categoryCounts: {
            StoreCategory.paddy: (counts['paddy'] as int?) ?? 0,
            StoreCategory.rice: (counts['rice'] as int?) ?? 0,
            StoreCategory.riceMeal: (counts['riceMeal'] as int?) ?? 0,
            StoreCategory.other: (counts['other'] as int?) ?? 0,
          },
          totalListings: (data['totalListings'] as int?) ?? 0,
          totalCompanies: (data['totalCompanies'] as int?) ?? 0,
          totalDistricts: (data['totalDistricts'] as int?) ?? 0,
        ));
      },
    );
  }

  Future<void> loadListingsByCategory(StoreCategory category) async {
    emit(state.copyWith(status: StoreStatus.loading, currentCategory: category));

    final result = await _repository.getListings(category: category, limit: 100);
    result.fold(
      (failure) => emit(state.copyWith(
        status: StoreStatus.error,
        errorMessage: failure.message,
      )),
      (listings) => emit(state.copyWith(
        status: StoreStatus.success,
        listings: listings,
        currentCategory: category,
      )),
    );
  }

  Future<bool> addListing({
    required StoreCategory category,
    required String variety,
    required String district,
    required String contactPhone,
    double quantityKg = 0,
    double pricePerKg = 0,
    String description = '',
    String? clientId,
  }) async {
    emit(state.copyWith(status: StoreStatus.adding));

    final result = await _repository.createListing(
      category: category,
      variety: variety,
      district: district,
      contactPhone: contactPhone,
      quantityKg: quantityKg,
      pricePerKg: pricePerKg,
      description: description,
      clientId: clientId,
    );

    return result.fold(
      (failure) {
        emit(state.copyWith(
          status: StoreStatus.error,
          errorMessage: failure.message,
        ));
        return false;
      },
      (newListing) {
        // Prepend to listings if we're on the same category
        final updatedListings = state.currentCategory == category
            ? [newListing, ...state.listings]
            : state.listings;

        // Update counts
        final updatedCounts = Map<StoreCategory, int>.from(state.categoryCounts);
        updatedCounts[category] = (updatedCounts[category] ?? 0) + 1;

        emit(state.copyWith(
          status: StoreStatus.success,
          listings: updatedListings,
          categoryCounts: updatedCounts,
          totalListings: state.totalListings + 1,
        ));
        return true;
      },
    );
  }

  Future<void> refreshCategory() async {
    if (state.currentCategory != null) {
      await loadListingsByCategory(state.currentCategory!);
    }
  }

  void clearError() {
    emit(state.copyWith(status: StoreStatus.success, errorMessage: null));
  }
}
