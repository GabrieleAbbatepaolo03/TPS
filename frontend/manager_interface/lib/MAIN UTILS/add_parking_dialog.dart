import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:manager_interface/models/parking.dart';
import 'package:manager_interface/services/parking_service.dart';

Future<Parking?> showAddParkingDialog(
  BuildContext context, {
  required List<String> existingCities,
}) async {
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final totalSpotsController = TextEditingController();
  // RIMOSSO: rateController
  final latController = TextEditingController();
  final lngController = TextEditingController();
  final newCityController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final cityOptions = ['New City...', ...existingCities];

  String selectedCityOption = cityOptions.first;
  bool isLoading = false;

  return showDialog<Parking>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {

          void handleSave() async {
            if (!formKey.currentState!.validate()) return;
            
            if (selectedCityOption == 'New City...' && newCityController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select or enter a new city name.')),
              );
              return;
            }

            setState(() => isLoading = true);

            final finalCity = (selectedCityOption != 'New City...' 
                              ? selectedCityOption 
                              : newCityController.text.trim());

            final newParkingData = Parking(
              id: 0,
              name: nameController.text,
              city: finalCity,
              address: addressController.text,
              totalSpots: int.parse(totalSpotsController.text), 
              occupiedSpots: 0,
              // NUOVI CAMPI AGGIUNTI (Inizializzati a 0)
              todayEntries: 0, 
              todayRevenue: 0.0,
              
              latitude: double.tryParse(latController.text),
              longitude: double.tryParse(lngController.text),
              tariffConfigJson: Parking.defaultTariffConfig.toJson(), // Usa toJsonString()
            );

            try {
              // 1. Salva il parcheggio
              final savedParking = await ParkingService.saveParking(newParkingData);
              
              // 2. Crea i posti
              final int spotsToCreate = int.parse(totalSpotsController.text);

              if (spotsToCreate > 0) {
                List<Future> spotFutures = [];
                // Nota: Per grandi numeri, idealmente il backend dovrebbe avere un endpoint 'bulk_create'
                for (int i = 0; i < spotsToCreate; i++) {
                  spotFutures.add(ParkingService.addSpot(savedParking.id));
                }
                await Future.wait(spotFutures);
              }

              // 3. Costruisci l'oggetto finale per aggiornare la UI locale
              final finalParking = Parking(
                id: savedParking.id,
                name: savedParking.name,
                city: savedParking.city,
                address: savedParking.address,
                totalSpots: spotsToCreate, 
                occupiedSpots: 0,
                // NUOVI CAMPI AGGIUNTI
                todayEntries: 0, 
                todayRevenue: 0.0,
                
                latitude: savedParking.latitude,
                longitude: savedParking.longitude,
                tariffConfigJson: savedParking.tariffConfigJson,
              );

              Navigator.of(context).pop(finalParking);
            } catch (e) {
              setState(() => isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error creating parking: $e'), backgroundColor: Colors.red),
              );
            }
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            child: ConstrainedBox( 
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color.fromARGB(255, 52, 12, 108),
                      Color.fromARGB(255, 2, 11, 60),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Add New Parking',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // City Selection
                        Row(
                          children: [
                            Expanded(child: Container(height: 1, color: Colors.white30)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                'City Information',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                            Expanded(child: Container(height: 1, color: Colors.white30)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        _buildCitySelector(
                          selectedCityOption,
                          cityOptions,
                          (String? newValue) {
                            setState(() {
                              selectedCityOption = newValue!;
                            });
                          },
                        ),
                        if (selectedCityOption == 'New City...') ...[
                          const SizedBox(height: 16),
                          _buildStyledTextField(newCityController, 'New City Name', false, isEnabled: !isLoading),
                        ],
                        const SizedBox(height: 20),
                        Container(height: 1, color: Colors.white30),
                        const SizedBox(height: 20),

                        _buildStyledTextField(nameController, 'Parking Name', false, isEnabled: !isLoading),
                        const SizedBox(height: 16),
                        _buildStyledTextField(addressController, 'Address', false, isEnabled: !isLoading),
                        const SizedBox(height: 16),
                        
                        // MODIFICATO: Solo Total Spots, rimossa la tariffa
                        _buildStyledTextField(totalSpotsController, 'Total Spots', true, isEnabled: !isLoading),
                        
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildStyledTextField(latController, 'Latitude', true, isEnabled: !isLoading)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildStyledTextField(lngController, 'Longitude', true, isEnabled: !isLoading)),
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
                              ? const CircularProgressIndicator()
                              : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}


Widget _buildStyledTextField(TextEditingController controller, String label, bool isNumber, {bool isEnabled = true}) {
  return TextFormField(
    controller: controller,
    enabled: isEnabled,
    keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
    style: const TextStyle(color: Colors.white),
    cursorColor: Colors.white,
    validator: (value) {
      if (value == null || value.isEmpty) return 'Required';
      if (isNumber && double.tryParse(value.replaceAll(',', '.')) == null) return 'Invalid';
      return null;
    },
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.white),
      ),
    ),
  );
}

Widget _buildCitySelector(String selectedValue, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          dropdownColor: const Color.fromARGB(255, 52, 12, 108),
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: GoogleFonts.poppins()),
            );
          }).toList(),
        ),
      ),
    );
}