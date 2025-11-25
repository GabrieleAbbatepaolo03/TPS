import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manager_interface/models/tariff_config.dart';

class ActiveRulesCard extends StatelessWidget {
  final TariffConfig config;

  const ActiveRulesCard({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRow('Tariff Type', config.type.replaceAll('_', ' ')),
        const Divider(color: Colors.white12, height: 20),
        
        if (config.type == 'FIXED_DAILY') ...[
          _buildRow('Daily Flat Rate', '€${config.dailyRate.toStringAsFixed(2)}'),
          const SizedBox(height: 5),
          Text(
            "Applies to any duration up to 24h.",
            style: GoogleFonts.poppins(color: Colors.white30, fontSize: 12, fontStyle: FontStyle.italic),
          )
        ] else ...[
          // Linear & Variable condividono Day/Night base rates
          _buildRow('Day Base Rate', '€${config.dayBaseRate.toStringAsFixed(2)}/h'),
          _buildRow('Night Base Rate', '€${config.nightBaseRate.toStringAsFixed(2)}/h'),
          Text(
            'Night Schedule: ${config.nightStartTime} - ${config.nightEndTime}',
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
          ),
        ],

        if (config.type == 'HOURLY_VARIABLE' && config.flexRulesRaw.isNotEmpty) ...[
          const Divider(color: Colors.white12, height: 20),
          Text(
            'Duration Multipliers:',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...config.flexRulesRaw.map((r) {
             // 🚨 CORREZIONE: Gestione robusta delle chiavi JSON
             // Controlla sia 'from_hours' che 'duration_from_hours' per compatibilità
             final from = r['from_hours'] ?? r['duration_from_hours'] ?? '?';
             final to = r['to_hours'] ?? r['duration_to_hours'] ?? '?';
             final mult = r['multiplier'] ?? 1.0;
             
             return Padding(
               padding: const EdgeInsets.only(bottom: 4.0),
               child: Row(
                 children: [
                   const Icon(Icons.subdirectory_arrow_right, color: Colors.amber, size: 16),
                   const SizedBox(width: 8),
                   Text(
                     '$from - ${to}h',
                     style: GoogleFonts.poppins(color: Colors.white70),
                   ),
                   const Spacer(),
                   Text(
                     'x$mult',
                     style: GoogleFonts.poppins(color: Colors.amber, fontWeight: FontWeight.bold),
                   ),
                 ],
               ),
             );
          }),
        ]
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}