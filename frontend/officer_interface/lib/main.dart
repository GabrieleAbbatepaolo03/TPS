import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:officer_interface/SCREENS/login/login_screen.dart'; 
import 'package:officer_interface/SCREENS/start_shift_screen.dart';
import 'package:officer_interface/SERVICES/authentication%20helpers/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Check if controller is already logged in
  final secureStorage = SecureStorageService();
  final token = await secureStorage.getAccessToken();
  final bool isLoggedIn = token != null;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parking Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 52, 12, 108),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 2, 11, 60),
      ),
      home: isLoggedIn ? const StartShiftScreen() : const LoginScreen(),
    );
  }
}