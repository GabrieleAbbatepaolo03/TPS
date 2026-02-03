import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_interface/MAIN%20UTILS/page_transition.dart';
import 'package:intl/intl.dart';

import 'package:user_interface/MODELS/parking.dart';
import 'package:user_interface/MODELS/vehicle.dart';
import 'package:user_interface/SCREENS/root_screen.dart';
import 'package:user_interface/SCREENS/start%20session/parking_cost_calculator.dart';
import 'package:user_interface/SERVICES/vehicle_service.dart';
import 'package:user_interface/SERVICES/parking_session_service.dart';
import 'package:user_interface/MAIN UTILS/app_theme.dart';

import 'package:user_interface/STATE/payment_state.dart';
import 'package:user_interface/STATE/parking_session_state.dart';

// ✅ NEW: Choose payment method screen (single page)
import 'package:user_interface/SCREENS/payment/choose_payment_method_screen.dart';

enum StartSessionConfirmAction { cancel, changeMethod, confirm }

class StartSessionScreen extends ConsumerStatefulWidget {
  final Parking parkingLot;

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

  // Stato gestione durata
  int _selectedDurationMinutes = 60;
  double _prepaidCost = 0.0;
  DateTime _plannedEndTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (ref.read(parkingControllerProvider).active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToActiveSession();
      });
    }
    _vehiclesFuture = _vehicleService.fetchMyVehicles();

    // 🚨 SE FLAT RATE: Imposta default a 24h (1440 min)
    if (widget.parkingLot.tariffConfig.type == 'FIXED_DAILY') {
      _selectedDurationMinutes = 1440;
    }

    _recalculateAll();
  }

  void _recalculateAll() {
    final config = widget.parkingLot.tariffConfig;
    final calculator = CostCalculator(config);

    final double durationHours = _selectedDurationMinutes / 60.0;
    final double cost = calculator.calculateCostForHours(durationHours);

    final DateTime now = DateTime.now();
    final DateTime end = now.add(Duration(minutes: _selectedDurationMinutes));

    setState(() {
      _prepaidCost = cost;
      _plannedEndTime = end;
    });
  }

  // Usato per tariffa oraria
  void _adjustDuration(int deltaMinutes) {
    setState(() {
      _selectedDurationMinutes += deltaMinutes;
      if (_selectedDurationMinutes < 10) _selectedDurationMinutes = 10;
      if (_selectedDurationMinutes > 1440) _selectedDurationMinutes = 1440;
    });
    _recalculateAll();
  }

  // 🚨 Usato per tariffa Fixed Daily (+/- Giorni)
  void _adjustDays(int deltaDays) {
    setState(() {
      int currentDays = _selectedDurationMinutes ~/ 1440;
      if (currentDays == 0) currentDays = 1;

      int newDays = currentDays + deltaDays;
      if (newDays < 1) newDays = 1;
      if (newDays > 30) newDays = 30; // Max 30 giorni

      _selectedDurationMinutes = newDays * 1440; // Blocchi da 24h
    });
    _recalculateAll();
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

  void _showTariffDetailsDialog() {
    final config = widget.parkingLot.tariffConfig;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            Text('Tariff Details', style: GoogleFonts.poppins(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Type', config.type.replaceAll('_', ' ')),
              const Divider(color: Colors.white24),
              if (config.type == 'FIXED_DAILY')
                _buildInfoRow(
                    'Daily Rate', '€${config.dailyRate.toStringAsFixed(2)}'),
              if (config.type != 'FIXED_DAILY') ...[
                _buildInfoRow('Day Rate', '€${config.dayBaseRate.toStringAsFixed(2)}/h'),
                _buildInfoRow(
                    'Night Rate', '€${config.nightBaseRate.toStringAsFixed(2)}/h'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.blueAccent)),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.white70)),
          Text(value,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _startSession() async {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle first.')),
      );
      return;
    }

    String durationStr;
    if (widget.parkingLot.tariffConfig.type == 'FIXED_DAILY') {
      int days = _selectedDurationMinutes ~/ 1440;
      durationStr = '$days Day${days > 1 ? 's' : ''} (24h block)';
    } else {
      final int h = _selectedDurationMinutes ~/ 60;
      final int m = _selectedDurationMinutes % 60;
      durationStr = '${h}h ${m}m';
    }

    // ✅ Scenario A: First time only -> choose default payment method
    final payState = ref.read(paymentProvider);
    if (!payState.hasDefaultMethod) {
      final chosen = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const ChoosePaymentMethodScreen()),
      );
      if (chosen != true) return;
    }

    // ✅ Confirm dialog with "Pay with ..." + Change method
    while (true) {
      final payLabel = ref.read(paymentProvider).defaultMethodLabel;
      final String endTimeStr = DateFormat('dd MMM yyyy, HH:mm').format(_plannedEndTime);

      final action = await showDialog<StartSessionConfirmAction>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF020B3C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Confirm Payment',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSessionSummary(durationStr, endTimeStr),
                const SizedBox(height: 12),
                Text('Payment method', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(payLabel, style: GoogleFonts.poppins(color: Colors.white))),
                      Icon(Icons.payment, color: Colors.white54, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Full-width Change method button (giallo)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, StartSessionConfirmAction.changeMethod),
                    style: FilledButton.styleFrom(backgroundColor: Colors.amber),
                    child: Text('Change method', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
                  ),
                ),

                const SizedBox(height: 10),
                Text('This amount is non-refundable.', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          actions: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(
                  onPressed: () => Navigator.pop(context, StartSessionConfirmAction.cancel),
                  style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                  child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(context, StartSessionConfirmAction.confirm),
                  style: FilledButton.styleFrom(backgroundColor: Colors.greenAccent),
                  child: Text('Pay & Start', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      );

      if (action == null || action == StartSessionConfirmAction.cancel) return;

      if (action == StartSessionConfirmAction.changeMethod) {
        final changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const ChoosePaymentMethodScreen()),
        );
        // If user changed, loop again to refresh label; if they backed out, just loop.
        if (changed == true) continue;
        continue;
      }

      // confirm
      break;
    }

    setState(() => _isLoading = true);

    final paymentNotifier = ref.read(paymentProvider.notifier);
    // await paymentNotifier.charge(_prepaidCost);
    await paymentNotifier.charge
    (
      _prepaidCost,
      reason: 'Start Session',
    );


    final session = await _sessionService.startSession(
      vehicleId: _selectedVehicle!.id,
      parkingLotId: widget.parkingLot.id,
      durationMinutes: _selectedDurationMinutes,
      prepaidCost: _prepaidCost,
    );

    if (mounted) {
      if (session != null) {
        ref.read(parkingControllerProvider.notifier).start(
          sessionId: session.id,
          vehicleId: session.vehicle!.id,
          parkingLotId: session.parkingLot!.id,
          startAt: session.startTime,
          tariffConfig: widget.parkingLot.tariffConfig,
        );
        Navigator.of(context).push(slideRoute(const RootPage(initialIndex: 1)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start session. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Widget _buildSessionSummary(String durationStr, String endTimeStr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parcheggio
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.parkingLot.name,
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(widget.parkingLot.address,
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Veicolo
          Row(
            children: [
              const Icon(Icons.directions_car, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_selectedVehicle?.plate ?? '—'} • ${_selectedVehicle?.name ?? ''}',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Durata + Fine
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(durationStr, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Ends: $endTimeStr', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Totale
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
              Text('€${_prepaidCost.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(color: Colors.greenAccent, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(parkingControllerProvider).active) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final isFixedDaily = widget.parkingLot.tariffConfig.type == 'FIXED_DAILY';

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradientDecoration,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildParkingDetails(),
                      const SizedBox(height: 20),

                      isFixedDaily
                          ? _buildDailyDurationSelector()
                          : _buildPrecisionDurationSelector(),

                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Select Vehicle',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildVehicleSelector(),
                    ],
                  ),
                ),
              ),
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
        children: [
          IconButton(
            icon: const Icon(IconlyLight.arrow_left, color: Colors.white),
            onPressed: () => Navigator.of(context)
                .push(slideRoute(const RootPage(initialIndex: 0))),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Start Session',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildParkingDetails() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            widget.parkingLot.name,
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            widget.parkingLot.address,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _showTariffDetailsDialog,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(IconlyLight.info_circle,
                      color: Colors.blueAccent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _getTariffLabel(),
                    style: GoogleFonts.poppins(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  String _getTariffLabel() {
    final type = widget.parkingLot.tariffConfig.type;
    if (type == 'FIXED_DAILY') return 'Daily Flat Rate';
    if (type == 'HOURLY_LINEAR') return 'Hourly Linear Rate';
    return 'Variable Hourly Rate';
  }

  Widget _buildDailyDurationSelector() {
    final int days = _selectedDurationMinutes ~/ 1440;
    final String endTimeStr = DateFormat('dd MMM, HH:mm').format(_plannedEndTime);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FLAT COST',
                      style: GoogleFonts.poppins(
                          color: Colors.amber,
                          fontSize: 12,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold)),
                  Text(
                    '€${_prepaidCost.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('VALID UNTIL',
                      style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                          letterSpacing: 1)),
                  Text(
                    endTimeStr,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBigCircleButton(
                  icon: Icons.remove, onTap: () => _adjustDays(-1)),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                width: 140,
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Text(
                      '$days',
                      style: GoogleFonts.poppins(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Text(
                      days == 1 ? 'Day' : 'Days',
                      style: GoogleFonts.poppins(fontSize: 18, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              _buildBigCircleButton(
                  icon: Icons.add, onTap: () => _adjustDays(1)),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            "Fixed price per 24h. Covers full day.",
            style: GoogleFonts.poppins(
                color: Colors.white30, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildPrecisionDurationSelector() {
    final int hours = _selectedDurationMinutes ~/ 60;
    final int minutes = _selectedDurationMinutes % 60;
    final String endTimeStr = DateFormat('HH:mm').format(_plannedEndTime);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOTAL COST',
                      style: GoogleFonts.poppins(
                          color: Colors.white54, fontSize: 12, letterSpacing: 1)),
                  Text(
                    '€${_prepaidCost.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                        color: Colors.greenAccent,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('ENDS AT',
                      style: GoogleFonts.poppins(
                          color: Colors.white54, fontSize: 12, letterSpacing: 1)),
                  Text(
                    endTimeStr,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 30),

          // 1. Controlli Principali
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBigCircleButton(icon: Icons.remove, onTap: () => _adjustDuration(-1)),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                width: 180,
                alignment: Alignment.center,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                          text: '$hours',
                          style: GoogleFonts.poppins(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      TextSpan(
                          text: 'h ',
                          style: GoogleFonts.poppins(fontSize: 20, color: Colors.white70)),
                      TextSpan(
                          text: '$minutes',
                          style: GoogleFonts.poppins(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      TextSpan(
                          text: 'm',
                          style: GoogleFonts.poppins(fontSize: 20, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
              _buildBigCircleButton(icon: Icons.add, onTap: () => _adjustDuration(1)),
            ],
          ),

          const SizedBox(height: 15),

          // 2. Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: Colors.blueAccent,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: _selectedDurationMinutes.toDouble(),
              min: 10,
              max: 1440,
              divisions: (1440 - 10) ~/ 10,
              onChanged: (val) {
                setState(() {
                  _selectedDurationMinutes = val.toInt();
                });
                _recalculateAll();
              },
            ),
          ),

          const SizedBox(height: 10),

          // 3. Bottoni Rapidi (2 Righe)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickButton('+10m', 10, color: Colors.greenAccent.withOpacity(0.2)),
              _buildQuickButton('+15m', 15, color: Colors.greenAccent.withOpacity(0.2)),
              _buildQuickButton('+30m', 30, color: Colors.greenAccent.withOpacity(0.2)),
              _buildQuickButton('+1h', 60, color: Colors.greenAccent.withOpacity(0.2)),
              _buildQuickButton('+2h', 120, color: Colors.greenAccent.withOpacity(0.2)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickButton('-10m', -10, color: Colors.redAccent.withOpacity(0.2)),
              _buildQuickButton('-15m', -15, color: Colors.redAccent.withOpacity(0.2)),
              _buildQuickButton('-30m', -30, color: Colors.redAccent.withOpacity(0.2)),
              _buildQuickButton('-1h', -60, color: Colors.redAccent.withOpacity(0.2)),
              _buildQuickButton('-2h', -120, color: Colors.redAccent.withOpacity(0.2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBigCircleButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildQuickButton(String label, int minutes, {Color? color}) {
    return InkWell(
      onTap: () => _adjustDuration(minutes),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 50,
        height: 35,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: color ?? Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white10)),
        child: Text(label,
            style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildVehicleSelector() {
    return FutureBuilder<List<Vehicle>>(
      future: _vehiclesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final vehicles = snapshot.data!;

        if (_selectedVehicle == null && vehicles.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedVehicle = vehicles.first);
          });
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: vehicles.length,
          itemBuilder: (ctx, index) {
            final v = vehicles[index];
            final isSelected = v.id == _selectedVehicle?.id;

            return GestureDetector(
              onTap: () => setState(() => _selectedVehicle = v),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blueAccent : Colors.white10,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.plate,
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        Text(v.name,
                            style: GoogleFonts.poppins(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Colors.white, size: 24)
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 5,
          ),
          onPressed: _isLoading ? null : _startSession,
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black))
              : Text(
                  'GO TO CHECKOUT',
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
