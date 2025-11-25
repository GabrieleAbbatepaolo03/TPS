import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class OccupancyCard extends StatelessWidget {
  final double percentage;
  final int totalSpots;
  final int occupiedSpots;

  const OccupancyCard({
    super.key,
    required this.percentage,
    required this.totalSpots,
    required this.occupiedSpots,
  });

  @override
  Widget build(BuildContext context) {
    Color color = percentage > 80 ? Colors.redAccent : (percentage > 50 ? Colors.orange : Colors.greenAccent);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Occupancy',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Divider(color: Colors.white12, height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeWidth: 10,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(color: color, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(width: 30),
            Column(
              children: [
                Text(
                  'Total: $totalSpots spots',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
                Text(
                  'Occupied: $occupiedSpots spots',
                  style: GoogleFonts.poppins(color: color),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class RevenueCard extends StatelessWidget {
  final double projectedRevenue;

  const RevenueCard({super.key, required this.projectedRevenue});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Revenue',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Divider(color: Colors.white12, height: 20),
        Text(
          currencyFormatter.format(projectedRevenue),
          style: GoogleFonts.poppins(
            color: Colors.greenAccent,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Total revenue accumulated today from ended sessions.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}

class DailyEntriesCard extends StatelessWidget {
  final int dailyEntries;
  final double avgStayHours;

  const DailyEntriesCard({
    super.key,
    required this.dailyEntries,
    required this.avgStayHours,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Entries',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Divider(color: Colors.white12, height: 20),
        Text(
          '$dailyEntries vehicles',
          style: GoogleFonts.poppins(
            color: Colors.blueAccent,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Total number of vehicles that entered the parking lot today.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}