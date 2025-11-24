import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_interface/MODELS/payment_card.dart';
import 'package:user_interface/SERVICES/payment_service.dart';

// Classe per simulare l'input di un numero (solo cifre)
class NumericTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String filteredText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    return TextEditingValue(
      text: filteredText,
      selection: TextSelection.collapsed(offset: filteredText.length),
    );
  }
}

Future<PaymentCard?> showAddPaymentCardDialog(BuildContext context) async {
  final cardNumberController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  final paymentService = PaymentService();

  return showDialog<PaymentCard>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        
        Future<void> handleSave() async {
          if (!formKey.currentState!.validate()) return;
          setState(() => isLoading = true);

          try {
            final newCard = await paymentService.addCard(
              cardNumber: cardNumberController.text.trim(),
            );
            if (context.mounted) Navigator.of(context).pop(newCard);
          } catch (e) {
            setState(() => isLoading = false);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error adding card: ${e.toString()}'), backgroundColor: Colors.red),
              );
            }
          }
        }

        Widget buildField(TextEditingController controller, String label, {List<TextInputFormatter>? inputFormatters}) {
          return TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: inputFormatters,
            enabled: !isLoading,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            cursorColor: Colors.white,
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.white)),
            ),
          );
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color.fromARGB(255, 52, 12, 108), Color.fromARGB(255, 2, 11, 60)],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Add Payment Card',
                        style: GoogleFonts.poppins(
                            fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 20),
                    buildField(
                      cardNumberController,
                      'Card Number (e.g., Last 4 digits)',
                      inputFormatters: [
                        NumericTextFormatter(),
                        LengthLimitingTextInputFormatter(4), // Limita l'input per simulazione
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isLoading ? null : handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Text('Save Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}