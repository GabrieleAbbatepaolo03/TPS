import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:officer_interface/MODELS/parking_session.dart';

import 'package:officer_interface/services/controller_service.dart';
import 'package:officer_interface/services/auth_service.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _plateController = TextEditingController();
  ParkingSession? _activeSession;
  String? _message;
  bool _isLoading = false;

  Future<void> _searchPlate() async {
    final plate = _plateController.text.trim().toUpperCase();
    if (plate.isEmpty) {
      setState(() {
        _activeSession = null;
        _message = "Please enter a license plate.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _activeSession = null;
      _message = null;
    });

    try {
      final session = await ControllerService.searchActiveSessionByPlate(plate);
      
      setState(() {
        _activeSession = session;
        if (session == null) {
          _message = "Vehicle with plate '$plate' has NO active parking session.";
        }
      });
    } catch (e) {
      setState(() {
        _message = "Error during search: Failed to connect or invalid data.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      // Navigate to login screen (assuming main.dart will handle pushReplacement)
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Controller Dashboard",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: Text("Logout", style: GoogleFonts.poppins(color: Colors.white)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 2, 11, 60), 
              Color.fromARGB(255, 52, 12, 108), 
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Session Verification",
                    style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    "Enter the license plate to check for an active parking session.",
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 30),

                  // Search Bar and Button
                  Row(
                    children: [
                      Expanded(
                        child: _buildPlateTextField(),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _searchPlate,
                        icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.search, color: Colors.black),
                        label: Text(
                          _isLoading ? "Searching..." : "Check Plate",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Results Area
                  _buildResultsArea(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPlateTextField() {
    return TextField(
      controller: _plateController,
      textCapitalization: TextCapitalization.characters,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, letterSpacing: 2),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: "E.g., AB123CD",
        hintStyle: GoogleFonts.poppins(color: Colors.white54, fontSize: 20, letterSpacing: 2),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      ),
      onSubmitted: (_) => _searchPlate(),
    );
  }

  Widget _buildResultsArea() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    
    if (_activeSession != null) {
      return _buildActiveSessionCard(_activeSession!);
    }

    if (_message != null) {
      final isError = _message!.contains("NO active parking session");
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isError ? Colors.red.withOpacity(0.1) : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isError ? Colors.redAccent : Colors.greenAccent),
          ),
          child: Text(
            _message!,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: isError ? Colors.redAccent : Colors.greenAccent,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
  
  Widget _buildActiveSessionCard(ParkingSession session) {
    final startTime = session.startTime.toLocal();
    final duration = DateTime.now().difference(startTime);
    final formatter = DateFormat('MMM d, yyyy HH:mm');
    final durationHours = duration.inHours;
    final durationMinutes = duration.inMinutes % 60;
    
    final cost = session.totalCost != null 
        ? NumberFormat.currency(locale: 'it_IT', symbol: '€').format(session.totalCost) 
        : 'N/A';
    
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade800.withOpacity(0.3),
            const Color.fromARGB(255, 2, 11, 60).withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ACTIVE SESSION",
                style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 30),
            ],
          ),
          const Divider(color: Colors.white38, height: 30),
          
          // FIXED: Show only Plate, not Name
          _buildInfoRow("License Plate", session.vehiclePlate), 
          _buildInfoRow("Parking Lot", session.parkingLot?.name ?? "Unknown Parking"),
          _buildInfoRow("Parking Address", session.parkingLot?.address ?? "N/A"),
          _buildInfoRow("Session ID", "#${session.id}"),
          
          const Divider(color: Colors.white38, height: 30),

          // Duration and Cost
          _buildInfoRow(
            "Start Time", 
            formatter.format(startTime), 
            isHighlight: true
          ),
          _buildInfoRow(
            "Duration", 
            "${durationHours}h ${durationMinutes}m",
            isHighlight: true
          ),
          _buildInfoRow(
            "Estimated Cost (Base Rate)", 
            cost, 
            isHighlight: true
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: isHighlight ? Colors.white : Colors.white, 
                fontSize: 16, 
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal
              ),
            ),
          ),
        ],
      ),
    );
  }
}