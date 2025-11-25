import 'tariff_config.dart';

class Parking {
  final int id;
  final String name;
  final String city;
  final String address;
  final int totalSpots;
  final int occupiedSpots;
  
  // NUOVI CAMPI
  final int todayEntries;
  final double todayRevenue;

  final String tariffConfigJson; 
  final double? latitude;
  final double? longitude;

  Parking({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.totalSpots,
    required this.occupiedSpots,
    required this.todayEntries,
    required this.todayRevenue,
    required this.tariffConfigJson,
    this.latitude,
    this.longitude,
  });

  TariffConfig get tariffConfig {
    if (tariffConfigJson.isEmpty) return Parking.defaultTariffConfig;
    return TariffConfig.fromJson(tariffConfigJson);
  }
  
  double get displayRate {
      if (tariffConfig.type == 'FIXED_DAILY') return tariffConfig.dailyRate;
      return tariffConfig.dayBaseRate;
  }

  static TariffConfig get defaultTariffConfig {
    return TariffConfig(
      type: 'HOURLY_LINEAR',
      dailyRate: 20.00,
      dayBaseRate: 2.50,
      nightBaseRate: 1.50,
      nightStartTime: '22:00',
      nightEndTime: '06:00',
      flexRulesRaw: [],
    );
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final s = value.toString();
    final normalized = s.replaceAll(',', '.');
    return double.tryParse(normalized);
  }
  
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  factory Parking.fromJson(Map<String, dynamic> json) {
    final String rawTariffJson = json['tariff_config_json'] ?? '';

    return Parking(
      id: json['id'] as int,
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      totalSpots: json['total_spots'] is int ? json['total_spots'] : (int.tryParse('${json['total_spots']}') ?? 0),
      occupiedSpots: json['occupied_spots'] is int ? json['occupied_spots'] : (int.tryParse('${json['occupied_spots']}') ?? 0),
      
      // MAPPING NUOVI CAMPI
      todayEntries: json['today_entries'] is int ? json['today_entries'] : (int.tryParse('${json['today_entries']}') ?? 0),
      todayRevenue: _parseDouble(json['today_revenue']),
      
      tariffConfigJson: rawTariffJson, 
      latitude: _parseNullableDouble(json['latitude']),
      longitude: _parseNullableDouble(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'address': address,
      'total_spots': totalSpots,
      'occupied_spots': occupiedSpots,
      'tariff_config_json': tariffConfigJson, 
      'latitude': latitude,
      'longitude': longitude,
      'today_entries': todayEntries,
      'today_revenue': todayRevenue,
    };
  }

  int get availableSpots => totalSpots - occupiedSpots;
}