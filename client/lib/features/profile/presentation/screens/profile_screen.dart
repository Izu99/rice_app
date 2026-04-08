// lib/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../core/constants/districts.dart';
import '../../../../core/shared_widgets/confirmation_dialog.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/profile_menu_item.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<ProfileCubit>().loadProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Refresh profile data when app comes to foreground
      context.read<ProfileCubit>().loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listenWhen: (previous, current) =>
          previous.successMessage != current.successMessage ||
          previous.status != current.status,
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state.status == ProfileStatus.initial && state.user == null) {
          context.go('/login');
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(state),
              SliverPadding(
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Profile Card
                    _buildProfileCard(state),
                    const SizedBox(height: 24),

                    // Account Section
                    _buildSectionTitle(SiStrings.profileTitle,
                        SiStrings.isSinhala ? 'Account' : 'ගිණුම'),
                    const SizedBox(height: 12),
                    _buildAccountSection(state),
                    const SizedBox(height: 24),

                    // Settings Section
                    _buildSectionTitle(
                        SiStrings.isSinhala ? 'සැකසුම්' : 'Settings',
                        SiStrings.isSinhala ? 'Settings' : 'සැකසුම්'),
                    const SizedBox(height: 12),
                    _buildSettingsSection(state),
                    const SizedBox(height: 24),

                    // Logout Button
                    _buildLogoutButton(),
                    const SizedBox(height: 24),

                    // App Version
                    _buildAppVersion(state),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(ProfileState state) {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1C1C2E),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black12,
      scrolledUnderElevation: 1,
      title: Text(
        SiStrings.profileTitle,
        style: const TextStyle(
          color: Color(0xFF1C1C2E),
          fontWeight: FontWeight.w800,
          fontSize: 17,
        ),
      ),
      centerTitle: false,
      actions: [
        if (state.pendingSyncCount > 0)
          Badge(
            label: Text(state.pendingSyncCount.toString()),
            child: IconButton(
              icon: const Icon(Icons.sync, color: Color(0xFF1C1C2E)),
              onPressed: () {},
            ),
          ),
      ],
    );
  }

  Widget _buildProfileCard(ProfileState state) {
    final user = state.user;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: user?.avatar != null
                ? ClipOval(
                    child: Image.network(
                      user!.avatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildAvatarPlaceholder(user),
                    ),
                  )
                : _buildAvatarPlaceholder(user),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? SiStrings.roleUser,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.phone ?? '',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRoleDisplayName(user?.role),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Edit Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, size: 18),
            ),
            color: AppColors.white,
            onPressed: () => _showEditProfileDialog(state),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(dynamic role) {
    if (role == null) return SiStrings.roleOperator;
    final roleStr = role.toString().split('.').last;
    switch (roleStr) {
      case 'admin':
        return SiStrings.roleAdmin;
      case 'operator':
        return SiStrings.roleOperator;
      default:
        return SiStrings.roleOperator;
    }
  }

  Widget _buildAvatarPlaceholder(dynamic user) {
    return Center(
      child: Text(
        user?.initials ?? 'U',
        style: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountSection(ProfileState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          ProfileMenuItem(
            icon: Icons.person_outline,
            title: SiStrings.editProfile,
            subtitle: SiStrings.editProfileSubtitle,
            onTap: () => _showEditProfileDialog(state),
          ),
          const Divider(height: 1),
          ProfileMenuItem(
            icon: Icons.lock_outline,
            title: SiStrings.changePassword,
            subtitle: SiStrings.changePasswordSubtitle,
            onTap: _showChangePasswordDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(ProfileState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          ProfileMenuItem(
            icon: Icons.language,
            title: SiStrings.language,
            subtitle: state.language == 'en' ? 'English' : 'සිංහල',
            onTap: _showLanguageDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: ProfileMenuItem(
        icon: Icons.logout,
        title: SiStrings.logout,
        subtitle: SiStrings.logoutSubtitle,
        iconColor: AppColors.error,
        titleColor: AppColors.error,
        onTap: _handleLogout,
      ),
    );
  }

  Widget _buildAppVersion(ProfileState state) {
    return Center(
      child: Column(
        children: [
          Text(
            'ricemill',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '${SiStrings.version} ${state.appVersion}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
          ),
          if (state.lastSyncTime != null)
            Text(
              '${SiStrings.lastSynced} ${state.formattedLastSync}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(ProfileState state) {
    final nameController = TextEditingController(text: state.user?.name);
    final emailController = TextEditingController(text: state.user?.email);

    // Company fields
    final companyNameController =
        TextEditingController(text: state.company?.name);
    final phoneController = TextEditingController(text: state.company?.phone);
    final secondaryPhoneController =
        TextEditingController(text: state.company?.secondaryPhone);
    final addressController =
        TextEditingController(text: state.company?.address);
    final regNoController =
        TextEditingController(text: state.company?.registrationNumber);
    final taxNoController =
        TextEditingController(text: state.company?.taxNumber);
    final websiteController =
        TextEditingController(text: state.company?.website);
    String? selectedDistrict = state.company?.district;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL)),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with centered icon
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppDimensions.radiusL)),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_note_rounded,
                        size: 40, color: AppColors.primary),
                  ),
                ),
              ),

              // Scrollable Body - Combined Profile & Company
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDialogSectionTitle(SiStrings.updateProfile),
                      const SizedBox(height: 16),
                      _buildDialogField(
                          nameController, SiStrings.name, Icons.person_outline),
                      const SizedBox(height: 12),
                      _buildDialogField(emailController, SiStrings.email,
                          Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress),

                      const SizedBox(height: 24),
                      _buildDialogSectionTitle(SiStrings.companyInfo),
                      const SizedBox(height: 16),
                      _buildDialogField(companyNameController,
                          SiStrings.companyName, Icons.business_outlined),
                      const SizedBox(height: 12),
                      _buildDialogField(phoneController, SiStrings.phoneNumber,
                          Icons.phone_outlined,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 12),
                      _buildDialogField(
                          secondaryPhoneController,
                          SiStrings.secondaryPhone,
                          Icons.phone_android_outlined,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 12),
                      _buildDialogField(
                          regNoController,
                          SiStrings.registrationNumber,
                          Icons.app_registration_rounded),
                      const SizedBox(height: 12),
                      _buildDialogField(taxNoController, SiStrings.taxNumber,
                          Icons.receipt_long_outlined),
                      const SizedBox(height: 12),

                      // District Dropdown
                      Text(
                        SiStrings.district,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedDistrict,
                            isExpanded: true,
                            hint: Text(SiStrings.district),
                            items: SriLankanDistricts.sortedDistricts.map((d) {
                              return DropdownMenuItem(value: d, child: Text(d));
                            }).toList(),
                            onChanged: (val) {
                              setDialogState(() => selectedDistrict = val);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      _buildDialogField(addressController, SiStrings.address,
                          Icons.location_on_outlined,
                          maxLines: 2),
                      const SizedBox(height: 12),
                      _buildDialogField(websiteController, SiStrings.website,
                          Icons.language_outlined,
                          keyboardType: TextInputType.url),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F6FA),
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(AppDimensions.radiusL)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<ProfileCubit>().updateProfile(
                              name: nameController.text,
                              email: emailController.text,
                            );
                        context.read<ProfileCubit>().updateCompany(
                              name: companyNameController.text,
                              phone: phoneController.text,
                              address: addressController.text,
                              secondaryPhone: secondaryPhoneController.text,
                              email: emailController.text,
                              district: selectedDistrict,
                              registrationNumber: regNoController.text,
                              taxNumber: taxNoController.text,
                              website: websiteController.text,
                            );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(SiStrings.save,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF444466),
                        side: const BorderSide(color: Color(0xFFE8E8EE)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.white,
                      ),
                      child: Text(SiStrings.cancel,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1C1C2E),
      ),
    );
  }

  Widget _buildDialogField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ProfileCubit>(),
        child: BlocConsumer<ProfileCubit, ProfileState>(
          listenWhen: (prev, curr) =>
              prev.passwordChangeStatus != curr.passwordChangeStatus,
          listener: (context, state) {
            if (state.passwordChangeStatus == PasswordChangeStatus.success) {
              Navigator.pop(dialogContext);
              context.read<ProfileCubit>().resetPasswordChangeStatus();
            }
          },
          builder: (context, state) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL)),
              contentPadding: EdgeInsets.zero,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with centered icon
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppDimensions.radiusL)),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_outline,
                            size: 40, color: AppColors.primary),
                      ),
                    ),
                  ),

                  // Scrollable Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            SiStrings.resetPassword,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1C1C2E),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: currentController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: SiStrings.currentPassword,
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: newController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: SiStrings.newPassword,
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: confirmController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: SiStrings.confirmPassword,
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                          if (state.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                state.errorMessage!,
                                style: const TextStyle(
                                    color: AppColors.error, fontSize: 12),
                              ),
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Footer
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F6FA),
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(AppDimensions.radiusL)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: state.isChangingPassword
                              ? null
                              : () {
                                  if (newController.text !=
                                      confirmController.text) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            SiStrings.passwordsDoNotMatch),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                    return;
                                  }
                                  context.read<ProfileCubit>().changePassword(
                                        currentPassword: currentController.text,
                                        newPassword: newController.text,
                                      );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: state.isChangingPassword
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(SiStrings.change,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF444466),
                            side: const BorderSide(color: Color(0xFFE8E8EE)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Colors.white,
                          ),
                          child: Text(SiStrings.cancel,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.language_outlined,
                      size: 32, color: AppColors.primary),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SiStrings.selectLanguage,
                    style: const TextStyle(
                        color: Color(0xFF1C1C2E),
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildLanguageTile('🇺🇸', 'English', 'en', dialogContext),
                  const SizedBox(height: 8),
                  _buildLanguageTile('🇱🇰', 'සිංහල', 'si', dialogContext),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
      String flag, String label, String code, BuildContext dialogContext) {
    return InkWell(
      onTap: () {
        Navigator.pop(dialogContext);
        context.read<ProfileCubit>().changeLanguage(code);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1C1C2E),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Color(0xFFB0B0C0), size: 20),
          ],
        ),
      ),
    );
  }

  void _handleLogout() async {
    final confirmed = await ConfirmationDialog.showLogout(context);

    if (confirmed && mounted) {
      context.read<AuthCubit>().logout();
    }
  }
}
