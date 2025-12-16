import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_interface/MODELS/payment_card.dart';

class CardTile extends StatelessWidget {
  final PaymentCard card;
  final bool isDefault;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  const CardTile({
    super.key,
    required this.card,
    required this.isDefault,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDefault ? Colors.greenAccent : Colors.white12,
            width: isDefault ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.credit_card_rounded,
              color: isDefault ? Colors.greenAccent : Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Credit / Debit Card',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '•••• ${card.cardNumber}',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isDefault)
              const Icon(Icons.check_circle, color: Colors.greenAccent),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
