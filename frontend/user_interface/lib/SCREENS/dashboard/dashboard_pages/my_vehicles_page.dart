import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_interface/MAIN%20UTILS/app_sizes.dart';
import 'package:user_interface/MAIN%20UTILS/app_theme.dart';
import 'package:user_interface/MAIN%20UTILS/PLATE%20RECOGNITION/vehicle_card.dart';
import 'package:user_interface/MODELS/vehicle.dart';
import 'package:user_interface/SERVICES/vehicle_service.dart';
import 'package:user_interface/MAIN%20UTILS/DIALOGS/add_vehicle_dialog.dart';
import 'package:user_interface/STATE/vehicle_state.dart';

class MyVehiclesPage extends ConsumerStatefulWidget {
  const MyVehiclesPage({super.key});

  @override
  ConsumerState<MyVehiclesPage> createState() => _MyVehiclesPageState();
}

class _MyVehiclesPageState extends ConsumerState<MyVehiclesPage> {
  bool _isDeleting = false;
  List<Vehicle>? _optimisticVehicles;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(vehicleListProvider);
    });
  }

  Future<void> _refreshList() async {
    return ref.refresh(vehicleListProvider.future);
  }

  void _handleToggleFavorite(BuildContext context, Vehicle vehicle) async {
    if (_optimisticVehicles != null) {
      setState(() {
        _optimisticVehicles = _optimisticVehicles!.map((v) {
          if (v.id == vehicle.id) {
            return v.copyWith(isFavorite: !v.isFavorite);
          }
          return v;
        }).toList();
      });
    }

    final service = VehicleService();
    try {
      await service.toggleFavorite(
        vehicleId: vehicle.id,
        isFavorite: !vehicle.isFavorite,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection error: changes may not be saved.')),
        );
      }
    }
  }

  Future<void> _handleDeleteVehicle(BuildContext context, Vehicle vehicle) async {
    final service = VehicleService();
    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color.fromARGB(255, 2, 11, 60),
        title: Text('Delete Vehicle?',
            style: GoogleFonts.poppins(color: Colors.white)),
        content: Text('Are you sure you want to delete ${vehicle.name}?',
            style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () => Navigator.of(ctx).pop(false)),
          TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );

    if (didConfirm == true) {
      setState(() => _isDeleting = true);
      
      try {
        final success = await service.deleteVehicle(vehicle.id);
        if (success) {
          await _refreshList();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete vehicle.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  void _showAddVehicleDialog(BuildContext context) async {
    final newVehicle = await showAddVehicleDialog(context);
    if (newVehicle != null) {
      _refreshList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehicleListProvider);

    ref.listen<AsyncValue<List<Vehicle>>>(vehicleListProvider, (previous, next) {
      next.whenData((vehicles) {
        setState(() {
          _optimisticVehicles = vehicles;
        });
      });
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('My Vehicles',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: _buildAddVehicleButton(context),
          )
        ],
      ),
      body: Container(
        height: AppSizes.screenHeight,
        width: AppSizes.screenWidth,
        decoration: AppTheme.backgroundGradientDecoration,
        child: SafeArea(
          child: _isDeleting
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : RefreshIndicator(
                  onRefresh: () async => _refreshList(),
                  color: Colors.white,
                  child: vehiclesAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(color: Colors.white)),
                    error: (err, stack) => Center(
                        child: Text('Error: $err',
                            style: const TextStyle(color: Colors.red))),
                    data: (vehiclesFromProvider) {
                      final displayList = _optimisticVehicles ?? vehiclesFromProvider;

                      if (displayList.isEmpty) {
                        return Center(
                            child: Text('You currently have no Vehicles.',
                                style: GoogleFonts.poppins(
                                    color: Colors.white54)));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 10),
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          final vehicle = displayList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: VehicleCard(
                              vehicle: vehicle,
                              onDelete: () =>
                                  _handleDeleteVehicle(context, vehicle),
                              onFavoriteToggle: () =>
                                  _handleToggleFavorite(context, vehicle),
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

  Widget _buildAddVehicleButton(BuildContext context) {
    return TextButton(
      onPressed: () => _showAddVehicleDialog(context),
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