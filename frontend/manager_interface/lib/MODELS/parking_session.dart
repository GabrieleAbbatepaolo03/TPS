class ParkingSession {
  final int id;
  final String vehiclePlate;
  final String vehicleName;
  final String parkingLotName; // NUOVO: Nome del parcheggio
  final String parkingLotCity; // NUOVO: Città del parcheggio
  final DateTime startTime;
  final bool isActive;
  final double? totalCost;

  ParkingSession({
    required this.id,
    required this.vehiclePlate,
    required this.vehicleName,
    required this.parkingLotName,
    required this.parkingLotCity,
    required this.startTime,
    required this.isActive,
    this.totalCost,
  });

  factory ParkingSession.fromJson(Map<String, dynamic> json) {

    final vehicleData = json['vehicle'] ?? {};
    final parkingLotData = json['parking_lot'] ?? {};
    
    return ParkingSession(
      id: json['id'],
      vehiclePlate: vehicleData['plate'] ?? 'UNKNOWN',
      vehicleName: vehicleData['name'] ?? 'Unknown',
      parkingLotName: parkingLotData['name'] ?? 'Unknown Parking Lot',
      parkingLotCity: parkingLotData['city'] ?? 'Unknown City',
      startTime: DateTime.parse(json['start_time']),
      isActive: json['is_active'] ?? false,
      totalCost: json['total_cost'] != null 
          ? double.tryParse(json['total_cost'].toString()) 
          : null,
    );
  }
}