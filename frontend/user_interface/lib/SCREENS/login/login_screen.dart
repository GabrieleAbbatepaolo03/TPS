import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_interface/MAIN%20UTILS/page_transition.dart';
import 'package:user_interface/SCREENS/login/utils/custom_switch.dart';
import 'package:user_interface/SCREENS/root_screen.dart';
import 'package:user_interface/SERVICES/auth_service.dart';
import 'package:user_interface/services/AUTHETNTICATION%20HELPERS/secure_storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final AuthService _authService = AuthService();
  final SecureStorageService _storageService = SecureStorageService(); 

  bool isLogin = true;
  bool showPassword = false;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      slideRoute(const RootPage()), 
    );
  }

  void _handleSignUp() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _authService.register(
      firstName: _nameController.text.trim(),
      lastName: _surnameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (result != null) {
      final accessToken = result['tokens']['access'];
      final refreshToken = result['tokens']['refresh'];
      
      await _storageService.saveTokens(
        accessToken: accessToken, 
        refreshToken: refreshToken
      );
      _navigateToMain();
    } else {
      _showErrorSnackbar('Registration failed. Please check the information entered.');
    }
  }

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (result != null) {
      final accessToken = result['access']; 
      final refreshToken = result['refresh']; 
      
      await _storageService.saveTokens(
        accessToken: accessToken, 
        refreshToken: refreshToken
      );
      _navigateToMain();
    } else {
      _showErrorSnackbar('Access failed, Invalid credantials.'); 
    }
  }
  
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color.fromARGB(255, 52, 12, 108),
              Color.fromARGB(255, 2, 11, 60),
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 100),
                Text(
                  'Sign Up or Log In',
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),

                // SWITCH LOGIN / REGISTER
                CustomSwitch(
                  leftLabel: "Login",
                  rightLabel: "Register",
                  primaryColor: Colors.white,
                  secondaryColor: Colors.white24,
                  textColor: Colors.black,
                  isLoginSelected: isLogin,
                  onChanged: (value) {
                    setState(() => isLogin = value);
                  },
                ),

                const SizedBox(height: 40),

                // FORM BOX
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (!isLogin) ...[
                        _buildTextField(
                          controller: _nameController,
                          label: "First Name",
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _surnameController,
                          label: "Last Name",
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildTextField(
                        controller: _emailController,
                        label: "Email",
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        label: "Password",
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: !showPassword,
                        onVisibilityToggle: () {
                          setState(() => showPassword = !showPassword);
                        },
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          if (isLogin) {
                             _handleLogin();
                          } else {
                            _handleSignUp();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: _isLoading 
                            ? const SizedBox( 
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: Colors.black),
                              )
                            : Text(
                                isLogin ? "Log In" : "Sign Up",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // TextField builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onVisibilityToggle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}
