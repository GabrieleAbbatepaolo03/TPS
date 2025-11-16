import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:user_interface/MAIN%20UTILS/BOTTOM%20NAV%20BAR/bottom_navigation_bar.dart';
import 'package:user_interface/SCREENS/dashboard/dashboard_screen.dart';
import 'package:user_interface/SCREENS/home/home_screen.dart'; 
import 'package:user_interface/SCREENS/sessions/sessions_screen.dart'; 
import 'package:user_interface/SCREENS/profile/profile_screen.dart'; 

class RootPage extends StatefulWidget {

  final int initialIndex;

  const RootPage({
    super.key,
    this.initialIndex = 0, 
  });


  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _currentIndex = 0; 

  final List<Widget> _screens = [
    const HomeScreen(),
    const SessionsScreen(),
    const DashboardScreen(),
    const ProfileScreen(),
  ];

  final List<IconData> _navIcons = [
    IconlyLight.home,
    IconlyLight.ticket,
    IconlyLight.category,
    IconlyLight.profile,
  ];

  // --- MODIFICA: Imposta _currentIndex in initState ---
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }
  // --- FINE MODIFICA ---

  void _onItemSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: BottomNavBar(
          currentIndex: _currentIndex,
          onItemSelected: _onItemSelected,
          icons: _navIcons,
        ),
      ),
    );
  }
}