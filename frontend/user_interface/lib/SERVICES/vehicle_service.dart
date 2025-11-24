import 'dart:convert';
import 'package:user_interface/MODELS/vehicle.dart';
import 'package:user_interface/SERVICES/AUTHETNTICATION%20HELPERS/authenticated_http_client.dart';

const String _baseUrl = 'http://127.0.0.1:8000/api/vehicles/';

class VehicleService {
  final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient();

  Future<List<Vehicle>> fetchMyVehicles() async {
    final url = Uri.parse(_baseUrl);
    try {
      final response = await _httpClient.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return Vehicle.listFromJson(jsonList);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<Vehicle?> addVehicle({
    required String plate,
    required String name,
    bool isFavorite = false,
  }) async {
    final url = Uri.parse(_baseUrl);
    try {
      final response = await _httpClient.post(
        url,
        // 🚨 CORREZIONE: Passa direttamente la Map, NON json.encode(...)
        // Il client HTTP farà la codifica una sola volta.
        body: {
          'plate': plate,
          'name': name,
          'is_favorite': isFavorite, 
        },
      );
      if (response.statusCode == 201) {
        return Vehicle.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> toggleFavorite({
    required int vehicleId,
    required bool isFavorite,
  }) async {
    final url = Uri.parse('$_baseUrl$vehicleId/set_favorite/');
    
    final body = {'is_favorite': isFavorite}; 
    
    final response = await _httpClient.patch(
      url, 
      body: body,
    );
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update favorite status: ${response.statusCode}');
    }
  }

  Future<bool> deleteVehicle(int vehicleId) async {
    final url = Uri.parse('$_baseUrl$vehicleId/');
    try {
      final response = await _httpClient.delete(url);
      return (response.statusCode == 204);
    } catch (e) {
      return false;
    }
  }
}