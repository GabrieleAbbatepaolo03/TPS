import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:user_interface/MODELS/payment_card.dart';

class CardTile extends StatelessWidget {
  final PaymentCard card;
  final VoidCallback onDelete;

  const CardTile({
    super.key,
    required this.card,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card.isDefault ? const Color.fromARGB(255, 68, 13, 136) : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: card.isDefault ? Colors.white : Colors.white24, 
          width: 1.5
        ),
        boxShadow: card.isDefault
            ? [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          // Icona della Carta
          Icon(
            IconlyBold.wallet,
            color: card.isDefault ? Colors.white : Colors.white70,
            size: 30,
          ),
          const SizedBox(width: 15),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Etichetta del tipo di carta (Simulazione)
                Text(
                  'Visa Card', 
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                
                // Numero della carta (solo ultime 4 cifre)
                Text(
                  '**** **** **** ${card.cardNumber}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                // Badge Predefinito
                if (card.isDefault) 
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Default',
                        style: GoogleFonts.poppins(
                          color: const Color.fromARGB(255, 52, 12, 108),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          IconButton(
            icon: const Icon(IconlyLight.delete, color: Colors.redAccent, size: 22),
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}