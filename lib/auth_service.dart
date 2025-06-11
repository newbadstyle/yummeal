import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // URL do Twojego API (Swagger)
  static const String loginUrl = 'http://localhost:5018/api/Auth/login';
  static const String registerUrl = 'http://localhost:5018/api/Auth/register';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Supabase client
  final SupabaseClient supabase = Supabase.instance.client;

  // Cache dla tokenów
  String? _cachedToken;
  String? _cachedUid;

  // Rejestracja przez Twoje API (które komunikuje się z Supabase)
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Zapisz dane użytkownika
        await _saveUserData(data);

        // Opcjonalnie: Zaloguj też przez Supabase SDK
        await _syncWithSupabase(email, password);

        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Logowanie przez Twoje API
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Zapisz dane użytkownika
        await _saveUserData(data);

        // Opcjonalnie: Zaloguj też przez Supabase SDK
        await _syncWithSupabase(email, password);

        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Synchronizacja z Supabase SDK (opcjonalne)
  Future<void> _syncWithSupabase(String email, String password) async {
    try {
      // Spróbuj zalogować przez Supabase SDK
      await supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      // Jeśli logowanie się nie udało, spróbuj utworzyć konto
      try {
        await supabase.auth.signUp(email: email, password: password);
      } catch (signUpError) {
        // Ignoruj błędy - API jest głównym źródłem prawdy
        print('Supabase sync error: $signUpError');
      }
    }
  }

  // Zapisywanie danych użytkownika
  Future<void> _saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    // Zapisz access token - różne API mogą zwracać token pod różnymi nazwami
    final token =
        data['access_token'] ??
        data['accessToken'] ??
        data['token'] ??
        data['session']?['access_token'];

    if (token != null) {
      await prefs.setString('auth_token', token);
      _cachedToken = token;
    }

    // Zapisz UID użytkownika - również może być pod różnymi nazwami
    final uid =
        data['user']?['id'] ??
        data['uid'] ??
        data['userId'] ??
        data['user_id'] ??
        data['id'];

    if (uid != null) {
      await prefs.setString('user_uid', uid.toString());
      _cachedUid = uid.toString();
    }

    // Zapisz refresh token jeśli jest
    final refreshToken =
        data['refresh_token'] ??
        data['refreshToken'] ??
        data['session']?['refresh_token'];

    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
    }

    // Zapisz dane użytkownika
    if (data['user'] != null) {
      await prefs.setString('user_data', jsonEncode(data['user']));
    }

    // Zapisz email
    final email =
        data['user']?['email'] ??
        data['email'] ??
        supabase.auth.currentUser?.email;

    if (email != null) {
      await prefs.setString('user_email', email);
    }
  }

  // Pobierz token
  Future<String?> getToken() async {
    // Najpierw sprawdź cache
    if (_cachedToken != null) return _cachedToken;

    // Potem SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('auth_token');

    // Jeśli nie ma, sprawdź Supabase SDK
    if (_cachedToken == null) {
      final session = supabase.auth.currentSession;
      if (session != null) {
        _cachedToken = session.accessToken;
        await prefs.setString('auth_token', _cachedToken!);
      }
    }

    return _cachedToken;
  }

  // Pobierz UID
  Future<String?> getUid() async {
    // Najpierw sprawdź cache
    if (_cachedUid != null) return _cachedUid;

    // Potem SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _cachedUid = prefs.getString('user_uid');

    // Jeśli nie ma, sprawdź Supabase SDK
    if (_cachedUid == null) {
      final user = supabase.auth.currentUser;
      if (user != null) {
        _cachedUid = user.id;
        await prefs.setString('user_uid', _cachedUid!);
      }
    }

    return _cachedUid;
  }

  // Pobierz wszystkie dane użytkownika
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // Pobierz dane z różnych źródeł
    final uid = await getUid();
    final token = await getToken();
    final email =
        prefs.getString('user_email') ?? supabase.auth.currentUser?.email;

    // Spróbuj odczytać zapisane dane użytkownika
    Map<String, dynamic>? userData;
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      try {
        userData = jsonDecode(userDataString);
      } catch (e) {
        userData = null;
      }
    }

    return {
      'uid': uid,
      'token': token,
      'email': email,
      'userData': userData,
      'isSupabaseConnected': supabase.auth.currentUser != null,
    };
  }

  // Sprawdź czy użytkownik jest zalogowany
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    final uid = await getUid();

    // Użytkownik jest zalogowany jeśli ma token i UID
    return token != null && uid != null;
  }

  // Wykonaj zapytanie z autoryzacją
  Future<http.Response> authenticatedRequest({
    required String url,
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

    // Jeśli token wygasł, spróbuj odświeżyć
    if (response.statusCode == 401) {
      await _refreshToken();
      // Powtórz zapytanie z nowym tokenem
      return authenticatedRequest(
        url: url,
        method: method,
        body: body,
        additionalHeaders: additionalHeaders,
      );
    }

    return response;
  }

  // Odśwież token
  Future<void> _refreshToken() async {
    try {
      // Najpierw spróbuj przez Supabase SDK
      final session = await supabase.auth.refreshSession();
      if (session.session != null) {
        await _saveUserData({
          'access_token': session.session!.accessToken,
          'refresh_token': session.session!.refreshToken,
          'user': {'id': session.session!.user.id},
        });
        return;
      }
    } catch (e) {
      // Jeśli Supabase SDK nie działa, użyj API
    }

    // Spróbuj przez API
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null) {
      throw Exception('No refresh token - login required');
    }

    // Tutaj wywołaj endpoint do odświeżania tokena
    // final response = await http.post(...);
  }

  // Wylogowanie
  Future<void> logout() async {
    // Wyloguj z Supabase
    try {
      await supabase.auth.signOut();
    } catch (e) {
      print('Supabase logout error: $e');
    }

    // Wyczyść lokalne dane
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_uid');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
    await prefs.remove('user_email');

    // Wyczyść cache
    _cachedToken = null;
    _cachedUid = null;
  }

  // Metody pomocnicze dla Supabase

  // Pobierz dane z tabeli Supabase
  Future<List<Map<String, dynamic>>> getSupabaseData(String table) async {
    try {
      final response = await supabase.from(table).select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching data from $table: $e');
    }
  }

  // Dodaj dane do tabeli Supabase
  Future<Map<String, dynamic>> insertSupabaseData(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final response =
          await supabase.from(table).insert(data).select().single();
      return response;
    } catch (e) {
      throw Exception('Error inserting data to $table: $e');
    }
  }
}
