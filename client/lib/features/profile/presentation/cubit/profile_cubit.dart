// lib/features/profile/presentation/cubit/profile_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../../core/constants/si_strings.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final AuthRepository _authRepository;

  ProfileCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(ProfileState.initial()) {
    // Set initial language
    SiStrings.setLanguage(state.language);
  }

  Future<void> loadProfile() async {
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));

    final userResult = await _authRepository.getCurrentUser();
    final companyResult = await _authRepository.getCompany();
    final lastSyncResult = await _authRepository.getLastSyncTime();

    userResult.fold(
      (failure) {
        emit(state.copyWith(
          status: ProfileStatus.error,
          errorMessage: failure.message,
        ));
      },
      (user) {
        final company = companyResult.fold((l) => null, (r) => r);
        final lastSync = lastSyncResult.fold((l) => null, (r) => r);

        emit(state.copyWith(
          status: ProfileStatus.loaded,
          user: user,
          company: company,
          lastSyncTime: lastSync,
        ));
      },
    );
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? avatar,
  }) async {
    emit(state.copyWith(status: ProfileStatus.updating, clearError: true));

    final result = await _authRepository.updateProfile(
      name: name,
      email: email,
      avatar: avatar,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: ProfileStatus.loaded,
          errorMessage: failure.message,
        ));
      },
      (user) {
        emit(state.copyWith(
          status: ProfileStatus.loaded,
          user: user,
          successMessage: 'Profile updated successfully',
        ));
      },
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(state.copyWith(
      passwordChangeStatus: PasswordChangeStatus.changing,
      clearError: true,
    ));

    final result = await _authRepository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          passwordChangeStatus: PasswordChangeStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (_) {
        emit(state.copyWith(
          passwordChangeStatus: PasswordChangeStatus.success,
          successMessage: 'Password changed successfully',
        ));
      },
    );
  }

  Future<void> updateCompany({
    required String name,
    required String address,
    required String phone,
    String? email,
    String? district,
    String? registrationNumber,
    String? taxNumber,
    String? website,
    String? secondaryPhone,
  }) async {
    if (state.company == null) return;

    emit(state.copyWith(status: ProfileStatus.updating, clearError: true));

    final updatedCompany = state.company!.copyWith(
      name: name,
      address: address,
      phone: phone,
      email: email,
      district: district,
      registrationNumber: registrationNumber,
      taxNumber: taxNumber,
      website: website,
      secondaryPhone: secondaryPhone,
    );

    final result = await _authRepository.updateCompany(company: updatedCompany);

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: ProfileStatus.loaded,
          errorMessage: failure.message,
        ));
      },
      (company) {
        emit(state.copyWith(
          status: ProfileStatus.loaded,
          company: company,
          successMessage: 'Company updated successfully',
        ));
      },
    );
  }

  Future<void> logout() async {
    emit(state.copyWith(status: ProfileStatus.loading));
    await _authRepository.logout();
    emit(state.copyWith(status: ProfileStatus.initial, clearUser: true));
  }

  void reset() {
    emit(ProfileState.initial().copyWith(language: state.language));
  }

  void changeLanguage(String language) {
    SiStrings.setLanguage(language);
    emit(state.copyWith(language: language));
  }

  void resetPasswordChangeStatus() {
    emit(state.copyWith(passwordChangeStatus: PasswordChangeStatus.initial));
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}
