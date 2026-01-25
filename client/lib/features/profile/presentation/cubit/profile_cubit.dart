// lib/features/profile/presentation/cubit/profile_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/auth_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final AuthRepository _authRepository;

  ProfileCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(ProfileState.initial());

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
  }) async {
    if (state.company == null) return;

    emit(state.copyWith(status: ProfileStatus.updating, clearError: true));

    final updatedCompany = state.company!.copyWith(
      name: name,
      address: address,
      phone: phone,
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

  void toggleDarkMode(bool value) {
    emit(state.copyWith(isDarkMode: value));
    // TODO: Save to preferences
  }

  void toggleNotifications(bool value) {
    emit(state.copyWith(notificationsEnabled: value));
    // TODO: Save to preferences
  }

  void toggleBiometric(bool value) {
    emit(state.copyWith(biometricEnabled: value));
    // TODO: Save to preferences
  }

  void changeLanguage(String language) {
    emit(state.copyWith(language: language));
    // TODO: Save to preferences and update app locale
  }

  void resetPasswordChangeStatus() {
    emit(state.copyWith(passwordChangeStatus: PasswordChangeStatus.initial));
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }
}

