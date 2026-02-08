import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:officer_interface/SERVICES/CONFIG/api.dart';
import 'secure_storage_service.dart';

const String _authBaseUrl = Api.users;

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
    String method, {
    Map<String, String>? headers,
    Object? body,
    bool isRetry = false,
  }) async {
    String? currentToken = await _storageService.getAccessToken();

    final authHeaders = await _getAuthHeaders(currentToken);

    if (headers != null) {
      authHeaders.addAll(headers);
    }

    final bodyString = body != null ? json.encode(body) : null;

    if (bodyString != null && !authHeaders.containsKey('Content-Type')) {
      authHeaders['Content-Type'] = 'application/json';
    }

    Future<http.Response> execute() {
      if (method == 'POST') {
        return http.post(url, headers: authHeaders, body: bodyString);
      } else if (method == 'PUT') {
        return http.put(url, headers: authHeaders, body: bodyString);
      } else if (method == 'PATCH') {
        return http.patch(url, headers: authHeaders, body: bodyString);
      } else if (method == 'DELETE') {
        return http.delete(url, headers: authHeaders);
      }
      return http.get(url, headers: authHeaders);
    }

    try {
      http.Response response = await execute();

      if (response.statusCode == 401 && !isRetry) {
        print("Token expired (401). Attempting refresh...");
        final newAccessToken = await _refreshToken();

        if (newAccessToken != null) {
          print("Refresh success. Retrying original request.");
          return _sendRequest(
            url,
            method,
            headers: headers,
            body: body,
            isRetry: true,
          );
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

  Future<http.Response> postMultipart(
    Uri url, {
    Map<String, String>? fields,
    File? imageFile,
    String imageFieldName = 'image',
    bool isRetry = false,
  }) async {
    String? currentToken = await _storageService.getAccessToken();

    var request = http.MultipartRequest('POST', url);

    final authHeaders = await _getAuthHeaders(currentToken);
    request.headers.addAll(authHeaders);

    if (fields != null) {
      request.fields.addAll(fields);
    }
    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        imageFieldName,
        imageFile.path,
      ));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401 && !isRetry) {
        print("Token expired (401) during Multipart. Attempting refresh...");
        final newAccessToken = await _refreshToken();

        if (newAccessToken != null) {
          print("Refresh success. Retrying Multipart request.");
          return postMultipart(
            url,
            fields: fields,
            imageFile: imageFile,
            imageFieldName: imageFieldName,
            isRetry: true,
          );
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

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
      _sendRequest(url, 'GET', headers: headers);

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _sendRequest(url, 'POST', headers: headers, body: body);

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _sendRequest(url, 'PUT', headers: headers, body: body);

  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) => _sendRequest(url, 'PATCH', headers: headers, body: body);

  Future<http.Response> delete(Uri url, {Map<String, String>? headers}) =>
      _sendRequest(url, 'DELETE', headers: headers);
}
