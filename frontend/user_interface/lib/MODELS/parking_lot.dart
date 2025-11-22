// [FULL REPLACEMENT] parking_lot.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'tariff_config.dart';

class ParkingLot {
  final int id;
  final String name;
  final String city;
  final String address;
  final double hourlyRate;
  final LatLng centerPosition;
  final int totalSpots;
  final int availableSpaces;
  final TariffConfig tariffConfig;

  ParkingLot({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.hourlyRate,
    required this.centerPosition,
    required this.totalSpots,
    required this.availableSpaces,
    required this.tariffConfig,
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

  static double _parseRate(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final s = value.toString();
    final normalized = s.replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
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

    final dynamic rawTariffJson = json['tariff_config_json'];
    final TariffConfig config =
        (rawTariffJson is String && rawTariffJson.isNotEmpty)
        ? TariffConfig.fromJson(rawTariffJson)
        : ParkingLot.defaultTariffConfig;

    return ParkingLot(
      id: json['id'] as int,
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',

      hourlyRate: _parseRate(json['rate'] ?? json['rate_per_hour']),

      centerPosition: LatLng(lat, lng),

      totalSpots: (json['total_spots'] is int)
          ? json['total_spots'] as int
          : (int.tryParse('${json['total_spots']}') ?? 0),
      availableSpaces: (json['available_spots'] is int)
          ? json['available_spots'] as int
          : (int.tryParse('${json['available_spots']}') ?? 0),

      tariffConfig: config,
    );
  }

  static List<ParkingLot> listFromJson(List<dynamic> jsonList) {
    return jsonList
        .map((item) => ParkingLot.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
