import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Zmień localhost na właściwy adres
  static const String _baseUrl =
      'http://10.0.2.2:5018/api'; // Dla Android Emulator
  // static const String _baseUrl = 'http://192.168.1.100:5018/api'; // Dla fizycznego urządzenia
  // static const String _baseUrl = 'http://localhost:5018/api'; // Tylko dla web/desktop

  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Rejestracja przez nasze API (tylko email i hasło)
  Future<bool> register({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      print('Attempting registration with API');

      final response = await http.post(
        Uri.parse('http://10.0.2.2:5018/api/Auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          if (username != null) 'username': username,
        }),
      );

      print('Registration response status: ${response.statusCode}');
      print('Registration response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // Zapisz token i dane użytkownika z API
        await _saveAuthData(responseData);

        print('Registration successful: $email');
        return true;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid registration data');
      } else if (response.statusCode == 409) {
        throw Exception('User already registered');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('Registration error: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          'Cannot connect to server. Please check your connection.',
        );
      }
      throw Exception(_getErrorMessage(e));
    }
  }

  // Logowanie przez nasze API
  Future<bool> login({required String email, required String password}) async {
    try {
      print('Attempting login with API');

      final response = await http.post(
        Uri.parse('http://10.0.2.2:5018/api/Auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Zapisz token i dane użytkownika z API
        await _saveAuthData(responseData);

        print('Login successful: $email');
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid login credentials');
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('Login error: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          'Cannot connect to server. Please check your connection.',
        );
      }
      throw Exception(_getErrorMessage(e));
    }
  }

  // Test API connection
  Future<bool> testApiConnection() async {
    try {
      print('Testing API connection');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5018/api/Auth/test'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('API test response status: ${response.statusCode}');
      print('API test response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('API connection test failed: $e');
      return false;
    }
  }

  // Pobierz profil użytkownika z API
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      print('Fetching user profile from API');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5018/api/User/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Fetch profile response status: ${response.statusCode}');
      print('Fetch profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // DEBUG: Sprawdź co zwraca API
        print('API returned profile data: $responseData');

        // Zaktualizuj lokalne dane użytkownika
        final currentUserData = await getUserData();
        if (currentUserData != null) {
          currentUserData.addAll(responseData);
          await _saveAuthData(currentUserData);
        }

        return responseData;
      } else if (response.statusCode == 401) {
        // Token wygasł, wyloguj użytkownika
        await logout();
        return null;
      } else if (response.statusCode == 404) {
        // Profil nie istnieje - sprawdź lokalne dane
        print('Profile not found on server, checking local data');
        final localUserData = await getUserData();
        return localUserData;
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        print('Network error, falling back to local data');
        // Jeśli nie ma połączenia, zwróć lokalne dane
        final localUserData = await getUserData();
        return localUserData;
      }
    }
    return null;
  }

  // Aktualizuj profil użytkownika przez API
  Future<Map<String, dynamic>?> updateUserProfile(
    Map<String, dynamic> profileData,
  ) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      print('Updating user profile with data: $profileData');

      final response = await http.put(
        Uri.parse('http://10.0.2.2:5018/api/User/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode(profileData),
      );

      print('Profile update response status: ${response.statusCode}');
      print('Profile update response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Zaktualizuj lokalne dane użytkownika
        final currentUserData = await getUserData();
        if (currentUserData != null) {
          currentUserData.addAll(responseData);
          await _saveAuthData(currentUserData);
        }

        return responseData;
      } else if (response.statusCode == 401) {
        // Token wygasł, wyloguj użytkownika
        await logout();
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid profile data');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Profile update failed');
      }
    } catch (e) {
      print('Error updating user profile: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          'Cannot connect to server. Please check your connection.',
        );
      }
      rethrow;
    }
  }

  // Kompletuj onboarding
  Future<Map<String, dynamic>?> completeOnboarding(
    Map<String, dynamic> onboardingData,
  ) async {
    final token = await getToken();
    if (token == null) return null;

    try {
      print('Completing onboarding with data: $onboardingData');

      final response = await http.post(
        Uri.parse('http://10.0.2.2:5018/api/User/onboarding/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode(onboardingData),
      );

      print('Onboarding complete response status: ${response.statusCode}');
      print('Onboarding complete response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        print('Onboarding API SUCCESS - response: $responseData');

        // Zaktualizuj lokalne dane użytkownika
        final currentUserData = await getUserData();
        if (currentUserData != null) {
          currentUserData.addAll(responseData);
          currentUserData['isOnboardingCompleted'] = true;
          await _saveAuthData(currentUserData);
          print('Local data updated with onboarding completion');
        }

        return responseData;
      } else if (response.statusCode == 401) {
        // Token wygasł, wyloguj użytkownika
        await logout();
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid onboarding data');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Onboarding completion failed');
      }
    } catch (e) {
      print('Error completing onboarding: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          'Cannot connect to server. Please check your connection.',
        );
      }
      rethrow;
    }
  }

  // Przelicz nutrition
  Future<Map<String, dynamic>?> recalculateNutrition() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      print('Recalculating nutrition');

      final response = await http.post(
        Uri.parse('http://10.0.2.2:5018/api/User/nutrition/recalculate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Nutrition recalculate response status: ${response.statusCode}');
      print('Nutrition recalculate response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else if (response.statusCode == 401) {
        // Token wygasł, wyloguj użytkownika
        await logout();
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Nutrition recalculation failed',
        );
      }
    } catch (e) {
      print('Error recalculating nutrition: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          'Cannot connect to server. Please check your connection.',
        );
      }
      rethrow;
    }
  }

  // Pobierz token z lokalnego storage
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Pobierz UID z danych użytkownika
  Future<String?> getUid() async {
    final userData = await getUserData();
    return userData?['id'] ?? userData?['uid'];
  }

  // Pobierz dane użytkownika z lokalnego storage
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  // Sprawdź czy użytkownik jest zalogowany
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Wylogowanie - usuń dane z lokalnego storage
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userDataKey);
      print('User logged out successfully');
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Logout failed');
    }
  }

  // Zapisz dane uwierzytelniania w lokalnym storage - PUBLICZNE
  Future<void> saveAuthDataPublic(Map<String, dynamic> authData) async {
    await _saveAuthData(authData);
  }

  // Zapisz dane uwierzytelniania w lokalnym storage - PRYWATNE
  Future<void> _saveAuthData(Map<String, dynamic> authData) async {
    final prefs = await SharedPreferences.getInstance();

    // Zapisz token
    if (authData['token'] != null) {
      await prefs.setString(_tokenKey, authData['token']);
    }

    // Zapisz dane użytkownika
    await prefs.setString(_userDataKey, jsonEncode(authData));
    print('Auth data saved locally: ${authData.keys.toList()}');
  }

  // Pomocnicza funkcja do obsługi błędów
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('Invalid login credentials')) {
      return 'Nieprawidłowy email lub hasło';
    } else if (errorString.contains('Email not confirmed')) {
      return 'Email nie został potwierdzony';
    } else if (errorString.contains('User already registered')) {
      return 'Użytkownik o tym adresie email już istnieje';
    } else if (errorString.contains('Cannot connect to server')) {
      return 'Nie można połączyć się z serwerem';
    } else if (errorString.contains('timeout')) {
      return 'Przekroczono limit czasu połączenia';
    }

    return 'Wystąpił nieoczekiwany błąd';
  }
}
