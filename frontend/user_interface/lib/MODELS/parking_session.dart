// [FULL REPLACEMENT] parking_session.dart

import 'parking_lot.dart';
import 'vehicle.dart';

class ParkingSession {
  final int id;
  final Vehicle? vehicle;
  final ParkingLot? parkingLot;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;
  final double? totalCost;

  // --- Nuovi Campi di Controllo (Prerischio) ---
  final int durationPurchasedMinutes;
  final double prepaidCost;
  final DateTime? plannedEndTime;

  ParkingSession({
    required this.id,
    this.vehicle,
    this.parkingLot,
    required this.startTime,
    this.endTime,
    required this.isActive,
    this.totalCost,
    // Nuovi Campi nel Costruttore
    required this.durationPurchasedMinutes,
    required this.prepaidCost,
    this.plannedEndTime,
  });

  factory ParkingSession.fromJson(Map<String, dynamic> json) {
    final vehicleData = json['vehicle'];

    // Helper per parsing numerico
    double _parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return ParkingSession(
      id: json['id'] as int,
      vehicle: (vehicleData != null)
          ? Vehicle.fromJson(vehicleData as Map<String, dynamic>)
          : null,

      parkingLot: (json['parking_lot'] != null)
          ? ParkingLot.fromJson(json['parking_lot'] as Map<String, dynamic>)
          : null,

      startTime: DateTime.parse(json['start_time']),

      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,

      isActive: json['is_active'] ?? false,
      totalCost: json['total_cost'] != null
          ? double.tryParse(json['total_cost'].toString())
          : null,
      
      // Assegnazione Nuovi Campi
      durationPurchasedMinutes: json['duration_purchased_minutes'] as int? ?? 0,
      prepaidCost: _parseDouble(json['prepaid_cost']),
      plannedEndTime: json['planned_end_time'] != null
          ? DateTime.parse(json['planned_end_time'] as String)
          : null,
    );
  }

  static List<ParkingSession> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((item) => ParkingSession.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}