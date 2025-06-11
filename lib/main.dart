import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yummeal/auth_service.dart';
import 'welcome_page.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicjalizacja Supabase
  await Supabase.initialize(
    url: 'https://ipyzybezgqczyjyrjpcf.supabase.co', // Zastąp swoim URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlweXp5YmV6Z3FjenlqeXJqcGNmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk1NzMzNTIsImV4cCI6MjA2NTE0OTM1Mn0.XTonGkjfsdZKMbsTI6AEpm_bUS6714L9IuyIjLS6HbY', // Zastąp swoim kluczem
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yummeal',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        // Główny kolor aplikacji
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF4CAF50),

        // Schemat kolorów
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
        ),

        // Konfiguracja AppBar (na później)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        // Stylizacja przycisków ElevatedButton
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Stylizacja TextButton
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF666666)),
        ),

        useMaterial3: true,
      ),

      // Status bar style
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          child: child!,
        );
      },

      // Routes konfiguracja
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
      },

      // Initial route
      initialRoute: '/',
    );
  }
}

// Nowy ekran startowy
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Małe opóźnienie dla lepszego UX
    await Future.delayed(const Duration(seconds: 1));

    // Sprawdź czy użytkownik jest zalogowany
    final isLoggedIn = await _authService.isLoggedIn();

    if (mounted) {
      if (isLoggedIn) {
        // Jeśli zalogowany, idź do home
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Jeśli nie, idź do welcome page
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Text(
              '✨ Yummeal ✨',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
