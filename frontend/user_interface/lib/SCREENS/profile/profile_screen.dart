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

  // ✅ NEW: Stato per gestire il caricamento durante le azioni sui veicoli (es. togliere preferito)
  bool _isLoadingAction = false;

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

    // Forza il refresh della lista veicoli all'apertura del profilo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(vehicleListProvider);
    });
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Profile updated!")));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Failed to update profile. Check the console for details.",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshList() async {
    // ref.refresh(provider.future) restituisce il Future dei nuovi dati
    return ref.refresh(vehicleListProvider.future);
  }

  // ✅ MODIFICATO: Attende il refresh prima di togliere il loader
  Future<void> _handleToggleFavorite(Vehicle vehicle) async {
    setState(() => _isLoadingAction = true); // Mostra loader
    try {
      // 1. Chiamata API per rimuovere/aggiungere preferito
      await _vehicleService.toggleFavorite(
        vehicleId: vehicle.id,
        isFavorite: !vehicle.isFavorite,
      );
      
      // 2. IMPORTANTE: Attendiamo che la lista si aggiorni dal server
      // In questo modo il loader rimane visibile finché i nuovi dati non sono pronti
      await _refreshList(); 

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAction = false); // Nascondi loader SOLO ora
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

  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 2, 11, 60),
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: Text(
            'Logout',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleLogout();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
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
                : RefreshIndicator(
                    onRefresh: _loadUserProfile,
                    color: Colors.black,
                    backgroundColor: Colors.white,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
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

        // ✅ LOGIC: Se stiamo caricando (es. dopo toggle favorite), mostriamo il loader AL POSTO della lista
        if (_isLoadingAction)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          )
        else
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
              final favoriteVehicles =
                  allVehicles.where((v) => v.isFavorite).toList();

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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
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
                  color: valueColor ?? Colors.white,
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
      onPressed: _showLogoutDialog,
    );
  }
}