import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_interface/MAIN%20UTILS/PLATE%20RECOGNITION/plate_recognition_service.dart';
import 'package:user_interface/MODELS/vehicle.dart';
import 'package:user_interface/SERVICES/vehicle_service.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
}

Future<Vehicle?> showAddVehicleDialog(BuildContext context) async {
  final plateController = TextEditingController();
  final nameController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  PlateCountry? detectedCountry;
  final vehicleService = VehicleService();
  final recognitionService = PlateRecognitionService();

  return showDialog<Vehicle>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        Future<void> handleSave() async {
          if (!formKey.currentState!.validate()) return;
          setState(() => isLoading = true);

          try {
            final recognition = recognitionService.recognizePlate(plateController.text);
            final vehicle = await vehicleService.addVehicle(
              plate: recognition['plate'],
              name: nameController.text.trim(),
            );
            if (context.mounted) Navigator.of(context).pop(vehicle);
          } catch (e) {
            setState(() => isLoading = false);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error adding vehicle: $e'), backgroundColor: Colors.red),
              );
            }
          }
        }

        void onPlateChanged(String value) {
          final recognition = recognitionService.recognizePlate(value);
          setState(() => detectedCountry = recognition['country']);
        }

        Widget buildField(TextEditingController controller, String label,
            {List<TextInputFormatter>? inputFormatters, Widget? suffix}) {
          return TextFormField(
            controller: controller,
            onChanged: inputFormatters != null ? onPlateChanged : null,
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
              suffixIcon: suffix,
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
                    Text('Add New Vehicle',
                        style: GoogleFonts.poppins(
                            fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 20),
                    buildField(
                      plateController,
                      'Plate (e.g., AB123CD)',
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z]'))
                      ],
                      suffix: detectedCountry != null
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(detectedCountry!.flagEmoji, style: const TextStyle(fontSize: 28)),
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    buildField(nameController, 'Vehicle Name (e.g., My Car)'),
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
                          : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
