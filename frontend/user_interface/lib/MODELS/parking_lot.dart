import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'tariff_config.dart';

class ParkingLot {
  final int id;
  final String name;
  final String city;
  final String address;
  final LatLng centerPosition;
  final int totalSpots;
  final int availableSpaces;
  
  // Campo che riceve la stringa JSON grezza dal backend
  final String tariffConfigJson; 

  // Getter che converte la stringa in oggetto TariffConfig quando serve
  TariffConfig get tariffConfig {
      if (tariffConfigJson.isEmpty) {
          return ParkingLot.defaultTariffConfig;
      }
      return TariffConfig.fromJson(tariffConfigJson);
  }

  ParkingLot({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.centerPosition,
    required this.totalSpots,
    required this.availableSpaces,
    required this.tariffConfigJson,
  });

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

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final s = value.toString();
    final normalized = s.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  factory ParkingLot.fromJson(Map<String, dynamic> json) {
    final double lat =
        (json['latitude'] as num?)?.toDouble() ??
        (json['center_latitude'] as num?)?.toDouble() ??
        41.9028;

    final double lng =
        (json['longitude'] as num?)?.toDouble() ??
        (json['center_longitude'] as num?)?.toDouble() ??
        12.4964;

    final String rawTariffJson = json['tariff_config_json'] ?? '';
    
    return ParkingLot(
      id: _parseInt(json['id']), // Usa _parseInt per sicurezza
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',

      centerPosition: LatLng(lat, lng),

      // 🚨 QUI LA CORREZIONE CHIAVE: Parsing sicuro
      totalSpots: _parseInt(json['total_spots']),
      availableSpaces: _parseInt(json['available_spots']),

      tariffConfigJson: rawTariffJson,
    );
  }

  static List<ParkingLot> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((item) => ParkingLot.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}