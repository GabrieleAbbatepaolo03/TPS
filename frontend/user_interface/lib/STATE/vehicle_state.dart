import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_interface/MODELS/vehicle.dart';
import 'package:user_interface/SERVICES/vehicle_service.dart';

final vehicleListProvider = FutureProvider.autoDispose<List<Vehicle>>((ref) async {
  final service = VehicleService();
  return await service.fetchMyVehicles();
});