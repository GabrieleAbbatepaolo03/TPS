import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // IMPORTA RIVERPOD
import 'package:user_interface/MAIN%20UTILS/app_sizes.dart';
import 'package:user_interface/MAIN%20UTILS/app_theme.dart';
import 'package:user_interface/MAIN%20UTILS/PLATE%20RECOGNITION/vehicle_card.dart';
import 'package:user_interface/MODELS/vehicle.dart';
import 'package:user_interface/SERVICES/vehicle_service.dart';
import 'package:user_interface/MAIN%20UTILS/DIALOGS/add_vehicle_dialog.dart';
// IMPORTA IL NUOVO PROVIDER
import 'package:user_interface/STATE/vehicle_state.dart';

class MyVehiclesPage extends ConsumerWidget { 
  const MyVehiclesPage({super.key});
  
  void _refreshList(WidgetRef ref) {

    // ignore: unused_result
    ref.refresh(vehicleListProvider);
  }

  void _handleToggleFavorite(BuildContext context, WidgetRef ref, Vehicle vehicle) async {
    final service = VehicleService();
    try {
      await service.toggleFavorite(
        vehicleId: vehicle.id,
        isFavorite: !vehicle.isFavorite,
      );
      _refreshList(ref); // Ricarica tutto
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update favorite status.')),
        );
      }
    }
  }

  void _handleDeleteVehicle(BuildContext context, WidgetRef ref, Vehicle vehicle) async {
    final service = VehicleService();
    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 20, 30, 50),
        title: Text('Delete Vehicle?', style: GoogleFonts.poppins(color: Colors.white)),
        content: Text('Are you sure you want to delete ${vehicle.name}?', style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop(false)),
          TextButton(child: const Text('Delete', style: TextStyle(color: Colors.red)), onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );

    if (didConfirm == true) {
      final success = await service.deleteVehicle(vehicle.id);
      if (success) {
        _refreshList(ref);
      }
    }
  }

  void _showAddVehicleDialog(BuildContext context, WidgetRef ref) async {
    final newVehicle = await showAddVehicleDialog(context);
    if (newVehicle != null) {
      _refreshList(ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ASCOLTA IL PROVIDER: Si aggiorna automaticamente quando i dati cambiano
    final vehiclesAsync = ref.watch(vehicleListProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('My Vehicles', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: _buildAddVehicleButton(context, ref),
          )
        ],
      ),
      body: Container(
        height: AppSizes.screenHeight,
        width: AppSizes.screenWidth,
        decoration: AppTheme.backgroundGradientDecoration,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async => _refreshList(ref),
            color: Colors.white,
            child: vehiclesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
              data: (vehicles) {
                if (vehicles.isEmpty) {
                  return Center(child: Text('You currently have no Vehicles.', style: GoogleFonts.poppins(color: Colors.white54)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: VehicleCard(
                        vehicle: vehicle,
                        onDelete: () => _handleDeleteVehicle(context, ref, vehicle),
                        onFavoriteToggle: () => _handleToggleFavorite(context, ref, vehicle),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddVehicleButton(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () => _showAddVehicleDialog(context, ref),
      style: TextButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
}
