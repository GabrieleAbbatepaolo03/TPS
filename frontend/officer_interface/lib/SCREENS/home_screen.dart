import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:officer_interface/MODELS/parking_session.dart';
import 'package:officer_interface/services/controller_service.dart';

// ✅ Shift
import 'package:officer_interface/services/shift_service.dart';
import 'package:officer_interface/SCREENS/start_shift_screen.dart';

// ✅ Plate OCR
import 'package:officer_interface/services/plate_ocr_service.dart';

class HomeScreen extends StatefulWidget {
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
  final ImagePicker _picker = ImagePicker();

  ParkingSession? _activeSession;
  String? _message;
  bool _isLoading = false;

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

  // ===============================
  // 🔍 手动查询
  // ===============================
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
      final session =
          await ControllerService.searchActiveSessionByPlate(plate);

      setState(() {
        _activeSession = session;
        if (session == null) {
          _message =
              "Vehicle with plate '$plate' has NO active parking session.";
        }
      });
    } catch (e) {
      setState(() {
        _message = "Error during search.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ===============================
  // 📷 OCR 拍照识别
  // ===============================
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
      final plate =
          (result['plate'] ?? '').toString().trim().toUpperCase();

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _scanPlate,
                        icon: const Icon(Icons.photo_camera),
                        label: const Text("Scan"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amberAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.all(20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _searchPlate,
                        icon: const Icon(Icons.search),
                        label: Text(_isLoading ? "Searching..." : "Check"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.all(20),
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
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 20),
      decoration: InputDecoration(
        hintText: "E.g. AB123CD",
        hintStyle: GoogleFonts.poppins(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
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
      return Text(
        "ACTIVE SESSION FOUND",
        style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 20),
      );
    }

    if (_message != null) {
      return Text(
        _message!,
        style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 18),
      );
    }

    return const SizedBox.shrink();
  }
}
