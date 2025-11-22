// [FULL REPLACEMENT] parking_session_state.dart

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

  final hours = totalMinutes / 60.0;
  double totalCost = 0.0;

  if (config.type == 'FIXED_DAILY') {
    return config.dailyRate.toStringAsFixed(2);
  }

  List<Map<String, dynamic>> getFlexRules() {
    return (config.flexRulesRaw as List<dynamic>?)
            ?.map((r) => r as Map<String, dynamic>)
            .toList() ??
        [];
  }

  bool _isNightTime(double hourOfDay, TariffConfig config) {
    final nightStart =
        double.tryParse(config.nightStartTime.split(':').first) ?? 22.0;
    final nightEnd =
        double.tryParse(config.nightEndTime.split(':').first) ?? 6.0;

    if (nightStart > nightEnd) {
      return hourOfDay >= nightStart || hourOfDay < nightEnd;
    } else {
      return hourOfDay >= nightStart && hourOfDay < nightEnd;
    }
  }

  double remainingHours = hours;
  double currentSimulationHours = 0.0;
  final List<Map<String, dynamic>> flexRules = getFlexRules();

  while (remainingHours > 0) {
    double hourlyRate;
    double segmentDuration = (remainingHours >= 1.0) ? 1.0 : remainingHours;

    bool isNight = _isNightTime(currentSimulationHours % 24, config);
    double baseRate = isNight ? config.nightBaseRate : config.dayBaseRate;

    if (config.type == 'HOURLY_LINEAR') {
      hourlyRate = baseRate;
    } else if (config.type == 'HOURLY_VARIABLE') {
      double elapsedTime = hours - remainingHours;
      double multiplier = 1.0;

      for (var rule in flexRules) {
        final durationFromHours =
            (rule['duration_from_hours'] as num?)?.toDouble() ?? 0.0;
        final durationToHours =
            (rule['duration_to_hours'] as num?)?.toDouble() ?? double.infinity;
        final ruleMultiplier = (rule['multiplier'] as num?)?.toDouble() ?? 1.0;

        if (elapsedTime >= durationFromHours && elapsedTime < durationToHours) {
          multiplier = ruleMultiplier;
          break;
        }
      }

      hourlyRate = baseRate * multiplier;
    } else {
      hourlyRate = 0.0;
    }

    totalCost += hourlyRate * segmentDuration;

    remainingHours -= segmentDuration;
    currentSimulationHours += segmentDuration;
  }

  final double max24hCost = 24.0 * config.dayBaseRate;
  if (totalCost > max24hCost) {
    totalCost = max24hCost;
  }

  return totalCost.toStringAsFixed(2);
}
