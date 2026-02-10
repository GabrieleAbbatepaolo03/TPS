class Api {
  
  // PRODUCTION (Railway)
  static const String baseUrl = 'https://tps-production-c025.up.railway.app/api';
  
  // LOCALHOST (Android Emulator)
  // static const String baseUrl = 'http://10.0.2.2:8000/api'; 
  
  // LOCALHOST (iOS Simulator / Web)
  //static const String baseUrl = 'http://127.0.0.1:8000/api';

  static const String users = '$baseUrl/users'; 
  static const String vehicles = '$baseUrl/vehicles/';
  static const String sessions = '$baseUrl/sessions/';
  static const String payments = '$baseUrl/payments/cards/';
}