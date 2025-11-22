import 'package:flutter_riverpod/flutter_riverpod.dart';

class OneOffTicket {
  final DateTime expiresAt;
  const OneOffTicket({required this.expiresAt});
  bool get isActive => expiresAt.isAfter(DateTime.now());
}

class PaymentState {
  final String? method;
  final OneOffTicket? activeTicket;
  final double? lastCharge;

  final bool preAuthorized;

  const PaymentState({
    this.method,
    this.activeTicket,
    this.lastCharge,
    this.preAuthorized = false,
  });

  bool get hasMethod => method != null && method!.isNotEmpty;

  PaymentState copyWith({
    String? method,
    OneOffTicket? activeTicket,
    double? lastCharge,
    bool? preAuthorized,
  }) {
    return PaymentState(
      method: method ?? this.method,
      activeTicket: activeTicket ?? this.activeTicket,
      lastCharge: lastCharge ?? this.lastCharge,
      preAuthorized: preAuthorized ?? this.preAuthorized,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier() : super(const PaymentState());

  void save(String method) {
    state = state.copyWith(method: method);
  }

  void setPaymentMethod(String number) {
    final last4 = number
        .replaceAll(' ', '')
        .split('')
        .reversed
        .take(4)
        .toList()
        .reversed
        .join();
    state = state.copyWith(method: last4);
  }

  void buyTicket3h() {
    final expiresAt = DateTime.now().add(const Duration(hours: 3));
    state = state.copyWith(activeTicket: OneOffTicket(expiresAt: expiresAt));
  }

  Future<void> charge(double amount) async {
    state = state.copyWith(lastCharge: amount);
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void setPreAuthorized(bool value) {
    state = state.copyWith(preAuthorized: value);
  }

  void resetPreAuthorization() {
    state = state.copyWith(preAuthorized: false);
  }
}

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((
  ref,
) {
  return PaymentNotifier();
});
