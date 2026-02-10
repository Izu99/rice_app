// lib/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
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
                    _buildSectionTitle('Account', 'ගිණුම'),
                    const SizedBox(height: 12),
                    _buildAccountSection(state),
                    const SizedBox(height: 24),

                    // Settings Section
                    _buildSectionTitle('Settings', 'සැකසුම්'),
                    const SizedBox(height: 12),
                    _buildSettingsSection(state),
                    const SizedBox(height: 24),

                    // Support Section
                    _buildSectionTitle('Support', 'සහාය'),
                    const SizedBox(height: 12),
                    _buildSupportSection(),
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
      expandedHeight: 60,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      title: const Text('Profile'),
      actions: [
        if (state.pendingSyncCount > 0)
          Badge(
            label: Text(state.pendingSyncCount.toString()),
            child: IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () {
                // TODO: Sync data
              },
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
                  user?.name ?? 'User',
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
                    user?.roleDisplayName ?? 'Operator',
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
            title: 'Edit Profile',
            subtitle: 'Change name, email, photo',
            onTap: () => _showEditProfileDialog(state),
          ),
          const Divider(height: 1),
          ProfileMenuItem(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your password',
            onTap: _showChangePasswordDialog,
          ),
          const Divider(height: 1),
          ProfileMenuItem(
            icon: Icons.business,
            title: 'Company Info',
            subtitle: state.company?.name ?? 'Not set',
            onTap: () {
              if (state.company != null) {
                _showCompanyDialog(state);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No company info available')),
                );
              }
            },
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
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Enable dark theme',
            trailing: Switch(
              value: state.isDarkMode,
              onChanged: (value) {
                context.read<ProfileCubit>().toggleDarkMode(value);
              },
              activeThumbColor: AppColors.primary,
            ),
          ),
          const Divider(height: 1),
          ProfileMenuItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Push notifications',
            trailing: Switch(
              value: state.notificationsEnabled,
              onChanged: (value) {
                context.read<ProfileCubit>().toggleNotifications(value);
              },
              activeThumbColor: AppColors.primary,
            ),
          ),
          const Divider(height: 1),
          ProfileMenuItem(
            icon: Icons.fingerprint,
            title: 'Biometric Login',
            subtitle: 'Use fingerprint/face ID',
            trailing: Switch(
              value: state.biometricEnabled,
              onChanged: (value) {
                context.read<ProfileCubit>().toggleBiometric(value);
              },
              activeThumbColor: AppColors.primary,
            ),
          ),
          const Divider(height: 1),
          ProfileMenuItem(
            icon: Icons.language,
            title: 'Language',
            subtitle: state.language == 'en' ? 'English' : 'සිංහල',
            onTap: _showLanguageDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
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
            icon: Icons.help_outline,
            title: 'Help & FAQ',
            subtitle: 'Get help and answers',
            onTap: () {
              // TODO: Navigate to help
            },
          ),
          const Divider(height: 1),
          ProfileMenuItem(
            icon: Icons.description_outlined,
            title: 'Terms & Privacy',
            subtitle: 'Read our policies',
            onTap: () {
              // TODO: Navigate to terms
            },
          ),
          const Divider(height: 1),
          ProfileMenuItem(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Help us improve',
            onTap: () {
              // TODO: Show feedback dialog
            },
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
        title: 'Logout',
        subtitle: 'Sign out of your account',
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
            'Rice Mill ERP',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            'Version ${state.appVersion}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
          ),
          if (state.lastSyncTime != null)
            Text(
              'Last sync: ${state.formattedLastSync}',
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProfileCubit>().updateProfile(
                    name: nameController.text,
                    email: emailController.text,
                  );
            },
            child: const Text('Save'),
          ),
        ],
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
              title: const Text('Change Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: state.isChangingPassword
                      ? null
                      : () {
                          if (newController.text != confirmController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Passwords do not match'),
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
                  child: state.isChangingPassword
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Change'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showCompanyDialog(ProfileState state) {
    if (state.company == null) return;

    final nameController = TextEditingController(text: state.company?.name);
    final phoneController = TextEditingController(text: state.company?.phone);
    final addressController =
        TextEditingController(text: state.company?.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Company Info'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProfileCubit>().updateCompany(
                    name: nameController.text,
                    phone: phoneController.text,
                    address: addressController.text,
                  );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              onTap: () {
                Navigator.pop(context);
                this.context.read<ProfileCubit>().changeLanguage('en');
              },
            ),
            ListTile(
              leading: const Text('🇱🇰', style: TextStyle(fontSize: 24)),
              title: const Text('සිංහල'),
              onTap: () {
                Navigator.pop(context);
                this.context.read<ProfileCubit>().changeLanguage('si');
              },
            ),
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
