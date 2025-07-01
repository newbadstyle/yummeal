import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:yummeal/onboarding.dart';
import 'welcome_page.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Załaduj zmienne środowiskowe z pliku .env
  await dotenv.load(fileName: ".env");

  // Inicjalizacja Supabase ze zmiennymi środowiskowymi
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
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

      // Status bar
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
        '/onboarding': (context) => const OnboardingFlow(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfileScreen(),
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
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Opóźnienie dla lepszego UX
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Sprawdź czy użytkownik jest zalogowany w Supabase
      final user = supabase.auth.currentUser;

      if (user != null) {
        // Sprawdź czy użytkownik ma profil (ukończył onboarding)
        final profileResponse =
            await supabase
                .from('user_profiles')
                .select()
                .eq('id', user.id)
                .maybeSingle();

        if (mounted) {
          if (profileResponse != null) {
            // Użytkownik ma profil - idź do home
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            // Użytkownik zalogowany ale nie ma profilu - onboarding
            Navigator.pushReplacementNamed(context, '/onboarding');
          }
        }
      } else {
        // Użytkownik nie zalogowany - welcome page
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/welcome');
        }
      }
    } catch (e) {
      print('Error checking auth status: $e');
      if (mounted) {
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
            Text(
              '✨ Yummeal ✨',
              style: GoogleFonts.margarine(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
          ],
        ),
      ),
    );
  }
}
