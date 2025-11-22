import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:user_interface/MAIN UTILS/app_sizes.dart';
import 'package:user_interface/MAIN UTILS/page_title.dart';
import 'package:user_interface/MODELS/parking_session.dart';
import 'package:user_interface/SERVICES/parking_session_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../MAIN UTILS/app_theme.dart';
import 'package:user_interface/MODELS/parking_lot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_interface/STATE/parking_session_state.dart';
import 'package:user_interface/STATE/payment_state.dart';
import 'package:user_interface/MODELS/tariff_config.dart';

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  final ParkingSessionService _sessionService = ParkingSessionService();

  late Future<List<ParkingSession>> _sessionsFuture;
  bool _isStopping = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    setState(() {
      _sessionsFuture = _sessionService.fetchSessions(onlyActive: false);
    });

    _sessionsFuture.then((sessions) {
      final active = sessions.where((s) => s.isActive).firstOrNull;

      if (active != null) {
        final config =
            active.parkingLot?.tariffConfig ?? ParkingLot.defaultTariffConfig;

        ref
            .read(parkingControllerProvider.notifier)
            .start(
              sessionId: active.id,
              vehicleId: active.vehicle!.id,
              parkingLotId: active.parkingLot!.id,
              startAt: active.startTime,
              tariffConfig: config,
            );
      } else {
        ref.read(parkingControllerProvider.notifier).reset();
        ref.read(paymentProvider.notifier).resetPreAuthorization();
      }
    });
  }

  void _stopSession(int sessionId) async {
    if (_isStopping) return;
    setState(() => _isStopping = true);

    final activeState = ref.read(parkingControllerProvider);
    final config = activeState.tariffConfig ?? ParkingLot.defaultTariffConfig;

    final elapsed =
        ref.read(parkingElapsedProvider).valueOrNull ?? Duration.zero;

    final feeStr = calculateFee(elapsed, config);
    final roundedFee = double.parse(feeStr);

    final endedSession = await _sessionService.endSession(sessionId);

    if (mounted && endedSession != null) {
      await ref.read(paymentProvider.notifier).charge(roundedFee);

      ref.read(parkingControllerProvider.notifier).reset();
      ref.read(paymentProvider.notifier).resetPreAuthorization();

      _loadSessions();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Parking stopped. Charged €${roundedFee.toStringAsFixed(2)}',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to end session. Please check connection.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    setState(() => _isStopping = false);
  }

  @override
  Widget build(BuildContext context) {
    final activeState = ref.watch(parkingControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        height: AppSizes.screenHeight,
        decoration: AppTheme.backgroundGradientDecoration,
        child: SafeArea(
          child: FutureBuilder<List<ParkingSession>>(
            future: _sessionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading sessions',
                    style: GoogleFonts.poppins(color: Colors.redAccent),
                  ),
                );
              }

              final List<ParkingSession> allSessions = snapshot.data ?? [];

              final List<ParkingSession> activeSessionList = activeState.active
                  ? allSessions
                        .where((s) => s.id == activeState.sessionId)
                        .toList()
                  : [];

              final historySessions = allSessions
                  .where((s) => !s.isActive)
                  .toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PageTitle(title: 'Sessions'),
                    const SizedBox(height: 30),
                    _buildSectionTitle(context, 'Active Sessions'),
                    const SizedBox(height: 15),
                    _buildActiveSessionsList(activeSessionList),
                    const SizedBox(height: 30),
                    _buildSectionTitle(context, 'History'),
                    const SizedBox(height: 15),
                    _buildHistorySessionsList(historySessions),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.white.withOpacity(0.8),
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildActiveSessionsList(List<ParkingSession> sessions) {
    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Center(
          child: Text(
            'No active sessions found.',
            style: GoogleFonts.poppins(color: Colors.white54),
          ),
        ),
      );
    }

    return ActiveSessionCard(
      session: sessions.first,
      onEndSession: () => _stopSession(sessions.first.id),
      isStopping: _isStopping,
    );
  }

  Widget _buildHistorySessionsList(List<ParkingSession> sessions) {
    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Center(
          child: Text(
            'History is empty.',
            style: GoogleFonts.poppins(color: Colors.white54),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        return _buildHistorySessionCard(context, session: sessions[index]);
      },
    );
  }

  Widget _buildHistorySessionCard(
    BuildContext context, {
    required ParkingSession session,
  }) {
    final lotName = session.parkingLot?.name ?? 'Unknown Lot';
    final vehiclePlate = session.vehicle?.plate ?? 'N/A';
    final cost = session.totalCost != null
        ? '€${session.totalCost!.toStringAsFixed(2)}'
        : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(15, 255, 255, 255),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(
          IconlyBold.calendar,
          color: Colors.white70,
          size: 30,
        ),
        title: Text(
          lotName,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Vehicle: $vehiclePlate | Ended: ${session.endTime != null ? DateFormat('dd MMM, HH:mm').format(session.endTime!) : 'N/A'}',
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Cost',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
            ),
            Text(
              cost,
              style: GoogleFonts.poppins(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActiveSessionCard extends ConsumerStatefulWidget {
  final ParkingSession session;
  final VoidCallback onEndSession;
  final bool isStopping;

  const ActiveSessionCard({
    super.key,
    required this.session,
    required this.onEndSession,
    required this.isStopping,
  });

  @override
  ConsumerState<ActiveSessionCard> createState() => _ActiveSessionCardState();
}

class _ActiveSessionCardState extends ConsumerState<ActiveSessionCard> {
  @override
  Widget build(BuildContext context) {
    final elapsedTimeAsync = ref.watch(parkingElapsedProvider);
    final config =
        ref.watch(parkingControllerProvider).tariffConfig ??
        ParkingLot.defaultTariffConfig;

    final fee = elapsedTimeAsync.when(
      data: (d) => calculateFee(d, config),
      loading: () => '0.00',
      error: (_, __) => 'N/A',
    );

    final timeElapsedFormatted = elapsedTimeAsync.when(
      data: (d) => formatDuration(d),
      loading: () => '--:--:--',
      error: (_, __) => 'N/A',
    );

    final lotName = widget.session.parkingLot?.name ?? 'Unknown Lot';
    final vehiclePlate = widget.session.vehicle?.plate ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(25, 255, 255, 255),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              IconlyBold.time_circle,
              color: Colors.greenAccent,
              size: 40,
            ),
            title: Text(
              lotName,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            subtitle: Text(
              'Vehicle: $vehiclePlate | Started: ${DateFormat('HH:mm').format(widget.session.startTime)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Elapsed: $timeElapsedFormatted',
                style: GoogleFonts.poppins(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'Fee: €$fee',
                style: GoogleFonts.poppins(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isStopping ? null : widget.onEndSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: widget.isStopping
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'End Session',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
