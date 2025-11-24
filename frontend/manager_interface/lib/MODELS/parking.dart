import 'tariff_config.dart';

class Parking {
  final int id;
  final String name;
  final String city;
  final String address;
  final int totalSpots;
  final int occupiedSpots;
  final double ratePerHour;
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
    required this.ratePerHour,
    required this.tariffConfigJson,
    this.latitude,
    this.longitude,
  });

  // --- GETTER PER LA CONVERSIONE AL VOLO ---
  // Questo risolve l'errore che avevi: ora accedi all'oggetto TariffConfig tramite questo getter.
  TariffConfig get tariffConfig {
    if (tariffConfigJson.isEmpty) {
        return Parking.defaultTariffConfig;
    }
    return TariffConfig.fromJson(tariffConfigJson);
  }

  // --- STATIC GETTERS AND UTILS  ---
  
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

  static double _parseRate(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final s = value.toString();
    final normalized = s.replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final s = value.toString();
    final normalized = s.replaceAll(',', '.');
    return double.tryParse(normalized);
  }
  
  // --- FACTORY CONSTRUCTOR ---
  
  factory Parking.fromJson(Map<String, dynamic> json) {
    final String rawTariffJson = json['tariff_config_json'] ?? '';
    // NOTA: Non decodifichiamo più TariffConfig qui, la memorizziamo come stringa.

    return Parking(
      id: json['id'] as int,
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      totalSpots: (json['total_spots'] is int)
          ? json['total_spots'] as int
          : (int.tryParse('${json['total_spots']}') ?? 0),
      occupiedSpots: (json['occupied_spots'] is int)
          ? json['occupied_spots'] as int
          : (int.tryParse('${json['occupied_spots']}') ?? 0),
      ratePerHour: _parseRate(json['rate'] ?? json['rate_per_hour']),
      // Passiamo la stringa grezza
      tariffConfigJson: rawTariffJson, 
      latitude: _parseNullableDouble(json['latitude']),
      longitude: _parseNullableDouble(json['longitude']),
    );
  }

  // --- SERIALIZATION TO JSON ---

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'address': address,
      'total_spots': totalSpots,
      'occupied_spots': occupiedSpots,
      'rate': ratePerHour,
      'latitude': latitude,
      'longitude': longitude,
      // Usiamo la stringa JSON grezza o la generiamo dall'oggetto TariffConfig
      'tariff_config_json': tariffConfigJson.isNotEmpty ? tariffConfigJson : tariffConfig.toJson(), 
    };
  }

  // --- DERIVED PROPERTIES ---
  
  int get availableSpots => totalSpots - occupiedSpots;
}