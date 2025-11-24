import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_interface/MODELS/parking_session.dart';
import 'package:user_interface/MAIN%20UTILS/page_transition.dart'; // Assumi path
import 'package:user_interface/SCREENS/dashboard/dashboard_pages/parking_history_page.dart'; // Assumi path
import 'history_session_card.dart'; // Importa il nuovo widget card



class LimitedHistoryList extends StatelessWidget {
  final List<ParkingSession> sessions;
  final int totalCount;

  const LimitedHistoryList({
    super.key,
    required this.sessions,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty && totalCount == 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Center(
          child: Text(
            'History is empty.',
            style: GoogleFonts.poppins(color: Colors.white54),
          ),
        ),
      );
    }

    return Column(
      children: [
        // 1. Lista Limitata
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            return HistorySessionCard(session: sessions[index]);
          },
        ),

        // 2. Pulsante per la lista completa (mostrato se ci sono più sessioni non visualizzate)
        if (totalCount > sessions.length) 
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: TextButton(
              onPressed: () {
                // Naviga alla pagina completa della cronologia
                Navigator.of(context).push(
                  slideRoute(const ParkingHistoryPage()),
                );
              },
              child: Text(
                'Click here to see the full list of ${totalCount} sessions.',
                style: GoogleFonts.poppins(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.greenAccent,
                ),
              ),
            ),
          ),
      ],
    );
  }
}