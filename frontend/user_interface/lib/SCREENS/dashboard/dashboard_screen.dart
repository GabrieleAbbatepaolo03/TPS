import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_interface/MAIN%20UTILS/page_title.dart';
import 'package:user_interface/MAIN%20UTILS/page_transition.dart';
import '../../MAIN UTILS/app_theme.dart';

import 'package:user_interface/SCREENS/dashboard/dashboard_pages/parking_history_page.dart';
import 'package:user_interface/SCREENS/dashboard/dashboard_pages/payments_history_page.dart';
import 'package:user_interface/SCREENS/dashboard/dashboard_pages/payments_method_page/payment_methods_page.dart';
import 'package:user_interface/SCREENS/dashboard/dashboard_pages/settings_page.dart';
import 'package:user_interface/SCREENS/dashboard/dashboard_pages/support_page.dart';
import 'package:user_interface/SCREENS/dashboard/dashboard_pages/my_vehicles_page.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

                // ===========================
                // Row 1
                // ===========================
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
                                padding: const EdgeInsets.only(
                                  right: 8.0,
                                  bottom: 8.0,
                                ),
                                child: _buildDashboardTile(
                                  context,
                                  icon: IconlyBold.time_circle,
                                  label: 'Parking History',
                                  // ✅ Pixel 5：地图更大 + 更居中一点
                                  overlay: const _NeonOverlay(
                                    assetPath: 'assets/illustrations/neon_map.png',
                                    alignment: Alignment.center,
                                    widthFactor: 1.6,
                                    heightFactor: 0.70,
                                    offset: Offset(0, 13),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      slideRoute(const ParkingHistoryPage()),
                                    );
                                  },
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
                                  padding: const EdgeInsets.only(
                                    left: 8.0,
                                    bottom: 8.0,
                                  ),
                                  child: _buildDashboardTile(
                                    context,
                                    icon: IconlyBold.wallet,
                                    label: 'Payments',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        slideRoute(const PaymentsHistoryPage()),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8.0,
                                    top: 8.0,
                                    bottom: 8.0,
                                  ),
                                  child: _buildDashboardTile(
                                    context,
                                    icon: IconlyBold.plus,
                                    label: 'Add Payment method',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        slideRoute(const PaymentMethodsPage()),
                                      );
                                    },
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

                // ===========================
                // Row 2
                // ===========================
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
                                padding: const EdgeInsets.only(
                                  right: 8.0,
                                  top: 8.0,
                                  bottom: 8.0,
                                ),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: _buildDashboardTile(
                                    context,
                                    icon: IconlyBold.setting,
                                    label: 'Settings',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        slideRoute(const SettingsPage()),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  right: 8.0,
                                  top: 8.0,
                                ),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: _buildDashboardTile(
                                    context,
                                    icon: IconlyBold.info_circle,
                                    label: 'Support',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        slideRoute(const SupportPage()),
                                      );
                                    },
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
                          padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                          child: _buildDashboardTile(
                            context,
                            icon: IconlyBold.activity,
                            label: 'My Vehicles',
                            // ✅ Pixel 5：车更大 + 更靠中间（避免贴底）
                            overlay: const _NeonOverlay(
                              assetPath: 'assets/illustrations/neon_car.png',
                              alignment: Alignment.center,
                              widthFactor: 0.80,
                              heightFactor: 0.62,
                              offset: Offset(0, 8),
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                slideRoute(const MyVehiclesPage()),
                              );
                            },
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
    Widget? overlay,
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              if (overlay != null) overlay,

              Padding(
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
            ],
          ),
        ),
      ),
    );
  }
}

/// ✅ 霓虹图片覆盖层：按 tile 尺寸比例缩放（Pixel 5 更稳定）
/// - widthFactor/heightFactor：相对 tile 的占比（0~1）
/// - alignment：放哪（topCenter/center/bottomCenter...）
/// - offset：微调位置（像素）
class _NeonOverlay extends StatelessWidget {
  final String assetPath;

  final double widthFactor;
  final double heightFactor;

  final Alignment alignment;
  final Offset offset;

  const _NeonOverlay({
    required this.assetPath,
    this.widthFactor = 0.95,
    this.heightFactor = 0.60,
    this.alignment = Alignment.center,
    this.offset = Offset.zero,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth * widthFactor;
          final h = c.maxHeight * heightFactor;

          return Align(
            alignment: alignment,
            child: Transform.translate(
              offset: offset,
              child: IgnorePointer(
                child: Container(
                  width: w,
                  height: h,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3CFFD7).withOpacity(0.30),
                        blurRadius: 30,
                        spreadRadius: 6,
                      ),
                      BoxShadow(
                        color: const Color(0xFF5B7CFF).withOpacity(0.16),
                        blurRadius: 45,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Image.asset(assetPath, fit: BoxFit.contain),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
