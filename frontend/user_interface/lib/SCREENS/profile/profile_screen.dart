import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_interface/MAIN%20UTILS/app_sizes.dart';
import 'package:user_interface/MAIN%20UTILS/page_title.dart';
import '../../MAIN UTILS/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:user_interface/SERVICES/user_service.dart';
import 'package:user_interface/SERVICES/AUTHETNTICATION%20HELPERS/secure_storage_service.dart';
import 'package:user_interface/SCREENS/login/login_screen.dart';
import 'package:user_interface/MODELS/vehicle.dart';
import 'package:user_interface/SERVICES/vehicle_service.dart';
import 'package:user_interface/MAIN%20UTILS/PLATE%20RECOGNITION/vehicle_card.dart';
import 'package:user_interface/STATE/vehicle_state.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final UserService _userService = UserService();
  final VehicleService _vehicleService = VehicleService();

  Map<String, dynamic>? _userData;
  bool _isLoadingProfile = true;

  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final data = await _userService.fetchUserProfile();
    if (mounted) {
      setState(() {
        _userData = data;
        _isLoadingProfile = false;
        if (data != null) {
          _firstNameController.text = data['first_name'] ?? '';
          _lastNameController.text = data['last_name'] ?? '';
        }
      });
    }
  }

  Future<void> _handleSaveName() async {
    // Validazione
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('First name and last name cannot be empty'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final success = await _userService.updateProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (success) {
      setState(() {
        _isEditing = false;
        _userData?['first_name'] = _firstNameController.text.trim();
        _userData?['last_name'] = _lastNameController.text.trim();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated!")),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to update profile. Check the console for details."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _refreshList(WidgetRef ref) {
    // ignore: unused_result
    ref.refresh(vehicleListProvider);
  }

  void _handleToggleFavorite(Vehicle vehicle) async {
    try {
      await _vehicleService.toggleFavorite(
        vehicleId: vehicle.id,
        isFavorite: !vehicle.isFavorite,
      );
      _refreshList(ref);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status.')),
        );
      }
    }
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
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
        child: _isLoadingProfile
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _userData == null
            ? const Center(
                child: Text(
                  'Failed to load profile',
                  style: TextStyle(color: Colors.red),
                ),
              )
            : SingleChildScrollView(
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

                    _buildUserInfoCard(context),

                    const SizedBox(height: 30),
                    _buildFavoriteVehiclesSection(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context) {
    final String email = _userData?['email'] ?? 'N/A';
    final String joined = _formatJoinDate(_userData?['date_joined']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(25, 255, 255, 255),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    IconlyLight.profile,
                    color: Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 15),
                  Text(
                    'Personal Info',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              IconButton(
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        _isEditing ? Icons.check : IconlyLight.edit,
                        color: _isEditing ? Colors.greenAccent : Colors.white70,
                        size: 20,
                      ),
                onPressed: _isSaving
                    ? null
                    : () {
                        if (_isEditing) {
                          _handleSaveName();
                        } else {
                          setState(() => _isEditing = true);
                        }
                      },
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (_isEditing) ...[
            Row(
              children: [
                Expanded(
                  child: _buildEditField(_firstNameController, "First Name"),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildEditField(_lastNameController, "Last Name"),
                ),
              ],
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.only(left: 35.0),
              child: Text(
                "${_userData?['first_name']} ${_userData?['last_name']}",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],

          const Divider(color: Colors.white24, height: 25),
          _buildInfoRow(IconlyLight.message, 'Email', email),
          const Divider(color: Colors.white24, height: 25),
          _buildInfoRow(IconlyLight.calendar, 'Joined', joined),
        ],
      ),
    );
  }

  Widget _buildEditField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white30),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white30),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFavoriteVehiclesSection() {
    // ASCOLTA IL PROVIDER GLOBALE
    final vehiclesAsync = ref.watch(vehicleListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Favorite Vehicles',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 15),

        vehiclesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white54),
          ),
          error: (err, stack) => Text(
            'Error loading vehicles',
            style: TextStyle(color: Colors.redAccent),
          ),
          data: (allVehicles) {
            // Filtra solo i preferiti
            final favoriteVehicles = allVehicles
                .where((v) => v.isFavorite)
                .toList();

            if (favoriteVehicles.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'No favorite vehicles selected.',
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              );
            }

            return Column(
              children: favoriteVehicles
                  .map(
                    (vehicle) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: VehicleCard(
                        vehicle: vehicle,
                        onDelete: null,
                        onFavoriteToggle: () => _handleToggleFavorite(vehicle),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
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
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(IconlyLight.logout, color: Colors.redAccent, size: 20),
      label: Text(
        'Logout',
        style: GoogleFonts.poppins(
          color: Colors.redAccent,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        backgroundColor: const Color.fromARGB(40, 244, 67, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.8), width: 1),
        ),
      ),
      onPressed: _handleLogout,
    );
  }
}
