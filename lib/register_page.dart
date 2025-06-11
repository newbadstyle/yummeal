import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yummeal/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    // Test połączenia z API
    print('Testing API connection...');
    final isConnected = await _authService.testConnection();
    if (!isConnected) {
      _showSnackBar('Cannot connect to API. Check if your server is running.');
      return;
    }
    // Poprawność danych wejściowych
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('Please enter your email');
      return;
    }

    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(_emailController.text.trim())) {
      _showSnackBar('Please enter a valid email address');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showSnackBar('Please enter your password');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnackBar('Password must be at least 6 characters long');
      return;
    }

    if (_confirmPasswordController.text.isEmpty) {
      _showSnackBar('Please confirm your password');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match');
      return;
    }

    // Rozpocznij ładowanie
    setState(() {
      _isLoading = true;
    });

    try {
      // Rzeczywista rejestracja przez API

      // Sprawdź czy widget jest nadal zamontowany
      if (!mounted) return;

      // Pobierz dane użytkownika po rejestracji
      final userData = await _authService.getUserData();
      final uid = userData['uid'];

      _showSnackBar('Registration successful! Your UID: $uid', isSuccess: true);

      // Po udanej rejestracji:
      // 1. Automatycznie zalogować użytkownika
      // 2. Przekierowanie do logowania

      // Sprawdź czy użytkownik jest zalogowany po rejestracji
      final isLoggedIn = await _authService.isLoggedIn();

      if (isLoggedIn) {
        // Jeśli API automatycznie loguje po rejestracji
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Jeśli nie to przekieruj do logowania
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      // Obsługa błędów
      if (!mounted) return;

      _showSnackBar(
        'Registration failed: ${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
      // Zakończ ładowanie
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              Text(
                '✨ Yummeal ✨',
                style: GoogleFonts.margarine(
                  color: const Color(0xFF1A1A1A),
                  fontSize: 25,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 80),

              Text(
                'Create Account!',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Sign up to start tracking your nutrition',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 40),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap:
                        _isLoading
                            ? null
                            : () {
                              Navigator.pushNamed(context, '/login');
                            },
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color:
                            _isLoading ? Colors.grey : const Color(0xFF4CAF50),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Terms i Privacy
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      _showSnackBar('Terms & Conditions');
                    },
                    child: const Text(
                      'T&Cs',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const Text(
                    '  •  ',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  GestureDetector(
                    onTap: () {
                      _showSnackBar('Privacy Policy');
                    },
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
