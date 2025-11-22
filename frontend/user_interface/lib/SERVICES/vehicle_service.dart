import 'dart:convert';
import 'package:user_interface/MODELS/vehicle.dart';
import 'package:user_interface/SERVICES/AUTHETNTICATION%20HELPERS/authenticated_http_client.dart';

const String _baseUrl = 'http://127.0.0.1:8000/api/vehicles/';

class VehicleService {
  final AuthenticatedHttpClient _httpClient;
  VehicleService() : _httpClient = AuthenticatedHttpClient();

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
  }) async {
    final url = Uri.parse(_baseUrl);
    try {
      final response = await _httpClient.post(
        url,
        body: {'plate': plate, 'name': name},
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
