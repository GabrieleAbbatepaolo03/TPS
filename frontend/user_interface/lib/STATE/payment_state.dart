import 'package:flutter_riverpod/flutter_riverpod.dart';

class OneOffTicket {
  final DateTime expiresAt;
  const OneOffTicket({required this.expiresAt});
  bool get isActive => expiresAt.isAfter(DateTime.now());
}

/// Payment state for the user app.
///
/// IMPORTANT: we keep the existing behaviour intact (card last4, one-off ticket,
/// pre-authorization, simulated charge). We only add a "default payment method"
/// concept used by the parking Start/Stop workflow.
class PaymentState {
  /// Legacy field: stores only the last 4 digits (e.g., "1234").
  final String? method;

  /// New: default payment method type for the parking workflow.
  /// Values: 'card' | 'apple_pay' | 'google_pay'
  final String? defaultMethodType;

  final OneOffTicket? activeTicket;
  final double? lastCharge;
  final bool preAuthorized;

  const PaymentState({
    this.method,
    this.defaultMethodType,
    this.activeTicket,
    this.lastCharge,
    this.preAuthorized = false,
  });

  bool get hasMethod => method != null && method!.isNotEmpty;

  bool get hasDefaultMethod =>
      defaultMethodType != null && defaultMethodType!.isNotEmpty;

  /// Label used in confirmation dialogs.
  String get defaultMethodLabel {
    switch (defaultMethodType) {
      case 'apple_pay':
        return 'Apple Pay';
      case 'google_pay':
        return 'Google Pay';
      case 'card':
        return hasMethod ? 'Card •••• $method' : 'Card';
      default:
        return hasMethod ? 'Card •••• $method' : 'Not selected';
    }
  }

  PaymentState copyWith({
    String? method,
    String? defaultMethodType,
    OneOffTicket? activeTicket,
    double? lastCharge,
    bool? preAuthorized,
    bool clearDefaultMethodType = false,
  }) {
    return PaymentState(
      method: method ?? this.method,
      defaultMethodType: clearDefaultMethodType
          ? null
          : (defaultMethodType ?? this.defaultMethodType),
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

  /// Takes any card number string and stores only the last 4 digits.
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

  /// New: set default method type for parking flow.
  void setDefaultMethodType(String type) {
    state = state.copyWith(defaultMethodType: type);
  }

  void clearDefaultMethodType() {
    state = state.copyWith(clearDefaultMethodType: true);
  }

  void buyTicket3h() {
    final expiresAt = DateTime.now().add(const Duration(hours: 3));
    state = state.copyWith(activeTicket: OneOffTicket(expiresAt: expiresAt));
  }

  /// Simulated charge. (No real payment integration.)
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

final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>(
  (ref) => PaymentNotifier(),
);
