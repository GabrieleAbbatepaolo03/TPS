import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:user_interface/MODELS/parking_session.dart';
import 'package:user_interface/STATE/parking_session_state.dart'; 

class ActiveSessionCard extends ConsumerWidget {
  final ParkingSession session;
  final VoidCallback onEndSession;
  final bool isStopping;

  const ActiveSessionCard({
    super.key,
    required this.session,
    required this.onEndSession,
    required this.isStopping,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Recupera il tempo trascorso dal timer globale
    final elapsedAsync = ref.watch(parkingElapsedProvider);
    final Duration elapsed = elapsedAsync.value ?? Duration.zero;

    // 2. Calcola la durata totale e il tempo rimanente
    // Usiamo durationPurchasedMinutes dal modello
    final int totalMinutes = session.durationPurchasedMinutes;
    final Duration totalDuration = Duration(minutes: totalMinutes);
    
    final Duration remaining = totalDuration - elapsed;
    final bool isExpired = remaining.isNegative;
    
    // 3. Calcolo percentuale per il grafico circolare (0.0 -> 1.0)
    double progress = 0.0;
    if (totalDuration.inSeconds > 0) {
      progress = elapsed.inSeconds / totalDuration.inSeconds;
    }
    if (progress > 1.0) progress = 1.0;

    // 4. Determina Colore e Stato (Verde=Ok, Arancio=In scadenza, Rosso=Scaduto)
    Color statusColor = Colors.greenAccent;
    String statusText = "ACTIVE";
    
    if (isExpired) {
      statusColor = Colors.redAccent;
      statusText = "EXPIRED";
    } else if (remaining.inMinutes < 15) {
      statusColor = Colors.orangeAccent;
      statusText = "EXPIRING SOON";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER: Parcheggio e Veicolo ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // Accesso sicuro all'oggetto nidificato
                      session.parkingLot?.name ?? 'Unknown Parking',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(IconlyBold.discovery, size: 14, color: Colors.white70),
                        const SizedBox(width: 5),
                        Text(
                          // Accesso sicuro all'oggetto nidificato
                          session.vehicle?.plate ?? 'Unknown Plate',
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const Divider(color: Colors.white12, height: 30),

          // --- TIMER CENTRALE E PROGRESSO ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Grafico Circolare
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: Colors.white10,
                      color: statusColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${(progress * 100).toInt()}%",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(width: 20),
              
              // Testo Tempo Rimanente
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "REMAINING TIME",
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      // Se scaduto, mostra il tempo negativo
                      isExpired 
                          ? "- ${_formatDuration(remaining.abs())}" 
                          : _formatDuration(remaining),
                      style: GoogleFonts.poppins(
                        color: statusColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Usa plannedEndTime dal modello
                    Text(
                      "Expires at: ${_formatTime(session.plannedEndTime)}",
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- DETTAGLI PAGAMENTO ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(IconlyLight.wallet, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text("Paid Amount", style: GoogleFonts.poppins(color: Colors.white70)),
                  ],
                ),
                // Usa prepaidCost dal modello
                Text(
                  "€${session.prepaidCost.toStringAsFixed(2)}",
                  style: GoogleFonts.poppins(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- BOTTONE STOP ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isStopping ? null : onEndSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
              child: isStopping
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      "STOP SESSION (NO REFUND)",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Helpers per formattazione oraria
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return "--:--";
    return DateFormat('HH:mm').format(dt);
  }
}