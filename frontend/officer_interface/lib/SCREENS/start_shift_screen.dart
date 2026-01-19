import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:officer_interface/MAIN%20UTILS/page_transition.dart';
import 'package:officer_interface/SCREENS/home_screen.dart';
import 'package:officer_interface/services/shift_service.dart';

class StartShiftScreen extends StatefulWidget {
  const StartShiftScreen({super.key});

  @override
  State<StartShiftScreen> createState() => _StartShiftScreenState();
}

class _StartShiftScreenState extends State<StartShiftScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _startShift() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final shift = await ShiftService.startShift();
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        slideRoute(HomeScreen(shiftStartTime: shift.startTime, shiftId: shift.id)),
      );
    } catch (e) {
      setState(() => _error = "Failed to start shift. Please try again.");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // 可选：进来先查有没有已开启的 shift，有就直接进 Home
    _resumeIfActive();
  }

  Future<void> _resumeIfActive() async {
    try {
      final current = await ShiftService.getCurrentShift();
      if (current != null && mounted) {
        Navigator.of(context).pushReplacement(
          slideRoute(HomeScreen(shiftStartTime: current.startTime, shiftId: current.id)),
        );
      }
    } catch (_) {
      // 不阻断 UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color.fromARGB(255, 52, 12, 108),
              Color.fromARGB(255, 2, 11, 60),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Start Shift",
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Press the button below to begin your duty shift.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 30),

                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    const SizedBox(height: 12),
                  ],

                  ElevatedButton(
                    onPressed: _loading ? null : _startShift,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.black),
                          )
                        : const Text("Start Shift", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
