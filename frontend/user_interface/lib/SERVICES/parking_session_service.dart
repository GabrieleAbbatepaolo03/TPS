import 'dart:convert';
import 'package:user_interface/MODELS/parking_session.dart';
import 'package:user_interface/SERVICES/AUTHETNTICATION HELPERS/authenticated_http_client.dart';

const String _baseUrl = 'http://127.0.0.1:8000/api/sessions/';

class ParkingSessionService {
  final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient();

  Future<List<ParkingSession>> fetchSessions({bool onlyActive = false}) async {
    final url = Uri.parse(onlyActive ? '$_baseUrl?active=true' : _baseUrl);
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
            .map(
              (json) => ParkingSession.fromJson(json as Map<String, dynamic>),
            )
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
  }) async {
    final url = Uri.parse(_baseUrl);
    try {
      final response = await _httpClient.post(
        url,
        body: {
          'vehicle_id': vehicleId.toString(),
          'parking_lot_id': parkingLotId.toString(),
        },
      );
      if (response.statusCode == 201) {
        return ParkingSession.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      }
      print(
        'Errore startSession status: ${response.statusCode}\nBody: ${response.body}',
      );
    } catch (e) {
      print('Errore startSession network: $e');
    }
    return null;
  }

  Future<ParkingSession?> endSession(int sessionId) async {
    final url = Uri.parse('$_baseUrl$sessionId/end_session/');
    try {
      final response = await _httpClient.post(url);
      if (response.statusCode == 200) {
        return ParkingSession.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      }
      print(
        'Errore endSession status: ${response.statusCode}\nBody: ${response.body}',
      );
    } catch (e) {
      print('Errore endSession network: $e');
    }
    return null;
  }
}
