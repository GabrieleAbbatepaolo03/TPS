import 'package:google_maps_flutter/google_maps_flutter.dart';

class ParkingEntrance {
  final LatLng position;
  final String address;

  ParkingEntrance({
    required this.position,
    required this.address,
  });

  factory ParkingEntrance.fromJson(Map<String, dynamic> json) {
    return ParkingEntrance(
      position: LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      ),
      address: json['address_line'] as String,
    );
  }
}