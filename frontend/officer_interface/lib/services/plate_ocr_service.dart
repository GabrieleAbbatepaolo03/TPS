import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:officer_interface/config/api';


import 'package:officer_interface/services/authentication%20helpers/secure_storage_service.dart';

class PlateOcrService {
  static final SecureStorageService _storage = SecureStorageService();

  /// 上传图片并返回后端 JSON（plate/confidence/candidates）
  static Future<Map<String, dynamic>> recognizePlate(XFile image) async {
    // 1) 取 JWT access token
    // ⚠️ 这里依赖你们 SecureStorageService 的实现
    // 我先按“常见写法”假设它有 getAccessToken()。
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception("No access token found. Please login again.");
    }

    // 2) 读图片 bytes（Web 也支持）
    final bytes = await image.readAsBytes();

    // 3) Multipart POST
    final uri = Uri.parse('${Api.api}/plate-ocr/');
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
