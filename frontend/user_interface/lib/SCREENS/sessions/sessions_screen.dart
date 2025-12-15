import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_interface/MAIN%20UTILS/app_sizes.dart';
import 'package:user_interface/MAIN%20UTILS/page_title.dart';
import 'package:user_interface/MODELS/parking_session.dart';
import 'package:user_interface/SCREENS/sessions/utils/active_session_card.dart';
import 'package:user_interface/SERVICES/parking_session_service.dart';
import 'dart:async';
import '../../MAIN UTILS/app_theme.dart';
import 'package:user_interface/MODELS/parking_lot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_interface/STATE/parking_session_state.dart';
import 'package:user_interface/STATE/payment_state.dart';
import 'package:user_interface/SCREENS/payment/choose_payment_method_screen.dart';
import 'utils/limited_history_list.dart';

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  final ParkingSessionService _sessionService = ParkingSessionService();

  late Future<List<ParkingSession>> _allSessionsFuture;
  bool _isStopping = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    setState(() {
      _allSessionsFuture = _sessionService.fetchSessions();
    });

    _allSessionsFuture.then((sessions) {
      final active = sessions.where((s) => s.isActive).firstOrNull;

      if (active != null) {
        final config =
            active.parkingLot?.tariffConfig ?? ParkingLot.defaultTariffConfig;

        ref.read(parkingControllerProvider.notifier).start(
              sessionId: active.id,
              vehicleId: active.vehicle!.id,
              parkingLotId: active.parkingLot!.id,
              startAt: active.startTime,
              tariffConfig: config,
            );
      } else {
        if (ref.read(parkingControllerProvider).active) {
          ref.read(parkingControllerProvider.notifier).reset();
          ref.read(paymentProvider.notifier).resetPreAuthorization();
        }
      }
    });
  }

  void _stopSession(int sessionId) async {
    if (_isStopping) return;
    setState(() => _isStopping = true);

    final endedSession = await _sessionService.endSession(sessionId);

    if (mounted && endedSession != null) {
      // Scenario B: pay only the remaining amount (extra > 0)
      final finalCost = endedSession.totalCost ?? 0.0;
      final prepaidCost = endedSession.prepaidCost;
      final extra = finalCost - prepaidCost;

      if (extra > 0.0001) {
        final chosen = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ChoosePaymentMethodScreen(
              amount: extra,
              title: 'Pay the remaining amount',
            ),
          ),
        );

        if (chosen == true) {
          await ref.read(paymentProvider.notifier).charge(extra);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Extra payment completed. Charged €${extra.toStringAsFixed(2)}',
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Session ended. Extra payment of €${extra.toStringAsFixed(2)} is pending.',
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Parking stopped. No extra payment needed.'),
            ),
          );
        }
      }

      ref.read(parkingControllerProvider.notifier).reset();
      ref.read(paymentProvider.notifier).resetPreAuthorization();

      _loadSessions();
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
            future: _allSessionsFuture,
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
                  ? allSessions.where((s) => s.id == activeState.sessionId).toList()
                  : [];

              if (!activeState.active && activeSessionList.isEmpty) {
                final dbActive = allSessions.where((s) => s.isActive).toList();
                if (dbActive.isNotEmpty) {
                  activeSessionList.addAll(dbActive);
                }
              }

              final historySessions = allSessions.where((s) => !s.isActive).toList();
              final List<ParkingSession> limitedHistory = historySessions.take(3).toList();

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
                    LimitedHistoryList(
                      sessions: limitedHistory,
                      totalCount: historySessions.length,
                    ),
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
}
