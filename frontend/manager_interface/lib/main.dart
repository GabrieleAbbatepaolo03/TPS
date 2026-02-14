import 'package:flutter/material.dart';
import 'package:manager_interface/SCREENS/login/login_screen.dart';
import 'package:manager_interface/SCREENS/home/home_screen.dart';
import 'package:manager_interface/SERVICES/authentication%20helpers/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final secureStorage = SecureStorageService();
  final token = await secureStorage.getAccessToken();
  final bool isLoggedIn = token != null;

  runApp(ManagerApp(isLoggedIn: isLoggedIn));
}

class ManagerApp extends StatelessWidget {
  final bool isLoggedIn;

  const ManagerApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manager Interface',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
