import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secure_storage_service.dart';

const String _authBaseUrl = 'http://127.0.0.1:8000/api/users'; 

class AuthenticatedHttpClient {
  final SecureStorageService _storageService;

  AuthenticatedHttpClient() : _storageService = SecureStorageService();

  final Map<String, String> _baseHeaders = {
    'Content-Type': 'application/json',
  };

  Future<Map<String, String>> _getAuthHeaders(String? token) async {
    final headers = {..._baseHeaders};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
  
  Future<String?> _refreshToken() async {
    final refreshToken = await _storageService.getRefreshToken();
  
    print('DEBUG REFRESH: Token letto dallo storage: $refreshToken'); 
    
    if (refreshToken == null) {
        print('DEBUG REFRESH: Token mancante in storage. Ritorno NULL.');
        return null;
    }

    const refreshUrl = '$_authBaseUrl/token/refresh/'; 
    
    try {
      final response = await http.post(
          Uri.parse(refreshUrl),
          headers: _baseHeaders,
          body: json.encode({'refresh': refreshToken}),
      );

      print('DEBUG REFRESH: Server Response Status: ${response.statusCode}');
      print('DEBUG REFRESH: Server Response Body: ${response.body}');

      if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final newAccessToken = data['access'];
          final newRefreshToken = data['refresh'] ?? refreshToken; 
          
          await _storageService.saveTokens(
              accessToken: newAccessToken, 
              refreshToken: newRefreshToken,
          );
          print('DEBUG REFRESH: Refresh SUCCESS. New Access Token saved.');
          return newAccessToken;
      } else {
          print('DEBUG REFRESH: Refresh FAILED. Status ${response.statusCode}.');
      }
    } catch (e) {
        print('DEBUG REFRESH: Network error during refresh attempt: $e');
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
      
      Future<http.Response> execute() {
          if (method == 'POST') {
              return http.post(url, headers: headers, body: bodyString);
          } else if (method == 'PUT') {
              return http.put(url, headers: headers, body: bodyString);
          } else if (method == 'DELETE') {
              return http.delete(url, headers: headers);
          }
          return http.get(url, headers: headers);
      }
      
      try {
          http.Response response = await execute();

          if (response.statusCode == 401 && !isRetry) {
              final newAccessToken = await _refreshToken();
              
              if (newAccessToken != null) {
                  return _sendRequest(url, method, body: body, isRetry: true);
              } else {
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

  Future<http.Response> delete(Uri url) => _sendRequest(url, 'DELETE');
}