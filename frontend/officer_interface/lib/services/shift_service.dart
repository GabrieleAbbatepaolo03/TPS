import 'dart:convert';
import 'package:officer_interface/config/api';
import 'package:officer_interface/services/authentication%20helpers/authenticated%20_http_client.dart';

class ShiftInfo {
  final int id;
  final DateTime startTime;

  ShiftInfo({
    required this.id,
    required this.startTime,
  });

  factory ShiftInfo.fromJson(Map<String, dynamic> json) {
    return ShiftInfo(
      id: json['id'],
      startTime: DateTime.parse(json['start_time']).toLocal(),
    );
  }
}

class ShiftService {
  static final AuthenticatedHttpClient _client = AuthenticatedHttpClient();

  // 
  static String get _apiRoot => Api.api;

  /// GET /api/users/shifts/current/
  static Future<ShiftInfo?> getCurrentShift() async {
    final url = Uri.parse('$_apiRoot/users/shifts/current/');
    final res = await _client.get(url);

    if (res.statusCode != 200) {
      throw Exception(
        "Failed to get current shift: ${res.statusCode} ${res.body}",
      );
    }

    final data = jsonDecode(res.body);
    if (data['active'] != true || data['shift'] == null) {
      return null;
    }

    return ShiftInfo.fromJson(data['shift']);
  }

  /// POST /api/users/shifts/start/
  static Future<ShiftInfo> startShift() async {
    final url = Uri.parse('$_apiRoot/users/shifts/start/');
    final res = await _client.post(url);

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
        "Failed to start shift: ${res.statusCode} ${res.body}",
      );
    }

    return ShiftInfo.fromJson(jsonDecode(res.body));
  }

  /// POST /api/users/shifts/end/
  /// 后端会自动结束当前 OPEN shift（不需要 body）
  static Future<void> endShift() async {
    final url = Uri.parse('$_apiRoot/users/shifts/end/');
    final res = await _client.post(url);

    if (res.statusCode != 200) {
      throw Exception(
        "Failed to end shift: ${res.statusCode} ${res.body}",
      );
    }
  }
}
