import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:officer_interface/SERVICES/authentication%20helpers/secure_storage_service.dart';
import 'package:officer_interface/SERVICES/user_session.dart';
import 'package:officer_interface/SERVICES/CONFIG/api.dart';

class AuthService {
  static final SecureStorageService _storageService = SecureStorageService();

  static Future<bool> loginUser(
    String email,
    String password, {
    String requiredRole = 'any',
  }) async {

    final baseUrl = Api.users;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token/controller/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final accessToken = data['access'];
        final refreshToken = data['refresh'];

        final role = data['role'];
        final allowedCities = data['allowed_cities'] as List<dynamic>?;

        await _storageService.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        UserSession().setSession(role: role, allowedCities: allowedCities);

        if (data.containsKey('role')) {
          if (role == 'superuser') return true;

          if (requiredRole == 'any' || role == requiredRole) {
            return true;
          }

          await logout();
          return false;
        }

        return requiredRole == 'any';
      } else {
        return false;
      }
    } catch (e) {
      print("Login error: $e");
      return false;
    }
  }

  static Future<bool> loginController(String email, String password) =>
      loginUser(email, password, requiredRole: 'controller');

  static Future<void> logout() async {
    await _storageService.deleteTokens();
    UserSession().clear();
  }
}
