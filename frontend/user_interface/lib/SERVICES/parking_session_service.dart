import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:user_interface/MODELS/parking_session.dart';
import 'package:user_interface/SERVICES/AUTHETNTICATION%20HELPERS/authenticated_http_client.dart';

// URL corretto
const String _baseUrl = 'http://127.0.0.1:8000/api/sessions/';

class ParkingSessionService {
  final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient();

  Future<List<ParkingSession>> fetchSessions({bool? active}) async {
    // ... (il codice fetchSessions rimane uguale a prima)
    String urlString = _baseUrl;
    if (active != null) {
      urlString += '?active=${active.toString()}';
    }
    final url = Uri.parse(urlString);
    try {
      final response = await _httpClient.get(url);
      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        List<dynamic> jsonList;
        if (decodedBody is Map<String, dynamic> &&
            decodedBody.containsKey('results')) {
          jsonList = decodedBody['results'] as List<dynamic>;
        } else if (decodedBody is List) {
          jsonList = decodedBody;
        } else {
          jsonList = [];
        }
        return jsonList
            .map((json) => ParkingSession.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Errore fetchSessions: $e');
    }
    return [];
  }

  Future<ParkingSession?> startSession({
    required int vehicleId,
    required int parkingLotId,
    required int durationMinutes,
    required double prepaidCost, 
  }) async {
    final url = Uri.parse(_baseUrl);
    
    // 🚨 FIX: Arrotondiamo il costo a 2 decimali per evitare errori 400 lato server
    final double roundedCost = double.parse(prepaidCost.toStringAsFixed(2));

    try {
      final response = await _httpClient.post(
        url,
        body: {
          'vehicle_id': vehicleId,
          'parking_lot_id': parkingLotId,
          'duration_purchased_minutes': durationMinutes,
          'prepaid_cost': roundedCost, // Inviamo il valore arrotondato
        },
      );

      if (response.statusCode == 201) {
        return ParkingSession.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      }
      
      // 🚨 DEBUG: Leggi questo messaggio nella console di Flutter se fallisce ancora!
      print('❌ ERRORE 400 DETTAGLIO: ${response.body}');
      
    } catch (e) {
      print('Errore startSession network: $e');
    }
    return null;
  }

  Future<ParkingSession?> endSession(int sessionId) async {
    // ... (codice endSession rimane uguale)
    final url = Uri.parse('$_baseUrl$sessionId/end_session/');
    try {
      final response = await _httpClient.post(url);
      if (response.statusCode == 200) {
        return ParkingSession.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      }
      print('Errore endSession status: ${response.statusCode}\nBody: ${response.body}');
    } catch (e) {
      print('Errore endSession network: $e');
    }
    return null;
  }
}