import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:user_interface/MAIN%20UTILS/app_theme.dart';
import 'package:user_interface/STATE/payment_state.dart';

class PaymentsHistoryPage extends ConsumerWidget {
  const PaymentsHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pay = ref.watch(paymentProvider);
    final history = pay.history;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Payment History',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              onPressed: () {
                ref.read(paymentProvider.notifier).clearHistory();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment history cleared.')),
                );
              },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Container(
        decoration: AppTheme.backgroundGradientDecoration,
        child: SafeArea(
          child: history.isEmpty
              ? _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final tx = history[index];
                    final timeStr =
                        DateFormat('dd MMM yyyy, HH:mm').format(tx.createdAt);

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.receipt_long,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.reason,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$timeStr • ${tx.methodLabel} • ${tx.status}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '€${tx.amount.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text
        (
           'No payment records yet.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 14),
        ),
      ),
    );
  }
}
