import 'package:google_maps_flutter/google_maps_flutter.dart';

class ParkingLot {
  final int id; 
  final String name;
  final String city;
  final String address;
  final double hourlyRate;
  final LatLng centerPosition;
  final int totalSpots;
  final int availableSpaces;

  ParkingLot({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.hourlyRate,
    required this.centerPosition,
    required this.totalSpots,
    required this.availableSpaces,
  });

  factory ParkingLot.fromJson(Map<String, dynamic> json) {
    return ParkingLot(
      id: json['id'] as int, 
      name: json['name'] as String? ?? 'N/A',
      city: json['city'] as String? ?? 'N/A',
      address: json['address'] as String? ?? 'N/A',

      hourlyRate: double.tryParse(json['rate_per_hour']?.toString() ?? '0.0') ?? 0.0,
      
      centerPosition: LatLng(
        (json['center_latitude'] as num?)?.toDouble() ?? 41.9028,
        (json['center_longitude'] as num?)?.toDouble() ?? 12.4964,
      ),
      
      totalSpots: json['total_spots'] as int? ?? 0,
      availableSpaces: json['available_spots'] as int? ?? 0,
    );
  }

  static List<ParkingLot> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((item) => ParkingLot.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}