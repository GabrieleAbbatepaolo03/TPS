import 'dart:convert';
import 'package:manager_interface/SERVICES/CONFIG/api.dart';
import 'package:manager_interface/SERVICES/authentication%20helpers/authenticated_http_client.dart';

class ActiveOfficer {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final int shiftId;
  final DateTime shiftStart;
  final int shiftDurationSeconds;

  ActiveOfficer({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.shiftId,
    required this.shiftStart,
    required this.shiftDurationSeconds,
  });

  factory ActiveOfficer.fromJson(Map<String, dynamic> json) {
    return ActiveOfficer(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'],
      shiftId: json['shift_id'],
      shiftStart: DateTime.parse(json['shift_start']).toLocal(),
      shiftDurationSeconds: json['shift_duration_seconds'],
    );
  }

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? email.split('@').first : name;
  }

  String get formattedDuration {
    final hours = shiftDurationSeconds ~/ 3600;
    final minutes = (shiftDurationSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }
}

class OfficerService {
  static final AuthenticatedHttpClient _client = AuthenticatedHttpClient();

  static Future<List<ActiveOfficer>> getActiveOfficers(String city) async {
    final url = Uri.parse('${Api.users}/shifts/active-officers/?city=$city');
    final response = await _client.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to load active officers');
    }

    final data = jsonDecode(response.body);
    final officers = (data['active_officers'] as List)
        .map((json) => ActiveOfficer.fromJson(json))
        .toList();

    return officers;
  }
}
