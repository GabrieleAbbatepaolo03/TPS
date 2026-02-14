import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:officer_interface/MAIN%20UTILS/page_transition.dart';
import 'package:officer_interface/SCREENS/home/home_screen.dart';
import 'package:officer_interface/SCREENS/login/login_screen.dart';
import 'package:officer_interface/SERVICES/shift_service.dart';
import 'package:officer_interface/SERVICES/auth_service.dart';

class StartShiftScreen extends StatefulWidget {
  const StartShiftScreen({super.key});

  @override
  State<StartShiftScreen> createState() => _StartShiftScreenState();
}

class _StartShiftScreenState extends State<StartShiftScreen> {
  bool _loading = false;
  String? _error;
  List<ShiftInfo> _shiftHistory = [];
  bool _loadingHistory = false;
  ShiftInfo? _activeShift; // Add this
  bool _checkingActiveShift = true; // Add this

  @override
  void initState() {
    super.initState();
    _checkForActiveShift();
    _loadShiftHistory();
  }

  Future<void> _checkForActiveShift() async {
    setState(() => _checkingActiveShift = true);
    try {
      final current = await ShiftService.getCurrentShift();
      if (mounted) {
        setState(() {
          _activeShift = current;
          _checkingActiveShift = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _checkingActiveShift = false);
      }
    }
  }

  Future<void> _loadShiftHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final history = await ShiftService.getShiftHistory(limit: 10);
      if (mounted) {
        setState(() => _shiftHistory = history);
      }
    } catch (e) {
      // Silent fail for history
    } finally {
      if (mounted) {
        setState(() => _loadingHistory = false);
      }
    }
  }

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

  Future<void> _resumeShift() async {
    if (_activeShift == null) return;
    
    Navigator.of(context).pushReplacement(
      slideRoute(HomeScreen(
        shiftStartTime: _activeShift!.startTime,
        shiftId: _activeShift!.id,
      )),
    );
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
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
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [

                  Text(
                    "Welcome Back!",
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _activeShift != null
                        ? "You have an active shift running"
                        : "Press the button to start your shift",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 30),

                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_checkingActiveShift)
                    const SizedBox(
                      height: 56,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.greenAccent),
                      ),
                    )
                  else if (_activeShift != null)
                    ElevatedButton.icon(
                      onPressed: _resumeShift,
                      icon: const Icon(Icons.play_arrow, size: 24),
                      label: Text(
                        "Resume Active Shift",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: _loading ? null : _startShift,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.black),
                            )
                          : Text(
                              "Start Shift",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),

                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent Shifts",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (_loadingHistory)
                        const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: _buildShiftList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShiftList() {
    if (_shiftHistory.isEmpty && !_loadingHistory) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            "No shift history yet",
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        overscroll: false,
        physics: const ClampingScrollPhysics(),
      ),
      child: ListView.builder(
        physics: const ClampingScrollPhysics(),
        itemCount: _shiftHistory.length,
        itemBuilder: (context, index) {
          final cardinalIndex = _shiftHistory.length - index;
          return _buildShiftCard(_shiftHistory[index], cardinalIndex);
        },
      ),
    );
  }

  Widget _buildShiftCard(ShiftInfo shift, int displayId) {
    final isOpen = shift.status == 'OPEN';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isOpen ? Colors.greenAccent.withOpacity(0.3) : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Status Indicator
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isOpen ? Colors.greenAccent : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Shift Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Shift #$displayId",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(shift.startTime),
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Duration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isOpen 
                  ? Colors.greenAccent.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              shift.formattedDuration,
              style: GoogleFonts.poppins(
                color: isOpen ? Colors.greenAccent : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final shiftDate = DateTime(date.year, date.month, date.day);

    String day;
    if (shiftDate == today) {
      day = 'Today';
    } else if (shiftDate == yesterday) {
      day = 'Yesterday';
    } else {
      day = '${date.day}/${date.month}/${date.year}';
    }

    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$day at $time';
  }
}
