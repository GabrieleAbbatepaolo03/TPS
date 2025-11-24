// File: vehicle_card.dart (CORRETTO - Stella sempre visibile)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:user_interface/MAIN%20UTILS/PLATE%20RECOGNITION/plate_recognition_service.dart';
import 'package:user_interface/MAIN%20UTILS/PLATE%20RECOGNITION/vehicle_plate_visual.dart';
import 'package:user_interface/MODELS/vehicle.dart';


class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback? onDelete; 
  final VoidCallback? onFavoriteToggle; 
  
  // Rimosso 'showFavoriteToggle' poiché la stella deve essere sempre visibile.
  final PlateRecognitionService _recognitionService = PlateRecognitionService();

  VehicleCard({
    super.key,
    required this.vehicle,
    this.onDelete, 
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final recognition = _recognitionService.recognizePlate(vehicle.plate);
    final PlateCountry? country = recognition['country'];
    
    // Logica dello stato: Piena (Bold/Gialla) se isFavorite è true, altrimenti Vuota (Light/Bianca).
    final IconData favoriteIcon = vehicle.isFavorite ? IconlyBold.star : IconlyLight.star;
    final Color favoriteColor = vehicle.isFavorite ? Colors.yellow : Colors.white54;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white12, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1), 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  vehicle.name,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icona Preferito: SEMPRE PRESENTE
                  IconButton(
                    icon: Icon(favoriteIcon, color: favoriteColor, size: 24),
                    onPressed: onFavoriteToggle, 
                    visualDensity: VisualDensity.compact,
                  ),
                  
                  // Pulsante Cancella (Mostrato se la callback è fornita)
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(IconlyLight.delete, color: Colors.redAccent, size: 22),
                      onPressed: onDelete, 
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          PlateWidget(
            plate: vehicle.plate,
            country: country,
          ),
        ],
      ),
    );
  }
}