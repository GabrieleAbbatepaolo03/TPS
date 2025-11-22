import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manager_interface/models/parking.dart';

typedef ParkingDeleteCallback = void Function(Parking parking);

class ParkingCard extends StatelessWidget {
  final Parking parking;
  final List<Parking> allParkings;
  final VoidCallback onTap;
  final ParkingDeleteCallback onDelete;

  const ParkingCard({
    super.key,
    required this.parking,
    required this.onTap,
    required this.onDelete,
    required this.allParkings,
  });

  Future<bool?> _showConfirmDeleteDialog(
    BuildContext context,
    List<Parking> allParkings,
  ) {
    final isOnlyParkingInCity =
        allParkings.where((p) => p.city == parking.city).length == 1;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color.fromARGB(255, 52, 12, 108),
                    Color.fromARGB(255, 2, 11, 60),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confirm Deletion',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Are you sure you want to delete the parking lot "${parking.name}"? \n\nThis action cannot be undone and all spots will be lost.',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  if (isOnlyParkingInCity) ...[
                    const SizedBox(height: 10),
                    Text(
                      '⚠️ This is the only parking in "${parking.city}". Deleting it will remove the city from the list.',
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.red.shade900),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableSpots = parking.totalSpots - parking.occupiedSpots;

    final rateUnit = parking.tariffConfig.type == 'FIXED_DAILY' ? '/day' : '/h';
    final rateDisplay = parking.ratePerHour.toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      parking.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final confirm = await _showConfirmDeleteDialog(
                        context,
                        allParkings,
                      );
                      if (confirm == true) {
                        onDelete(parking);
                      }
                    },
                    child: Text(
                      'Delete',
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${parking.city} - ${parking.address}',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available: $availableSpots / ${parking.totalSpots}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Rate: \$${rateDisplay}${rateUnit}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
