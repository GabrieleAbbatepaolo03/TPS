import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:user_interface/MODELS/tariff_config.dart';

const double kPreAuthAmount = 20.0;

class ParkingState {
  final bool active;
  final DateTime? startAt;
  final int? sessionId;
  final int? vehicleId;
  final int? parkingLotId;
  final TariffConfig? tariffConfig;

  const ParkingState({
    this.active = false,
    this.startAt,
    this.sessionId,
    this.vehicleId,
    this.parkingLotId,
    this.tariffConfig,
  });

  ParkingState copyWith({
    bool? active,
    DateTime? startAt,
    int? sessionId,
    int? vehicleId,
    int? parkingLotId,
    TariffConfig? tariffConfig,
  }) => ParkingState(
    active: active ?? this.active,
    startAt: startAt ?? this.startAt,
    sessionId: sessionId ?? this.sessionId,
    vehicleId: vehicleId ?? this.vehicleId,
    parkingLotId: parkingLotId ?? this.parkingLotId,
    tariffConfig: tariffConfig ?? this.tariffConfig,
  );
}

class ParkingController extends StateNotifier<ParkingState> {
  ParkingController() : super(const ParkingState());

  void start({
    required int sessionId,
    required int vehicleId,
    required int parkingLotId,
    required DateTime startAt,
    required TariffConfig tariffConfig,
  }) {
    state = ParkingState(
      active: true,
      startAt: startAt,
      sessionId: sessionId,
      vehicleId: vehicleId,
      parkingLotId: parkingLotId,
      tariffConfig: tariffConfig,
    );
  }

  void reset() => state = const ParkingState();
}

final parkingControllerProvider =
    StateNotifierProvider<ParkingController, ParkingState>(
      (ref) => ParkingController(),
    );

final parkingElapsedProvider = StreamProvider<Duration>((ref) {
  final s = ref.watch(parkingControllerProvider);
  if (!s.active || s.startAt == null) {
    return Stream<Duration>.value(Duration.zero);
  }

  return Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now().difference(s.startAt!),
  );
});

String formatDuration(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours.toString().padLeft(2, '0');
  final m = two(d.inMinutes.remainder(60));
  final s = two(d.inSeconds.remainder(60));
  return "$h:$m:$s";
}

String calculateFee(Duration d, TariffConfig config) {
  final totalMinutes = d.inMinutes;
  if (totalMinutes <= 0) return '0.00';

  if (config.type == 'FIXED_DAILY') {
    return config.dailyRate.toStringAsFixed(2);
  }

  final now = DateTime.now();
  final currentHourMinute = now.hour * 60 + now.minute;

  final nightStartParts = config.nightStartTime
      .split(':')
      .map((e) => int.parse(e))
      .toList();
  final nightEndParts = config.nightEndTime
      .split(':')
      .map((e) => int.parse(e))
      .toList();

  final nightStart = nightStartParts[0] * 60 + nightStartParts[1];
  final nightEnd = nightEndParts[0] * 60 + nightEndParts[1];

  bool isNight;
  if (nightStart > nightEnd) {
    isNight = currentHourMinute >= nightStart || currentHourMinute < nightEnd;
  } else {
    isNight = currentHourMinute >= nightStart && currentHourMinute < nightEnd;
  }

  double baseRatePerHour = isNight ? config.nightBaseRate : config.dayBaseRate;

  final ratePerMinute = baseRatePerHour / 60.0;
  double totalCost = 0.0;

  if (config.type == 'HOURLY_LINEAR') {
    totalCost = totalMinutes * ratePerMinute;
  } else if (config.type == 'VARIABLE_COMPLEX') {
    double totalHours = totalMinutes / 60.0;
    double currentMultiplier = 1.0;

    for (var rule in config.flexRulesRaw) {
      if (rule is Map<String, dynamic>) {
        final durationHours = rule['duration_h'] as int? ?? 0;
        final multiplier = (rule['multiplier'] as num?)?.toDouble() ?? 1.0;

        if (totalHours >= durationHours) {
          currentMultiplier = multiplier;
        }
      }
    }

    totalCost = totalMinutes * ratePerMinute * currentMultiplier;
  }

  return totalCost.toStringAsFixed(2);
}
