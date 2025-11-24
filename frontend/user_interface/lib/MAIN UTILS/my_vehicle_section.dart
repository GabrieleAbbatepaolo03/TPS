import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_interface/MAIN%20UTILS/DIALOGS/add_vehicle_dialog.dart';
import 'package:user_interface/MAIN%20UTILS/PLATE%20RECOGNITION/vehicle_card.dart';
import 'package:user_interface/MODELS/vehicle.dart';
import 'package:user_interface/SERVICES/vehicle_service.dart';



class MyVehiclesSection extends StatefulWidget {
  const MyVehiclesSection({super.key});

  @override
  State<MyVehiclesSection> createState() => _MyVehiclesSectionState();
}

class _MyVehiclesSectionState extends State<MyVehiclesSection> {
  final VehicleService _vehicleService = VehicleService();
  late Future<List<Vehicle>> _vehiclesFuture;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  void _loadVehicles() {
    setState(() {
      _vehiclesFuture = _vehicleService.fetchMyVehicles();
    });
  }

  void _showAddVehicleDialog() async {
    final newVehicle = await showAddVehicleDialog(context);
    if (newVehicle != null && mounted) {
      _loadVehicles();
    }
  }

  void _handleDeleteVehicle(Vehicle vehicle) async {
    final bool? didConfirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 20, 30, 50),
        title: Text('Delete Vehicle?', style: GoogleFonts.poppins(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${vehicle.name} (${vehicle.plate})?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white70)),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.redAccent)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (didConfirm == true && mounted) {
      final success = await _vehicleService.deleteVehicle(vehicle.id);
      if (success) {
        _loadVehicles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete vehicle.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleToggleFavorite(Vehicle vehicle) async {
    final bool newFavoriteState = !vehicle.isFavorite;

    try {

      await _vehicleService.toggleFavorite(
        vehicleId: vehicle.id,
        isFavorite: newFavoriteState,
      );

      _loadVehicles();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorite status.'), 
            backgroundColor: Colors.red
          ),
        );
      }
    }
  }


  Widget _buildAddVehicleButton() {
    return TextButton(
      onPressed: _showAddVehicleDialog,
      style: TextButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.add,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            'Add Vehicle',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'My Vehicles',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            _buildAddVehicleButton(),
          ],
        ),
        const SizedBox(height: 15),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 2, 11, 60), 
            borderRadius: BorderRadius.circular(20),

          ),
          child: FutureBuilder<List<Vehicle>>(
            future: _vehiclesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: CircularProgressIndicator(color: Colors.white24),
                ));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Failed to load vehicles', style: GoogleFonts.poppins(color: Colors.redAccent)));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Text('You currently have no Vehicles.', style: GoogleFonts.poppins(color: Colors.white54)),
                ));
              }
              
              final vehicles = snapshot.data!;
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  
                  return Padding(
                    padding: EdgeInsets.only(bottom: index == vehicles.length - 1 ? 0 : 8),
                    child: VehicleCard(
                      vehicle: vehicle, 
                      onDelete: () => _handleDeleteVehicle(vehicle), 
                      onFavoriteToggle: () {}, 
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}