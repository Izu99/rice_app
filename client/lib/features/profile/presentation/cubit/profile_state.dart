// lib/features/profile/presentation/cubit/profile_state.dart

import 'package:equatable/equatable.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../../data/models/company_model.dart';

enum ProfileStatus {
  initial,
  loading,
  loaded,
  updating,
  error,
}

enum PasswordChangeStatus {
  initial,
  changing,
  success,
  failure,
}

class ProfileState extends Equatable {
  final ProfileStatus status;
  final PasswordChangeStatus passwordChangeStatus;
  final UserEntity? user;
  final CompanyModel? company;
  final String? errorMessage;
  final String? successMessage;
  final bool isDarkMode;
  final String language;
  final bool notificationsEnabled;
  final bool biometricEnabled;
  final DateTime? lastSyncTime;
  final int pendingSyncCount;
  final String appVersion;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.passwordChangeStatus = PasswordChangeStatus.initial,
    this.user,
    this.company,
    this.errorMessage,
    this.successMessage,
    this.isDarkMode = false,
    this.language = 'en',
    this.notificationsEnabled = true,
    this.biometricEnabled = false,
    this.lastSyncTime,
    this.pendingSyncCount = 0,
    this.appVersion = '1.0.0',
  });

  factory ProfileState.initial() => const ProfileState();

  bool get isLoading => status == ProfileStatus.loading;
  bool get isUpdating => status == ProfileStatus.updating;
  bool get hasError => status == ProfileStatus.error;
  bool get isChangingPassword =>
      passwordChangeStatus == PasswordChangeStatus.changing;

  String? get formattedLastSync {
    if (lastSyncTime == null) return null;
    final diff = DateTime.now().difference(lastSyncTime!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  ProfileState copyWith({
    ProfileStatus? status,
    PasswordChangeStatus? passwordChangeStatus,
    UserEntity? user,
    CompanyModel? company,
    String? errorMessage,
    String? successMessage,
    bool? isDarkMode,
    String? language,
    bool? notificationsEnabled,
    bool? biometricEnabled,
    DateTime? lastSyncTime,
    int? pendingSyncCount,
    String? appVersion,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      passwordChangeStatus: passwordChangeStatus ?? this.passwordChangeStatus,
      user: clearUser ? null : (user ?? this.user),
      company: clearUser ? null : (company ?? this.company),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: successMessage,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  @override
  List<Object?> get props => [
        status,
        passwordChangeStatus,
        user,
        company,
        errorMessage,
        successMessage,
        isDarkMode,
        language,
        notificationsEnabled,
        biometricEnabled,
        lastSyncTime,
        pendingSyncCount,
        appVersion,
      ];
}
