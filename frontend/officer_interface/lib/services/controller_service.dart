import 'dart:convert';
import 'package:officer_interface/services/authentication%20helpers/authenticated%20_http_client.dart';

class ControllerService {
  static final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient();
  static const String _apiRoot = 'http://127.0.0.1:8000/api';
  // static const String _apiRoot = 'http://10.0.2.2:8000/api';

  // Calls: api/sessions/search_by_plate/?plate=XXXXXX
  static Future<Map<String, dynamic>?> searchActiveSessionByPlate(
    String plate,
  ) async {
    final url = Uri.parse('$_apiRoot/sessions/search_by_plate/?plate=$plate');

    try {
      final response = await _httpClient.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception(
          'Permission denied: You are not authorized for this city.',
        );
      } else if (response.statusCode == 404) {
        return {'status': 'not_found'};
      } else {
        return null;
      }
    } catch (e) {
      print('Network error: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<int> reportViolation(String plate) async {
    final url = Uri.parse('$_apiRoot/users/violations/report/');
    try {
      final response = await _httpClient.post(url, body: {'plate': plate});

      return response.statusCode;
    } catch (e) {
      print('Report error: $e');
      return 500;
    }
  }
}
