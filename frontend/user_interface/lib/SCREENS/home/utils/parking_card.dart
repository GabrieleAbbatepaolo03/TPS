import 'package:flutter/material.dart';
import 'package:user_interface/MODELS/parking.dart';

class ParkingCard extends StatelessWidget {
  final Parking parkingLot;
  final double distance;

  const ParkingCard({
    super.key,
    required this.parkingLot,
    required this.distance,
  });

  String _getTariffDisplay() {
    final config = parkingLot.tariffConfig;
    switch (config.type) {
      case 'FIXED_DAILY':
        return '€${config.dailyRate.toStringAsFixed(2)} Daily';
      case 'HOURLY_LINEAR':
        return '€${config.dayBaseRate.toStringAsFixed(2)}/h';
      case 'HOURLY_VARIABLE':
        return 'Variable Rate';
      default:
        return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            parkingLot.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            "${parkingLot.address} · ${distance.toStringAsFixed(1)} km",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${parkingLot.availableSpots} spots • ${_getTariffDisplay()}",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}