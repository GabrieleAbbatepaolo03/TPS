import 'dart:convert';
import 'package:user_interface/services/AUTHETNTICATION%20HELPERS/authenticated_http_client.dart';
import 'package:user_interface/services/AUTHETNTICATION%20HELPERS/secure_storage_service.dart';


// const String _baseUrl = 'http://127.0.0.1:8000/api/users'; 
const String _baseUrl = 'http://10.0.2.2:8000/api/users'; 

class UserService {
  final AuthenticatedHttpClient _httpClient;
  final SecureStorageService _storageService;
  
  UserService() 
    : _httpClient = AuthenticatedHttpClient(), 
      _storageService = SecureStorageService();

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final url = Uri.parse('$_baseUrl/profile/');
    
    try {
      final response = await _httpClient.get(url); 

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await _storageService.deleteTokens();
        return null; 
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
