import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:user_interface/MODELS/payment_card.dart';
import 'package:user_interface/SERVICES/AUTHETNTICATION%20HELPERS/authenticated_http_client.dart'; 

const String _baseUrl = 'http://127.0.0.1:8000/api/payments/cards/'; 

class PaymentService {
  final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient();

  Future<List<PaymentCard>> fetchMyCards() async {
    final Uri uri = Uri.parse(_baseUrl);
    try {
      final http.Response response = await _httpClient.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return PaymentCard.listFromJson(jsonList);
      } else if (response.statusCode == 404 || response.statusCode == 204) {
        return []; 
      } else {
        throw Exception('Failed to load payment cards: ${response.statusCode}');
      }
    } catch (e) {
      return []; 
    }
  }

  Future<PaymentCard> addCard({
    required String cardNumber,
  }) async {
    final Uri uri = Uri.parse(_baseUrl);
    final http.Response response = await _httpClient.post(
      uri,
      body: {
        'card_number': cardNumber, 
      },
    );

    if (response.statusCode == 201) {
      return PaymentCard.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add card: ${response.body}');
    }
  }

  Future<void> deleteCard(int cardId) async {
    final Uri uri = Uri.parse('$_baseUrl$cardId/');
    final http.Response response = await _httpClient.delete(uri);

    if (response.statusCode != 204) {
      throw Exception('Failed to delete card: ${response.body}');
    }
  }
}