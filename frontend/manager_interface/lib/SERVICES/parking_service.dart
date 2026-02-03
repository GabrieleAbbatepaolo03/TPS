import 'dart:convert';
import 'package:manager_interface/SERVICES/authentication%20helpers/authenticated_http_client.dart';
import 'package:http/http.dart' as http;
import '../models/parking.dart';
import '../models/spot.dart';
import '../models/parking_session.dart';
import 'package:manager_interface/models/city.dart';
import 'dart:developer' as developer;

class ParkingService {
  static final AuthenticatedHttpClient _httpClient = AuthenticatedHttpClient();
  
  static const String _apiRoot = 'http://127.0.0.1:8000/api'; 

  static Future<List<String>> getCities() async {
    developer.log('🌐 Fetching cities from: $_apiRoot/cities-list/');
    final response = await _httpClient.get(Uri.parse('$_apiRoot/cities-list/'));
    
    developer.log('📥 Response status: ${response.statusCode}');
    developer.log('📥 Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      developer.log('📊 Parsed data type: ${data.runtimeType}');
      
      if (data is Map && data.containsKey('cities')) {
        final cities = (data['cities'] as List<dynamic>).cast<String>();
        cities.sort();
        developer.log('✅ Loaded ${cities.length} cities: $cities');
        return cities;
      } else {
        throw Exception('Unexpected response format: expected Map with "cities" key, got: ${data.runtimeType}');
      }
    } else {
      throw Exception('Failed to load cities: HTTP ${response.statusCode}');
    }
  }

  static Future<List<City>> getCitiesWithCoordinates() async {
    developer.log('🌐 Fetching city coordinates from: $_apiRoot/cities/list_with_coordinates/');
    final url = Uri.parse('$_apiRoot/cities/list_with_coordinates/');
    final response = await _httpClient.get(url);

    developer.log('📥 Response status: ${response.statusCode}');
    developer.log('📥 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      final cities = data.map((json) => City.fromJson(json)).toList();
      developer.log('✅ Loaded ${cities.length} cities with coordinates');
      return cities;
    } else {
      throw Exception('Failed to load cities with coordinates: HTTP ${response.statusCode}');
    }
  }

  static Future<List<Parking>> getParkingsByCity(String city) async {
    final response = await _httpClient.get(Uri.parse('$_apiRoot/parkings/?city=$city'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Parking.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load parkings for city $city: ${response.statusCode}');
    }
  }

  static Future<Parking> getParking(int parkingId) async {
    final response = await _httpClient.get(Uri.parse('$_apiRoot/parkings/$parkingId/'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return Parking.fromJson(jsonData);
    } else {
      throw Exception('Failed to load parking $parkingId: ${response.statusCode}');
    }
  }

  static Future<List<Spot>> getSpots(int parkingId) async {
    final response = await _httpClient.get(Uri.parse('$_apiRoot/parkings/$parkingId/spots/'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Spot.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load spots for parking $parkingId: ${response.statusCode}');
    }
  }

  // NEW: Get active sessions for Manager
  static Future<List<ParkingSession>> getLiveSessions(int parkingId) async {
    final response = await _httpClient.get(Uri.parse('$_apiRoot/parkings/$parkingId/sessions/'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ParkingSession.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load live sessions: ${response.statusCode}');
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
      throw Exception('Failed to save parking: ${response.statusCode} ${response.body}');
    }
  }

  static Future<bool> deleteParking(int parkingId) async {
    final url = Uri.parse('$_apiRoot/parkings/$parkingId/');
    final response = await _httpClient.delete(url);
    if (response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Failed to delete parking: ${response.statusCode}');
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
      throw Exception('Failed to add spot: ${response.body}');
    }
  }

  static Future<bool> deleteSpot(int spotId) async {
    final url = Uri.parse('$_apiRoot/spots/$spotId/');
    final response = await _httpClient.delete(url);
    return response.statusCode == 204;
  }
}