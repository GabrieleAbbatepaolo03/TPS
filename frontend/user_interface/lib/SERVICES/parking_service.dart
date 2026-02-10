import 'dart:convert';
import '../MODELS/parking.dart';
import 'AUTHETNTICATION HELPERS/authenticated_http_client.dart';
import 'CONFIG/api.dart';

final String _baseUrl = '${Api.baseUrl}/parkings/';

class ParkingApiService {
  final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient();

  Future<List<Parking>> fetchLiteParkings({String? city}) async {
    try {
      String url = '${_baseUrl}search_map/';
      if (city != null && city.isNotEmpty) {
        url += '?city=$city';
      }
      
      final response = await _httpClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList
            .map((json) => Parking.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load map data');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Parking> fetchParkingDetails(int id) async {
    try {
      final response = await _httpClient.get(Uri.parse('$_baseUrl$id/'));
      
      if (response.statusCode == 200) {
        return Parking.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load parking details');
      }
    } catch (e) {
      rethrow;
    }
  }

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
          'Failed to load parking lots',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
