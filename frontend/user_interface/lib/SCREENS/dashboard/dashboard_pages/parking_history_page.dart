import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_interface/MAIN%20UTILS/app_sizes.dart';
import 'package:user_interface/MAIN%20UTILS/app_theme.dart';
import 'package:user_interface/MODELS/parking_session.dart';
import 'package:user_interface/SCREENS/sessions/utils/history_session_card.dart'; 
import 'package:user_interface/SERVICES/parking_session_service.dart';  

class ParkingHistoryPage extends StatefulWidget { 
  const ParkingHistoryPage({super.key});

  @override
  State<ParkingHistoryPage> createState() => _ParkingHistoryPageState();
}

class _ParkingHistoryPageState extends State<ParkingHistoryPage> {
  final ParkingSessionService _sessionService = ParkingSessionService();
  late Future<List<ParkingSession>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = _sessionService.fetchSessions(active: false); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Full Session History',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        height: AppSizes.screenHeight,
        width: AppSizes.screenWidth,
        decoration: AppTheme.backgroundGradientDecoration,
        child: SafeArea(

          child: RefreshIndicator( 
            onRefresh: () => Future.sync(() => _loadHistory()),
            color: Colors.white,
            child: FutureBuilder<List<ParkingSession>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white70));
                }
                
                if (snapshot.hasError) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Text(
                      'Failed to load history. Error: ${snapshot.error}',
                      style: GoogleFonts.poppins(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ));
                }
                
                final sessions = snapshot.data ?? [];
                
                if (sessions.isEmpty) {
                  return Center(child: Text(
                    'No parking sessions found in your history.',
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16),
                    textAlign: TextAlign.center,
                  ));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    return HistorySessionCard(session: sessions[index]);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}