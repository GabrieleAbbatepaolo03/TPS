

class PaymentCard {
  final int id;
  final String cardNumber; 
  final bool isDefault;

  PaymentCard({
    required this.id,
    required this.cardNumber,
    this.isDefault = false,
  });

  factory PaymentCard.fromJson(Map<String, dynamic> json) {
    return PaymentCard(
      id: json['id'] as int,
      cardNumber: json['card_number'] as String? ?? 'XXXX',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  static List<PaymentCard> listFromJson(List<dynamic> jsonList) {
    return jsonList.map((item) => PaymentCard.fromJson(item as Map<String, dynamic>)).toList();
  }
}