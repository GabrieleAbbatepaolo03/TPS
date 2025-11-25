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
// Importa i widget che abbiamo creato (assicurati che i file esistano)
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
      // 🚨 CORREZIONE QUI: Rimuovi 'active: false'. 
      // Ora scarica TUTTE le sessioni (attive e storiche).
      _allSessionsFuture = _sessionService.fetchSessions(); 
    });

    _allSessionsFuture.then((sessions) {
      // Cerca se c'è una sessione attiva nella lista scaricata
      final active = sessions.where((s) => s.isActive).firstOrNull;

      if (active != null) {
        // Se trovata, sincronizza il controller locale
        final config = active.parkingLot?.tariffConfig ?? ParkingLot.defaultTariffConfig;

        ref.read(parkingControllerProvider.notifier).start(
              sessionId: active.id,
              vehicleId: active.vehicle!.id,
              parkingLotId: active.parkingLot!.id,
              startAt: active.startTime,
              tariffConfig: config,
            );
      } else {
        // Se non ci sono sessioni attive nel backend, resetta lo stato locale
        // (Utile se la sessione è scaduta o chiusa altrove)
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

    // Invia la richiesta di stop
    final endedSession = await _sessionService.endSession(sessionId);

    if (mounted && endedSession != null) {
      // Usa il costo totale restituito dal server
      final finalCost = endedSession.totalCost ?? 0.0;
      
      await ref.read(paymentProvider.notifier).charge(finalCost);

      ref.read(parkingControllerProvider.notifier).reset();
      ref.read(paymentProvider.notifier).resetPreAuthorization();

      _loadSessions(); // Ricarica la lista per aggiornare la UI
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Parking stopped. Charged €${finalCost.toStringAsFixed(2)}',
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

              // Filtra la sessione attiva basandosi sull'ID nello stato o sul flag isActive
              final List<ParkingSession> activeSessionList = activeState.active
                  ? allSessions.where((s) => s.id == activeState.sessionId).toList()
                  : [];
              
              // Se lo stato locale non è attivo ma ne troviamo una attiva nel DB, mostriamola
              // (Safety check per casi di desincronizzazione)
              if (!activeState.active && activeSessionList.isEmpty) {
                  final dbActive = allSessions.where((s) => s.isActive).toList();
                  if (dbActive.isNotEmpty) {
                      // Nota: Idealmente dovremmo aggiornare lo stato qui, ma evitiamo loop nel build
                      // Usiamo quella del DB per la visualizzazione
                      activeSessionList.addAll(dbActive);
                  }
              }

              // Filtra la cronologia (sessioni non attive)
              final historySessions = allSessions
                  .where((s) => !s.isActive)
                  .toList();
              
              // Prepara la lista limitata per il widget
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
                    
                    // Usa il widget LimitedHistoryList
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