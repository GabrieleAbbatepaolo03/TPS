import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';

import 'package:user_interface/MAIN%20UTILS/app_theme.dart';
import 'package:user_interface/MODELS/payment_card.dart';
import 'package:user_interface/SCREENS/dashboard/dashboard_pages/payments_method_page/utils/add_payment_card_dialog.dart';
import 'package:user_interface/SCREENS/dashboard/dashboard_pages/payments_method_page/utils/card_tile.dart';
import 'package:user_interface/SERVICES/payment_service.dart';
import 'package:user_interface/STATE/payment_state.dart';

class PaymentMethodsPage extends ConsumerStatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  ConsumerState<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends ConsumerState<PaymentMethodsPage> {
  final PaymentService _paymentService = PaymentService();
  late Future<List<PaymentCard>> _cardsFuture;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  void _loadCards() {
    setState(() {
      _cardsFuture = _paymentService.fetchMyCards();
    });
  }

  Future<void> _showAddCardDialog() async {
    final newCard = await showAddPaymentCardDialog(context);
    if (newCard != null && mounted) {
      _loadCards();
    }
  }

  void _setAsDefaultCard(PaymentCard card) {
    // Save last4 locally for the whole app (ChoosePaymentMethod will read this)
    ref.read(paymentProvider.notifier).setPaymentMethod(card.cardNumber);
    ref.read(paymentProvider.notifier).setDefaultMethodType('card');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Default card set: •••• ${card.cardNumber}')),
    );

    // Return true so previous page can refresh
    Navigator.pop(context, true);
  }

  Future<void> _handleDeleteCard(PaymentCard card) async {
    final bool? didConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 20, 30, 50),
        title: Text('Delete Card?', style: GoogleFonts.poppins(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete card ****${card.cardNumber}?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white70)),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.redAccent)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (didConfirm != true) return;

    try {
      await _paymentService.deleteCard(card.id);

      // If deleted card was default, clear local default
      final pay = ref.read(paymentProvider);
      if (pay.method == card.cardNumber) {
        ref.read(paymentProvider.notifier).save('');
        if (pay.defaultMethodType == 'card') {
          ref.read(paymentProvider.notifier).clearDefaultMethodType();
        }
      }

      _loadCards();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Card ****${card.cardNumber} deleted successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting card: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pay = ref.watch(paymentProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Container(
        height: screenHeight,
        decoration: AppTheme.backgroundGradientDecoration,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  'Payment Methods',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(IconlyLight.plus, color: Colors.white, size: 20),
                    label: Text(
                      'Add New Card',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                    ),
                    onPressed: _showAddCardDialog,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.white54, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _buildCardsList(pay),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardsList(PaymentState pay) {
    return FutureBuilder<List<PaymentCard>>(
      future: _cardsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: CircularProgressIndicator(color: Colors.white24),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load cards: ${snapshot.error}',
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                'You currently have no payment cards.',
                style: GoogleFonts.poppins(color: Colors.white54),
              ),
            ),
          );
        }

        final cards = snapshot.data!;
        return ListView.builder(
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            final isDefault = pay.method == card.cardNumber;

            return CardTile(
              card: card,
              isDefault: isDefault,
              onSelect: () => _setAsDefaultCard(card),
              onDelete: () => _handleDeleteCard(card),
            );
          },
        );
      },
    );
  }
}
