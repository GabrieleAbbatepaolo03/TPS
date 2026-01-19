import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:officer_interface/MODELS/parking_session.dart';

import 'package:officer_interface/services/controller_service.dart';
import 'package:officer_interface/services/auth_service.dart';
import 'package:officer_interface/SCREENS/login_screen.dart';
import 'package:officer_interface/services/user_session.dart';

// ✅ 新增：值班相关
import 'package:officer_interface/services/shift_service.dart';
import 'package:officer_interface/SCREENS/start_shift_screen.dart';

class HomeScreen extends StatefulWidget {
  /// ✅ 可选：如果从 StartShiftScreen 进入，则会传入
  final DateTime? shiftStartTime;
  final int? shiftId;

  const HomeScreen({
    super.key,
    this.shiftStartTime,
    this.shiftId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _plateController = TextEditingController();
  ParkingSession? _activeSession;
  String? _message;
  bool _isLoading = false;

  // ✅ Shift timer
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();

    // 只有当传入 shiftStartTime 时才启动计时器
    if (widget.shiftStartTime != null) {
      _tick();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    final start = widget.shiftStartTime;
    if (start == null) return;
    setState(() {
      _elapsed = DateTime.now().difference(start);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _plateController.dispose();
    super.dispose();
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleEndShift() async {
    // 没有 shiftId 就不做（理论上不会发生，因为从 StartShift 来都会有）
    if (widget.shiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No active shift info found.")),
      );
      return;
    }

    try {
      await ShiftService.endShift();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const StartShiftScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to end shift."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSession();

    String jurisdictionText;
    if (session.isSuperAdmin) {
      jurisdictionText = "ALL CITIES (Global Access)";
    } else {
      jurisdictionText = session.allowedCities.isEmpty
          ? "No Jurisdiction Assigned"
          : session.allowedCities.join(", ");
    }

    final hasShift = widget.shiftStartTime != null && widget.shiftId != null;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Controller Dashboard",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.greenAccent,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    jurisdictionText.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),

            // ✅ 新增：Shift 计时器显示
            if (hasShift) ...[
              const SizedBox(height: 4),
              Text(
                "SHIFT: ${_formatElapsed(_elapsed)}",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // ✅ 新增：End Shift
          if (hasShift)
            TextButton.icon(
              onPressed: _handleEndShift,
              icon: const Icon(Icons.stop_circle, color: Colors.redAccent),
              label: Text(
                "End Shift",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),

          TextButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: Text(
              "Logout",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
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
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Enter the license plate to check for an active parking session.",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(child: _buildPlateTextField()),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _searchPlate,
                        icon: _isLoading
                            ? const SizedBox.shrink()
                            : const Icon(Icons.search, color: Colors.black),
                        label: Text(
                          _isLoading ? "Searching..." : "Check Plate",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
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
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 20,
        letterSpacing: 2,
      ),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: "E.g., AB123CD",
        hintStyle: GoogleFonts.poppins(
          color: Colors.white54,
          fontSize: 20,
          letterSpacing: 2,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
      ),
      onSubmitted: (_) => _searchPlate(),
    );
  }

  Widget _buildResultsArea() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
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
            color: isError
                ? Colors.red.withOpacity(0.1)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isError ? Colors.redAccent : Colors.greenAccent,
            ),
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
        ? NumberFormat.currency(
            locale: 'it_IT',
            symbol: '€',
          ).format(session.totalCost)
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
                style: GoogleFonts.poppins(
                  color: Colors.greenAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(
                Icons.check_circle,
                color: Colors.greenAccent,
                size: 30,
              ),
            ],
          ),
          const Divider(color: Colors.white38, height: 30),
          _buildInfoRow("License Plate", session.vehiclePlate),
          _buildInfoRow(
            "Parking Lot",
            session.parkingLot?.name ?? "Unknown Parking",
          ),
          _buildInfoRow("City", session.parkingLot?.city ?? "N/A"),
          _buildInfoRow("Session ID", "#${session.id}"),
          const Divider(color: Colors.white38, height: 30),
          _buildInfoRow(
            "Start Time",
            formatter.format(startTime),
            isHighlight: true,
          ),
          _buildInfoRow(
            "Duration",
            "${durationHours}h ${durationMinutes}m",
            isHighlight: true,
          ),
          _buildInfoRow("Estimated Cost", cost, isHighlight: true),
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
                color: Colors.white,
                fontSize: 16,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
