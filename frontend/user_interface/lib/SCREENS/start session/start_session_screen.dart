import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:user_interface/MODELS/parking_lot.dart';
import 'package:user_interface/MODELS/vehicle.dart';
import 'package:user_interface/SCREENS/root_screen.dart';
import 'package:user_interface/SERVICES/vehicle_service.dart';
import 'package:user_interface/SERVICES/parking_session_service.dart';
import 'package:user_interface/MAIN%20UTILS/app_theme.dart';

class StartSessionScreen extends StatefulWidget {
  final ParkingLot parkingLot;

  const StartSessionScreen({super.key, required this.parkingLot});

  @override
  State<StartSessionScreen> createState() => _StartSessionScreenState();
}

class _StartSessionScreenState extends State<StartSessionScreen> {
  final VehicleService _vehicleService = VehicleService();
  final ParkingSessionService _sessionService = ParkingSessionService();
  
  late Future<List<Vehicle>> _vehiclesFuture;
  Vehicle? _selectedVehicle;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _vehiclesFuture = _vehicleService.fetchMyVehicles();
  }

  Future<void> _startSession() async {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle first.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final session = await _sessionService.startSession(
      vehicleId: _selectedVehicle!.id,
      parkingLotId: widget.parkingLot.id,
    );

    if (mounted) {
      if (session != null) {

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(

            builder: (context) => const RootPage(initialIndex: 1), 
          ),
          (Route<dynamic> route) => false, 
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start session. Is one already active?')),
        );
      }
    }
    
    // In caso di fallimento, smetti di caricare
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradientDecoration,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildParkingDetails(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Select Vehicle',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: _buildVehicleSelector(),
              ),
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(IconlyLight.arrow_left, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            'Start Session',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildParkingDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(25, 255, 255, 255),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.parkingLot.name,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(IconlyLight.location, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Expanded( 
                child: Text(
                  '${widget.parkingLot.address}, ${widget.parkingLot.city}',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailChip('€${widget.parkingLot.hourlyRate.toStringAsFixed(2)}/h', IconlyLight.wallet),
              _buildDetailChip('${widget.parkingLot.availableSpaces} Available', IconlyLight.tick_square),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(30, 255, 255, 255),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelector() {
    return FutureBuilder<List<Vehicle>>(
      future: _vehiclesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No vehicles found.\nPlease add a vehicle in your profile.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
            ),
          );
        }

        final vehicles = snapshot.data!;
        if (_selectedVehicle == null && vehicles.isNotEmpty) {
          _selectedVehicle = vehicles.first; 
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = vehicles[index];
            final bool isSelected = _selectedVehicle?.id == vehicle.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent.withOpacity(0.3) : const Color.fromARGB(15, 255, 255, 255),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? Colors.blueAccent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                leading: Icon(IconlyBold.star, color: isSelected ? Colors.blueAccent : Colors.white, size: 30),
                title: Text(
                  vehicle.plate,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${vehicle.name}',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                ),
                onTap: () {
                  setState(() {
                    _selectedVehicle = vehicle;
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: _isLoading ? null : _startSession,
          child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : Text(
                  'Confirm & Start Session',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}