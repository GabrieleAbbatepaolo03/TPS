import 'tariff_config.dart';
import 'dart:convert';

class Parking {
  final int id;
  final String name;
  final String city;
  final String address;
  final double ratePerHour;
  
  final double? markerLatitude;
  final double? markerLongitude;
  
  final List<ParkingCoordinate> polygonCoords;
  final List<ParkingEntrance> entrances;
  
  final double? latitude;
  final double? longitude;

  final int totalSpots;
  final int occupiedSpots;
  final int todayEntries;
  final double todayRevenue;
  
  final String tariffConfigJson;

  Parking({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.ratePerHour,
    this.markerLatitude,
    this.markerLongitude,
    this.polygonCoords = const [],
    this.entrances = const [],
    this.latitude,
    this.longitude,
    required this.totalSpots,
    required this.occupiedSpots,
    required this.todayEntries,
    required this.todayRevenue,
    String? tariffConfigJson,
  }) : tariffConfigJson = tariffConfigJson ?? defaultTariffConfig.toJson();

  static TariffConfig get defaultTariffConfig => TariffConfig(
        type: 'HOURLY_LINEAR',
        dailyRate: 20.0,
        dayBaseRate: 2.5,
        nightBaseRate: 1.5,
        nightStartTime: '22:00',
        nightEndTime: '06:00',
        flexRulesRaw: [],
      );

  TariffConfig get tariffConfig {
    try {
      return TariffConfig.fromJson(jsonDecode(tariffConfigJson));
    } catch (e) {
      return defaultTariffConfig;
    }
  }

  /// Returns the display rate based on tariff type
  double get displayRate {
    final config = tariffConfig;
    if (config.type == 'FIXED_DAILY') {
      return config.dailyRate;
    } else {
      return config.dayBaseRate;
    }
  }

  factory Parking.fromJson(Map<String, dynamic> json) {
    return Parking(
      id: json['id'],
      name: json['name'],
      city: json['city'],
      address: json['address'],
      
      // MODIFICA 1: Gestione sicura di rate_per_hour (può mancare nella map view)
      ratePerHour: double.tryParse(json['rate_per_hour']?.toString() ?? '') ?? 0.0,
      
      markerLatitude: json['marker_latitude']?.toDouble(),
      markerLongitude: json['marker_longitude']?.toDouble(),
      
      polygonCoords: (json['polygon_coords'] as List<dynamic>?)
              ?.map((e) => ParkingCoordinate.fromJson(e))
              .toList() ??
          [],
          
      entrances: (json['entrances'] as List<dynamic>?)
              ?.map((e) => ParkingEntrance.fromJson(e))
              .toList() ??
          [],
          
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      
      // MODIFICA 2: Default a 0 se i dati statistici non sono inviati
      totalSpots: json['total_spots'] ?? 0,
      occupiedSpots: json['occupied_spots'] ?? 0,
      todayEntries: json['today_entries'] ?? 0,
      
      // MODIFICA 3: Parsing sicuro per revenue (evita crash su null o stringhe vuote)
      todayRevenue: double.tryParse(json['today_revenue']?.toString() ?? '') ?? 0.0,
      
      // Il costruttore gestisce già il null per questo campo
      tariffConfigJson: json['tariff_config_json'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      'name': name,
      'city': city,
      'address': address,
      'rate_per_hour': ratePerHour,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'tariff_config_json': tariffConfigJson,
      if (polygonCoords.isNotEmpty)
        'polygon_coordinates': polygonCoords.map((c) => c.toJson()).toList(),
    };
  }

  int get availableSpots => totalSpots - occupiedSpots;
}

class ParkingCoordinate {
  final double lat;
  final double lng;

  ParkingCoordinate({required this.lat, required this.lng});

  factory ParkingCoordinate.fromJson(Map<String, dynamic> json) {
    return ParkingCoordinate(
      lat: json['lat'].toDouble(),
      lng: json['lng'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

class ParkingEntrance {
  final int id;
  final String addressLine;
  final double latitude;
  final double longitude;

  ParkingEntrance({
    required this.id,
    required this.addressLine,
    required this.latitude,
    required this.longitude,
  });

  factory ParkingEntrance.fromJson(Map<String, dynamic> json) {
    return ParkingEntrance(
      id: json['id'],
      addressLine: json['address_line'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }
}