class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  String? _role;
  List<String> _allowedCities = [];

  void setSession({required String role, List<dynamic>? allowedCities}) {
    _role = role;
    if (allowedCities != null) {
      _allowedCities = allowedCities.map((e) => e.toString()).toList();
    } else {
      _allowedCities = [];
    }
  }

  void clear() {
    _role = null;
    _allowedCities = [];
  }

  bool get isSuperAdmin => _role == 'superuser';
  List<String> get allowedCities => _allowedCities;
}
