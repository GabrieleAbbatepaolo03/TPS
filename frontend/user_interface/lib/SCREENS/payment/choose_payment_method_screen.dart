import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'dart:io';
import 'package:user_interface/STATE/payment_state.dart';
import 'package:user_interface/SCREENS/dashboard/dashboard_pages/payments_method_page/payment_methods_page.dart';
import 'package:user_interface/MAIN UTILS/app_theme.dart';

class ChoosePaymentMethodScreen extends ConsumerStatefulWidget {
  final double? amount;
  final String? title;

  const ChoosePaymentMethodScreen({super.key, this.amount, this.title});

  @override
  ConsumerState<ChoosePaymentMethodScreen> createState() =>
      _ChoosePaymentMethodScreenState();
}

class _ChoosePaymentMethodScreenState
    extends ConsumerState<ChoosePaymentMethodScreen> {
  String? _selectedType; 

  @override
  void initState() {
    super.initState();
    final pay = ref.read(paymentProvider);
    _selectedType = pay.defaultMethodType ?? (pay.hasMethod ? 'card' : null);
  }

  void _select(String type) {
    setState(() => _selectedType = type);
  }

  Future<bool> _openManageCards() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaymentMethodsPage()),
    );

    if (!mounted) return false;

    // Force rebuild so subtitle updates
    setState(() {});

    return result == true;
  }

  Future<void> _confirm() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method.')),
      );
      return;
    }

    // Always read latest state
    var pay = ref.read(paymentProvider);

    // ✅ If card selected but no default card saved, guide user to Manage cards first
    if (_selectedType == 'card' && !pay.hasMethod) {
      // Auto-open Manage cards to let user choose/set default card
      await _openManageCards();

      // Re-check after returning
      pay = ref.read(paymentProvider);

      if (!pay.hasMethod) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No card found. Please add a card first.'),
          ),
        );
        return;
      }

      // Optional: auto-select card after user sets default
      if (mounted) setState(() => _selectedType = 'card');
    }

    ref.read(paymentProvider.notifier).setDefaultMethodType(_selectedType!);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final pay = ref.watch(paymentProvider);

    final title = widget.title ?? 'Choose payment method';
    final amountText = widget.amount != null
        ? 'Amount: €${widget.amount!.toStringAsFixed(2)}'
        : 'Set your default payment method';

    final double topOffset = MediaQuery.of(context).padding.top + kToolbarHeight + 16;

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(title, style: GoogleFonts.poppins()),
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.backgroundGradientDecoration,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, topOffset, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  amountText,
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                if (Platform.isIOS) ...[
                  _MethodTile(
                    title: 'Apple Pay',
                    subtitle: 'Fast • Secure • No card details stored',
                    icon: IconlyBold.wallet,
                    selected: _selectedType == 'apple_pay',
                    onTap: () => _select('apple_pay'),
                  ),
                  const SizedBox(height: 10),
                ],

                if (Platform.isAndroid) ...[
                  _MethodTile(
                    title: 'Google Pay',
                    subtitle: 'Fast • Secure • No card details stored',
                    icon: IconlyBold.wallet,
                    selected: _selectedType == 'google_pay', 
                    onTap: () => _select('google_pay'),
                  ),
                  const SizedBox(height: 10),
                ],
                _MethodTile(
                  title: 'Credit / Debit Card',
                  subtitle: pay.hasMethod
                      ? 'Using saved card •••• ${pay.method}'
                      : 'No saved card. Tap “Manage cards” to add one.',
                  icon: Icons.credit_card_rounded,
                  selected: _selectedType == 'card',
                  onTap: () => _select('card'),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _openManageCards,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Manage cards', style: GoogleFonts.poppins()),
                ),
                const Spacer(),
                Text(
                  'Note: Payments are delegated to third-party providers. '
                  'We do not store full card details in the app.',
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      widget.amount != null
                          ? 'Pay €${widget.amount!.toStringAsFixed(2)}'
                          : 'Confirm',
                      style: GoogleFonts.poppins(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.greenAccent : Colors.white12,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0,4)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.greenAccent),
          ],
        ),
      ),
    );
  }
}
