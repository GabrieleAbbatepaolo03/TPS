import 'dart:convert';
import 'package:http/http.dart' as http;
// Since this file is used by both officer and manager interfaces, 
// we must ensure the import path to secure_storage_service.dart is correct 
import 'package:officer_interface/services/authentication%20helpers/secure_storage_service.dart'; 

class AuthService {
  // Assumed correct URL from tps_backend/urls.py (api/users/)
  static const String baseUrl = "http://127.0.0.1:8000/api/users";
  static final SecureStorageService _storageService = SecureStorageService();

  // Unified login method for Manager or Controller
  static Future<bool> loginUser(String email, String password, {String requiredRole = 'any'}) async {
    // FIXED: Use standard JWT token endpoint
    final url = Uri.parse('$baseUrl/token/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final accessToken = data['access'];
      final refreshToken = data['refresh'];

      // 1. Save tokens securely
      await _storageService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      
      // 2. Role validation (Requires backend to return the role in token response)
      if (data.containsKey('role')) {
        final userRole = data['role'];
        
        // Superuser can access everything
        if (userRole == 'superuser') {
          return true;
        }
        
        // Check role match
        if (requiredRole == 'any' || userRole == requiredRole) {
          return true;
        }
        
        // Role mismatch: log out and fail
        await logout();
        return false;
      }

      // If backend doesn't return role, assume success if no specific role is required
      return requiredRole == 'any';
    } else {
      // Login failed (401 or other HTTP error)
      return false;
    }
  }

  // Convenience methods (calling the unified method)
  static Future<bool> loginManager(String email, String password) => 
      loginUser(email, password, requiredRole: 'manager');
  
  static Future<bool> loginController(String email, String password) => 
      loginUser(email, password, requiredRole: 'controller');


  // Logout
  static Future<void> logout() async {
    await _storageService.deleteTokens();
  }
}