import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_interface/MAIN%20UTILS/app_sizes.dart';
import 'package:user_interface/MAIN%20UTILS/app_theme.dart';
import 'package:user_interface/MAIN%20UTILS/page_transition.dart';
import 'package:user_interface/SCREENS/profile/profile_screen.dart';
import 'package:user_interface/SCREENS/login/login_screen.dart';
import 'package:user_interface/SERVICES/AUTHETNTICATION%20HELPERS/secure_storage_service.dart';
import 'package:user_interface/services/user_service.dart';

import 'package:user_interface/main.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

// 4. Change to ConsumerState
class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;
  final SecureStorageService _storageService = SecureStorageService();
  final UserService _userService = UserService();

  Future<void> _handleLogout() async {
    await _storageService.deleteTokens();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        slideRoute(const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _handleDeleteAccount() async {
    final success = await _userService.deleteAccount();

    if (!mounted) return;

    Navigator.of(context).pop();

    if (success) {
      await _storageService.deleteTokens();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          slideRoute(const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete account. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    final TextEditingController oldPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 30, 40, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Change Password',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField(
                    controller: oldPassController,
                    hint: 'Current Password',
                  ),
                  const SizedBox(height: 15),
                  _buildDialogTextField(
                    controller: newPassController,
                    hint: 'New Password',
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(color: Color(0xFF8B2C87)),
                  ],
                ],
              ),
              actions: isLoading
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(color: Colors.white54),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final oldPass = oldPassController.text;
                          final newPass = newPassController.text;

                          if (oldPass.isEmpty || newPass.isEmpty) {
                            return;
                          }

                          setStateDialog(() => isLoading = true);

                          final success = await _userService.changePassword(
                            oldPassword: oldPass,
                            newPassword: newPass,
                          );

                          if (ctx.mounted) {
                            setStateDialog(() => isLoading = false);

                            if (success) {
                              // Note: This assumes userService returns bool as per your previous code
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password updated successfully',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Failed. Check your current password.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          'Update',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF8B2C87),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 30, 40, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Account',
          style: GoogleFonts.poppins(
            color: Colors.redAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone and you will lose all your data.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) => const Center(
                  child: CircularProgressIndicator(color: Colors.redAccent),
                ),
              );

              _handleDeleteAccount();
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        height: AppSizes.screenHeight,
        width: AppSizes.screenWidth,
        decoration: AppTheme.backgroundGradientDecoration,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildSectionHeader('Account'),
                const SizedBox(height: 15),
                _buildSettingsTile(
                  context,
                  icon: IconlyBold.profile,
                  title: 'Edit Profile',
                  subtitle: 'Update personal details',
                  onTap: () {
                    // 5. THIS IS THE ONLY LOGIC CHANGED
                    // Update Provider to switch to Profile tab (Index 3)
                    ref.read(bottomNavIndexProvider.notifier).state = 3;
                    // Close Settings page
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 10),
                _buildSettingsTile(
                  context,
                  icon: IconlyBold.lock,
                  title: 'Change Password',
                  subtitle: 'Update your security',
                  onTap: _showChangePasswordDialog,
                ),
                const SizedBox(height: 30),
                _buildSectionHeader('Preferences'),
                const SizedBox(height: 15),
                _buildSwitchTile(
                  context,
                  icon: IconlyBold.notification,
                  title: 'Notifications',
                  value: _notificationsEnabled,
                  onChanged: (val) {
                    setState(() => _notificationsEnabled = val);
                  },
                ),
                const SizedBox(height: 30),
                _buildSectionHeader('Danger Zone'),
                const SizedBox(height: 15),
                _buildDangerTile(
                  context,
                  icon: IconlyBold.delete,
                  title: 'Delete Account',
                  onTap: _showDeleteAccountDialog,
                ),
                const SizedBox(height: 10),
                _buildDangerTile(
                  context,
                  icon: IconlyBold.logout,
                  title: 'Logout',
                  onTap: _handleLogout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.white70,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
        trailing: const Icon(
          IconlyLight.arrow_right_2,
          color: Colors.white54,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF8B2C87),
          activeTrackColor: const Color(0xFF8B2C87).withOpacity(0.4),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.white24,
        ),
      ),
    );
  }

  Widget _buildDangerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.redAccent, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.redAccent,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
