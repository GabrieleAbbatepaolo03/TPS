import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconly/iconly.dart';
import 'package:user_interface/MAIN%20UTILS/BOTTOM%20NAV%20BAR/bottom_navigation_bar.dart';
import 'package:user_interface/SCREENS/dashboard/dashboard_screen.dart';
import 'package:user_interface/SCREENS/home/home_screen.dart';
import 'package:user_interface/SCREENS/sessions/sessions_screen.dart';
import 'package:user_interface/SCREENS/profile/profile_screen.dart';
import 'package:user_interface/main.dart';

class RootPage extends ConsumerStatefulWidget {
  final int initialIndex;

  const RootPage({super.key, this.initialIndex = 0});

  @override
  ConsumerState<RootPage> createState() => _RootPageState();
}

class _RootPageState extends ConsumerState<RootPage> {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bottomNavIndexProvider.notifier).state = widget.initialIndex;
    });
  }

  void _onItemSelected(int index) {
    ref.read(bottomNavIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: BottomNavBar(
          currentIndex: currentIndex,
          onItemSelected: _onItemSelected,
          icons: _navIcons,
        ),
      ),
    );
  }
}
