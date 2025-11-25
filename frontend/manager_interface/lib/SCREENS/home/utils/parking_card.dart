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

  Future<bool?> _showConfirmDeleteDialog(BuildContext context, List<Parking> allParkings) {
    final isOnlyParkingInCity = allParkings.where((p) => p.city == parking.city).length == 1;

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
                  colors: [Color.fromARGB(255, 52, 12, 108), Color.fromARGB(255, 2, 11, 60)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Confirm Deletion', style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text('Are you sure you want to delete the parking lot "${parking.name}"? \n\nThis action cannot be undone.', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                  if (isOnlyParkingInCity) ...[
                    const SizedBox(height: 10),
                    Text('⚠️ This is the only parking in "${parking.city}". Deleting it will remove the city.', style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w400)),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(backgroundColor: Colors.red.shade700),
                        child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
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
    final availableSpots = parking.availableSpots; // Usa la proprietà derivata del modello

    // 🚨 LOGICA AGGIORNATA PER LA TARIFFA
    // Usa il getter intelligente 'tariffConfig' del modello Parking
    final config = parking.tariffConfig;
    
    final isFixedDaily = config.type == 'FIXED_DAILY';
    final rateUnit = isFixedDaily ? '/day' : '/h';
    
    // Usa il getter 'displayRate' che abbiamo aggiunto al modello
    final rateDisplay = parking.displayRate.toStringAsFixed(2);

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
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Tasto Delete ...
                  TextButton(
                      onPressed: () async {
                          final confirm = await _showConfirmDeleteDialog(context, allParkings);
                          if (confirm == true) onDelete(parking);
                      },
                      child: Text('Delete', style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w500))
                  )
                ],
              ),
              const SizedBox(height: 4),
              Text('${parking.city} - ${parking.address}', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w400)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Available: $availableSpots / ${parking.totalSpots}', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                  // 🚨 DISPLAY AGGIORNATO
                  Text('Rate: €$rateDisplay$rateUnit', style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}