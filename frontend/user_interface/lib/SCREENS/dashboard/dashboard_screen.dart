import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_interface/MAIN UTILS/page_title.dart';
import 'package:user_interface/MAIN UTILS/page_transition.dart';
import 'package:user_interface/SCREENS/payment/payment_screen.dart';
import 'package:user_interface/SCREENS/payment/add_card_sheet.dart';
import 'package:user_interface/STATE/payment_state.dart';
import '../../MAIN UTILS/app_theme.dart';
import 'package:user_interface/SCREENS/profile/my_vehicles_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _navigateToPaymentSettings(BuildContext context) {
    Navigator.of(context).push(slideRoute(const PaymentScreen()));
  }

  void _navigateToMyVehicles(BuildContext context) {
    Navigator.of(context).push(slideRoute(const MyVehiclesScreen()));
  }

  Future<void> _showAddCardModal(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => const AddCardSheet(),
    );

    if (!context.mounted) return;

    if (result != null && result.isNotEmpty) {
      ref.read(paymentProvider.notifier).setPaymentMethod(result);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment method saved!')));
    }
  }

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
                                  padding: const EdgeInsets.only(
                                    left: 8.0,
                                    bottom: 8.0,
                                  ),
                                  child: _buildDashboardTile(
                                    context,
                                    icon: IconlyBold.wallet,
                                    label: 'Payments',
                                    onTap: () =>
                                        _navigateToPaymentSettings(context),
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
                                    onTap: () =>
                                        _showAddCardModal(context, ref),
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
                                    onTap: () {},
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
                          padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                          child: _buildDashboardTile(
                            context,
                            icon: IconlyBold.activity,
                            label: 'My Vehicles',
                            onTap: () => _navigateToMyVehicles(context),
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
