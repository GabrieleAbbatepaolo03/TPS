import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:officer_interface/MODELS/parking_session.dart';

// --- ACTIVE SESSION CARD ---
class ActiveSessionCard extends StatelessWidget {
  final ParkingSession session;

  const ActiveSessionCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final startTime = session.startTime.toLocal();
    final duration = DateTime.now().difference(startTime);
    final formatter = DateFormat('MMM d, yyyy HH:mm');
    final durationHours = duration.inHours;
    final durationMinutes = duration.inMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade800.withOpacity(0.3),
            const Color.fromARGB(255, 2, 11, 60).withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("ACTIVE SESSION",
                  style: GoogleFonts.poppins(
                      color: Colors.greenAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const Icon(Icons.check_circle,
                  color: Colors.greenAccent, size: 30),
            ],
          ),
          const Divider(color: Colors.white38, height: 30),
          _buildInfoRow("License Plate", session.vehiclePlate),
          _buildInfoRow(
              "Parking Lot", session.parkingLot?.name ?? "Unknown Parking"),
          _buildInfoRow(
              "Parking Address", session.parkingLot?.address ?? "N/A"),
          _buildInfoRow("Session ID", "#${session.id}"),
          const Divider(color: Colors.white38, height: 30),
          _buildInfoRow("Start Time", formatter.format(startTime),
              isHighlight: true),
          _buildInfoRow("Duration", "${durationHours}h ${durationMinutes}m",
              isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(label,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: isHighlight ? Colors.white : Colors.white,
                fontSize: 16,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- GRACE PERIOD CARD ---
class GracePeriodCard extends StatelessWidget {
  final ParkingSession session;
  final String? message;

  const GracePeriodCard({super.key, required this.session, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orangeAccent),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orangeAccent, size: 50),
          const SizedBox(height: 10),
          Text("GRACE PERIOD",
              style: GoogleFonts.poppins(
                  color: Colors.orangeAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(message ?? "Session expired but within grace time.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 20),
          _simpleRow("Session Expired At",
              DateFormat('HH:mm').format(session.endTime.toLocal())),
          _simpleRow("Plate", session.vehiclePlate),
        ],
      ),
    );
  }

  Widget _simpleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("$label: ", style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- NOT FOUND CARD ---
class NotFoundCard extends StatelessWidget {
  const NotFoundCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.car_crash_outlined,
              color: Colors.redAccent, size: 50),
          const SizedBox(height: 15),
          Text("VEHICLE NOT FOUND",
              style: GoogleFonts.poppins(
                  color: Colors.redAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("This license plate is not registered in the database.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}

// --- VIOLATION CARD ---
class ViolationCard extends StatelessWidget {
  final String? message;
  final VoidCallback onIssueTicket;

  const ViolationCard({super.key, this.message, required this.onIssueTicket});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.redAccent),
          ),
          child: Column(
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 40),
              const SizedBox(height: 10),
              Text(message ?? "Violation Detected",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      color: Colors.redAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onIssueTicket,
            label: Text("ISSUE TICKET",
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ),
      ],
    );
  }
}