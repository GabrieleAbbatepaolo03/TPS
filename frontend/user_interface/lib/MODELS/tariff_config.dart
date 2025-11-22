// [NEW FILE] lib/MODELS/tariff_config.dart

import 'dart:convert';

class TariffConfig {
  final String type;

  final double dailyRate;

  final double dayBaseRate;
  final double nightBaseRate;
  final String nightStartTime;
  final String nightEndTime;
  final List<dynamic> flexRulesRaw;

  TariffConfig({
    required this.type,
    required this.dailyRate,
    required this.dayBaseRate,
    required this.nightBaseRate,
    required this.nightStartTime,
    required this.nightEndTime,
    required this.flexRulesRaw,
  });

  factory TariffConfig.fromJson(String jsonString) {
    if (jsonString.isEmpty || jsonString == '{}') {
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

    try {
      // ⭐ 注意: 修正了原始代码中的类型问题，确保安全解析
      final Map<String, dynamic> json =
          jsonDecode(jsonString) as Map<String, dynamic>;

      return TariffConfig(
        type: json['type'] ?? 'HOURLY_LINEAR',
        dailyRate: double.tryParse(json['daily_rate'].toString()) ?? 0.0,
        dayBaseRate: double.tryParse(json['day_base_rate'].toString()) ?? 0.0,
        nightBaseRate:
            double.tryParse(json['night_base_rate'].toString()) ?? 0.0,
        nightStartTime: json['night_start_time'] ?? '22:00',
        nightEndTime: json['night_end_time'] ?? '06:00',
        flexRulesRaw: json['flex_rules'] as List<dynamic>? ?? [],
      );
    } catch (_) {
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
  }

  String toJson() {
    return jsonEncode({
      'type': type,
      'daily_rate': dailyRate,
      'day_base_rate': dayBaseRate,
      'night_base_rate': nightBaseRate,
      'night_start_time': nightStartTime,
      'night_end_time': nightEndTime,
      'flex_rules': flexRulesRaw,
    });
  }
}
