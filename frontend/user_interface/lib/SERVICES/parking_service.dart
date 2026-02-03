// [FULL REPLACEMENT] frontend/user_interface/lib/SERVICES/parking_service.dart

import 'dart:convert';
import '../MODELS/parking.dart';
import 'AUTHETNTICATION HELPERS/authenticated_http_client.dart';
//final String _baseUrl = 'http://127.0.0.1:8000/api/parkings/';
final String _baseUrl = 'http://10.0.2.2:8000/api/parkings/';

class ParkingApiService {
  final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient();

  

  Future<List<Parking>> fetchAllParkingLots() async {
    try {
      final response = await _httpClient.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final dynamic decodedBody = json.decode(response.body);
        List<dynamic> jsonList;

        if (decodedBody is List) {
          jsonList = decodedBody;
        } else if (decodedBody is Map<String, dynamic> &&
            decodedBody.containsKey('results')) {
          jsonList = decodedBody['results'] as List<dynamic>;
        } else if (decodedBody is Map<String, dynamic> && decodedBody.isEmpty) {
          jsonList = [];
        } else {
          jsonList = [];
        }

        return jsonList
            .map((json) => Parking.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Failed to load parking lots. Status: ${response.statusCode}. Body: ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
