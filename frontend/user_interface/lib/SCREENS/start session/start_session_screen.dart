import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_interface/MAIN%20UTILS/page_transition.dart';

import 'package:user_interface/MODELS/parking_lot.dart';
import 'package:user_interface/MODELS/vehicle.dart';
// import 'package:user_interface/MODELS/tariff_config.dart'; // Non più strettamente necessario se usiamo il getter di ParkingLot
import 'package:user_interface/SCREENS/root_screen.dart';
import 'package:user_interface/SCREENS/start%20session/parking_cost_calculator.dart';
import 'package:user_interface/SERVICES/vehicle_service.dart';
import 'package:user_interface/SERVICES/parking_session_service.dart';
import 'package:user_interface/MAIN UTILS/app_theme.dart';


import 'package:user_interface/STATE/payment_state.dart';
import 'package:user_interface/STATE/parking_session_state.dart';


class StartSessionScreen extends ConsumerStatefulWidget {
  final ParkingLot parkingLot;

  const StartSessionScreen({super.key, required this.parkingLot});

  @override
  ConsumerState<StartSessionScreen> createState() => _StartSessionScreenState();
}

class _StartSessionScreenState extends ConsumerState<StartSessionScreen> {
  final VehicleService _vehicleService = VehicleService();
  final ParkingSessionService _sessionService = ParkingSessionService();

  late Future<List<Vehicle>> _vehiclesFuture;
  Vehicle? _selectedVehicle;
  bool _isLoading = false;
  
  // NUOVO STATO PER LA DURATA E IL COSTO
  int _selectedDurationHours = 1; 
  double _prepaidCost = 0.0;

  @override
  void initState() {
    super.initState();
    if (ref.read(parkingControllerProvider).active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToActiveSession();
      });
    }
    _vehiclesFuture = _vehicleService.fetchMyVehicles();
    
    // Calcolo iniziale del costo
    _calculatePrepaidCost();
  }
  
  // Funzione per ricalcolare il costo quando cambia la durata
  void _calculatePrepaidCost() {
      // Recupera la configurazione tariffaria dal parcheggio
      final config = widget.parkingLot.tariffConfig;
      
      // Usa il calcolatore (assumendo che tu abbia creato parking_cost_calculator.dart)
      final calculator = CostCalculator(config); 
      
      // Calcola il costo per la durata selezionata (in ore)
      final cost = calculator.calculateCostForHours(_selectedDurationHours.toDouble());
      
      setState(() {
          _prepaidCost = cost;
      });
  }

  void _navigateToActiveSession() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A session is already active. Redirecting...'),
      ),
    );
    Navigator.of(context).push(
      slideRoute(const RootPage(initialIndex: 1)),
    );
  }

  Future<void> _startSession() async {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle first.')),
      );
      return;
    }

    final paymentNotifier = ref.read(paymentProvider.notifier);

    // Conferma con il costo esatto calcolato
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text(
          'You are purchasing $_selectedDurationHours hours of parking for €${_prepaidCost.toStringAsFixed(2)}.\n\nThis amount is non-refundable if you end the session early.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pay & Start'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    // Addebita l'importo esatto (Prepagato)
    await paymentNotifier.charge(_prepaidCost);
    // Non serve setPreAuthorized(true) perché è un addebito diretto

    final durationMinutes = _selectedDurationHours * 60;

    final session = await _sessionService.startSession(
      vehicleId: _selectedVehicle!.id,
      parkingLotId: widget.parkingLot.id,
      durationMinutes: durationMinutes,
      prepaidCost: _prepaidCost,       
    );

    if (mounted) {
      if (session != null &&
          session.vehicle != null &&
          session.parkingLot != null) {
        
        // Avvia il controller locale
        ref
            .read(parkingControllerProvider.notifier)
            .start(
              sessionId: session.id,
              vehicleId: session.vehicle!.id,
              parkingLotId: session.parkingLot!.id,
              startAt: session.startTime,
              tariffConfig: widget.parkingLot.tariffConfig, 
            );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session started for ${session.vehicle!.plate}'),
          ),
        );

        Navigator.of(context).push(slideRoute(const RootPage(initialIndex: 1)));
      } else {
        // In caso di errore API, si potrebbe voler rimborsare (logica complessa omessa)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start session. Please try again.'),
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(parkingControllerProvider).active) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradientDecoration,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              
              // 1. Dettagli Parcheggio e Tariffa
              _buildParkingDetails(),
              
              const SizedBox(height: 10),
              
              // 2. Selettore Durata (NUOVO)
              _buildDurationSelector(),
              
              const SizedBox(height: 10),
              
              // 3. Selettore Veicolo (Titolo)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Select Vehicle',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              // 4. Lista Veicoli
              Expanded(child: _buildVehicleSelector()),
              
              // 5. Bottone Conferma
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(IconlyLight.arrow_left, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                slideRoute(const RootPage(initialIndex: 1)),
              );
            },
          ),
          Text(
            'Start Session',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildParkingDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(25, 255, 255, 255),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.parkingLot.name,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(IconlyLight.location, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.parkingLot.address}, ${widget.parkingLot.city}',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          
          // Info sulla Tariffa
          _buildTariffInfo(),
        ],
      ),
    );
  }
  
  Widget _buildTariffInfo() {
      final config = widget.parkingLot.tariffConfig;
      String infoText = '';
      
      if (config.type == 'FIXED_DAILY') {
          infoText = 'Flat Daily Rate: €${config.dailyRate.toStringAsFixed(2)}';
      } else if (config.type == 'HOURLY_LINEAR') {
          infoText = 'Hourly Rate: €${config.dayBaseRate.toStringAsFixed(2)}/h';
          if (config.nightBaseRate != config.dayBaseRate) {
              infoText += '\nNight Rate: €${config.nightBaseRate.toStringAsFixed(2)}/h (${config.nightStartTime}-${config.nightEndTime})';
          }
      } else {
          infoText = 'Variable Rate:\nDay: €${config.dayBaseRate}/h | Night: €${config.nightBaseRate}/h\n+ Multipliers apply based on duration.';
      }
      
      return Text(
          infoText, 
          style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w500)
      );
  }

  // Widget per selezionare la durata
  Widget _buildDurationSelector() {
      return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white10),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text('Select Duration', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          // Mostra Ore
                          Text(
                              '$_selectedDurationHours Hours', 
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                          ),
                          // Mostra Costo Calcolato
                          Text(
                              '€${_prepaidCost.toStringAsFixed(2)}', 
                              style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)
                          ),
                      ],
                  ),
                  Slider(
                      value: _selectedDurationHours.toDouble(),
                      min: 1,
                      max: 24, // Massimo 24 ore per sessione
                      divisions: 23,
                      activeColor: Colors.blueAccent,
                      inactiveColor: Colors.white24,
                      onChanged: (value) {
                          setState(() {
                              _selectedDurationHours = value.toInt();
                          });
                          _calculatePrepaidCost(); // Ricalcola il costo al cambio
                      },
                  ),
              ],
          ),
      );
  }

  Widget _buildVehicleSelector() {
    return FutureBuilder<List<Vehicle>>(
      future: _vehiclesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No vehicles found.\nPlease add a vehicle in your profile.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
            ),
          );
        }

        final vehicles = snapshot.data!;
        if (_selectedVehicle == null && vehicles.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedVehicle = vehicles.first;
              });
            }
          });
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = vehicles[index];
            final bool isSelected = _selectedVehicle?.id == vehicle.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blueAccent.withOpacity(0.3)
                    : const Color.fromARGB(15, 255, 255, 255),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? Colors.blueAccent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  // Se il veicolo è preferito, usa la stella piena, altrimenti vuota
                  // (Assumendo che vehicle abbia isFavorite)
                  vehicle.isFavorite ? IconlyBold.star : IconlyLight.activity,
                  color: isSelected ? Colors.blueAccent : (vehicle.isFavorite ? Colors.amber : Colors.white),
                  size: 30,
                ),
                title: Text(
                  vehicle.plate,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  vehicle.name,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedVehicle = vehicle;
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConfirmButton() {
    final isActive = ref.watch(parkingControllerProvider).active;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: _isLoading || isActive ? null : _startSession,
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Text(
                  isActive ? 'Session Active' : 'Pay & Start Session',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}