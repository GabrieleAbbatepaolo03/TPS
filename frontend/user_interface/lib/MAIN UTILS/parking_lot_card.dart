import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../MODELS/parking_lot.dart';
import '../MAIN UTILS/location_utils.dart';

class ParkingLotCard extends StatelessWidget {
  final ParkingLot parkingLot;
  final LatLng userPosition;
  final VoidCallback onTap;

  const ParkingLotCard({
    super.key,
    required this.parkingLot,
    required this.userPosition,
    required this.onTap,
  });

  Color _getAvailabilityColor() {
    if (parkingLot.totalSpots == 0) return Colors.grey;
    final ratio = parkingLot.availableSpaces / parkingLot.totalSpots;
    if (ratio > 0.6) return Colors.greenAccent;
    if (ratio > 0.2) return Colors.orangeAccent;
    if (ratio > 0) return Colors.redAccent;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final availableSpots = parkingLot.availableSpaces;
    final availabilityColor = _getAvailabilityColor();
    final distance = LocationUtils.calculateDistance(userPosition, parkingLot.centerPosition);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(25, 255, 255, 255),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 20,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                  gradient: LinearGradient(
                    colors: [availabilityColor.withOpacity(0.7), availabilityColor],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              parkingLot.name,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            distance,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(IconlyLight.location, color: Colors.white54, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${parkingLot.city}, ${parkingLot.address}',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$availableSpots',
                                style: GoogleFonts.poppins(
                                  color: availabilityColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Available Spots',
                                style: GoogleFonts.poppins(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '€${parkingLot.hourlyRate.toStringAsFixed(2)}/h',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Hourly Rate',
                                style: GoogleFonts.poppins(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
