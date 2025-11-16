import 'package:user_interface/MODELS/parking_lot.dart'; 
import 'package:user_interface/MODELS/vehicle.dart'; 

class ParkingSession {
  final int id;
  final Vehicle? vehicle; 
  final ParkingLot? parkingLot; 
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;
  final double? totalCost;

  ParkingSession({
    required this.id,
    this.vehicle,
    this.parkingLot,
    required this.startTime,
    this.endTime,
    required this.isActive,
    this.totalCost,
  });

  factory ParkingSession.fromJson(Map<String, dynamic> json) {
    return ParkingSession(
      id: json['id'] as int,
      
      vehicle: json['vehicle'] != null 
          ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>) 
          : null,

      parkingLot: json['parking_lot'] != null 
          ? ParkingLot.fromJson(json['parking_lot'] as Map<String, dynamic>) 
          : null,

      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
      isActive: json['is_active'] as bool,
      totalCost: json['total_cost'] != null ? double.tryParse(json['total_cost'].toString()) : null,
    );
  }

  static List<ParkingSession> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((item) => ParkingSession.fromJson(item as Map<String, dynamic>)).toList();
  }
}