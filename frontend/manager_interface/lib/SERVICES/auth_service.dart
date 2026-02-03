import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:manager_interface/services/authentication%20helpers/secure_storage_service.dart';
import 'package:manager_interface/SERVICES/user_session.dart';

class AuthService {
  static const String baseUrl = "http://127.0.0.1:8000/api/users";
  static final SecureStorageService _storageService = SecureStorageService();

  static Future<bool> loginManager(String email, String password) async {
    final url = Uri.parse('$baseUrl/token/manager/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Backend now validates role - if we get here, user is a manager
      final accessToken = data['access'];
      final refreshToken = data['refresh'];
      final role = data['role'] ?? 'user';
      final allowedCities = data['allowed_cities'] as List<dynamic>?;

      await _storageService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      UserSession().setSession(role: role, allowedCities: allowedCities);

      return true;
    } else {
      // Login failed - wrong credentials or not a manager
      return false;
    }
  }

  // Logout
  static Future<void> logout() async {
    await _storageService.deleteTokens();
    UserSession().clear();
  }
}
