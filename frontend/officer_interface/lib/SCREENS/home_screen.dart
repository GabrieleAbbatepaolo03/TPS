import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:officer_interface/MAIN%20UTILS/issue_ticket_dialog.dart';
import 'package:officer_interface/MODELS/parking_session.dart';
import 'package:officer_interface/SERVICES/controller_service.dart';

import 'package:officer_interface/SERVICES/shift_service.dart';
import 'package:officer_interface/SCREENS/start_shift_screen.dart';

import 'package:officer_interface/SERVICES/plate_ocr_service.dart';

class HomeScreen extends StatefulWidget {
  final DateTime? shiftStartTime;
  final int? shiftId;

  const HomeScreen({super.key, this.shiftStartTime, this.shiftId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _plateController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  ParkingSession? _activeSession;
  String? _message;
  bool _isLoading = false;
  String? _status;
  bool _canIssueTicket = false;
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
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
        _status = null;
        _message = "Please enter a license plate.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _activeSession = null;
      _status = null;
      _canIssueTicket = false;
      _message = null;
    });

    try {
      final result = await ControllerService.searchActiveSessionByPlate(plate);

      setState(() {
        if (result != null) {
          _status = result['status'];
          _canIssueTicket = result['can_issue_ticket'] ?? false;
          _message = result['message'];

          if (result['session_data'] != null) {
            _activeSession = ParkingSession.fromJson(result['session_data']);
          } else {
            _activeSession = null;
          }
        } else {
          _message = "Connection error or unauthorized.";
        }
      });
    } catch (e) {
      setState(() {
        _message = "Error during search: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scanPlate() async {
    try {
      setState(() {
        _isLoading = true;
        _message = null;
        _activeSession = null;
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() {
          _isLoading = false;
          _message = "No image selected.";
        });
        return;
      }

      final result = await PlateOcrService.recognizePlate(image);
      final plate = (result['plate'] ?? '').toString().trim().toUpperCase();

      if (plate.isEmpty) {
        setState(() {
          _isLoading = false;
          _message = "OCR failed: no plate detected.";
        });
        return;
      }

      _plateController.text = plate;

      await _searchPlate();
    } catch (e) {
      setState(() {
        _message = "OCR error: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleEndShift() async {
    if (widget.shiftId == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 2, 11, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "End Shift?",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          content: Text(
            "Are you sure you want to end your current shift?",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "End Shift",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await ShiftService.endShift();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const StartShiftScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasShift = widget.shiftStartTime != null && widget.shiftId != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dashboard",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (hasShift)
              Text(
                "Shift: ${_formatElapsed(_elapsed)}",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          if (hasShift)
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              child: ElevatedButton.icon(
                onPressed: _handleEndShift,
                icon: const Icon(Icons.stop, size: 18),
                label: const Text("End Shift"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 2, 11, 60),
              Color.fromARGB(255, 52, 12, 108),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
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
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(child: _buildPlateTextField()),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _scanPlate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A2D3E),
                          foregroundColor: Colors.amberAccent,
                          padding: const EdgeInsets.all(20),
                          elevation: 8,
                          shadowColor: Colors.black.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Colors.amberAccent, width: 2),
                          ),
                        ),
                        child: const Icon(Icons.photo_camera, size: 28),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _searchPlate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A2D3E),
                          foregroundColor: Colors.greenAccent,
                          padding: const EdgeInsets.all(20),
                          elevation: 8,
                          shadowColor: Colors.black.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Colors.greenAccent, width: 2),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  color: Colors.greenAccent,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Icon(Icons.search, size: 28),
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
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _plateController,
        style: GoogleFonts.sourceCodePro( // Monospaced font looks better for plates
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.normal,
          letterSpacing: 4, // Spacing like a real plate
        ),
        cursorColor: Colors.greenAccent,
        // Force uppercase and alphanumeric
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
          TextInputFormatter.withFunction((oldValue, newValue) {
            return newValue.copyWith(text: newValue.text.toUpperCase());
          }),
        ],
        decoration: InputDecoration(
          hintText: "Plate No.",
          hintStyle: GoogleFonts.sourceCodePro(
            color: Colors.white24,
            fontSize: 22,
            letterSpacing: 4,
          ),
          filled: true,
          fillColor: const Color(0xFF2A2D3E),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white24, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.greenAccent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 22,
          ),
        ),
        onSubmitted: (_) => _searchPlate(),
      ),
    );
  }

  Widget _buildResultsArea() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_status == 'active' && _activeSession != null) {
      return _buildActiveSessionCard(_activeSession!);
    }
    if (_status == 'grace_period' && _activeSession != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orangeAccent),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orangeAccent,
              size: 50,
            ),
            const SizedBox(height: 10),
            Text(
              "GRACE PERIOD",
              style: GoogleFonts.poppins(
                color: Colors.orangeAccent,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _message ?? "Session expired but within grace time.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              "Expired At",
              DateFormat('HH:mm').format(_activeSession!.endTime.toLocal()),
            ),
            _buildInfoRow("Plate", _activeSession!.vehiclePlate),
          ],
        ),
      );
    }
    if (_status == 'not_found') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.car_crash_outlined,
              color: Colors.redAccent,
              size: 50,
            ),
            const SizedBox(height: 15),
            Text(
              "VEHICLE NOT FOUND",
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "This license plate is not registered in the database.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 5),
            Text(
              "Cannot issue digital ticket.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }
    if (_canIssueTicket) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.redAccent),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 40,
                ),
                const SizedBox(height: 10),
                Text(
                  _message ?? "Violation Detected",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.redAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _handleReportViolation,
              label: Text(
                "ISSUE TICKET",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_message != null) {
      return Text(_message!, style: const TextStyle(color: Colors.white));
    }

    return const SizedBox.shrink();
  }

  Future<void> _handleReportViolation() async {
    final plate = _plateController.text.trim();
    if (plate.isEmpty) return;

    // 1. Apri il Dialog e aspetta i dati (TicketData)
    final TicketData? ticketData = await showDialog<TicketData>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => IssueTicketDialog(
        plate: plate,
        sessionId: _activeSession?.id,
      ),
    );

    // Se null, l'utente ha annullato
    if (ticketData == null) return;

    setState(() => _isLoading = true);

    // 2. Chiama il servizio con tutti i dati
    final int statusCode = await ControllerService.reportViolation(
      plate: plate,
      reason: ticketData.reason,
      notes: ticketData.notes,
      image: ticketData.image,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;

      if (statusCode == 200 || statusCode == 201) {
        _plateController.clear();
        _message = null;
        _canIssueTicket = false; 
        _status = null;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text("Violation Reported!"),
                ]),
                Text("Reason: ${ticketData.reason}", style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Failed. Error: $statusCode"), backgroundColor: Colors.red),
        );
      }
    });
  }

  Widget _buildActiveSessionCard(ParkingSession session) {
    final startTime = session.startTime.toLocal();
    final duration = DateTime.now().difference(startTime);
    final formatter = DateFormat('MMM d, yyyy HH:mm');
    final durationHours = duration.inHours;
    final durationMinutes = duration.inMinutes % 60;

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

          // FIXED: Show only Plate, not Name
          _buildInfoRow("License Plate", session.vehiclePlate),
          _buildInfoRow(
            "Parking Lot",
            session.parkingLot?.name ?? "Unknown Parking",
          ),
          _buildInfoRow(
            "Parking Address",
            session.parkingLot?.address ?? "N/A",
          ),
          _buildInfoRow("Session ID", "#${session.id}"),

          const Divider(color: Colors.white38, height: 30),

          // Duration and Cost
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
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
