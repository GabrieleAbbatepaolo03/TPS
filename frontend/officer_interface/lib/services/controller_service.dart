import 'dart:convert';
import 'dart:io';
import 'package:officer_interface/SERVICES/CONFIG/api.dart';
import 'package:officer_interface/SERVICES/authentication%20helpers/authenticated%20_http_client.dart';

class ControllerService {
  static final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient();
  static const String _apiRoot = Api.baseUrl;

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
      throw Exception('Network error: $e');
    }
  }

  static Future<int> reportViolation({
    required String plate, 
    required String reason, 
    required String notes, 
    File? image
  }) async {
    final url = Uri.parse('$_apiRoot/users/violations/report/');
    
    try {
      final response = await _httpClient.postMultipart(
        url,
        fields: {
          'plate': plate,
          'reason': reason,
          'notes': notes,
        },
        imageFile: image,
        imageFieldName: 'image', 
      );

      return response.statusCode;
    } catch (e) {
      return 500;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchViolationTypes() async {
    final url = Uri.parse('$_apiRoot/users/violations/types/'); 
    
    try {
      final response = await _httpClient.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      rethrow;
    }

    return [
      {"name": "General Parking Violation", "amount": 50.0},
    ];
  }
}
