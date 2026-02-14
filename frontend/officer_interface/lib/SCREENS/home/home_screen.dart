import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:officer_interface/MAIN%20UTILS/issue_ticket_dialog.dart';
import 'package:officer_interface/MODELS/parking_session.dart';
import 'package:officer_interface/SCREENS/home/utils/plate_search_section.dart';
import 'package:officer_interface/SCREENS/home/utils/status_cards.dart';
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
      setState(() => _message = "Error during search: $e");
    } finally {
      setState(() => _isLoading = false);
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
        source: ImageSource.camera,
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
      setState(() => _message = "OCR error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEndShift() async {
    if (widget.shiftId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 2, 11, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("End Shift?",
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
          content: Text("Are you sure you want to end your current shift?",
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: Text("End Shift", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
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

  Future<void> _handleReportViolation() async {
    final plate = _plateController.text.trim();
    if (plate.isEmpty) return;

    final TicketData? ticketData = await showDialog<TicketData>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => IssueTicketDialog(
        plate: plate,
        sessionId: _activeSession?.id,
      ),
    );

    if (ticketData == null) return;

    setState(() => _isLoading = true);

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
          const SnackBar(content: Text("Violation Reported!"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed. Error: $statusCode"), backgroundColor: Colors.red),
        );
      }
    });
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
            Text("Dashboard",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20)),
            if (hasShift)
              Text("Shift: ${_formatElapsed(_elapsed)}",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.greenAccent, fontWeight: FontWeight.w500)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 2, 11, 60), Color.fromARGB(255, 52, 12, 108)],
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
                  Text("Session Verification",
                      style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 30),

                  PlateSearchSection(
                    controller: _plateController,
                    isLoading: _isLoading,
                    onScan: _scanPlate,
                    onSearch: _searchPlate,
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

  Widget _buildResultsArea() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_status == 'active' && _activeSession != null) {
      return ActiveSessionCard(session: _activeSession!);
    }
    
    if (_status == 'grace_period' && _activeSession != null) {
      return GracePeriodCard(session: _activeSession!, message: _message);
    }
    
    if (_status == 'not_found') {
      return const NotFoundCard();
    }
    
    if (_canIssueTicket) {
      return ViolationCard(
        message: _message,
        onIssueTicket: _handleReportViolation,
      );
    }

    if (_message != null) {
      return Text(_message!, style: const TextStyle(color: Colors.white));
    }

    return const SizedBox.shrink();
  }
}