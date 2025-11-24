import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_interface/MODELS/parking_session.dart'; // Assumi questo percorso
import 'package:intl/intl.dart'; 

class HistorySessionCard extends StatelessWidget {
  final ParkingSession session;

  const HistorySessionCard({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final lotName = session.parkingLot?.name ?? 'Unknown Lot';
    final vehiclePlate = session.vehicle?.plate ?? 'N/A';
    final cost = session.totalCost != null
        ? '€${session.totalCost!.toStringAsFixed(2)}'
        : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration( 
        color: Colors.white12,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,

        title: Text(
          lotName,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Vehicle: $vehiclePlate | Ended: ${session.endTime != null ? DateFormat('dd MMM, HH:mm').format(session.endTime!) : 'N/A'}',
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Cost',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
            ),
            Text(
              cost,
              style: GoogleFonts.poppins(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}