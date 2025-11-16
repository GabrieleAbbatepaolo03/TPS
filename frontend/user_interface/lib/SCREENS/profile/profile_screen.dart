import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:user_interface/MAIN%20UTILS/app_sizes.dart';
import 'package:user_interface/MAIN%20UTILS/my_vehicle_section.dart';
import 'package:user_interface/MAIN%20UTILS/page_title.dart'; 
import '../../MAIN UTILS/app_theme.dart';
import 'package:intl/intl.dart'; 

import 'package:user_interface/SERVICES/user_service.dart';
import 'package:user_interface/SERVICES/AUTHETNTICATION%20HELPERS/secure_storage_service.dart';
import 'package:user_interface/SCREENS/login/login_screen.dart';
import 'package:user_interface/MAIN%20UTILS/page_transition.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late Future<Map<String, dynamic>?> _userProfileFuture;

  @override
  void initState() {
    super.initState();
    _userProfileFuture = _userService.fetchUserProfile();
  }

  String _formatJoinDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final DateTime parsedDate = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(parsedDate);
    } catch (e) {
      return 'N/A'; 
    }
  }

  Future<void> _handleLogout() async {
    final storageService = SecureStorageService();
    await storageService.deleteTokens(); 

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        slideRoute(const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: AppSizes.screenHeight,
        decoration: AppTheme.backgroundGradientDecoration,
        child: SafeArea(
          child: FutureBuilder<Map<String, dynamic>?>(
            future: _userProfileFuture,
            builder: (context, snapshot) {
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                return Center(
                  child: Text(
                    'Failed to load profile', 
                    style: GoogleFonts.poppins(color: Colors.redAccent)
                  ),
                );
              }

              final userData = snapshot.data!;
              final String name = "${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}";
              final String email = userData['email'] ?? 'N/A';
              final String joined = _formatJoinDate(userData['date_joined']);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const PageTitle(title: 'Profile'),
                        _buildLogoutButton(context),
                      ],
                    ),
                    const SizedBox(height: 30),

                    _buildUserInfoCard(context, name: name, email: email, joined: joined),
                    const SizedBox(height: 30),

                    MyVehiclesSection(), 
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          ),
        ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context, {required String name, required String email, required String joined}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(25, 255, 255, 255),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(IconlyLight.profile, 'Name', name), 
          const Divider(color: Colors.white24, height: 25),
          _buildInfoRow(IconlyLight.message, 'Email', email), 
          const Divider(color: Colors.white24, height: 25),
          _buildInfoRow(IconlyLight.calendar, 'Joined', joined), 
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 15),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis, 
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    // --- MODIFICA: Rimosso SizedBox ---
    return TextButton.icon(
      icon: const Icon(IconlyLight.logout, color: Colors.redAccent, size: 20),
      label: Text(
        'Logout',
        style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w600),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        backgroundColor: const Color.fromARGB(40, 244, 67, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          // --- MODIFICA: Aggiunto bordo rosso ---
          side: BorderSide(color: Colors.redAccent.withOpacity(0.8), width: 1),
        ),
      ),
      onPressed: _handleLogout, 
    );
  }
}