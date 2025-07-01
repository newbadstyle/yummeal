import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Rejestracja przez Supabase
  Future<bool> register({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      print('Attempting registration with Supabase');

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: username != null ? {'username': username} : null,
      );

      if (response.user != null) {
        print('Registration successful: ${response.user!.email}');
        return true;
      }

      return false;
    } catch (e) {
      print('Registration error: $e');
      throw Exception(_getErrorMessage(e));
    }
  }

  // Logowanie przez Supabase
  Future<bool> login({required String email, required String password}) async {
    try {
      print('Attempting login with Supabase');

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('Login successful: ${response.user!.email}');
        return true;
      }

      return false;
    } catch (e) {
      print('Login error: $e');
      throw Exception(_getErrorMessage(e));
    }
  }

  // Pobierz token
  Future<String?> getToken() async {
    final session = supabase.auth.currentSession;
    return session?.accessToken;
  }

  // Pobierz UID
  Future<String?> getUid() async {
    final user = supabase.auth.currentUser;
    return user?.id;
  }

  // Pobierz dane użytkownika
  Future<Map<String, dynamic>?> getUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    return {
      'uid': user.id,
      'email': user.email,
      'created_at': user.createdAt,
      'user_metadata': user.userMetadata,
    };
  }

  // Sprawdź czy użytkownik jest zalogowany
  Future<bool> isLoggedIn() async {
    return supabase.auth.currentUser != null;
  }

  // Wylogowanie
  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
      print('User logged out successfully');
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Logout failed');
    }
  }

  // Reset hasła
  Future<void> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
      print('Password reset email sent to: $email');
    } catch (e) {
      print('Password reset error: $e');
      throw Exception('Failed to send password reset email');
    }
  }

  // Pomocnicza funkcja do obsługi błędów
  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Nieprawidłowy email lub hasło';
        case 'Email not confirmed':
          return 'Email nie został potwierdzony';
        case 'User already registered':
          return 'Użytkownik o tym adresie email już istnieje';
        default:
          return error.message;
      }
    }
    return 'Wystąpił nieoczekiwany błąd';
  }

  // Test połączenia z Supabase
  Future<bool> testConnection() async {
    try {
      // Próba pobrania informacji o sesji
      final session = supabase.auth.currentSession;
      print('Supabase connection test - Session exists: ${session != null}');
      return true;
    } catch (e) {
      print('Supabase connection test failed: $e');
      return false;
    }
  }
}
