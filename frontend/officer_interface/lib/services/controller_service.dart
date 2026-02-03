import 'dart:convert';
import 'package:officer_interface/MODELS/parking_session.dart';
import 'package:officer_interface/services/authentication%20helpers/authenticated%20_http_client.dart';

class ControllerService {
  static final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient();
  // static const String _apiRoot = 'http://127.0.0.1:8000/api';
  static const String _apiRoot = 'http://10.0.2.2:8000/api';

  // Calls: api/sessions/search_by_plate/?plate=XXXXXX
  static Future<ParkingSession?> searchActiveSessionByPlate(
    String plate,
  ) async {
    final url = Uri.parse('$_apiRoot/sessions/search_by_plate/?plate=$plate');

    try {
      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ParkingSession.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        // No active session or vehicle not found
        return null;
      } else {
        throw Exception('Failed to search session: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network or processing error: $e');
    }
  }
}
