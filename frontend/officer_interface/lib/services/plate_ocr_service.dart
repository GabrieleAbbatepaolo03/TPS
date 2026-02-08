import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:officer_interface/SERVICES/CONFIG/api.dart';
import 'package:officer_interface/SERVICES/authentication%20helpers/secure_storage_service.dart';

class PlateOcrService {
  static final SecureStorageService _storage = SecureStorageService();

  static Future<Map<String, dynamic>> recognizePlate(XFile image) async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception("No access token found. Please login again.");
    }
    final bytes = await image.readAsBytes();

    final uri = Uri.parse('${Api.baseUrl}/plate-ocr/');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: image.name,
      ),
    );

    final streamed = await request.send();
    final respBody = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception('Plate OCR failed: ${streamed.statusCode} - $respBody');
    }

    return jsonDecode(respBody) as Map<String, dynamic>;
  }
}
