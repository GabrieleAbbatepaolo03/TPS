import 'dart:convert';
import 'package:officer_interface/SERVICES/CONFIG/api.dart';
import 'package:officer_interface/SERVICES/authentication%20helpers/authenticated%20_http_client.dart';

class ShiftInfo {
  final int id;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;

  ShiftInfo({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.status,
  });

  factory ShiftInfo.fromJson(Map<String, dynamic> json) {
    return ShiftInfo(
      id: json['id'],
      startTime: DateTime.parse(json['start_time']).toLocal(),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']).toLocal() : null,
      status: json['status'] ?? 'OPEN',
    );
  }

  Duration? get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return null;
  }

  String get formattedDuration {
    final dur = duration;
    if (dur == null) return 'Ongoing';
    
    final hours = dur.inHours;
    final minutes = dur.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}

class ShiftService {
  static final AuthenticatedHttpClient _client = AuthenticatedHttpClient();

  static const String _apiRoot = Api.baseUrl; 

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

  static Future<void> endShift() async {
    final url = Uri.parse('$_apiRoot/users/shifts/end/');
    final res = await _client.post(url);

    if (res.statusCode != 200) {
      throw Exception(
        "Failed to end shift: ${res.statusCode} ${res.body}",
      );
    }
  }

  static Future<List<ShiftInfo>> getShiftHistory({int? limit}) async {
    final queryParams = limit != null ? '?limit=$limit' : '';
    final url = Uri.parse('$_apiRoot/users/shifts/history/$queryParams');
    final res = await _client.get(url);

    if (res.statusCode != 200) {
      throw Exception(
        "Failed to get shift history: ${res.statusCode} ${res.body}",
      );
    }

    final data = jsonDecode(res.body);
    final shifts = (data['shifts'] as List)
        .map((json) => ShiftInfo.fromJson(json))
        .toList();
    
    return shifts;
  }
}
