import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:user_interface/MAIN%20UTILS/app_sizes.dart';
import 'package:user_interface/MAIN%20UTILS/page_title.dart';
import 'package:user_interface/MODELS/parking_session.dart';
import 'package:user_interface/SERVICES/parking_session_service.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Importa Timer
import '../../MAIN UTILS/app_theme.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final ParkingSessionService _sessionService = ParkingSessionService();
  
  late Future<List<ParkingSession>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    setState(() {

      _sessionsFuture = _sessionService.fetchSessions(onlyActive: false);
    });
  }
  
  void _endSession(int sessionId) async {

    final endedSession = await _sessionService.endSession(sessionId);
    if (mounted && endedSession != null) {
      _loadSessions(); 
    }
  }

  @override
  Widget build(BuildContext context) {
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
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error loading sessions', style: GoogleFonts.poppins(color: Colors.redAccent)));
              }
              final allSessions = snapshot.data ?? [];
              final activeSessions = allSessions.where((s) => s.isActive).toList();
              final historySessions = allSessions.where((s) => !s.isActive).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PageTitle(title: 'Sessions'),
                    const SizedBox(height: 30),

                    _buildSectionTitle(context, 'Active Sessions'),
                    const SizedBox(height: 15),
                    _buildActiveSessionsList(activeSessions),
                    
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
        child: Center(child: Text('No active sessions found.', style: GoogleFonts.poppins(color: Colors.white54))),
      );
    }

    return ActiveSessionCard(
      session: sessions.first, 
      onEndSession: () => _endSession(sessions.first.id),
    );
  }

  Widget _buildHistorySessionsList(List<ParkingSession> sessions) {
    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Center(child: Text('History is empty.', style: GoogleFonts.poppins(color: Colors.white54))),
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

  Widget _buildHistorySessionCard(BuildContext context, {required ParkingSession session}) {
    final lotName = session.parkingLot?.name ?? 'Unknown Lot';
    final vehiclePlate = session.vehicle?.plate ?? 'N/A';
    final cost = session.totalCost != null ? '€${session.totalCost!.toStringAsFixed(2)}' : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(15, 255, 255, 255),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(IconlyBold.calendar, color: Colors.white70, size: 30),
        title: Text(
          lotName,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          'Vehicle: $vehiclePlate | Ended: ${session.endTime != null ? DateFormat('dd MMM, HH:mm').format(session.endTime!) : 'N/A'}',
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Cost', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
            Text(cost, style: GoogleFonts.poppins(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class ActiveSessionCard extends StatefulWidget {
  final ParkingSession session;
  final VoidCallback onEndSession;

  const ActiveSessionCard({
    super.key,
    required this.session,
    required this.onEndSession,
  });

  @override
  State<ActiveSessionCard> createState() => _ActiveSessionCardState();
}

class _ActiveSessionCardState extends State<ActiveSessionCard> {
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsedTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateElapsedTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

  void _updateElapsedTime() {
    if (mounted) {
      setState(() {
        _elapsedTime = DateTime.now().difference(widget.session.startTime);
      });
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = d.inHours.toString();
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final lotName = widget.session.parkingLot?.name ?? 'Unknown Lot';
    final vehiclePlate = widget.session.vehicle?.plate ?? 'N/A';
    final timeElapsedFormatted = _formatDuration(_elapsedTime);

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
            leading: const Icon(IconlyBold.time_circle, color: Colors.greenAccent, size: 40),
            title: Text(
              lotName,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
            ),
            subtitle: Text(
              'Vehicle: $vehiclePlate | Started: ${DateFormat('HH:mm').format(widget.session.startTime)}',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            ),
          ),
          
          const SizedBox(height: 8),

          Text(
            'Time Elapsed: $timeElapsedFormatted', 
            style: GoogleFonts.poppins(
              color: Colors.greenAccent, 
              fontWeight: FontWeight.w600, 
              fontSize: 16,
              fontFeatures: const [FontFeature.tabularFigures()], 
            ),
          ),
          
          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onEndSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('End Session', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}