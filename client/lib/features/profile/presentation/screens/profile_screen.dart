// lib/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/si_strings.dart';
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
                    _buildSectionTitle('ගිණුම', 'Account'),
                    const SizedBox(height: 12),
                    _buildAccountSection(state),
                    const SizedBox(height: 24),

                    // Settings Section
                    _buildSectionTitle('සැකසුම්', 'Settings'),
                    const SizedBox(height: 12),
                    _buildSettingsSection(state),
                    const SizedBox(height: 24),

                    // Support Section
                    _buildSectionTitle('සහාය', 'Support'),
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
      title: Text(SiStrings.profile),
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
                  user?.name ?? 'පරිශීලකයා', // User
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
    if (role == null) return 'ක්‍රියාකරු'; // Operator
    final roleStr = role.toString().split('.').last;
    switch (roleStr) {
      case 'admin':
        return 'පරිපාලක'; // Admin
      case 'operator':
        return 'ක්‍රියාකරු'; // Operator
      default:
        return 'ක්‍රියාකරු';
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
            title: 'ගිණුම යාවත්කාලීන කරන්න', // Edit Profile
            subtitle: 'නම, ඊමේල්, ඡායාරූපය වෙනස් කරන්න',
            onTap: () => _showEditProfileDialog(state),
          ),
          const Divider(height: 1),
          ProfileMenuItem(
            icon: Icons.lock_outline,
            title: 'මුරපදය වෙනස් කරන්න', // Change Password
            subtitle: 'ඔබගේ මුරපදය යාවත්කාලීන කරන්න',
            onTap: _showChangePasswordDialog,
          ),
          const Divider(height: 1),
          ProfileMenuItem(
            icon: Icons.business,
            title: 'ආයතනයේ විස්තර', // Company Info
            subtitle: state.company?.name ?? 'ඇතුළත් කර නැත',
            onTap: () {
              if (state.company != null) {
                _showCompanyDialog(state);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ආයතනයේ විස්තර ලබා ගත නොහැක')),
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
            title: 'අඳුරු තේමාව', // Dark Mode
            subtitle: 'Dark Mode සක්‍රීය කරන්න',
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
            title: 'දැනුම්දීම්', // Notifications
            subtitle: 'Push Notifications',
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
            subtitle: 'ඇඟිලි සලකුණු/මුහුණ හඳුනාගැනීම භාවිතා කරන්න',
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
            title: 'භාෂාව', // Language
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
            title: 'උදව් සහ නිතර අසන පැණ', // Help & FAQ
            subtitle: 'සහාය ලබා ගන්න',
            onTap: () {
              // TODO: Navigate to help
            },
          ),
          const Divider(height: 1),
          ProfileMenuItem(
            icon: Icons.description_outlined,
            title: 'කොන්දේසි සහ රහස්‍යතාව', // Terms & Privacy
            subtitle: 'අපගේ ප්‍රතිපත්ති කියවන්න',
            onTap: () {
              // TODO: Navigate to terms
            },
          ),
          const Divider(height: 1),
          ProfileMenuItem(
            icon: Icons.feedback_outlined,
            title: 'ප්‍රතිචාර එවන්න', // Send Feedback
            subtitle: 'අපව වැඩිදියුණු කිරීමට උදව් වන්න',
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
        title: SiStrings.logout,
        subtitle: 'ඔබගේ ගිණුමෙන් ඉවත් වන්න',
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
              'අවසන් වරට සමමුහුර්ත කළේ: ${state.formattedLastSync}',
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
        title: const Text('ගිණුම යාවත්කාලීන කිරීම'), // Edit Profile
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'නම', // Name
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'විද්‍යුත් තැපෑල (Email)', // Email
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(SiStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ProfileCubit>().updateProfile(
                    name: nameController.text,
                    email: emailController.text,
                  );
            },
            child: Text(SiStrings.save),
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
              title: Text(SiStrings.resetPassword),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'වත්මන් මුරපදය', // Current Password
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'නව මුරපදය', // New Password
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'මුරපදය නැවත ඇතුළත් කරන්න', // Confirm Password
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
                  child: Text(SiStrings.cancel),
                ),
                ElevatedButton(
                  onPressed: state.isChangingPassword
                      ? null
                      : () {
                          if (newController.text != confirmController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('මුරපද එකිනෙකට නොගැලපේ'), // Passwords do not match
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
                      : const Text('වෙනස් කරන්න'), // Change
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
        title: const Text('ආයතනයේ විස්තර'), // Company Info
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'ආයතනයේ නම', // Company Name
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'දුරකථන අංකය', // Phone
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'ලිපිනය', // Address
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
            child: Text(SiStrings.cancel),
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
            child: Text(SiStrings.save),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('භාෂාව තෝරන්න'), // Select Language
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              onTap: () {
                Navigator.pop(context);
                context.read<ProfileCubit>().changeLanguage('en');
              },
            ),
            ListTile(
              leading: const Text('🇱🇰', style: TextStyle(fontSize: 24)),
              title: const Text('සිංහල'),
              onTap: () {
                Navigator.pop(context);
                context.read<ProfileCubit>().changeLanguage('si');
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

