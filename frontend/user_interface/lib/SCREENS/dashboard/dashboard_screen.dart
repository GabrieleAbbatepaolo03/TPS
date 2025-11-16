import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:user_interface/MAIN%20UTILS/page_title.dart';
import '../../MAIN UTILS/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppTheme.backgroundGradientDecoration,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageTitle(title: 'Dashboard'),
                const SizedBox(height: 30),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: AspectRatio(
                        aspectRatio: 0.66, 
                        child: Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 0.66,
                              child: Padding(
                                padding: const EdgeInsets.only(right:8.0, bottom: 8.0),
                                child: _buildDashboardTile(
                                  context,
                                  icon: IconlyBold.time_circle,
                                  label: 'Parking History',
                                  onTap: () {},
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: AspectRatio(
                        aspectRatio: 0.33,
                        child: Column(
                          children: [
                            Expanded(
                              flex: 1,
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Padding(
                                  padding: const EdgeInsets.only(left:8.0, bottom:8.0),
                                  child: _buildDashboardTile(
                                    context,
                                    icon: IconlyBold.wallet,
                                    label: 'Payments',
                                    onTap: () {},
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Padding(
                                  padding: const EdgeInsets.only(left:8.0, top: 8.0, bottom:8.0),
                                  child: _buildDashboardTile(
                                    context,
                                    icon: IconlyBold.plus,
                                    label: 'Add Payment method',
                                    onTap: () {},
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: AspectRatio(
                        aspectRatio: 0.5, 
                        child: Column(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.only(right:8.0, top: 8.0, bottom:8.0),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: _buildDashboardTile(
                                    context,
                                    icon: IconlyBold.setting,
                                    label: 'Settings',
                                    onTap: () {},
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.only(right:8.0, top: 8.0),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: _buildDashboardTile(
                                    context,
                                    icon: IconlyBold.info_circle,
                                    label: 'Support',
                                    onTap: () {},
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: AspectRatio(
                        aspectRatio: 1, 
                        child: Padding(
                          padding: const EdgeInsets.only(left:8.0, top: 8.0),
                          child: _buildDashboardTile(
                            context,
                            icon: IconlyBold.activity,
                            label: 'My Vehicles',
                            onTap: () {},
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const Spacer(),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}