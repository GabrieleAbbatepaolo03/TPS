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
  final VoidCallback onExtendSession; // NEW
  final bool isStopping;

  // Grace period: 10 minuti dopo la scadenza
  static const Duration gracePeriod = Duration(minutes: 10);

  const ActiveSessionCard({
    super.key,
    required this.session,
    required this.onEndSession,
    required this.onExtendSession, // NEW
    required this.isStopping,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Recupera il tempo trascorso dal timer globale
    final elapsedAsync = ref.watch(parkingElapsedProvider);
    final Duration elapsed = elapsedAsync.value ?? Duration.zero;

    // 2. Calcola la durata totale e il tempo rimanente
    final int totalMinutes = session.durationPurchasedMinutes;
    final Duration totalDuration = Duration(minutes: totalMinutes);
    
    final Duration remaining = totalDuration - elapsed;
    final bool isExpired = remaining.isNegative;
    
    // 3. Calcolo grace period
    final Duration gracePeriodRemaining = isExpired 
        ? gracePeriod + remaining  // remaining è negativo, quindi sommiamo
        : Duration.zero;
    
    final bool isInGracePeriod = isExpired && !gracePeriodRemaining.isNegative;
    final bool isFinallyExpired = isExpired && gracePeriodRemaining.isNegative;
    
    // 4. Calcolo percentuale per il grafico circolare (0.0 -> 1.0)
    double progress = 0.0;
    if (totalDuration.inSeconds > 0) {
      progress = elapsed.inSeconds / totalDuration.inSeconds;
    }
    if (progress > 1.0) progress = 1.0;

    // 5. Determina Colore e Stato
    Color statusColor = Colors.greenAccent;
    String statusText = "ACTIVE";
    
    // Timer principale sempre a zero quando scaduto
    Duration displayMainTime = isExpired ? Duration.zero : remaining;
    
    if (isFinallyExpired) {
      statusColor = Colors.redAccent;
      statusText = "PENALTY RISK";
    } else if (isInGracePeriod) {
      statusColor = Colors.redAccent;  // ROSSO per expired/grace period
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
                      session.parkingLot?.name ?? 'Unknown Parking',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          session.vehicle?.plate ?? 'Unknown Plate',
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
                      _formatDuration(displayMainTime),
                      style: GoogleFonts.poppins(
                        color: statusColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isExpired
                          ? "Expired at: ${_formatTime(session.plannedEndTime)}"
                          : "Expires at: ${_formatTime(session.plannedEndTime)}",
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // --- WARNING BANNER se in grace period o oltre ---
          if (isInGracePeriod || isFinallyExpired) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(
                    isFinallyExpired ? Icons.warning : Icons.access_time,
                    color: statusColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFinallyExpired
                              ? 'PENALTY RISK!'
                              : 'Grace Period: ${_formatDuration(gracePeriodRemaining)}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isFinallyExpired
                              ? 'You may be subject to a penalty. Extend or stop now!'
                              : 'Extend or stop before penalty applies.',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

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

          // --- BOTTONI: EXTEND (se expired) e STOP ---
          if (isInGracePeriod || isFinallyExpired) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onExtendSession, // CHANGED from TODO
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: Text(
                  "EXTEND SESSION",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

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