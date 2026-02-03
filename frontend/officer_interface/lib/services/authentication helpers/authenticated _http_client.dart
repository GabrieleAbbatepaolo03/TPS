import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secure_storage_service.dart';

// Assicurati che questo URL sia corretto per l'emulatore
const String _authBaseUrl = 'http://10.0.2.2:8000/api/users'; 



class AuthenticatedHttpClient {
  final SecureStorageService _storageService;

  AuthenticatedHttpClient() : _storageService = SecureStorageService();

  Future<Map<String, String>> _getAuthHeaders(String? token) async {
    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
  
  Future<String?> _refreshToken() async {
    final refreshToken = await _storageService.getRefreshToken();
    
    if (refreshToken == null) {
        return null;
    }

    const refreshUrl = '$_authBaseUrl/token/refresh/'; 
    
    try {
      final response = await http.post(
          Uri.parse(refreshUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final newAccessToken = data['access'];
          // Alcuni backend non ritornano un nuovo refresh token, usiamo il vecchio se serve
          final newRefreshToken = data['refresh'] ?? refreshToken; 
          
          await _storageService.saveTokens(
              accessToken: newAccessToken, 
              refreshToken: newRefreshToken,
          );
          return newAccessToken;
      } else {
          print("Refresh failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
        print("Refresh network error: $e");
    }
    
    return null; 
  }

  Future<http.Response> _sendRequest(
    Uri url, 
    String method, 
    {Object? body, bool isRetry = false}
  ) async {
      String? currentToken = await _storageService.getAccessToken();
      
      final headers = await _getAuthHeaders(currentToken);
      final bodyString = body != null ? json.encode(body) : null;
      
      // Aggiunge Content-Type solo se c'è un body
      if (bodyString != null) {
          headers['Content-Type'] = 'application/json';
      }
      
      Future<http.Response> execute() {
          if (method == 'POST') {
              return http.post(url, headers: headers, body: bodyString);
          } else if (method == 'PUT') {
              return http.put(url, headers: headers, body: bodyString);
          } else if (method == 'PATCH') {
              return http.patch(url, headers: headers, body: bodyString);
          } else if (method == 'DELETE') {
              return http.delete(url, headers: headers);
          }
          return http.get(url, headers: headers);
      }
      
      try {
          http.Response response = await execute();

          // Se 401 (Non autorizzato), prova il refresh
          if (response.statusCode == 401 && !isRetry) {
              print("Token expired (401). Attempting refresh...");
              final newAccessToken = await _refreshToken();
              
              if (newAccessToken != null) {
                  print("Refresh success. Retrying original request.");
                  return _sendRequest(url, method, body: body, isRetry: true);
              } else {
                  print("Refresh failed. Logging out.");
                  await _storageService.deleteTokens();
                  throw Exception('Session Expired');
              }
          }

          return response;
      } catch (e) {
          rethrow; 
      }
  }

  Future<http.Response> get(Uri url) => _sendRequest(url, 'GET');
  Future<http.Response> post(Uri url, {Object? body}) => _sendRequest(url, 'POST', body: body);
  Future<http.Response> put(Uri url, {Object? body}) => _sendRequest(url, 'PUT', body: body);
  Future<http.Response> patch(Uri url, {Object? body}) => _sendRequest(url, 'PATCH', body: body);
  Future<http.Response> delete(Uri url) => _sendRequest(url, 'DELETE');
}