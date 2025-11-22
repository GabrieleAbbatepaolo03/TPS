import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_interface/STATE/payment_state.dart';
import 'add_card_sheet.dart';

const double kTicket3hPrice = 5.00;

class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pay = ref.watch(paymentProvider);
    final ticket = pay.activeTicket;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (!pay.hasMethod) const _MissingLikeBanner(),
          Card(
            elevation: 0,
            color: const Color(0xFFF2F2F7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                pay.hasMethod ? 'Payment method' : 'Add payment method',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: pay.method != null
                  ? Text('**** **** **** ${pay.method}')
                  : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (ctx) => const AddCardSheet(),
                );

                if (result is String && result.isNotEmpty) {
                  ref.read(paymentProvider.notifier).setPaymentMethod(result);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment method saved!')),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'One-Off Tickets',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: ticket?.isActive == true
                  ? const BorderSide(color: Colors.green, width: 2)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_filled,
                    color: Colors.blueAccent,
                    size: 30,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '3 Hour Parking Ticket',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'One-time payment for 3 hours of parking.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  if (ticket?.isActive == true)
                    const Chip(
                      label: Text('ACTIVE'),
                      backgroundColor: Colors.greenAccent,
                    )
                  else
                    FilledButton.icon(
                      onPressed: pay.hasMethod
                          ? () {
                              ref.read(paymentProvider.notifier).buyTicket3h();
                              ref
                                  .read(paymentProvider.notifier)
                                  .charge(kTicket3hPrice);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('3-Hour Ticket purchased!'),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.shopping_cart),
                      label: Text('€${kTicket3hPrice.toStringAsFixed(2)}'),
                    ),
                ],
              ),
            ),
          ),
          if (ticket?.isActive == true)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 5),
              child: Text(
                'Your 3-hour ticket is active. It will be used when you start parking and expires at ${ticket!.expiresAt.toLocal().toString().substring(11, 16)}.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          const SizedBox(height: 24),
          Text('Account Status', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _buildPreAuthCard(pay, ref, context),
        ],
      ),
    );
  }

  Widget _buildPreAuthCard(
    PaymentState pay,
    WidgetRef ref,
    BuildContext context,
  ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: pay.preAuthorized
            ? const BorderSide(color: Colors.blue, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  pay.preAuthorized ? Icons.lock_open : Icons.lock_outline,
                  color: pay.preAuthorized ? Colors.blue : Colors.grey,
                  size: 30,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Parking Pre-Authorization',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pay.preAuthorized
                            ? 'Your account is pre-authorized. Ready to park!'
                            : 'Pre-authorize your card to allow quick parking starts.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!pay.preAuthorized)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: pay.hasMethod
                        ? () async {
                            await ref
                                .read(paymentProvider.notifier)
                                .charge(1.00);
                            ref
                                .read(paymentProvider.notifier)
                                .setPreAuthorized(true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pre-Authorization Successful!'),
                              ),
                            );
                          }
                        : null,
                    child: const Text('Authorize Card'),
                  ),
                ),
              ),
            if (pay.lastCharge != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  'Last charge: €${pay.lastCharge!.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MissingLikeBanner extends StatelessWidget {
  const _MissingLikeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE6DAF5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFF7B1FA2)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your payment method is missing',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                SizedBox(height: 6),
                Text(
                  'Please add a payment method to enable all account features.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
