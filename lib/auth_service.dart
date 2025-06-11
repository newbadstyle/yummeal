import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // URL-e z Twojego Swaggera
  // Dla emulatora Android użyj 10.0.2.2 zamiast localhost
  static const String baseUrl = 'http://10.0.2.2:5018'; // Dla emulatora Android
  // static const String baseUrl = 'http://localhost:5018'; // Dla iOS Simulator
  // static const String baseUrl = 'http://192.168.1.100:5018'; // Dla fizycznego urządzenia (użyj swojego IP)

  static const String loginEndpoint = '/api/Auth/login';
  static const String registerEndpoint = '/api/Auth/register';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Cache dla tokenów
  String? _cachedToken;
  String? _cachedUid;

  // Rejestracja przez Twoje API
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      print('Attempting registration to: $baseUrl$registerEndpoint');
      print('Data: email=$email, password=$password');

      // Przygotuj dane - dostosuj do swojego API
      final Map<String, dynamic> requestBody = {
        'email': email,
        'password': password,
      };

      // Dodaj username tylko jeśli API go wymaga
      if (username != null && username.isNotEmpty) {
        requestBody['username'] = username;
      }

      print('Request body: ${jsonEncode(requestBody)}');

      final response = await http
          .post(
            Uri.parse('$baseUrl$registerEndpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout - check your API URL');
            },
          );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Zapisz dane użytkownika
        await _saveUserData(data);

        return data;
      } else {
        // Spróbuj zdekodować błąd
        try {
          final error = jsonDecode(response.body);
          // .NET API często zwraca błędy w formacie { errors: { ... } }
          if (error['errors'] != null) {
            final errorMessages = error['errors'].values.join(', ');
            throw Exception(errorMessages);
          }
          throw Exception(
            error['detail'] ??
                error['message'] ??
                error['title'] ??
                'Registration failed',
          );
        } catch (e) {
          if (response.statusCode == 400) {
            throw Exception(
              'Bad request - check email format and password requirements',
            );
          } else if (response.statusCode == 409) {
            throw Exception('Email already registered');
          }
          throw Exception('Registration failed: ${response.body}');
        }
      }
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: ${e.message}. Check if your API is running on port 5018.',
      );
    } catch (e) {
      print('Registration error: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Logowanie przez Twoje API
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting login to: $baseUrl$loginEndpoint');

      final response = await http
          .post(
            Uri.parse('$baseUrl$loginEndpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout - check your API URL');
            },
          );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Zapisz dane użytkownika
        await _saveUserData(data);

        return data;
      } else {
        // Spróbuj zdekodować błąd
        try {
          final error = jsonDecode(response.body);
          throw Exception(
            error['detail'] ?? error['message'] ?? 'Login failed',
          );
        } catch (e) {
          throw Exception('Login failed: ${response.body}');
        }
      }
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error: ${e.message}. Check if your API is running.',
      );
    } catch (e) {
      print('Login error: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Zapisywanie danych użytkownika
  Future<void> _saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    print('Saving user data: $data');

    // Zapisz access token - sprawdź różne możliwe nazwy
    final token =
        data['access_token'] ??
        data['accessToken'] ??
        data['token'] ??
        data['auth_token'];

    if (token != null) {
      await prefs.setString('auth_token', token.toString());
      _cachedToken = token.toString();
      print('Saved token: ${token.toString().substring(0, 20)}...');
    }

    // Zapisz UID użytkownika - sprawdź różne możliwe struktury
    final uid =
        data['user_id'] ??
        data['userId'] ??
        data['uid'] ??
        data['id'] ??
        data['user']?['id'] ??
        data['user']?['uid'];

    if (uid != null) {
      await prefs.setString('user_uid', uid.toString());
      _cachedUid = uid.toString();
      print('Saved UID: $uid');
    }

    // Zapisz email
    final email = data['email'] ?? data['user']?['email'] ?? data['user_email'];

    if (email != null) {
      await prefs.setString('user_email', email.toString());
      print('Saved email: $email');
    }

    // Zapisz całą odpowiedź dla debugowania
    await prefs.setString('last_auth_response', jsonEncode(data));
  }

  // Pobierz token
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;

    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('auth_token');
    return _cachedToken;
  }

  // Pobierz UID
  Future<String?> getUid() async {
    if (_cachedUid != null) return _cachedUid;

    final prefs = await SharedPreferences.getInstance();
    _cachedUid = prefs.getString('user_uid');
    return _cachedUid;
  }

  // Pobierz wszystkie dane użytkownika
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // Dla debugowania - pokaż ostatnią odpowiedź
    final lastResponse = prefs.getString('last_auth_response');
    if (lastResponse != null) {
      print('Last auth response: $lastResponse');
    }

    return {
      'uid': await getUid(),
      'token': await getToken(),
      'email': prefs.getString('user_email'),
      'lastResponse': lastResponse != null ? jsonDecode(lastResponse) : null,
    };
  }

  // Sprawdź czy użytkownik jest zalogowany
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    final uid = await getUid();
    return token != null && uid != null;
  }

  // Wykonaj zapytanie z autoryzacją
  Future<http.Response> authenticatedRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? additionalHeaders,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No auth token - user not logged in');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      ...?additionalHeaders,
    };

    final url = '$baseUrl$endpoint';
    print('Authenticated request to: $url');

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(Uri.parse(url), headers: headers);
        break;
      case 'POST':
        response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PUT':
        response = await http.put(
          Uri.parse(url),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(Uri.parse(url), headers: headers);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    print('Response status: ${response.statusCode}');
    return response;
  }

  // Wylogowanie
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Wyczyść cache
    _cachedToken = null;
    _cachedUid = null;
  }

  // Test połączenia z API
  Future<bool> testConnection() async {
    try {
      // Spróbuj dostać się do głównego URL lub health check endpoint
      final testUrl =
          '$baseUrl/api/Auth'; // lub '$baseUrl/health' jeśli masz taki endpoint
      print('Testing connection to: $testUrl');

      final response = await http
          .get(Uri.parse(testUrl), headers: {'Accept': 'application/json'})
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('Connection timeout to $testUrl');
              return http.Response('Timeout', 408);
            },
          );

      print('API test response: ${response.statusCode}');
      // Akceptuj różne kody odpowiedzi które oznaczają że API działa
      return response.statusCode < 500 ||
          response.statusCode ==
              405; // 405 = Method Not Allowed (ale API działa)
    } catch (e) {
      print('API connection test failed: $e');
      print('Make sure your API is running on $baseUrl');
      return false;
    }
  }
}
