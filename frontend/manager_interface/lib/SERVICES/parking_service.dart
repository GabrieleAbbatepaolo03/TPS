import 'dart:convert';
import 'package:manager_interface/SERVICES/CONFIG/api.dart';
import 'package:manager_interface/SERVICES/authentication%20helpers/authenticated_http_client.dart';
import 'package:http/http.dart' as http;
import '../models/parking.dart';
import '../models/spot.dart';
import '../models/parking_session.dart';
import 'package:manager_interface/models/city.dart';

class ParkingService {
  static final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient();
  
  static const String _apiRoot = Api.baseUrl; 

  static Future<List<City>> getCitiesWithCoordinates() async {
    final url = Uri.parse('$_apiRoot/cities/authorized/');
    final response = await _httpClient.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final cities = data.map((json) => City.fromJson(json)).toList();
      return cities;
    } else {
      throw Exception('Failed to load authorized cities: HTTP ${response.statusCode}');
    }
  }

  static Future<List<Parking>> getParkingsForMap(String city) async {
    final url = Uri.parse('$_apiRoot/parkings/search_map/?city=$city');
    final response = await _httpClient.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) {
        return Parking.fromJson(json); 
      }).toList();
    } else {
      throw Exception('Failed to load map parkings for city $city');
    }
  }

  static Future<List<Parking>> getParkingsByCity(String city) async {
    final response = await _httpClient.get(Uri.parse('$_apiRoot/parkings/?city=$city'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Parking.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load parkings for city $city');
    }
  }

  static Future<Parking> getParking(int parkingId) async {
    final response = await _httpClient.get(Uri.parse('$_apiRoot/parkings/$parkingId/'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return Parking.fromJson(jsonData);
    } else {
      throw Exception('Failed to load parking $parkingId');
    }
  }

  static Future<List<Spot>> getSpots(int parkingId) async {
    final response = await _httpClient.get(Uri.parse('$_apiRoot/parkings/$parkingId/spots/'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Spot.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load spots for parking $parkingId');
    }
  }

  static Future<List<ParkingSession>> getLiveSessions(int parkingId) async {
    final response = await _httpClient.get(Uri.parse('$_apiRoot/parkings/$parkingId/sessions/'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ParkingSession.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load live sessions');
    }
  }

  static Future<Parking> saveParking(Parking parkingData) async {
    Uri url;
    http.Response response;
    final body = parkingData.toJson();
    
    if (parkingData.id != 0) {
      url = Uri.parse('$_apiRoot/parkings/${parkingData.id}/');
      response = await _httpClient.put(url, body: body);
    } else {
      url = Uri.parse('$_apiRoot/parkings/');
      response = await _httpClient.post(url, body: body);
    }
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Parking.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to save parking');
    }
  }

  static Future<bool> deleteParking(int parkingId) async {
    final url = Uri.parse('$_apiRoot/parkings/$parkingId/');
    final response = await _httpClient.delete(url);
    if (response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Failed to delete parking');
    }
  }

  static Future<Spot> addSpot(int parkingId) async {
    final url = Uri.parse('$_apiRoot/spots/'); 
    final body = {
        'parking': parkingId, 
        'number': 'AUTO', 
        'floor': '0', 
        'zone': 'A', 
        'is_occupied': false
    };
    final response = await _httpClient.post(url, body: body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Spot.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add spot');
    }
  }

  static Future<bool> deleteSpot(int spotId) async {
    final url = Uri.parse('$_apiRoot/spots/$spotId/');
    final response = await _httpClient.delete(url);
    return response.statusCode == 204;
  }
}